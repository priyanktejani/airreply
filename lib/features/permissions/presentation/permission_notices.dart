import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/features/devices/devices_providers.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Everything that currently stops notifications from flowing, each with the action that fixes it. Empty when all
/// is well. [connection] adds offline devices (Home), not just permissions (Notifications).
class AttentionNotices extends ConsumerWidget {
  const AttentionNotices({this.connection = true, this.bottom = Space.x6, super.key});

  final bool connection;
  final double bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(deviceRoleProvider) == DeviceRole.sender
        ? _senderNotices(context, ref)
        : _receiverNotices(context, ref);
    if (notices.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        children: [
          for (final (i, notice) in notices.indexed) ...[if (i > 0) const SizedBox(height: Space.x3), notice],
        ],
      ),
    );
  }

  List<Widget> _senderNotices(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(senderPermissionsProvider).value;
    final status = ref.watch(syncStatusProvider).value;
    if (permissions == null || status == null) return const [];
    final sync = ref.read(syncStatusProvider.notifier);
    final restrictions = permissions.restrictions;

    return [
      if (!permissions.notificationAccess)
        Notice(
          tone: Tone.error,
          icon: Icons.notifications_off_outlined,
          title: 'Notification access is off',
          message: 'AirReply cannot see new notifications until you turn it back on.',
          actions: [
            TextButton(
              onPressed: guarded(context, ref.read(senderPermissionsProvider.notifier).openNotificationAccess),
              child: const Text('Open settings'),
            ),
          ],
        )
      else if (!status.enabled)
        Notice(
          icon: Icons.pause_circle_outline,
          title: 'Sharing is paused',
          message: 'Notifications on this phone are not being sent to your devices.',
          actions: [
            AsyncButton(label: 'Resume sharing', style: AsyncButtonStyle.text, onPressed: () => sync.setEnabled(true)),
          ],
        )
      else if (status.running && !status.listenerConnected)
        Notice(
          icon: Icons.sensors_off_outlined,
          title: 'Not receiving notifications',
          message: restrictions.hasAutostartScreen
              ? 'Android stopped AirReply\'s listener. Reconnect, and turn on Autostart for AirReply on '
                    '${restrictions.vendorName} phones so it does not happen again.'
              : 'Android stopped AirReply\'s notification listener. Reconnect to start again.',
          actions: [
            AsyncButton(label: 'Reconnect', style: AsyncButtonStyle.text, onPressed: sync.reconnectListener),
            if (restrictions.hasAutostartScreen)
              TextButton(
                onPressed: guarded(context, ref.read(senderPermissionsProvider.notifier).openAutostartSettings),
                child: const Text('Autostart'),
              ),
          ],
        ),
      if (permissions.notificationAccess && !restrictions.ignoringBatteryOptimizations && connection)
        Notice(
          tone: Tone.neutral,
          icon: Icons.battery_alert_outlined,
          title: 'Battery optimisation is on',
          message: 'Android may pause sharing to save battery. Set AirReply to "Unrestricted".',
          actions: [
            TextButton(
              onPressed: guarded(context, ref.read(senderPermissionsProvider.notifier).openBatterySettings),
              child: const Text('Battery settings'),
            ),
          ],
        ),
      if (connection) ..._offline(context, ref),
    ];
  }

  List<Widget> _receiverNotices(BuildContext context, WidgetRef ref) {
    final alertsAllowed = ref.watch(alertPermissionProvider).value;
    return [
      if (alertsAllowed == false)
        Notice(
          icon: Icons.notifications_paused_outlined,
          title: 'Alerts are off on this device',
          message: 'New notifications still appear here, but this device will not alert you.',
          actions: [
            AsyncButton(
              label: 'Allow alerts',
              style: AsyncButtonStyle.text,
              onPressed: ref.read(alertPermissionProvider.notifier).request,
            ),
          ],
        ),
      if (connection) ..._offline(context, ref),
    ];
  }

  /// One notice for every device that cannot sync (sender access problems are reported above instead).
  List<Widget> _offline(BuildContext context, WidgetRef ref) {
    final offline = [
      for (final pair in ref.watch(pairedDevicesProvider))
        if (ref.watch(deviceStatusProvider(pair.pairId)) case DeviceStatus(
          state: DeviceState.disconnected,
          fix: DeviceFix.retrySync,
        ))
          pair,
    ];
    if (offline.isEmpty) return const [];
    return [
      Notice(
        icon: Icons.cloud_off_outlined,
        title: offline.length == 1 ? '${offline.single.peerName} is offline' : '${offline.length} devices are offline',
        message: 'Showing saved notifications. New ones arrive once this device is back online.',
        actions: [
          TextButton(
            onPressed: () {
              for (final pair in offline) {
                refreshPair(ref, pair.pairId);
              }
            },
            child: const Text('Retry'),
          ),
          TextButton(onPressed: () => context.go(AppRoutes.devices), child: const Text('Devices')),
        ],
      ),
    ];
  }
}

/// Keeps a sender's sharing state readable for the notices without importing the native models everywhere.
extension SyncStatusLabel on SyncStatus {
  String get label => switch ((enabled, running, listenerConnected)) {
    (false, _, _) => 'Paused',
    (true, false, _) => 'Starting',
    (true, true, false) => 'Not receiving',
    (true, true, true) => 'Sharing',
  };
}
