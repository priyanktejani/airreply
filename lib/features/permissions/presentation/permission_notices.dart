import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/widgets/async_button.dart';
import 'package:air_reply/core/widgets/notice.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
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
  const AttentionNotices({this.connection = true, this.bottom = AppSpacing.xl, super.key});

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
          for (final (i, notice) in notices.indexed) ...[if (i > 0) const SizedBox(height: AppSpacing.md), notice],
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
          icon: AppIcons.notificationsOff,
          title: context.l10n.noticeAccessOffTitle,
          message: context.l10n.noticeAccessOffMessage,
          actions: [
            TextButton(
              onPressed: guarded(context, ref.read(senderPermissionsProvider.notifier).openNotificationAccess),
              child: Text(context.l10n.actionOpenSettings),
            ),
          ],
        )
      else if (!status.enabled)
        Notice(
          icon: AppIcons.pauseCircleOutline,
          title: context.l10n.noticePausedTitle,
          message: context.l10n.noticePausedMessage,
          actions: [
            AsyncButton(
              label: context.l10n.actionResumeSharing,
              style: AsyncButtonStyle.text,
              onPressed: () => sync.setEnabled(true),
            ),
          ],
        )
      else if (status.running && !status.listenerConnected)
        Notice(
          icon: AppIcons.sensorsOff,
          title: context.l10n.noticeNotReceivingTitle,
          message: restrictions.hasAutostartScreen
              ? context.l10n.noticeNotReceivingAutostart(restrictions.vendorName)
              : context.l10n.noticeNotReceivingMessage,
          actions: [
            AsyncButton(
              label: context.l10n.actionReconnect,
              style: AsyncButtonStyle.text,
              onPressed: sync.reconnectListener,
            ),
            if (restrictions.hasAutostartScreen)
              TextButton(
                onPressed: guarded(context, ref.read(senderPermissionsProvider.notifier).openAutostartSettings),
                child: Text(context.l10n.permissionAutostartTitle),
              ),
          ],
        ),
      if (permissions.notificationAccess && !restrictions.ignoringBatteryOptimizations && connection)
        Notice(
          tone: Tone.neutral,
          icon: AppIcons.batteryAlert,
          title: context.l10n.noticeBatteryTitle,
          message: context.l10n.noticeBatteryMessage,
          actions: [
            TextButton(
              onPressed: guarded(context, ref.read(senderPermissionsProvider.notifier).openBatterySettings),
              child: Text(context.l10n.actionBatterySettings),
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
          icon: AppIcons.notificationsPaused,
          title: context.l10n.noticeAlertsOffTitle,
          message: context.l10n.noticeAlertsOffMessage,
          actions: [
            AsyncButton(
              label: context.l10n.actionAllowAlerts,
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
        icon: AppIcons.cloudOff,
        title: offline.length == 1
            ? context.l10n.noticeOneOffline(offline.single.peerName)
            : context.l10n.noticeManyOffline(offline.length),
        message: context.l10n.noticeOfflineMessage,
        actions: [
          TextButton(
            onPressed: () {
              for (final pair in offline) {
                refreshPair(ref, pair.pairId);
              }
            },
            child: Text(context.l10n.actionRetry),
          ),
          TextButton(onPressed: () => context.go(AppRoutes.devices), child: Text(context.l10n.tabDevices)),
        ],
      ),
    ];
  }
}

/// Keeps a sender's sharing state readable for the notices without importing the native models everywhere.
extension SyncStatusLabel on SyncStatus {
  /// One word for whether this phone is sharing, in the person's language.
  String label(AppLocalizations l10n) => switch ((enabled, running, listenerConnected)) {
    (false, _, _) => l10n.devicePaused,
    (true, false, _) => l10n.syncStarting,
    (true, true, false) => l10n.deviceNotReceiving,
    (true, true, true) => l10n.syncSharing,
  };
}
