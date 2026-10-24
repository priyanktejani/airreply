import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/theme_mode.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/features/devices/devices_providers.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/permissions/presentation/permission_notices.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    return Scaffold(
      body: EditorialPage(
        header: const PageHeader(title: 'Settings'),
        slivers: [
          SliverList.list(
            children: [
              const SectionLabel('Permissions', top: 0),
              if (isSender) const _SenderPermissions() else const _ReceiverPermissions(),
              const SectionLabel('Apps'),
              const _AppsRow(),
              const SectionLabel('Mirroring and privacy'),
              if (isSender) const _SharingSettings() else const _AlertSettings(),
              const SectionLabel('Sync'),
              const _SyncSettings(),
              const SectionLabel('Appearance and accessibility'),
              const _AppearanceSettings(),
              const SectionLabel('Data'),
              const _DataSettings(),
              const SectionLabel('Help and about'),
              const _HelpSettings(),
            ],
          ),
        ],
      ),
    );
  }
}

/// A short status word for a permission row, with "Open" / "Allow" when it is not granted.
Widget _permissionTrailing(
  BuildContext context, {
  required bool? granted,
  required VoidCallback onFix,
  String fix = 'Open',
}) {
  final c = context.colors;
  return switch (granted) {
    true => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 16, color: c.success),
        const SizedBox(width: Space.x1),
        Text(
          'On',
          style: TextStyle(color: c.success, fontWeight: FontWeight.w500),
        ),
      ],
    ),
    _ => TextButton(onPressed: onFix, child: Text(fix)),
  };
}

class _SenderPermissions extends ConsumerWidget {
  const _SenderPermissions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(senderPermissionsProvider).value;
    final controller = ref.read(senderPermissionsProvider.notifier);
    final restrictions = permissions?.restrictions ?? BackgroundRestrictions.none;
    return RuledList(
      children: [
        InfoRow(
          icon: Icons.notifications_active_outlined,
          title: 'Notification access',
          subtitle: 'Required to read and share notifications',
          onTap: guarded(context, controller.openNotificationAccess),
          trailing: _permissionTrailing(
            context,
            granted: permissions?.notificationAccess,
            onFix: guarded(context, controller.openNotificationAccess),
          ),
        ),
        InfoRow(
          icon: Icons.campaign_outlined,
          title: 'Status notification',
          subtitle: 'Shows "Notification Sync Active" with a Pause button',
          onTap: guarded(context, controller.requestPostNotifications),
          trailing: _permissionTrailing(
            context,
            granted: permissions?.postNotifications,
            fix: 'Allow',
            onFix: guarded(context, controller.requestPostNotifications),
          ),
        ),
        if (restrictions.hasAutostartScreen)
          InfoRow(
            icon: Icons.rocket_launch_outlined,
            title: 'Autostart',
            subtitle: 'Required on ${restrictions.vendorName} phones. Android cannot report it, so check it there.',
            trailing: InfoRow.chevron,
            onTap: guarded(context, controller.openAutostartSettings),
          ),
        InfoRow(
          icon: Icons.battery_charging_full_outlined,
          title: 'Battery optimisation',
          subtitle: restrictions.ignoringBatteryOptimizations
              ? 'Unrestricted: Android will not pause sharing'
              : 'Set to "Unrestricted" so Android never pauses sharing',
          onTap: guarded(context, controller.openBatterySettings),
          trailing: _permissionTrailing(
            context,
            granted: permissions == null ? null : restrictions.ignoringBatteryOptimizations,
            onFix: guarded(context, controller.openBatterySettings),
          ),
        ),
      ],
    );
  }
}

class _ReceiverPermissions extends ConsumerWidget {
  const _ReceiverPermissions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(alertPermissionProvider).value;
    final request = ref.read(alertPermissionProvider.notifier).request;
    return RuledList(
      children: [
        InfoRow(
          icon: Icons.notifications_active_outlined,
          title: 'Alerts',
          subtitle: AppPlatform.isWeb
              ? 'Lets this browser show new notifications'
              : 'Lets this device alert you to new notifications',
          onTap: allowed == true ? null : guarded(context, request),
          trailing: _permissionTrailing(context, granted: allowed, fix: 'Allow', onFix: guarded(context, request)),
        ),
      ],
    );
  }
}

class _AppsRow extends ConsumerWidget {
  const _AppsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    final String subtitle;
    if (isSender) {
      subtitle = switch (ref.watch(appFilterProvider).value) {
        null => 'Loading…',
        AppFilter(mode: AppFilterMode.all) => 'Every app is shared',
        AppFilter(:final packages) when packages.isEmpty => 'No apps selected: nothing is shared',
        AppFilter(:final packages) => 'Only ${packages.length} selected ${packages.length == 1 ? 'app' : 'apps'}',
      };
    } else {
      final muted = ref.watch(appPreferencesProvider).value?.mutedApps.length ?? 0;
      subtitle = muted == 0 ? 'Every app can alert you' : '$muted muted: they arrive silently';
    }
    return RuledList(
      children: [
        InfoRow(
          icon: isSender ? Icons.apps_outlined : Icons.notifications_off_outlined,
          title: isSender ? 'Apps to share' : 'Muted apps',
          subtitle: subtitle,
          trailing: InfoRow.chevron,
          onTap: () => context.push(AppRoutes.apps),
        ),
      ],
    );
  }
}

const _encryption = InfoRow(
  icon: Icons.lock_outline,
  title: 'End-to-end encrypted',
  subtitle:
      'Each pair has its own key, agreed between the two devices (X25519). Notifications and replies are sealed '
      'with AES-256-GCM; the server only relays ciphertext.',
);

class _SharingSettings extends ConsumerWidget {
  const _SharingSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharing = ref.watch(syncStatusProvider).value ?? SyncStatus.off;
    final access = ref.watch(senderPermissionsProvider.select((p) => p.value?.notificationAccess)) ?? true;
    return RuledList(
      children: [
        SwitchRow(
          icon: Icons.podcasts_outlined,
          title: 'Share notifications',
          subtitle: access ? sharing.label : 'Turn on notification access first',
          value: sharing.enabled,
          onChanged: access
              ? (on) {
                  ref.tick();
                  unawaited(runGuarded(context, () => ref.read(syncStatusProvider.notifier).setEnabled(on)));
                }
              : null,
        ),
        _encryption,
      ],
    );
  }
}

class _AlertSettings extends ConsumerWidget {
  const _AlertSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider).value;
    return RuledList(
      children: [
        SwitchRow(
          icon: Icons.visibility_outlined,
          title: 'Show message text in alerts',
          subtitle: 'Off: alerts only name the app, for lock screens and shared displays',
          value: preferences?.alertShowsContent ?? true,
          onChanged: preferences == null
              ? null
              : (on) {
                  ref.tick();
                  unawaited(ref.read(appPreferencesProvider.notifier).setAlertShowsContent(on));
                },
        ),
        if (!AppPlatform.usesPush)
          InfoRow(
            icon: Icons.desktop_windows_outlined,
            title: AppPlatform.isWeb ? 'Alerts in this browser' : 'Alerts on this computer',
            subtitle:
                'New notifications alert you while AirReply is running. Keep it open (on Mac it keeps running when '
                'you close the window).',
          ),
        _encryption,
      ],
    );
  }
}

class _SyncSettings extends ConsumerWidget {
  const _SyncSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    final status = ref.watch(overallStatusProvider);
    final lastSynced = ref.watch(lastSyncedProvider);
    final subtitle = switch (status?.state) {
      null => 'No paired devices',
      DeviceState.connected => '${status!.label}. Live now.',
      _ when lastSynced != null => '${status!.label}. Last synced ${formatAgo(lastSynced)}.',
      _ => '${status!.label}. ${status.detail}',
    };
    return RuledList(
      children: [
        InfoRow(
          icon: Icons.sync,
          title: 'Sync status',
          subtitle: subtitle,
          trailing: TextButton(
            onPressed: () {
              for (final pair in ref.read(pairedDevicesProvider)) {
                refreshPair(ref, pair.pairId);
              }
              context.showMessage('Checking the connection…');
            },
            child: const Text('Refresh'),
          ),
        ),
        if (isSender)
          InfoRow(
            icon: Icons.sensors_outlined,
            title: 'Notification listener',
            subtitle: 'Ask Android to connect AirReply\'s listener again if devices stop receiving',
            trailing: AsyncButton(
              label: 'Reconnect',
              style: AsyncButtonStyle.text,
              onPressed: ref.read(syncStatusProvider.notifier).reconnectListener,
            ),
          ),
      ],
    );
  }
}

class _AppearanceSettings extends ConsumerWidget {
  const _AppearanceSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final haptics = ref.watch(appPreferencesProvider).value?.haptics ?? true;
    return RuledList(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoRow(icon: Icons.contrast, title: 'Theme', subtitle: 'System follows this device'),
              Padding(
                padding: const EdgeInsets.only(left: Space.x10),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {themeMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) {
                    ref.tick();
                    unawaited(ref.read(themeModeProvider.notifier).set(s.first));
                  },
                ),
              ),
            ],
          ),
        ),
        if (!AppPlatform.isDesktop && !AppPlatform.isWeb)
          SwitchRow(
            icon: Icons.vibration,
            title: 'Haptic feedback',
            subtitle: 'A light tap when you send, toggle or confirm',
            value: haptics,
            onChanged: (on) {
              unawaited(ref.read(appPreferencesProvider.notifier).setHaptics(on));
              if (on) ref.tick();
            },
          ),
        const InfoRow(
          icon: Icons.text_fields,
          title: 'Text size',
          subtitle: 'AirReply follows the text size and bold text set on this device',
        ),
      ],
    );
  }
}

class _DataSettings extends ConsumerWidget {
  const _DataSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final hidden = ref.watch(hiddenCountProvider);
    final devices = ref.watch(pairedDevicesProvider);
    final inbox = ref.read(inboxStateProvider.notifier);

    Future<void> removeAll() async {
      final confirmed = await context.confirm(
        title: 'Remove all devices?',
        message:
            'Syncing stops with ${devices.length == 1 ? devices.single.peerName : 'all ${devices.length} devices'}, '
            'every encryption key is deleted, and the shared history is removed. You can pair again afterwards.',
        confirmLabel: 'Remove all',
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
      await runGuarded(context, () async {
        for (final device in devices) {
          await ref.read(deviceSessionProvider.notifier).unpair(device.pairId);
        }
      });
    }

    return RuledList(
      children: [
        InfoRow(
          icon: Icons.done_all,
          title: 'Mark all as read',
          subtitle: unread == 0 ? 'Nothing unread' : '$unread unread',
          enabled: unread > 0,
          onTap: () {
            ref.success();
            unawaited(inbox.markAllRead());
            context.showMessage('All marked as read');
          },
        ),
        InfoRow(
          icon: Icons.visibility_outlined,
          title: 'Restore hidden notifications',
          subtitle: hidden == 0 ? 'Nothing hidden' : '$hidden hidden on this device',
          enabled: hidden > 0,
          onTap: () {
            ref.success();
            unawaited(inbox.restoreHidden());
            context.showMessage('Hidden notifications restored');
          },
        ),
        InfoRow(
          icon: Icons.link_off,
          title: 'Remove all devices',
          subtitle: 'Ends every pair and deletes the keys and shared history',
          destructive: true,
          enabled: devices.isNotEmpty,
          onTap: removeAll,
        ),
      ],
    );
  }
}

class _HelpSettings extends ConsumerWidget {
  const _HelpSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) => RuledList(
    children: [
      InfoRow(
        icon: Icons.help_outline,
        title: 'Troubleshooting',
        subtitle: 'What to check when notifications or replies do not arrive',
        trailing: InfoRow.chevron,
        onTap: () => context.go(AppRoutes.devices),
      ),
      InfoRow(
        icon: Icons.monitor_heart_outlined,
        title: 'Diagnostics',
        subtitle: 'Connection, permission and sync details to check or share',
        trailing: InfoRow.chevron,
        onTap: () => context.push(AppRoutes.diagnostics),
      ),
      InfoRow(
        icon: Icons.description_outlined,
        title: 'Open-source licences',
        trailing: InfoRow.chevron,
        onTap: () => showLicensePage(
          context: context,
          applicationName: 'AirReply',
          applicationLegalese: 'Your phone\'s notifications, on every screen.',
        ),
      ),
    ],
  );
}
