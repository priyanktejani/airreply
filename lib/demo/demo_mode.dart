import 'dart:async';
import 'dart:typed_data';

import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/core/platform/notification_permission.dart';
import 'package:air_reply/features/mirror/cleanup_providers.dart';
import 'package:air_reply/features/mirror/domain/entities/history_query.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/domain/inbox_state.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:air_reply/features/pairing/pairing_providers.dart';
import 'package:air_reply/features/session/domain/device_settings_store.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/misc.dart' show Override;

// Demo mode: the real screens, controllers and use cases running on in-memory sample data instead of Firebase and
// the Android notification listener. For design reviews, screenshots and trying the UI on any platform:
//
//   flutter run -d chrome --dart-define=AIRREPLY_DEMO=receiver
//   flutter run -d macos  --dart-define=AIRREPLY_DEMO=sender

List<Override> demoOverrides(String role) {
  final deviceRole = role == 'sender' ? DeviceRole.sender : DeviceRole.receiver;
  return [
    deviceSettingsStoreProvider.overrideWithValue(_DemoSettings(deviceRole)),
    pairingCredentialsStoreProvider.overrideWithValue(_DemoPairs(deviceRole)),
    pairingRepositoryProvider.overrideWithValue(_DemoPairing()),
    mirrorRepositoryProvider.overrideWith((ref, pairId) => _DemoMirror.of(pairId)),
    // sample history lives in memory: removing a demo device leaves the real database alone
    eraseHistoryProvider.overrideWithValue((_) async {}),
    removeDoorbellProvider.overrideWithValue((_) async {}),
    notificationBridgeProvider.overrideWithValue(_DemoBridge()),
    notificationPermissionProvider.overrideWithValue(_DemoPermission()),
    inboxStateStoreProvider.overrideWithValue(_DemoInbox()),
  ];
}

/// The last 20 minutes start out unread, so the inbox shows both states.
final class _DemoInbox implements InboxStateStore {
  InboxState? _state = InboxState(readBefore: _ago(const Duration(minutes: 20)));

  @override
  Future<InboxState?> load() async => _state;

  @override
  Future<void> save(InboxState state) async => _state = state;
}

/// Fresh sample data, so one test's replies do not leak into the next.
@visibleForTesting
void resetDemoData() => _DemoMirror._instances.clear();

final _now = DateTime.now();
DateTime _ago(Duration d) => _now.subtract(d);

final class _DemoSettings implements DeviceSettingsStore {
  _DemoSettings(this.role);

  DeviceRole? role;

  @override
  Future<DeviceRole?> readRole() async => role;

  @override
  Future<void> writeRole(DeviceRole? role) async => this.role = role;

  @override
  Future<bool> readDisclosureAccepted() async => true;

  @override
  Future<void> writeDisclosureAccepted() async {}
}

final class _DemoPairs implements PairingCredentialsStore {
  _DemoPairs(DeviceRole role)
    : _pairs = [
        for (final (id, name, age)
            in role == DeviceRole.receiver
                ? [('pixel', 'Pixel 9 Pro', 21), ('galaxy', 'Galaxy S25', 3)]
                : [('pixel', 'MacBook Pro', 14), ('galaxy', 'iPad Air', 2)])
          PairingCredentials(
            pairId: id,
            role: role,
            sharedKey: Uint8List(32),
            peerName: name,
            pairedAt: _ago(Duration(days: age)),
          ),
      ];

  final List<PairingCredentials> _pairs;

  @override
  Future<List<PairingCredentials>> readAll() async => [..._pairs];

  @override
  Future<void> save(PairingCredentials credentials) async => _pairs
    ..removeWhere((p) => p.pairId == credentials.pairId)
    ..add(credentials);

  @override
  Future<void> remove(String pairId) async => _pairs.removeWhere((p) => p.pairId == pairId);
}

final class _DemoPairing implements PairingRepository {
  static const _unavailable = PairingException('Pairing is turned off in demo mode.');

  @override
  Stream<bool> watchPairActive(String pairId) => Stream.value(true);

  @override
  Future<void> endPair(String pairId) async {}

  @override
  Future<void> registerPushToken({required String pairId, required DeviceRole role, required String token}) async {}

  @override
  Future<PairingSession> createSession({required Uint8List senderPublicKey, required String senderName}) =>
      Future.error(_unavailable);

  @override
  Future<PairingSession?> fetchSession(String code) => Future.error(_unavailable);

  @override
  Stream<PairingSession?> watchSession(String code) => Stream.error(_unavailable);

  @override
  Future<PairingSession> joinSession({
    required String code,
    required Uint8List receiverPublicKey,
    required String receiverName,
  }) => Future.error(_unavailable);

  @override
  Future<String> confirmSession(PairingSession session) => Future.error(_unavailable);

  @override
  Future<void> cancelSession(String code) async {}
}

/// One phone's feed. Replies go "Sending" then "Sent" after a moment, like a real phone answering.
final class _DemoMirror implements MirrorRepository {
  _DemoMirror(this._notifications, this._replies);

  static final _instances = <String, _DemoMirror>{};

  static _DemoMirror of(String pairId) => _instances.putIfAbsent(pairId, () => _seed(pairId));

  final List<MirroredNotification> _notifications;
  final List<ReplyCommand> _replies;
  final _changes = StreamController<void>.broadcast();

  /// One sample notification. [chat] (the app's conversation id) and [group] (a group chat's name) give it the
  /// conversation metadata a real phone reports; [isMessage] null mimics a notification mirrored before the phone
  /// reported it.
  static MirroredNotification _n(
    String id,
    String package,
    String app,
    String title,
    String text,
    Duration ago, {
    bool canReply = true,
    bool dismissed = false,
    bool? isMessage = true,
    String? chat,
    String? group,
    String? sender,
  }) => MirroredNotification(
    id: id,
    content: NotificationContent(
      key: 'demo|$package|$id',
      packageName: package,
      appName: app,
      title: title,
      text: sender == null ? text : '$sender: $text',
      postedAt: _ago(ago),
      conversationTitle: group,
      isGroupConversation: group != null,
      sender: sender,
      conversationId: chat,
      isMessage: isMessage,
    ),
    canReply: canReply,
    dismissedOnSender: dismissed,
  );

  static Duration _min(int m) => Duration(minutes: m);

  static _DemoMirror _seed(String pairId) {
    if (pairId == 'galaxy') {
      return _DemoMirror([
        _n(
          'g1',
          'com.whatsapp',
          'WhatsApp',
          'Mom',
          'Call me when you\'re free, nothing urgent 🙂',
          _min(12),
          chat: 'mom',
        ),
        _n('g0', 'com.whatsapp', 'WhatsApp', 'Mom', 'Did you eat?', _min(55), chat: 'mom'),
        _n(
          'g2',
          'com.google.android.calendar',
          'Calendar',
          'Design review',
          'Starts in 10 minutes · Room 4B',
          _min(48),
          canReply: false,
          isMessage: false,
        ),
        _n(
          'g4',
          'com.google.android.calendar',
          'Calendar',
          'Standup',
          'Starts in 5 minutes · Zoom',
          const Duration(hours: 5),
          canReply: false,
          isMessage: false,
        ),
        _n(
          'g3',
          'com.ubercab',
          'Uber',
          'Your driver is arriving',
          'Arjun · White Swift · KA 05 MX 2231',
          const Duration(hours: 26),
          canReply: false,
          dismissed: true,
          isMessage: false,
        ),
      ], []);
    }
    return _DemoMirror(
      [
        // WhatsApp: two people (one known only by number, mirrored before conversation ids existed), a family group
        // with several senders, and an app notice that must stay on its own.
        _n(
          'p1',
          'com.whatsapp',
          'WhatsApp',
          'Alex Morgan',
          'Are we still on for 7? I booked the table by the window 🍝',
          _min(2),
          chat: 'alex',
        ),
        _n('p1b', 'com.whatsapp', 'WhatsApp', 'Alex Morgan', 'Traffic is light, 15 min', _min(4), chat: 'alex'),
        _n('p1a', 'com.whatsapp', 'WhatsApp', 'Alex Morgan', 'Leaving the office now', _min(31), chat: 'alex'),
        _n(
          'w3',
          'com.whatsapp',
          'WhatsApp',
          'Family',
          'Dinner at 8?',
          _min(15),
          chat: 'family',
          group: 'Family',
          sender: 'Dad',
        ),
        _n(
          'w2',
          'com.whatsapp',
          'WhatsApp',
          'Family',
          'Landed safely ✈️',
          _min(52),
          chat: 'family',
          group: 'Family',
          sender: 'Riya',
        ),
        _n(
          'w1',
          'com.whatsapp',
          'WhatsApp',
          '+91 74052 94614',
          'Is this the right number for the delivery?',
          _min(40),
          isMessage: null,
        ),
        _n('w0', 'com.whatsapp', 'WhatsApp', '+91 74052-94614', 'I\'m at the gate', _min(38), isMessage: null),
        _n(
          'w9',
          'com.whatsapp',
          'WhatsApp',
          'WhatsApp',
          'Chat backup completed',
          const Duration(hours: 6),
          canReply: false,
          isMessage: false,
        ),
        // Telegram and Slack group chats.
        _n(
          'p2',
          'org.telegram.messenger',
          'Telegram',
          'Design Crew',
          'pushed the new editorial mockups, have a look before standup',
          _min(9),
          group: 'Design Crew',
          sender: 'Sam',
        ),
        _n(
          'p2b',
          'org.telegram.messenger',
          'Telegram',
          'Design Crew',
          'the serif headlines look great',
          _min(8),
          group: 'Design Crew',
          sender: 'Lee',
        ),
        _n(
          'p3',
          'com.Slack',
          'Slack',
          '#launch',
          'release checklist is all green ✅ shipping at 5',
          _min(34),
          group: '#launch',
          sender: 'Priya',
        ),
        // Emails are notices, not chats: one per message, never merged by sender.
        _n(
          'p4',
          'com.google.android.gm',
          'Gmail',
          'Stripe',
          'Your payout of ₹48,200 is on its way and should arrive within 2 business days.',
          const Duration(hours: 3),
          canReply: false,
          isMessage: false,
        ),
        _n(
          'p6',
          'com.google.android.gm',
          'Gmail',
          'Figma',
          'Your export "AirReply screens" is ready to download.',
          const Duration(hours: 4),
          canReply: false,
          isMessage: false,
        ),
        _n(
          'p5',
          'com.instagram.android',
          'Instagram',
          'maya.designs',
          'replied to your story: "where is this?! 😍"',
          const Duration(hours: 27),
          dismissed: true,
        ),
      ],
      [
        ReplyCommand(
          id: 'r1',
          notificationId: 'p2',
          text: 'Looks great, will review in 5',
          status: ReplyStatus.sent,
          createdAt: _ago(_min(7)),
        ),
      ],
    );
  }

  Stream<T> _watch<T>(T Function() read) => Stream.multi((controller) {
    controller.add(read());
    final sub = _changes.stream.listen((_) => controller.add(read()));
    controller.onCancel = sub.cancel;
  });

  @override
  Stream<List<MirroredNotification>> watchNotifications({int limit = 200}) => _watch(() => [..._notifications]);

  @override
  Stream<List<ReplyCommand>> watchReplies({int limit = 300}) => _watch(() => [..._replies]);

  /// Connects after a moment, like a real listener reaching the server.
  @override
  Stream<SyncState> watchSyncState() async* {
    yield SyncState.connecting;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    yield SyncState(SyncHealth.live, lastSyncedAt: DateTime.now());
  }

  @override
  Future<void> send({required String notificationId, required String notificationKey, required String text}) async {
    final id = 'r${_replies.length + 1}-${DateTime.now().microsecondsSinceEpoch}';
    ReplyCommand reply(ReplyStatus status) =>
        ReplyCommand(id: id, notificationId: notificationId, text: text, status: status, createdAt: DateTime.now());
    _replies.add(reply(ReplyStatus.pending));
    _changes.add(null);
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        final i = _replies.indexWhere((r) => r.id == id);
        if (i >= 0) _replies[i] = reply(ReplyStatus.sent);
        _changes.add(null);
      }),
    );
  }

  @override
  Future<MirroredNotification?> fetchNotification(String id) async =>
      _notifications.where((n) => n.id == id).firstOrNull;

  @override
  Future<MirroredNotification?> decodePushed({required String id, required String payload, required bool canReply}) =>
      fetchNotification(id);

  /// The sample history, searched and paged as the database would.
  @override
  Future<HistoryPage> browseHistory(HistoryQuery query, {HistoryCursor? after, int limit = 50}) async {
    final matching = _matching(query).where(
      (n) =>
          after == null ||
          n.postedAt.isBefore(after.postedAt) ||
          (n.postedAt == after.postedAt && n.id.compareTo(after.id) < 0),
    );
    final page = matching.take(limit).toList();
    final ids = {for (final n in page) n.id};
    return (
      notifications: page,
      replies: [
        for (final r in _replies)
          if (ids.contains(r.notificationId)) r,
      ],
      next: page.length < limit ? null : (postedAt: page.last.postedAt, id: page.last.id),
      // the sample notifications never change: nothing arrives after a search
      saved: 0,
    );
  }

  @override
  Future<int> countHistory(HistoryQuery query) async => _matching(query).length;

  Iterable<MirroredNotification> _matching(HistoryQuery query) {
    final text = query.text.trim().toLowerCase();
    return ([..._notifications]..sort((a, b) {
          final byTime = b.postedAt.compareTo(a.postedAt);
          return byTime != 0 ? byTime : b.id.compareTo(a.id);
        }))
        .where(
          (n) =>
              (text.isEmpty ||
                  [n.content.title, n.content.text, n.content.appName].any((s) => s.toLowerCase().contains(text))) &&
              (query.packageName == null || n.content.packageName == query.packageName) &&
              (query.after == null || n.postedAt.isAfter(query.after!)) &&
              query.savedAfter == null,
        );
  }

  @override
  Future<void> publish(NotificationContent content, {required bool canReply}) async {}

  @override
  Future<void> markDismissed(String notificationKey) async {}

  @override
  Stream<List<PendingReply>> watchPending() => const Stream.empty();

  @override
  Future<List<PendingReply>> fetchPending() async => const [];

  @override
  Future<void> resolve(String replyId, ReplyStatus status) async {}
}

/// The sender's native layer, simulated: sharing is on, and a notification is "captured" every few seconds.
final class _DemoBridge implements NotificationBridge {
  var _status = const SyncStatus(enabled: true, running: true, listenerConnected: true);
  var _filter = const AppFilter(mode: AppFilterMode.selected, packages: {'com.whatsapp', 'org.telegram.messenger'});
  final _statusChanges = StreamController<NativeEvent>.broadcast();

  static const _samples = [
    ('com.whatsapp', 'WhatsApp', 'Alex Morgan', 'On my way, 5 min'),
    ('org.telegram.messenger', 'Telegram', 'Design Crew', 'Sam: love the square cards'),
    ('com.Slack', 'Slack', '#launch', 'Priya: build 214 is live'),
    ('com.whatsapp', 'WhatsApp', 'Mom', 'Don\'t forget dinner Sunday'),
  ];

  @override
  bool get isSupported => true;

  @override
  Stream<NativeEvent> events() {
    var i = 0;
    final captured = Stream<NativeEvent>.periodic(const Duration(seconds: 4), (_) {
      final (package, app, title, text) = _samples[i++ % _samples.length];
      return NotificationPostedEvent(
        CapturedNotification(
          key: 'demo|$i',
          packageName: package,
          appName: app,
          title: title,
          text: text,
          postedAt: DateTime.now(),
          canReply: true,
        ),
      );
    });
    return StreamGroupLite.merge([captured, _statusChanges.stream]);
  }

  @override
  Future<SyncStatus> syncStatus() async => _status;

  @override
  Future<void> startSync() async => _setEnabled(true);

  @override
  Future<void> stopSync() async => _setEnabled(false);

  @override
  Future<void> reloadSync() async {}

  void _setEnabled(bool enabled) {
    _status = SyncStatus(enabled: enabled, running: enabled, listenerConnected: true);
    _statusChanges.add(SyncStateEvent(_status));
  }

  @override
  Future<bool> isNotificationAccessGranted() async => true;

  @override
  Future<void> openNotificationAccessSettings() async {}

  @override
  Future<void> openBatteryOptimizationSettings() async {}

  @override
  Future<void> openAutostartSettings() async {}

  @override
  Future<BackgroundRestrictions> backgroundRestrictions() async => BackgroundRestrictions.none;

  @override
  Future<void> requestListenerRebind() async {}

  @override
  Future<Uint8List?> appIcon(String packageName) async => null;

  @override
  Future<List<InstalledApp>> installedApps() async => const [
    InstalledApp(packageName: 'com.google.android.calendar', label: 'Calendar'),
    InstalledApp(packageName: 'com.google.android.gm', label: 'Gmail'),
    InstalledApp(packageName: 'com.instagram.android', label: 'Instagram'),
    InstalledApp(packageName: 'com.Slack', label: 'Slack'),
    InstalledApp(packageName: 'org.telegram.messenger', label: 'Telegram'),
    InstalledApp(packageName: 'com.ubercab', label: 'Uber'),
    InstalledApp(packageName: 'com.whatsapp', label: 'WhatsApp'),
  ];

  @override
  Future<AppFilter> appFilter() async => _filter;

  @override
  Future<void> setAppFilter(AppFilter filter) async => _filter = filter;

  @override
  Future<ReplyDispatchResult> sendReply({required String notificationKey, required String text}) async =>
      ReplyDispatchResult.sent;
}

final class _DemoPermission implements NotificationPermission {
  @override
  Future<bool> isGranted() async => true;

  @override
  Future<bool> request() async => true;
}

/// Merges broadcast streams (enough for the demo; avoids a dependency on package:async).
abstract final class StreamGroupLite {
  static Stream<T> merge<T>(List<Stream<T>> streams) => Stream.multi((controller) {
    final subs = [for (final s in streams) s.listen(controller.add, onError: controller.addError)];
    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };
  });
}
