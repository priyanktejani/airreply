import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';

/// The four states a paired device can be shown in. Never "connected" before the server has confirmed it.
enum DeviceState { connected, connecting, disconnected, permissionRequired }

/// What the UI says about one paired device, and what can fix it.
final class DeviceStatus {
  const DeviceStatus(this.state, this.label, this.detail, {this.fix, this.lastSyncedAt});

  final DeviceState state;

  /// One or two words: "Connected", "Offline".
  final String label;

  /// A sentence: what it means for the person.
  final String detail;

  /// What would resolve it, when something can.
  final DeviceFix? fix;
  final DateTime? lastSyncedAt;
}

enum DeviceFix { grantNotificationAccess, resumeSharing, reconnectListener, retrySync }

/// Receiver's view of a phone: only the sync connection decides it (the phone itself reports nothing live).
DeviceStatus phoneStatus(SyncState? sync) => switch (sync?.health) {
  SyncHealth.live => DeviceStatus(
    DeviceState.connected,
    'Connected',
    'New notifications arrive as they happen.',
    lastSyncedAt: sync!.lastSyncedAt,
  ),
  SyncHealth.offline => DeviceStatus(
    DeviceState.disconnected,
    'Offline',
    'Showing saved notifications until this device is back online.',
    fix: DeviceFix.retrySync,
    lastSyncedAt: sync!.lastSyncedAt,
  ),
  _ => const DeviceStatus(DeviceState.connecting, 'Connecting', 'Reaching the server…'),
};

/// Sender's view of one receiver: sharing must be on, the notification listener bound and the server reachable.
DeviceStatus receiverStatus({required SyncStatus sharing, required bool accessGranted, required SyncState? sync}) {
  if (!accessGranted) {
    return const DeviceStatus(
      DeviceState.permissionRequired,
      'Needs access',
      'Notification access is off, so nothing can be shared.',
      fix: DeviceFix.grantNotificationAccess,
    );
  }
  if (!sharing.enabled) {
    return const DeviceStatus(
      DeviceState.disconnected,
      'Paused',
      'Sharing is off. Turn it on to send notifications.',
      fix: DeviceFix.resumeSharing,
    );
  }
  if (!sharing.listenerConnected) {
    return const DeviceStatus(
      DeviceState.disconnected,
      'Not receiving',
      'Android stopped AirReply\'s notification listener.',
      fix: DeviceFix.reconnectListener,
    );
  }
  final phone = phoneStatus(sync);
  if (phone.state != DeviceState.connected) return phone;
  return DeviceStatus(
    DeviceState.connected,
    'Connected',
    'New notifications are shared as they arrive.',
    lastSyncedAt: phone.lastSyncedAt,
  );
}
