import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/theme/theme_mode.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/async_button.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/core/widgets/section_header.dart';
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
    final sections = [
      _Section(
        eyebrow: 'Access',
        title: 'Permissions',
        child: isSender ? const _SenderPermissions() : const _ReceiverPermissions(),
      ),
      const _Section(eyebrow: 'Apps', title: 'Apps', child: _AppsRow()),
      _Section(
        eyebrow: 'Privacy',
        title: 'Mirroring and privacy',
        child: isSender ? const _SharingSettings() : const _AlertSettings(),
      ),
      const _Section(eyebrow: 'Connection', title: 'Sync', child: _SyncSettings()),
      const _Section(eyebrow: 'Appearance', title: 'Appearance and accessibility', child: _AppearanceSettings()),
      const _Section(eyebrow: 'Data', title: 'Your data', child: _DataSettings()),
      const _Section(eyebrow: 'Help', title: 'Help and about', child: _HelpSettings()),
    ];
    return Scaffold(
      body: GlassScrollPage(
        title: const Text('Settings'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            sliver: SliverList.list(
              children: [for (final (i, w) in sections.indexed) FadeSlideIn.staggered(index: i, child: w)],
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled group: the section heading, then its card of rows.
class _Section extends StatelessWidget {
  const _Section({required this.eyebrow, required this.title, required this.child});

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.section),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          eyebrow: eyebrow,
          title: title,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}

/// A short status word for a permission row, with "Open" / "Allow" when it is not granted.
Widget _permissionTrailing(
  BuildContext context, {
  required bool? granted,
  required VoidCallback onFix,
  String fix = 'Open',
}) {
  final c = context.palette;
  return switch (granted) {
    true => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_rounded, size: 16, color: c.accent),
        const SizedBox(width: AppSpacing.xs),
        Text('On', style: AppType.button.copyWith(color: c.accent)),
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
    return CardGroup(
      children: [
        InfoRow(
          icon: Icons.notifications_active_rounded,
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
          icon: Icons.campaign_rounded,
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
            icon: Icons.rocket_launch_rounded,
            title: 'Autostart',
            subtitle: 'Required on ${restrictions.vendorName} phones. Android cannot report it, so check it there.',
            trailing: InfoRow.chevron,
            onTap: guarded(context, controller.openAutostartSettings),
          ),
        InfoRow(
          icon: Icons.battery_charging_full_rounded,
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
    return CardGroup(
      children: [
        InfoRow(
          icon: Icons.notifications_active_rounded,
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
    return CardGroup(
      children: [
        InfoRow(
          icon: isSender ? Icons.apps_rounded : Icons.notifications_off_rounded,
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
    return CardGroup(
      children: [
        SwitchRow(
          icon: Icons.podcasts_rounded,
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
    return CardGroup(
      children: [
        SwitchRow(
          icon: Icons.visibility_rounded,
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
            icon: Icons.desktop_windows_rounded,
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
    return CardGroup(
      children: [
        InfoRow(
          icon: Icons.sync_rounded,
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
            icon: Icons.sensors_rounded,
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
    return CardGroup(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoRow(icon: Icons.contrast_rounded, title: 'Theme', subtitle: 'System follows this device'),
              Padding(
                padding: const EdgeInsets.only(left: InfoRow.textInset, right: AppSpacing.card),
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
            icon: Icons.vibration_rounded,
            title: 'Haptic feedback',
            subtitle: 'A light tap when you send, toggle or confirm',
            value: haptics,
            onChanged: (on) {
              unawaited(ref.read(appPreferencesProvider.notifier).setHaptics(on));
              if (on) ref.tick();
            },
          ),
        const InfoRow(
          icon: Icons.text_fields_rounded,
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

    return CardGroup(
      children: [
        InfoRow(
          icon: Icons.done_all_rounded,
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
          icon: Icons.visibility_rounded,
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
          icon: Icons.link_off_rounded,
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
  Widget build(BuildContext context, WidgetRef ref) => CardGroup(
    children: [
      InfoRow(
        icon: Icons.help_outline_rounded,
        title: 'Troubleshooting',
        subtitle: 'What to check when notifications or replies do not arrive',
        trailing: InfoRow.chevron,
        onTap: () => context.go(AppRoutes.devices),
      ),
      InfoRow(
        icon: Icons.monitor_heart_rounded,
        title: 'Diagnostics',
        subtitle: 'Connection, permission and sync details to check or share',
        trailing: InfoRow.chevron,
        onTap: () => context.push(AppRoutes.diagnostics),
      ),
      InfoRow(
        icon: Icons.description_rounded,
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
