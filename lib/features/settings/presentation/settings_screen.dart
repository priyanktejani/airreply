import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/app_language.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/platform/system_notification_settings.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/theme/theme_mode.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_sheet.dart';
import 'package:air_reply/core/widgets/async_button.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/core/widgets/section_header.dart';
import 'package:air_reply/features/devices/devices_providers.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/devices/presentation/device_status_text.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/alert_delivery.dart';
import 'package:air_reply/features/permissions/domain/setup_tasks.dart';
import 'package:air_reply/features/permissions/presentation/permission_notices.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/permissions/presentation/setup_tasks_provider.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/erase_everything.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    // What this device does first (sharing, or alerting), then how it stays connected, how it looks, its data, help.
    final sections = [
      if (isSender) ...[
        _Section(
          eyebrow: context.l10n.settingsSharingEyebrow,
          title: context.l10n.settingsSharingTitle,
          child: const _SharingSettings(),
        ),
        _Section(
          eyebrow: context.l10n.settingsAccessEyebrow,
          title: context.l10n.settingsPermissionsTitle,
          child: const _SenderPermissions(),
        ),
      ] else
        _Section(
          eyebrow: context.l10n.settingsAlertsEyebrow,
          title: context.l10n.settingsAlertsTitle,
          child: const _AlertSettings(),
        ),
      _Section(
        eyebrow: context.l10n.settingsConnectionEyebrow,
        title: context.l10n.settingsSyncTitle,
        child: const _SyncSettings(),
      ),
      _Section(
        eyebrow: context.l10n.settingsAppearanceEyebrow,
        title: context.l10n.settingsAppearanceTitle,
        child: const _AppearanceSettings(),
      ),
      _Section(
        eyebrow: context.l10n.settingsPrivacyEyebrow,
        title: context.l10n.settingsDataTitle,
        child: const _DataSettings(),
      ),
      _Section(
        eyebrow: context.l10n.settingsHelpEyebrow,
        title: context.l10n.settingsHelpTitle,
        child: const _HelpSettings(),
      ),
    ];
    return Scaffold(
      body: GlassScrollPage(
        title: Text(context.l10n.tabSettings),
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
Widget _permissionTrailing(BuildContext context, {required bool? granted, required VoidCallback onFix, String? fix}) {
  final c = context.palette;
  return switch (granted) {
    true => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.check, size: 16, color: c.accent),
        const SizedBox(width: AppSpacing.xs),
        Text(context.l10n.permissionOn, style: AppType.button.copyWith(color: c.accent)),
      ],
    ),
    _ => TextButton(onPressed: onFix, child: Text(fix ?? context.l10n.actionOpen)),
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
          icon: AppIcons.notificationsActive,
          title: context.l10n.permissionAccessTitle,
          subtitle: context.l10n.permissionAccessSubtitle,
          onTap: guarded(context, controller.openNotificationAccess),
          trailing: _permissionTrailing(
            context,
            granted: permissions?.notificationAccess,
            onFix: guarded(context, controller.openNotificationAccess),
          ),
        ),
        InfoRow(
          icon: AppIcons.campaign,
          title: context.l10n.permissionStatusTitle,
          subtitle: context.l10n.permissionStatusSubtitle,
          onTap: guarded(context, controller.requestPostNotifications),
          trailing: _permissionTrailing(
            context,
            granted: permissions?.postNotifications,
            fix: context.l10n.actionAllow,
            onFix: guarded(context, controller.requestPostNotifications),
          ),
        ),
        if (restrictions.hasAutostartScreen)
          InfoRow(
            icon: AppIcons.rocketLaunch,
            title: context.l10n.permissionAutostartTitle,
            subtitle: context.l10n.permissionAutostartSubtitle(restrictions.vendorName),
            trailing: InfoRow.chevron,
            onTap: guarded(context, controller.openAutostartSettings),
          ),
        InfoRow(
          icon: AppIcons.batteryChargingFull,
          title: context.l10n.permissionBatteryTitle,
          subtitle: restrictions.ignoringBatteryOptimizations
              ? context.l10n.permissionBatteryOk
              : context.l10n.permissionBatteryFix,
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

Widget _encryption(BuildContext context) =>
    InfoRow(icon: AppIcons.lockOutline, title: context.l10n.encryptionTitle, subtitle: context.l10n.encryptionDetail);

class _SharingSettings extends ConsumerWidget {
  const _SharingSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharing = ref.watch(syncStatusProvider).value ?? SyncStatus.off;
    final access = ref.watch(senderPermissionsProvider.select((p) => p.value?.notificationAccess)) ?? true;
    return CardGroup(
      children: [
        SwitchRow(
          icon: AppIcons.podcasts,
          title: context.l10n.shareNotificationsTitle,
          subtitle: access ? sharing.label(context.l10n) : context.l10n.shareNeedsAccess,
          value: sharing.enabled,
          onChanged: access
              ? (on) {
                  ref.tick();
                  unawaited(runGuarded(context, () => ref.read(syncStatusProvider.notifier).setEnabled(on)));
                }
              : null,
        ),
        InfoRow(
          icon: AppIcons.apps,
          title: context.l10n.appsToShareTitle,
          subtitle: switch (ref.watch(appFilterProvider).value) {
            null => context.l10n.loading,
            AppFilter(mode: AppFilterMode.all) => context.l10n.appsAllShared,
            AppFilter(:final packages) when packages.isEmpty => context.l10n.appsNoneShared,
            AppFilter(:final packages) => context.l10n.appsSomeShared(packages.length),
          },
          trailing: InfoRow.chevron,
          onTap: () => context.push(AppRoutes.apps),
        ),
      ],
    );
  }
}

/// A device that shows notifications: what its alerts will do (as the system has them), where to change that, and
/// what only AirReply decides (muted apps, message text, receiving while closed).
class _AlertSettings extends ConsumerWidget {
  const _AlertSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final preferences = ref.watch(appPreferencesProvider).value;
    final muted = preferences?.mutedApps.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AlertExpectationBanner(),
        CardGroup(
          children: [
            // pop-up, sound, vibration and lock screen are the system's, as in other messaging apps
            if (canOpenSystemNotificationSettings)
              InfoRow(
                icon: AppIcons.tune,
                title: l10n.systemAlertSettingsTitle,
                subtitle: l10n.systemAlertSettingsSubtitle,
                trailing: InfoRow.chevron,
                onTap: guarded(context, () => openSystemNotificationSettings(ref.read(notificationBridgeProvider))),
              ),
            InfoRow(
              icon: AppIcons.notificationsOff,
              title: l10n.appsMutedTitle,
              subtitle: l10n.appsMuted(muted),
              trailing: InfoRow.chevron,
              onTap: () => context.push(AppRoutes.apps),
            ),
            SwitchRow(
              icon: AppIcons.visibility,
              title: l10n.alertTextTitle,
              subtitle: l10n.alertTextSubtitle,
              value: preferences?.alertShowsContent ?? true,
              onChanged: preferences == null
                  ? null
                  : (on) {
                      ref.tick();
                      unawaited(ref.read(appPreferencesProvider.notifier).setAlertShowsContent(on));
                    },
            ),
            // Android: the background service keeps alerts coming while AirReply is closed
            if (AppPlatform.isAndroid)
              SwitchRow(
                icon: AppIcons.notificationsPaused,
                title: l10n.receiveWhenClosedTitle,
                subtitle: l10n.receiveWhenClosedText,
                value: ref.watch(syncStatusProvider).value?.enabled ?? false,
                onChanged: preferences == null
                    ? null
                    : (on) {
                        ref.tick();
                        unawaited(
                          runGuarded(context, () async {
                            await ref.read(appPreferencesProvider.notifier).setReceiveWhenClosed(on);
                            await ref.read(syncStatusProvider.notifier).setEnabled(on);
                          }),
                        );
                      },
              ),
            // computers and browsers alert only while AirReply runs (phones also get pushes)
            if (AppPlatform.isDesktop || AppPlatform.isWeb)
              InfoRow(
                icon: AppIcons.desktopWindows,
                title: AppPlatform.isWeb ? l10n.alertsBrowserTitle : l10n.alertsComputerTitle,
                subtitle: l10n.alertsWhileOpen,
              ),
            InfoRow(
              icon: AppIcons.notificationsActive,
              title: l10n.alertStyleTest,
              subtitle: l10n.testAlertSubtitle,
              onTap: guarded(context, () => _sendTestAlert(context, ref)),
            ),
          ],
        ),
      ],
    );
  }

  /// A message that looks like a real one, alerting as a real one would; it cannot be answered.
  static Future<void> _sendTestAlert(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final permission = ref.read(alertPermissionProvider.notifier);
    if (!(ref.read(alertPermissionProvider).value ?? false)) await permission.request();
    if (!(ref.read(alertPermissionProvider).value ?? false)) {
      if (context.mounted) context.showMessage(l10n.noticeAlertsOffTitle, icon: AppIcons.notificationsOff);
      return;
    }
    await ref
        .read(mirroredAlertsProvider)
        .show(
          MirroredNotification(
            id: 'test-${DateTime.now().millisecondsSinceEpoch}',
            content: NotificationContent(
              key: 'airreply-test',
              packageName: 'com.airreply.test',
              appName: l10n.appTitle,
              title: l10n.alertStyleTestTitle,
              text: l10n.alertStyleTestText,
              postedAt: DateTime.now(),
              isMessage: true,
            ),
            canReply: false,
            dismissedOnSender: false,
          ),
          pairId: 'test',
          showContent: ref.read(appPreferencesProvider).value?.alertShowsContent ?? true,
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
      null => context.l10n.syncNoDevices,
      DeviceState.connected => context.l10n.syncLive(status!.label(context.l10n)),
      _ when lastSynced != null => context.l10n.syncLastSynced(
        status!.label(context.l10n),
        formatAgo(context.l10n, lastSynced),
      ),
      _ => context.l10n.syncStateDetail(status!.label(context.l10n), status.detail(context.l10n)),
    };
    return CardGroup(
      children: [
        InfoRow(
          icon: AppIcons.sync,
          title: context.l10n.syncStatusTitle,
          subtitle: subtitle,
          trailing: TextButton(
            onPressed: () {
              for (final pair in ref.read(pairedDevicesProvider)) {
                refreshPair(ref, pair.pairId);
              }
              context.showMessage(context.l10n.syncChecking);
            },
            child: Text(context.l10n.actionRefresh),
          ),
        ),
        if (isSender)
          InfoRow(
            icon: AppIcons.sensors,
            title: context.l10n.listenerTitle,
            subtitle: context.l10n.listenerSubtitle,
            trailing: AsyncButton(
              label: context.l10n.actionReconnect,
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
    final language = ref.watch(appLocaleProvider);
    return CardGroup(
      children: [
        InfoRow(
          icon: AppIcons.language,
          title: context.l10n.languageTitle,
          subtitle: language == null
              ? context.l10n.languageSystemCurrent(languageNames[context.l10n.localeName] ?? context.l10n.localeName)
              : languageNames[language.languageCode],
          trailing: InfoRow.chevron,
          onTap: () => unawaited(showAppSheet<void>(context, builder: (_) => const _LanguageSheet())),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoRow(icon: AppIcons.contrast, title: context.l10n.themeTitle, subtitle: context.l10n.themeSubtitle),
              Padding(
                padding: const EdgeInsets.only(left: InfoRow.textInset, right: AppSpacing.card),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(context.l10n.themeSystem)),
                    ButtonSegment(value: ThemeMode.light, label: Text(context.l10n.themeLight)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(context.l10n.themeDark)),
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
            icon: AppIcons.vibration,
            title: context.l10n.hapticsTitle,
            subtitle: context.l10n.hapticsSubtitle,
            value: haptics,
            onChanged: (on) {
              unawaited(ref.read(appPreferencesProvider.notifier).setHaptics(on));
              if (on) ref.tick();
            },
          ),
        InfoRow(icon: AppIcons.textFields, title: context.l10n.textSizeTitle, subtitle: context.l10n.textSizeSubtitle),
      ],
    );
  }
}

/// Every language the app speaks, each named in itself, and following the device; the choice applies at once.
class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final chosen = ref.watch(appLocaleProvider);
    Widget option(String title, Locale? locale) {
      final selected = chosen?.languageCode == locale?.languageCode;
      return Semantics(
        selected: selected,
        child: InfoRow(
          title: title,
          trailing: selected ? Icon(AppIcons.check, size: AppDimensions.iconMd, color: c.accent) : null,
          onTap: () {
            ref.tick();
            unawaited(ref.read(appLocaleProvider.notifier).set(locale));
            Navigator.pop(context);
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, AppSpacing.base),
          child: Text(context.l10n.languageTitle, style: AppType.section.copyWith(color: c.ink)),
        ),
        CardGroup(
          inset: AppSpacing.card,
          children: [
            option(context.l10n.languageSystem, null),
            for (final locale in AppLocalizations.supportedLocales)
              option(languageNames[locale.languageCode] ?? locale.languageCode, locale),
          ],
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
        title: context.l10n.removeAllConfirmTitle,
        message: devices.length == 1
            ? context.l10n.removeAllConfirmOne(devices.single.peerName)
            : context.l10n.removeAllConfirmMany(devices.length),
        confirmLabel: context.l10n.actionRemoveAll,
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
      await runGuarded(context, () async {
        for (final device in devices) {
          await ref.read(deviceSessionProvider.notifier).unpair(device.pairId);
        }
      });
    }

    final everyday = CardGroup(
      children: [
        _encryption(context),
        InfoRow(
          icon: AppIcons.doneAll,
          title: context.l10n.markAllReadTitle,
          subtitle: context.l10n.unreadCount(unread),
          enabled: unread > 0,
          onTap: () {
            ref.success();
            unawaited(inbox.markAllRead());
            context.showMessage(context.l10n.markedAllRead);
          },
        ),
        InfoRow(
          icon: AppIcons.visibility,
          title: context.l10n.restoreHiddenTitle,
          subtitle: context.l10n.hiddenCount(hidden),
          enabled: hidden > 0,
          onTap: () {
            ref.success();
            unawaited(inbox.restoreHidden());
            context.showMessage(context.l10n.hiddenRestored);
          },
        ),
      ],
    );
    // what cannot be undone, in a card of its own
    final destructive = CardGroup(
      children: [
        InfoRow(
          icon: AppIcons.linkOff,
          title: context.l10n.removeAllTitle,
          subtitle: context.l10n.removeAllSubtitle,
          destructive: true,
          enabled: devices.isNotEmpty,
          onTap: removeAll,
        ),
        InfoRow(
          icon: AppIcons.delete,
          title: context.l10n.eraseEverythingTitle,
          subtitle: context.l10n.eraseEverythingSubtitle,
          destructive: true,
          onTap: () async {
            final confirmed = await context.confirm(
              title: context.l10n.eraseEverythingConfirmTitle,
              message: context.l10n.eraseEverythingConfirmMessage,
              confirmLabel: context.l10n.actionErase,
              destructive: true,
            );
            if (!confirmed || !context.mounted) return;
            await runGuarded(context, ref.read(eraseEverythingProvider));
          },
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        everyday,
        const SizedBox(height: AppSpacing.md),
        destructive,
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
        icon: AppIcons.checklist,
        title: context.l10n.setupAssistantTitle,
        subtitle: switch (ref.watch(setupTasksProvider)) {
          final tasks => context.l10n.setupAssistantProgress(tasks.doneCount, tasks.length),
        },
        trailing: InfoRow.chevron,
        onTap: () => unawaited(context.push(AppRoutes.setupAssistant)),
      ),
      InfoRow(
        icon: AppIcons.helpOutline,
        title: context.l10n.troubleshootingTitle,
        subtitle: context.l10n.troubleshootingSubtitle,
        trailing: InfoRow.chevron,
        onTap: () => context.go(AppRoutes.devices),
      ),
      InfoRow(
        icon: AppIcons.monitorHeart,
        title: context.l10n.diagnosticsTitle,
        subtitle: context.l10n.diagnosticsSubtitle,
        trailing: InfoRow.chevron,
        onTap: () => context.push(AppRoutes.diagnostics),
      ),
      InfoRow(
        icon: AppIcons.bug,
        title: context.l10n.feedbackReportTitle,
        subtitle: context.l10n.feedbackReportSubtitle,
        trailing: InfoRow.chevron,
        onTap: () => unawaited(context.push(AppRoutes.feedbackAbout(idea: false))),
      ),
      InfoRow(
        icon: AppIcons.lightbulb,
        title: context.l10n.feedbackIdeaTitle,
        subtitle: context.l10n.feedbackIdeaSubtitle,
        trailing: InfoRow.chevron,
        onTap: () => unawaited(context.push(AppRoutes.feedbackAbout(idea: true))),
      ),
      InfoRow(
        icon: AppIcons.description,
        title: context.l10n.licencesTitle,
        trailing: InfoRow.chevron,
        onTap: () => showLicensePage(
          context: context,
          applicationName: 'AirReply',
          applicationLegalese: context.l10n.appTagline,
        ),
      ),
    ],
  );
}
