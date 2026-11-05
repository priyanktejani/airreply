import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/features/notifications/domain/alert_delivery.dart';
import 'package:air_reply/features/notifications/domain/alert_style.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this phone lets AirReply's alerts pop up and sound as the person chose (see [AlertDelivery]). Null where it
/// does not apply or cannot be read: not Android, not a device that shows notifications, nothing set to pop up or
/// sound, or alerts not allowed at all (that is asked for first).
final alertDeliveryProvider = AsyncNotifierProvider.autoDispose<AlertDeliveryController, AlertDelivery?>(
  AlertDeliveryController.new,
);

class AlertDeliveryController extends AsyncNotifier<AlertDelivery?> {
  /// How long a phone maker's notification manager may take to lower a channel the app just created.
  static const settle = Duration(milliseconds: 800);

  @override
  Future<AlertDelivery?> build() async {
    if (!AppPlatform.isAndroid || ref.watch(deviceRoleProvider) != DeviceRole.receiver) return null;
    // fixed: pop-up, sound and the rest are the system's settings of these channels
    const style = AlertStyle();
    final uses = alertChannelsFor(style);
    if (uses.isEmpty) return null;
    final bridge = ref.watch(notificationBridgeProvider);
    try {
      final states = <String, AlertChannelState>{};
      var created = false;
      for (final use in uses) {
        // the system can only say what it does with a channel that exists: make it as the first alert would. An
        // existing one is only renamed (names follow the app's language and version); what the person or the phone
        // chose for it stays.
        if (await bridge.alertChannel(use.channelId) == null) created = true;
        try {
          await ref.read(mirroredAlertsProvider).ensureChannel(use.mode, style);
        } on Object catch (e) {
          // only the name, or a channel the first alert makes anyway: the check goes on
          appLog('Alert channel not made: $e', name: 'air_reply.alerts');
        }
      }
      if (created) await Future<void>.delayed(settle);
      for (final use in uses) {
        if (await bridge.alertChannel(use.channelId) case final state?) states[use.channelId] = state;
      }
      // alerts switched off altogether: that is the alerts permission's step, not this one
      if (!(await ref.read(notificationPermissionProvider).isGranted())) return null;
      final vendor = (await bridge.backgroundRestrictions()).vendor;
      return judgeAlertDelivery(style, states, vendor: vendor);
    } on Object catch (e) {
      appLog('Alert delivery check failed: $e', name: 'air_reply.alerts');
      return null;
    }
  }

  /// Back from the system settings.
  Future<AlertDelivery?> refresh() async {
    ref.invalidateSelf();
    return future;
  }

  /// The system settings of the channel to fix (pop-up, sound), where only the person can raise it.
  Future<void> openSettings() async {
    final delivery = state.value;
    final channel = delivery?.fixChannelId;
    if (channel == null) return;
    await ref.read(notificationBridgeProvider).openAlertChannelSettings(channel, appPage: delivery!.fixOnAppPage);
  }
}
