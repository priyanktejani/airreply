import 'dart:async';

import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/async_button.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/notifications/domain/alert_style.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How mirrored notifications alert this device: for messages and for other notifications apart (pop up, in the list,
/// silent, off), sound and vibration, and what a locked screen shows. They always arrive in Notifications.
class AlertStyleScreen extends ConsumerWidget {
  const AlertStyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.palette;
    final style = ref.watch(appPreferencesProvider).value?.alertStyle ?? const AlertStyle();

    void set(AlertStyle next) {
      ref.tick();
      unawaited(() async {
        await ref.read(appPreferencesProvider.notifier).setAlertStyle(next);
        // the system's list of alert channels follows (Android)
        try {
          await ref.read(mirroredAlertsProvider).tidyChannels(next);
        } on Object catch (e) {
          appLog('Alert channels not tidied: $e', name: 'air_reply.alerts');
        }
      }());
    }

    List<Widget> modes(AlertMode selected, AlertStyle Function(AlertMode mode) change) => [
      for (final mode in AlertMode.values)
        _Choice(
          title: alertModeName(l10n, mode),
          subtitle: _modeHint(l10n, mode),
          selected: selected == mode,
          onTap: () => set(change(mode)),
        ),
    ];

    return Scaffold(
      body: GlassScrollPage(
        title: Text(l10n.alertStyleTitle),
        slivers: [
          SliverList.list(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.alertStyleIntro, style: AppType.body.copyWith(color: c.muted)),
              const SizedBox(height: AppSpacing.section),
              CardGroup(
                title: l10n.alertStyleMessages,
                inset: AppSpacing.card,
                children: modes(style.messages, (m) => style.copyWith(messages: m)),
              ),
              const SizedBox(height: AppSpacing.section),
              CardGroup(
                title: l10n.alertStyleOthers,
                inset: AppSpacing.card,
                children: modes(style.others, (m) => style.copyWith(others: m)),
              ),
              const SizedBox(height: AppSpacing.section),
              CardGroup(
                title: l10n.alertStyleSoundTitle,
                children: [
                  SwitchRow(
                    icon: AppIcons.volume,
                    title: l10n.alertStyleSound,
                    subtitle: l10n.alertStyleSoundHint,
                    value: style.sound,
                    onChanged: (on) => set(style.copyWith(sound: on)),
                  ),
                  // computers do not vibrate
                  if (AppPlatform.isAndroid || AppPlatform.isIOS)
                    SwitchRow(
                      icon: AppIcons.vibration,
                      title: l10n.alertStyleVibration,
                      subtitle: l10n.alertStyleSoundHint,
                      value: style.vibration,
                      onChanged: (on) => set(style.copyWith(vibration: on)),
                    ),
                ],
              ),
              // Only Android lets an app choose this per alert; elsewhere it is the system's setting.
              if (AppPlatform.isAndroid) ...[
                const SizedBox(height: AppSpacing.section),
                CardGroup(
                  title: l10n.alertStyleLockScreen,
                  inset: AppSpacing.card,
                  children: [
                    for (final choice in LockScreenAlerts.values)
                      _Choice(
                        title: _lockName(l10n, choice),
                        selected: style.lockScreen == choice,
                        onTap: () => set(style.copyWith(lockScreen: choice)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              AsyncButton(
                label: l10n.alertStyleTest,
                icon: AppIcons.notificationsActive,
                style: AsyncButtonStyle.outlined,
                expand: true,
                onPressed: () async {
                  final permission = ref.read(alertPermissionProvider.notifier);
                  if (!(ref.read(alertPermissionProvider).value ?? false)) await permission.request();
                  if (!(ref.read(alertPermissionProvider).value ?? false)) {
                    if (context.mounted) {
                      context.showMessage(l10n.noticeAlertsOffTitle, icon: AppIcons.notificationsOff);
                    }
                    return;
                  }
                  await ref
                      .read(mirroredAlertsProvider)
                      .show(
                        _sample(l10n),
                        pairId: 'test',
                        showContent: ref.read(appPreferencesProvider).value?.alertShowsContent ?? true,
                        style: style,
                      );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.alertStyleTestHint, style: AppType.supporting.copyWith(color: c.muted)),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ],
      ),
    );
  }

  /// A message that looks like a real one, to try the choices on; it cannot be answered.
  static MirroredNotification _sample(AppLocalizations l10n) => MirroredNotification(
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
  );

  static String? _modeHint(AppLocalizations l10n, AlertMode mode) => switch (mode) {
    AlertMode.popUp => l10n.alertModePopUpHint,
    AlertMode.normal => l10n.alertModeNormalHint,
    AlertMode.silent => l10n.alertModeSilentHint,
    AlertMode.off => l10n.alertModeOffHint,
  };

  static String _lockName(AppLocalizations l10n, LockScreenAlerts choice) => switch (choice) {
    LockScreenAlerts.show => l10n.lockScreenShow,
    LockScreenAlerts.hideContent => l10n.lockScreenHideContent,
    LockScreenAlerts.hide => l10n.lockScreenHide,
  };
}

/// A mode's name, as Settings shows it.
String alertModeName(AppLocalizations l10n, AlertMode mode) => switch (mode) {
  AlertMode.popUp => l10n.alertModePopUp,
  AlertMode.normal => l10n.alertModeNormal,
  AlertMode.silent => l10n.alertModeSilent,
  AlertMode.off => l10n.alertModeOff,
};

/// One choice of several: the chosen one ticked.
class _Choice extends StatelessWidget {
  const _Choice({required this.title, required this.selected, required this.onTap, this.subtitle});

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    child: InfoRow(
      title: title,
      subtitle: subtitle,
      trailing: selected ? Icon(AppIcons.check, size: AppDimensions.iconMd, color: context.palette.accent) : null,
      onTap: onTap,
    ),
  );
}
