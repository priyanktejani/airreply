import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How one paired device stands right now, from this device's point of view.
final deviceStatusProvider = Provider.autoDispose.family<DeviceStatus, String>((ref, pairId) {
  final sync = ref.watch(syncStateProvider(pairId)).value;
  if (ref.watch(deviceRoleProvider) != DeviceRole.sender) return phoneStatus(sync);

  final sharing = ref.watch(syncStatusProvider).value;
  final access = ref.watch(senderPermissionsProvider.select((p) => p.value?.notificationAccess));
  if (sharing == null) return phoneStatus(null);
  return receiverStatus(sharing: sharing, accessGranted: access ?? true, sync: sync);
});

/// All paired devices at once, for Home: the state that most needs attention wins. Null when nothing is paired.
final overallStatusProvider = Provider.autoDispose<DeviceStatus?>((ref) {
  final statuses = [for (final pair in ref.watch(pairedDevicesProvider)) ref.watch(deviceStatusProvider(pair.pairId))];
  if (statuses.isEmpty) return null;
  int severity(DeviceStatus s) => switch (s.state) {
    DeviceState.permissionRequired => 3,
    DeviceState.disconnected => 2,
    DeviceState.connecting => 1,
    DeviceState.connected => 0,
  };
  return statuses.reduce((worst, s) => severity(s) > severity(worst) ? s : worst);
});

/// When this device last synced with any paired device (the latest of them).
final lastSyncedProvider = Provider.autoDispose<DateTime?>((ref) {
  DateTime? latest;
  for (final pair in ref.watch(pairedDevicesProvider)) {
    final at = ref.watch(deviceStatusProvider(pair.pairId)).lastSyncedAt;
    if (at != null && (latest == null || at.isAfter(latest))) latest = at;
  }
  return latest;
});
