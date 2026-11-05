import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/notifications/alert_delivery_provider.dart';
import 'package:air_reply/features/permissions/domain/setup_tasks.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// This device's setup tasks (see [setupTasks]), kept current as permissions and settings change.
final setupTasksProvider = Provider.autoDispose<List<SetupTask>>((ref) {
  final role = ref.watch(deviceRoleProvider) ?? DeviceRole.receiver;
  final paired = ref.watch(pairedDevicesProvider).isNotEmpty;
  final preferences = ref.watch(appPreferencesProvider).value;
  return switch (role) {
    DeviceRole.sender => setupTasks(
      role: role,
      paired: paired,
      sender: switch (ref.watch(senderPermissionsProvider).value) {
        final p? => (
          notificationAccess: p.notificationAccess,
          postNotifications: p.postNotifications,
          restrictions: p.restrictions,
        ),
        null => null,
      },
      sharing: ref.watch(syncStatusProvider).value,
      autostartConfirmed: preferences?.autostartConfirmed ?? false,
    ),
    DeviceRole.receiver => setupTasks(
      role: role,
      paired: paired,
      alertsAllowed: ref.watch(alertPermissionProvider).value,
      popUpsWork: ref.watch(alertDeliveryProvider).value?.works,
      receiverRestrictions: AppPlatform.isAndroid ? ref.watch(senderPermissionsProvider).value?.restrictions : null,
      autostartConfirmed: preferences?.autostartConfirmed ?? false,
    ),
  };
});
