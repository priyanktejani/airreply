import 'dart:async';
import 'dart:typed_data';

import 'package:air_reply/core/device/device_identity.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/platform/background_sync_channel.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/core/storage/secret_store.dart';
import 'package:air_reply/features/mirror/domain/entities/history_query.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:air_reply/features/sender/domain/app_icons.dart';

/// In-memory backend for the pairing handshake, shared by a "sender" and a "receiver" in the same test.
class InMemoryPairingRepository implements PairingRepository {
  InMemoryPairingRepository({this.now});

  final DateTime Function()? now;
  final sessions = <String, PairingSession>{};
  final pairs = <String, bool>{};
  final tokens = <String, String>{};
  final _controllers = <String, StreamController<PairingSession?>>{};
  var _nextCode = 123456;
  var _nextPair = 1;

  DateTime get _now => now?.call() ?? DateTime.now();

  @override
  Future<PairingSession> createSession({required Uint8List senderPublicKey, required String senderName}) async {
    final code = '${_nextCode++}';
    return _put(
      PairingSession(
        code: code,
        status: PairingStatus.waiting,
        senderUid: 'sender-uid',
        senderName: senderName,
        senderPublicKey: senderPublicKey,
        expiresAt: _now.add(PairingSession.lifetime),
      ),
    );
  }

  @override
  Future<PairingSession?> fetchSession(String code) async => sessions[code];

  @override
  Stream<PairingSession?> watchSession(String code) =>
      (_controllers[code] ??= StreamController<PairingSession?>.broadcast()).stream;

  @override
  Future<PairingSession> joinSession({
    required String code,
    required Uint8List receiverPublicKey,
    required String receiverName,
  }) async {
    final session = sessions[code];
    if (session == null || session.status != PairingStatus.waiting) {
      throw const PairingException(AppError.codeUnavailable);
    }
    return _put(
      PairingSession(
        code: code,
        status: PairingStatus.joined,
        senderUid: session.senderUid,
        senderName: session.senderName,
        senderPublicKey: session.senderPublicKey,
        expiresAt: session.expiresAt,
        receiverUid: 'receiver-uid',
        receiverName: receiverName,
        receiverPublicKey: receiverPublicKey,
      ),
    );
  }

  @override
  String newPairId() => 'pair-${_nextPair++}';

  /// Each pair's acknowledgements, by role.
  final ready = <String, Set<DeviceRole>>{};
  final _readyChanges = StreamController<String>.broadcast();

  @override
  Future<void> markReady(String pairId, DeviceRole role) async {
    (ready[pairId] ??= {}).add(role);
    _readyChanges.add(pairId);
  }

  @override
  Stream<bool> watchReady(String pairId, DeviceRole role) async* {
    yield ready[pairId]?.contains(role) ?? false;
    yield* _readyChanges.stream.where((id) => id == pairId).map((_) => ready[pairId]?.contains(role) ?? false);
  }

  @override
  Future<void> confirmSession(PairingSession session, String pairId) async {
    pairs[pairId] = true;
    _put(
      PairingSession(
        code: session.code,
        status: PairingStatus.confirmed,
        senderUid: session.senderUid,
        senderName: session.senderName,
        senderPublicKey: session.senderPublicKey,
        expiresAt: session.expiresAt,
        receiverUid: session.receiverUid,
        receiverName: session.receiverName,
        receiverPublicKey: session.receiverPublicKey,
        pairId: pairId,
      ),
    );
  }

  @override
  Future<void> cancelSession(String code) async {
    sessions.remove(code);
    _controllers[code]?.add(null);
  }

  @override
  Stream<bool> watchPairActive(String pairId) => Stream.value(pairs[pairId] ?? false);

  @override
  Future<void> endPair(String pairId) async => pairs[pairId] = false;

  /// Each pair's other member, as the server would report it.
  final peers = <String, String>{};

  @override
  Future<String?> peerUidOf(String pairId) async => peers[pairId];

  @override
  Future<void> registerPushToken({required String pairId, required DeviceRole role, required String token}) async =>
      tokens['$pairId/${role.name}'] = token;

  /// Live updates stall (a listener that stopped hearing): only fetching the session sees changes.
  var muteUpdates = false;

  PairingSession _put(PairingSession session) {
    sessions[session.code] = session;
    if (!muteUpdates) _controllers[session.code]?.add(session);
    return session;
  }
}

final class InMemoryCredentialsStore implements PairingCredentialsStore {
  final pairs = <PairingCredentials>[];

  PairingCredentials? get single => pairs.length == 1 ? pairs.single : null;

  @override
  Future<List<PairingCredentials>> readAll() async => [...pairs];

  @override
  Future<void> save(PairingCredentials credentials) async => pairs
    ..removeWhere((p) => p.pairId == credentials.pairId)
    ..add(credentials);

  @override
  Future<void> remove(String pairId) async => pairs.removeWhere((p) => p.pairId == pairId);
}

final class FixedDeviceIdentity implements DeviceIdentity {
  const FixedDeviceIdentity(this.name);

  final String name;

  @override
  Future<String> displayName() async => name;
}

/// Records what the sender pipeline publishes and resolves.
class RecordingMirror implements MirrorRepository {
  final published = <(NotificationContent, bool)>[];
  final dismissed = <String>[];
  final resolved = <String, ReplyStatus>{};
  final sent = <({String notificationId, String notificationKey, String text})>[];
  final pending = StreamController<List<PendingReply>>.broadcast();
  List<PendingReply> serverPending = const [];

  @override
  Future<void> publish(NotificationContent content, {required bool canReply}) async =>
      published.add((content, canReply));

  @override
  Future<void> markDismissed(String notificationKey) async => dismissed.add(notificationKey);

  @override
  Stream<List<PendingReply>> watchPending() => pending.stream;

  @override
  Future<List<PendingReply>> fetchPending() async => serverPending;

  @override
  Future<void> resolve(String replyId, ReplyStatus status) async => resolved[replyId] = status;

  @override
  Stream<List<MirroredNotification>> watchNotifications({int limit = 200}) => const Stream.empty();

  @override
  Stream<List<ReplyCommand>> watchReplies({int limit = 300}) => const Stream.empty();

  @override
  Stream<SyncState> watchSyncState() => Stream.value(SyncState(SyncHealth.live, lastSyncedAt: DateTime(2026)));

  @override
  Future<MirroredNotification?> fetchNotification(String id) async => null;

  @override
  Future<HistoryPage> browseHistory(HistoryQuery query, {HistoryCursor? after, int limit = 50}) async =>
      (notifications: const <MirroredNotification>[], replies: const <ReplyCommand>[], next: null, saved: 0);

  @override
  Future<int> countHistory(HistoryQuery query) async => 0;

  @override
  Future<MirroredNotification?> decodePushed({
    required String id,
    required String payload,
    required bool canReply,
  }) async => null;

  @override
  Future<void> send({required String notificationId, required String notificationKey, required String text}) async =>
      sent.add((notificationId: notificationId, notificationKey: notificationKey, text: text));
}

/// A [NotificationBridge] whose reply outcome is set per key.
final class FakeNotificationBridge implements NotificationBridge {
  final replyResults = <String, ReplyDispatchResult>{};
  final repliesSent = <(String, String)>[];
  var syncStopped = false;
  var syncReloaded = false;
  var syncStarted = false;
  bool? startedReceiving;

  @override
  bool get isSupported => true;

  @override
  Future<ReplyDispatchResult> sendReply({required String notificationKey, required String text}) async {
    repliesSent.add((notificationKey, text));
    return replyResults[notificationKey] ?? ReplyDispatchResult.expired;
  }

  @override
  Future<void> stopSync() async => syncStopped = true;

  @override
  Future<void> reloadSync() async => syncReloaded = true;

  @override
  Future<void> startSync({bool receiving = false}) async {
    syncStarted = true;
    startedReceiving = receiving;
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
  Future<void> openAppSettings() async {}

  @override
  Future<bool> isAppVisible() async => false;

  /// What [alertChannel] answers, for every channel.
  AlertChannelState? channelState;

  @override
  Future<AlertChannelState?> alertChannel(String id) async => channelState;

  /// What [openAlertChannelSettings] was asked to open: the channel, and whether the app's page.
  final settingsOpened = <(String, bool)>[];

  @override
  Future<void> openAlertChannelSettings(String id, {bool appPage = false}) async => settingsOpened.add((id, appPage));

  var appNotificationSettingsOpened = 0;

  @override
  Future<void> openAppNotificationSettings() async => appNotificationSettingsOpened++;

  @override
  Future<void> clearNativeData() async {}

  /// What [backgroundRestrictions] answers (the phone's maker among it).
  var restrictions = BackgroundRestrictions.none;

  @override
  Future<BackgroundRestrictions> backgroundRestrictions() async => restrictions;

  @override
  Future<void> requestListenerRebind() async {}

  /// Icons by package name; apps not listed have none.
  final icons = <String, Uint8List>{};
  var iconRequests = 0;

  @override
  Future<Uint8List?> appIcon(String packageName) async {
    iconRequests++;
    return icons[packageName];
  }

  @override
  Future<List<InstalledApp>> installedApps() async => const [];

  @override
  Future<AppFilter> appFilter() async => AppFilter.everything;

  @override
  Future<void> setAppFilter(AppFilter filter) async {}

  @override
  Future<SyncStatus> syncStatus() async => SyncStatus.off;

  @override
  Stream<NativeEvent> events() => const Stream.empty();
}

final class FakeBackgroundChannel implements BackgroundSyncChannel {
  BackgroundSyncHandler? handler;
  var ready = false;

  @override
  void attach(BackgroundSyncHandler handler) => this.handler = handler;

  @override
  Future<void> signalReady() async => ready = true;
}

CapturedNotification captured({
  String key = '0|com.whatsapp|1|chat|10123',
  String title = 'Alex',
  String text = 'Are you coming?',
  bool canReply = true,
}) => CapturedNotification(
  key: key,
  packageName: 'com.whatsapp',
  appName: 'WhatsApp',
  title: title,
  text: text,
  postedAt: DateTime(2026, 10, 24, 12),
  canReply: canReply,
);

/// An [IconDeliveryLog] in memory: (pairId, package) pairs already sent.
final class MemoryIconLog implements IconDeliveryLog {
  final sent = <String>{};

  @override
  Future<bool> isDue(String pairId, String packageName) async => !sent.contains('$pairId|$packageName');

  @override
  Future<void> recordSent(String pairId, String packageName) async => sent.add('$pairId|$packageName');

  @override
  Future<void> keepOnly(Set<String> pairIds) async {}
}

final class MemorySecretStore implements SecretStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}
