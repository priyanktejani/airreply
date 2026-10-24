import 'dart:async';

import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/data/local_stores.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/inbox_state.dart';
import 'package:air_reply/features/notifications/domain/send_reply.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ------------------------------------------------------------------ per pair, straight from the backend

final mirroredNotificationsProvider = StreamProvider.autoDispose.family<List<MirroredNotification>, String>(
  (ref, pairId) => ref.watch(notificationFeedProvider(pairId)).watchNotifications(),
);

final sentRepliesProvider = StreamProvider.autoDispose.family<List<ReplyCommand>, String>(
  (ref, pairId) => ref.watch(notificationFeedProvider(pairId)).watchReplies(),
);

/// Live / connecting / offline, per pair.
final syncStateProvider = StreamProvider.autoDispose.family<SyncState, String>(
  (ref, pairId) => ref.watch(notificationFeedProvider(pairId)).watchSyncState(),
);

final sendReplyProvider = Provider.family<SendReply, String>(
  (ref, pairId) => SendReply(ref.watch(replyOutboxProvider(pairId))),
);

final mirroredAlertsProvider = Provider((ref) => MirroredAlerts(FlutterLocalNotificationsPlugin()));

/// Resubscribes a pair's listeners: "Retry" after an error, and pull to refresh.
void refreshPair(WidgetRef ref, String pairId) => ref
  ..invalidate(mirroredNotificationsProvider(pairId))
  ..invalidate(sentRepliesProvider(pairId))
  ..invalidate(syncStateProvider(pairId));

// ------------------------------------------------------------------ the merged feed

/// Every paired device's notifications joined with their replies, newest first. A sender sees what it shared (the
/// same notification went to each device, so copies are merged); a receiver sees what its phones sent. One
/// unreachable device does not hide the others.
final allFeedProvider = Provider.autoDispose<AsyncValue<List<FeedEntry>>>((ref) {
  final pairs = ref.watch(pairedDevicesProvider);
  final feeds = <List<FeedEntry>>[];
  var loading = false;
  AsyncError<List<FeedEntry>>? firstError;

  for (final pair in pairs) {
    final notifications = ref.watch(mirroredNotificationsProvider(pair.pairId));
    final replies = ref.watch(sentRepliesProvider(pair.pairId));
    if (notifications.value case final items?) {
      feeds.add(buildFeed(items, replies.value ?? const [], pairId: pair.pairId, deviceName: pair.peerName));
    } else if (notifications case AsyncError(:final error, :final stackTrace)) {
      firstError ??= AsyncError(error, stackTrace);
    } else {
      loading = true;
    }
  }

  if (feeds.isEmpty && firstError != null) return firstError;
  if (feeds.isEmpty && loading) return const AsyncLoading();
  return AsyncData(mergeFeeds(feeds, dedupe: ref.watch(deviceRoleProvider) == DeviceRole.sender));
});

/// One notification, for the detail screen; null once it is gone (or while loading).
final feedEntryProvider = Provider.autoDispose.family<FeedEntry?, ({String pairId, String id})>((ref, target) {
  final entries = ref.watch(allFeedProvider).value ?? const <FeedEntry>[];
  return entries.where((e) => e.pairId == target.pairId && e.notification.id == target.id).firstOrNull ??
      // A sender's merged entry is keyed by the first pair it went to; find copies by notification id too.
      entries.where((e) => e.notification.id == target.id).firstOrNull;
});

/// Every notification of the same conversation as [entry] from the same device, oldest first.
final conversationProvider = Provider.autoDispose.family<List<FeedEntry>, ({String pairId, String key})>((ref, c) {
  final entries = ref.watch(allFeedProvider).value ?? const <FeedEntry>[];
  return [
    for (final e in entries.reversed)
      if (e.pairId == c.pairId && e.notification.content.key == c.key) e,
  ];
});

// ------------------------------------------------------------------ read, unread, hidden

final inboxStateStoreProvider = Provider<InboxStateStore>(
  (ref) => PreferencesInboxStateStore(ref.watch(sharedPreferencesProvider)),
);

final inboxStateProvider = AsyncNotifierProvider<InboxController, InboxState>(InboxController.new);

/// What this device has read and hidden. On first use everything already there counts as read, so a long history
/// does not open as hundreds of unread notifications.
final class InboxController extends AsyncNotifier<InboxState> {
  @override
  Future<InboxState> build() async {
    final store = ref.watch(inboxStateStoreProvider);
    final saved = await store.load();
    if (saved != null) return saved;
    final fresh = InboxState(readBefore: DateTime.now());
    await store.save(fresh);
    return fresh;
  }

  Future<void> markRead(Iterable<String> keys) => _update((s) => s.markRead(keys));

  Future<void> markUnread(Iterable<String> keys) => _update((s) => s.markUnread(keys));

  Future<void> markAllRead() => _update((s) => s.markAllRead(DateTime.now()));

  Future<void> hide(Iterable<String> keys) => _update((s) => s.hide(keys));

  Future<void> unhide(Iterable<String> keys) => _update((s) => s.unhide(keys));

  Future<void> restoreHidden() => _update((s) => s.restoreHidden());

  /// Puts back an earlier state: Undo after "Mark all as read".
  Future<void> restore(InboxState previous) => _update((_) => previous);

  Future<void> _update(InboxState Function(InboxState current) change) async {
    final next = change(state.value ?? await future);
    state = AsyncData(next);
    await ref.read(inboxStateStoreProvider).save(next);
  }
}

/// Read state for the UI; everything counts as read until the stored state has loaded.
bool Function(FeedEntry) _isRead(InboxState? inbox) => inbox == null ? (_) => true : inbox.isRead;

// ------------------------------------------------------------------ search and filters

final inboxFilterProvider = NotifierProvider<InboxFilterController, FeedFilter>(InboxFilterController.new);

final class InboxFilterController extends Notifier<FeedFilter> {
  @override
  FeedFilter build() {
    // A filter on a device that was removed would hide everything.
    ref.listen(pairedDevicesProvider, (_, pairs) {
      if (state.pairId != null && pairs.every((p) => p.pairId != state.pairId)) device(null);
    });
    return FeedFilter.none;
  }

  void set(FeedFilter filter) => state = filter;

  void device(String? pairId) => state = state.copyWith(pairId: () => pairId);

  void app(String? packageName) => state = state.copyWith(packageName: () => packageName);

  void search(String query) => state = state.copyWith(query: query);

  void unreadOnly(bool value) => state = state.copyWith(unreadOnly: value);

  void period(FeedPeriod period) => state = state.copyWith(period: period);

  /// Clears every filter but keeps the search text.
  void clearFilters() => state = FeedFilter(query: state.query);

  void clear() => state = FeedFilter.none;
}

/// The inbox as shown: hidden entries removed, filters applied.
final visibleFeedProvider = Provider.autoDispose<AsyncValue<List<FeedEntry>>>((ref) {
  final feed = ref.watch(allFeedProvider);
  final inbox = ref.watch(inboxStateProvider).value;
  final filter = ref.watch(inboxFilterProvider);
  final isRead = _isRead(inbox);
  final now = DateTime.now();
  return feed.whenData(
    (entries) => [
      for (final e in entries)
        if (!(inbox?.isHidden(e) ?? false) && filter.matches(e, isRead: isRead, now: now)) e,
    ],
  );
});

final feedDaysProvider = Provider.autoDispose<AsyncValue<List<FeedDay>>>(
  (ref) => ref.watch(visibleFeedProvider).whenData(groupByDay),
);

/// Not hidden: what the inbox holds before search and filters.
final _inboxEntriesProvider = Provider.autoDispose<List<FeedEntry>>((ref) {
  final inbox = ref.watch(inboxStateProvider).value;
  return [
    for (final e in ref.watch(allFeedProvider).value ?? const <FeedEntry>[])
      if (!(inbox?.isHidden(e) ?? false)) e,
  ];
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final isRead = _isRead(ref.watch(inboxStateProvider).value);
  return ref.watch(_inboxEntriesProvider).where((e) => !isRead(e)).length;
});

final todayCountProvider = Provider.autoDispose<int>((ref) {
  final now = DateTime.now();
  return ref.watch(_inboxEntriesProvider).where((e) => FeedPeriod.today.includes(e.postedAt, now)).length;
});

final hiddenCountProvider = Provider.autoDispose<int>((ref) => ref.watch(inboxStateProvider).value?.hidden.length ?? 0);

/// The newest few notifications, for Home.
final recentEntriesProvider = Provider.autoDispose<AsyncValue<List<FeedEntry>>>((ref) {
  final recent = ref.watch(_inboxEntriesProvider).take(5).toList();
  return ref.watch(allFeedProvider).whenData((_) => recent);
});

/// Tells whether an entry has been read, for rows and the detail screen.
final readCheckProvider = Provider.autoDispose<bool Function(FeedEntry)>(
  (ref) => _isRead(ref.watch(inboxStateProvider).value),
);

/// The newest notification time per device, for "last notification" on Devices.
final lastActivityProvider = Provider.autoDispose.family<DateTime?, String>(
  (ref, pairId) => ref.watch(mirroredNotificationsProvider(pairId).select((n) => n.value?.firstOrNull?.postedAt)),
);

/// Apps in the feed, for the app filter and muting: package name -> app name, by name.
final feedAppsProvider = Provider.autoDispose<Map<String, String>>((ref) {
  final apps = <String, String>{};
  for (final e in ref.watch(allFeedProvider).value ?? const <FeedEntry>[]) {
    apps.putIfAbsent(e.notification.content.packageName, () => e.notification.content.appName);
  }
  final sorted = apps.entries.toList()..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
  return Map.fromEntries(sorted);
});

// ------------------------------------------------------------------ app icons

final appIconCacheProvider = Provider((ref) => AppIconCache(ref.watch(sharedPreferencesProvider)));

/// App icons by package name. Senders attach an app's icon to its notifications now and then; receivers keep the
/// latest one here (and on disk) so every notification of that app shows it.
final appIconsProvider = NotifierProvider<AppIconsController, Map<String, Uint8List>>(AppIconsController.new);

final class AppIconsController extends Notifier<Map<String, Uint8List>> {
  Timer? _saveSoon;

  @override
  Map<String, Uint8List> build() {
    ref.onDispose(() => _saveSoon?.cancel());
    final initial = <String, Uint8List>{};
    for (final pair in ref.watch(pairedDevicesProvider)) {
      final provider = mirroredNotificationsProvider(pair.pairId);
      _collect(ref.read(provider).value, initial);
      ref.listen(provider, (_, next) => _harvest(next.value));
    }
    unawaited(
      ref.read(appIconCacheProvider).load().then((saved) {
        if (ref.mounted && saved.isNotEmpty) state = {...saved, ...state};
      }),
    );
    return initial;
  }

  void _harvest(List<MirroredNotification>? items) {
    final next = {...state};
    if (!_collect(items, next)) return;
    state = next;
    _saveSoon?.cancel();
    _saveSoon = Timer(const Duration(seconds: 2), () => unawaited(ref.read(appIconCacheProvider).save(state)));
  }

  /// Adds the newest icon of each app in [items] to [into]; true when anything changed.
  static bool _collect(List<MirroredNotification>? items, Map<String, Uint8List> into) {
    var changed = false;
    // Oldest first, so the newest icon of an app wins.
    for (final n in (items ?? const <MirroredNotification>[]).reversed) {
      final icon = n.content.iconPng;
      if (icon == null) continue;
      final package = n.content.packageName;
      if (!listEquals(into[package], icon)) {
        into[package] = icon;
        changed = true;
      }
    }
    return changed;
  }
}

/// The icon the sender's own system has for an app (senders only).
final _nativeIconProvider = FutureProvider.family<Uint8List?, String>(
  (ref, packageName) => ref.watch(notificationBridgeProvider).appIcon(packageName).catchError((Object _) => null),
);

/// One app's icon, or null for the monogram fallback.
final appIconProvider = Provider.autoDispose.family<Uint8List?, String>((ref, packageName) {
  final harvested = ref.watch(appIconsProvider.select((icons) => icons[packageName]));
  if (harvested != null) return harvested;
  if (ref.watch(deviceRoleProvider) != DeviceRole.sender) return null;
  return ref.watch(_nativeIconProvider(packageName)).value;
});
