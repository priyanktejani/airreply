import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';

/// The four states a paired device can be shown in. Never "connected" before the server has confirmed it.
enum DeviceState { connected, connecting, disconnected, permissionRequired }

/// What exactly a device's state is, for the words the UI shows: a label ("Connected") and what it means.
enum DeviceCondition { receiving, sharing, offline, connecting, needsAccess, paused, notReceiving }

/// What the UI says about one paired device, and what can fix it. The words are the screen's, in the person's
/// language, from [condition].
final class DeviceStatus {
  const DeviceStatus(this.state, this.condition, {this.fix, this.lastSyncedAt});

  final DeviceState state;
  final DeviceCondition condition;

  /// What would resolve it, when something can.
  final DeviceFix? fix;
  final DateTime? lastSyncedAt;
}

enum DeviceFix { grantNotificationAccess, resumeSharing, reconnectListener, retrySync }

/// Receiver's view of a phone: only the sync connection decides it (the phone itself reports nothing live).
DeviceStatus phoneStatus(SyncState? sync) => switch (sync?.health) {
  SyncHealth.live => DeviceStatus(DeviceState.connected, DeviceCondition.receiving, lastSyncedAt: sync!.lastSyncedAt),
  SyncHealth.offline => DeviceStatus(
    DeviceState.disconnected,
    DeviceCondition.offline,
    fix: DeviceFix.retrySync,
    lastSyncedAt: sync!.lastSyncedAt,
  ),
  _ => const DeviceStatus(DeviceState.connecting, DeviceCondition.connecting),
};

/// Sender's view of one receiver: sharing must be on, the notification listener bound and the server reachable.
DeviceStatus receiverStatus({required SyncStatus sharing, required bool accessGranted, required SyncState? sync}) {
  if (!accessGranted) {
    return const DeviceStatus(
      DeviceState.permissionRequired,
      DeviceCondition.needsAccess,
      fix: DeviceFix.grantNotificationAccess,
    );
  }
  if (!sharing.enabled) {
    return const DeviceStatus(DeviceState.disconnected, DeviceCondition.paused, fix: DeviceFix.resumeSharing);
  }
  if (!sharing.listenerConnected) {
    return const DeviceStatus(DeviceState.disconnected, DeviceCondition.notReceiving, fix: DeviceFix.reconnectListener);
  }
  final phone = phoneStatus(sync);
  if (phone.state != DeviceState.connected) return phone;
  return DeviceStatus(DeviceState.connected, DeviceCondition.sharing, lastSyncedAt: phone.lastSyncedAt);
}
