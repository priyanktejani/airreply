import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/core/platform/notification_permission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the sender has granted so far, and what the phone may still block.
final class SenderPermissions {
  const SenderPermissions({
    required this.notificationAccess,
    required this.postNotifications,
    this.restrictions = BackgroundRestrictions.none,
  });

  /// Android "Notification access" for the listener service: required.
  final bool notificationAccess;

  /// Android 13+ permission to show the "Notification Sync Active" status notification: strongly recommended.
  final bool postNotifications;

  /// OEM autostart and battery optimisation; on Xiaomi and similar phones these decide whether sharing survives.
  final BackgroundRestrictions restrictions;
}

final senderPermissionsProvider = AsyncNotifierProvider.autoDispose<SenderPermissionsController, SenderPermissions>(
  SenderPermissionsController.new,
);

final class SenderPermissionsController extends AsyncNotifier<SenderPermissions> {
  NotificationBridge get _bridge => ref.read(notificationBridgeProvider);
  NotificationPermission get _permission => ref.read(notificationPermissionProvider);

  @override
  Future<SenderPermissions> build() => _load();

  /// Called when the app comes back from the system settings.
  Future<void> refresh() async => state = await AsyncValue.guard(_load);

  Future<void> openNotificationAccess() => _bridge.openNotificationAccessSettings();

  Future<void> openBatterySettings() => _bridge.openBatteryOptimizationSettings();

  Future<void> openAutostartSettings() => _bridge.openAutostartSettings();

  /// This app's system settings page: background activity, battery use.
  Future<void> openAppSettings() => _bridge.openAppSettings();

  Future<void> requestPostNotifications() async {
    await _permission.request();
    await refresh();
  }

  Future<SenderPermissions> _load() async => SenderPermissions(
    notificationAccess: await _bridge.isNotificationAccessGranted(),
    postNotifications: await _permission.isGranted(),
    restrictions: await _bridge.backgroundRestrictions(),
  );
}
