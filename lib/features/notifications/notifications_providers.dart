import 'dart:async';

import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/utils/clock_provider.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/data/local_stores.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/domain/inbox_state.dart';
import 'package:air_reply/features/notifications/domain/send_reply.dart';
import 'package:air_reply/features/notifications/history_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
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

/// Every paired device's newest notifications joined with their replies, newest first, as they arrive. A sender sees
/// what it shared (the same notification went to each device, so copies are merged); a receiver sees what its phones
/// sent. One unreachable device does not hide the others. The inbox, its counts and its alerts come from here.
final liveFeedProvider = Provider.autoDispose<AsyncValue<List<FeedEntry>>>((ref) => _feed(ref, const []));

/// The live feed plus the history on screen (a search's results, a phone's history), so a notification from long ago
/// that is shown groups with its chat and opens like any other. For finding what to open, not for counting.
final allFeedProvider = Provider.autoDispose<AsyncValue<List<FeedEntry>>>((ref) {
  final history = shownHistory(ref);
  // nothing on screen beyond the live feed (the usual case): the same list, not built twice
  if (history.every((h) => h.pages.values.every((p) => p.notifications.isEmpty))) return ref.watch(liveFeedProvider);
  return _feed(ref, history);
});

AsyncValue<List<FeedEntry>> _feed(Ref ref, List<HistoryResults> history) {
  final pairs = ref.watch(pairedDevicesProvider);
  final feeds = <List<FeedEntry>>[];
  var loading = false;
  AsyncError<List<FeedEntry>>? firstError;

  for (final pair in pairs) {
    final notifications = ref.watch(mirroredNotificationsProvider(pair.pairId));
    final replies = ref.watch(sentRepliesProvider(pair.pairId));
    if (notifications.value case final items?) {
      final (all, allReplies) = _withHistory(items, replies.value ?? const [], [
        for (final h in history) ?h.pages[pair.pairId],
      ]);
      feeds.add(buildFeed(all, allReplies, pairId: pair.pairId, deviceName: pair.peerName));
    } else if (notifications case AsyncError(:final error, :final stackTrace)) {
      firstError ??= AsyncError(error, stackTrace);
    } else {
      loading = true;
    }
  }

  if (feeds.isEmpty && firstError != null) return firstError;
  if (feeds.isEmpty && loading) return const AsyncLoading();
  return AsyncData(mergeFeeds(feeds, dedupe: ref.watch(deviceRoleProvider) == DeviceRole.sender));
}

/// [items] and [replies] with the pages of history read for the same pair, each once.
(List<MirroredNotification>, List<ReplyCommand>) _withHistory(
  List<MirroredNotification> items,
  List<ReplyCommand> replies,
  List<PairPages> pages,
) {
  if (pages.every((p) => p.notifications.isEmpty)) return (items, replies);
  final ids = {for (final n in items) n.id};
  final replyIds = {for (final r in replies) r.id};
  return (
    [
      ...items,
      for (final p in pages)
        for (final n in p.notifications)
          if (ids.add(n.id)) n,
    ],
    [
      ...replies,
      for (final p in pages)
        for (final r in p.replies)
          if (replyIds.add(r.id)) r,
    ],
  );
}

/// What is typed into Home's search box; the inbox keeps its own in [inboxFilterProvider].
final homeSearchQueryProvider = NotifierProvider<HomeSearchQuery, String>(HomeSearchQuery.new);

final class HomeSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

/// One notification, for the detail screen; null once it is gone (or while loading).
final feedEntryProvider = Provider.autoDispose.family<FeedEntry?, ({String pairId, String id})>((ref, target) {
  final entries = ref.watch(allFeedProvider).value ?? const <FeedEntry>[];
  return entries.where((e) => e.pairId == target.pairId && e.notification.id == target.id).firstOrNull ??
      // A sender's merged entry is keyed by the first pair it went to; find copies by notification id too.
      entries.where((e) => e.notification.id == target.id).firstOrNull;
});

/// Every notification's thread, by its entry key: built once per change of the inbox, so each row finds its chat
/// without searching every conversation.
final _threadOfProvider = Provider.autoDispose<Map<String, ConversationThread>>(
  (ref) => {
    for (final group in ref.watch(_allGroupsProvider))
      for (final thread in group.threads)
        for (final e in thread.entries) e.key: thread,
  },
);

/// The notifications grouped with one (its thread: a chat, or a notice and its updates), oldest first; empty while it
/// is not in any (loading, or hidden). Grouping decides this, never Android's notification key alone, which some apps
/// share between chats.
final conversationProvider = Provider.autoDispose.family<List<FeedEntry>, ({String pairId, String id})>((ref, target) {
  final thread = ref.watch(_threadOfProvider.select((index) => index['${target.pairId}/${target.id}']));
  return thread == null ? const [] : thread.entries.reversed.toList();
});

/// The chat a notification is shown in (a person or a group chat), or null when it is in none: an app's own notice,
/// or hidden. Opening such a notification opens its chat.
final chatOfProvider = Provider.autoDispose.family<ConversationThread?, ({String pairId, String id})>((ref, target) {
  final thread = ref.watch(_threadOfProvider.select((index) => index['${target.pairId}/${target.id}']));
  return thread == null || thread.kind == ThreadKind.single ? null : thread;
});

/// Whether a notification is a message the phone's user wrote, and how (see [ownMessage]): rows and the detail screen
/// show it as yours, under the other person's name, so your own words do not look like a message from someone else.
/// Judged within the chat it was grouped into, never by Android's notification key, which some apps share between
/// chats.
final ownMessageProvider = Provider.autoDispose.family<OwnMessage?, ({String pairId, String id})>((ref, target) {
  final entry = ref.watch(feedEntryProvider(target));
  if (entry == null) return null;
  final chat = ref.watch(chatOfProvider(target));
  return ownMessage(entry, chat?.replies ?? entry.replies);
});

/// Who a notification's conversation is with: its chat's name, from the newest of its notifications that is not the
/// user's own. Null when none names anyone.
final conversationNameProvider = Provider.autoDispose.family<String?, ({String pairId, String id})>((ref, target) {
  final chat = ref.watch(chatOfProvider(target));
  if (chat == null) return null;
  // a chat of only your own messages has no name of its own (its title falls back to the app's)
  final named = chat.entries.any((e) => ownMessage(e, chat.replies) == null);
  return named ? chat.title : null;
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
    // a pair that ends takes its read and hidden marks with it
    ref.listen(pairedDevicesProvider, (before, now) {
      final kept = {for (final p in now) p.pairId};
      for (final ended in before ?? const <PairingCredentials>[]) {
        if (!kept.contains(ended.pairId)) unawaited(_update((s) => s.forgetPair(ended.pairId)));
      }
    });
    // history that came back with a device paired again was read before it was removed
    ref.listen(continuedHistoryProvider, (_, keys) {
      if (keys.isNotEmpty) unawaited(markRead(keys));
    });
    final store = ref.watch(inboxStateStoreProvider);
    final saved = await store.load();
    if (saved != null) return saved;
    final fresh = InboxState(readBefore: DateTime.now());
    await store.save(fresh);
    return fresh;
  }

  /// Read in AirReply, so their alerts leave the system's notification panel too.
  Future<void> markRead(Iterable<String> keys) async {
    await _update((s) => s.markRead(keys));
    _dismissAlerts(keys);
  }

  Future<void> markUnread(Iterable<String> keys) => _update((s) => s.markUnread(keys));

  Future<void> markAllRead() async {
    await _update((s) => s.markAllRead(DateTime.now()));
    unawaited(_alerts((alerts) => alerts.dismissAll()));
  }

  Future<void> hide(Iterable<String> keys) async {
    await _update((s) => s.hide(keys));
    _dismissAlerts(keys);
  }

  /// Entry keys are `pairId/notificationId`; alerts are named by the notification.
  void _dismissAlerts(Iterable<String> keys) {
    final ids = [for (final key in keys) key.substring(key.indexOf('/') + 1)];
    if (ids.isNotEmpty) unawaited(_alerts((alerts) => alerts.dismiss(ids)));
  }

  /// Alerts are a courtesy here: where the system has none (tests, a Linux desktop without a notification daemon)
  /// reading still works.
  Future<void> _alerts(Future<void> Function(MirroredAlerts alerts) action) async {
    try {
      await action(ref.read(mirroredAlertsProvider));
    } on Object catch (e) {
      appLog('Alerts not taken down: $e', name: 'air_reply.alerts');
    }
  }

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

/// Read state for the UI; everything counts as read until the stored state has loaded. Your own messages (written on
/// the phone, or the app's copy of a reply) arrive read, unless marked unread on purpose.
bool Function(FeedEntry) _isRead(InboxState? inbox) => inbox == null
    ? (_) => true
    : (e) => !inbox.unread.contains(e.key) && (inbox.isRead(e) || isMarkedAsUser(e.notification.content));

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

/// The inbox as shown: hidden entries removed, filters applied. While searching, the search's results from the whole
/// history (see [historyResultsProvider]), which stay put as new notifications arrive; otherwise the live feed.
final visibleFeedProvider = Provider.autoDispose<AsyncValue<List<FeedEntry>>>((ref) {
  final searching = ref.watch(historyResultsProvider(inboxSearch).select((r) => r.isActive));
  final feed = searching
      ? AsyncData<List<FeedEntry>>(ref.watch(historyEntriesProvider(inboxSearch)))
      : ref.watch(liveFeedProvider);
  final inbox = ref.watch(inboxStateProvider).value;
  final filter = ref.watch(inboxFilterProvider);
  final isRead = _isRead(inbox);
  // filtered again as the day turns, so "Today" and "Last 7 days" move on with the clock
  ref.watch(clockProvider.select((t) => t.value?.day));
  final now = DateTime.now();
  return feed.whenData(
    (entries) => [
      for (final e in entries)
        if (!(inbox?.isHidden(e) ?? false) && filter.matches(e, isRead: isRead, now: now)) e,
    ],
  );
});

/// Not hidden: what the inbox holds before search and filters. Counts and Home come from here.
final _inboxEntriesProvider = Provider.autoDispose<List<FeedEntry>>((ref) {
  final inbox = ref.watch(inboxStateProvider).value;
  return [
    for (final e in ref.watch(liveFeedProvider).value ?? const <FeedEntry>[])
      if (!(inbox?.isHidden(e) ?? false)) e,
  ];
});

/// Not hidden, with the history on screen: what the group and chat screens find a notification in.
final _openableEntriesProvider = Provider.autoDispose<List<FeedEntry>>((ref) {
  final inbox = ref.watch(inboxStateProvider).value;
  return [
    for (final e in ref.watch(allFeedProvider).value ?? const <FeedEntry>[])
      if (!(inbox?.isHidden(e) ?? false)) e,
  ];
});

/// What [scope]'s results show: hidden notifications left out.
final shownResultsProvider = Provider.autoDispose.family<List<FeedEntry>, HistoryScope>((ref, scope) {
  final inbox = ref.watch(inboxStateProvider).value;
  return [
    for (final e in ref.watch(historyEntriesProvider(scope)))
      if (!(inbox?.isHidden(e) ?? false)) e,
  ];
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final isRead = _isRead(ref.watch(inboxStateProvider).value);
  return ref.watch(_inboxEntriesProvider).where((e) => !isRead(e)).length;
});

final todayCountProvider = Provider.autoDispose<int>((ref) {
  // rolls over at midnight while Home stays open
  final now = ref.watch(clockProvider).value ?? DateTime.now();
  return ref.watch(_inboxEntriesProvider).where((e) => FeedPeriod.today.includes(e.postedAt, now)).length;
});

final hiddenCountProvider = Provider.autoDispose<int>((ref) => ref.watch(inboxStateProvider).value?.hidden.length ?? 0);

// ------------------------------------------------------------------ smart grouping

/// Senders gather the copies of a notification sent to every device under one app group; receivers keep each
/// phone's apps apart.
final _groupPerDeviceProvider = Provider.autoDispose<bool>((ref) => ref.watch(deviceRoleProvider) != DeviceRole.sender);

/// The inbox as app groups and conversations, latest activity first, with search and filters applied.
final groupedInboxProvider = Provider.autoDispose<AsyncValue<List<AppGroup>>>((ref) {
  final perDevice = ref.watch(_groupPerDeviceProvider);
  return ref.watch(visibleFeedProvider).whenData((entries) => groupByApp(entries, perDevice: perDevice));
});

/// Every group, ignoring search and filters (hidden notifications excluded), for the group screens.
final _allGroupsProvider = Provider.autoDispose<List<AppGroup>>(
  (ref) => groupByApp(ref.watch(_openableEntriesProvider), perDevice: ref.watch(_groupPerDeviceProvider)),
);

/// One app's group, kept current as notifications arrive; null once it is gone.
final appGroupProvider = Provider.autoDispose.family<AppGroup?, ({String source, String packageName})>(
  (ref, g) =>
      ref.watch(_allGroupsProvider).where((a) => a.source == g.source && a.packageName == g.packageName).firstOrNull,
);

/// One conversation, kept current as notifications arrive; null once it is gone. A chat opened from your own message
/// before the other person's arrived is followed when it takes their name (its key gains the person: `id:x|name`).
final threadProvider = Provider.autoDispose
    .family<ConversationThread?, ({String source, String packageName, String key})>((ref, t) {
      final threads = ref.watch(appGroupProvider((source: t.source, packageName: t.packageName)))?.threads ?? const [];
      final exact = threads.where((thread) => thread.key == t.key).firstOrNull;
      if (exact != null) return exact;
      final named = threads.where((thread) => thread.key.startsWith('${t.key}|')).toList();
      return named.length == 1 ? named.single : null;
    });

/// The newest few notifications, for Home.
final recentEntriesProvider = Provider.autoDispose<AsyncValue<List<FeedEntry>>>((ref) {
  final recent = ref.watch(_inboxEntriesProvider).take(5).toList();
  return ref.watch(liveFeedProvider).whenData((_) => recent);
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
