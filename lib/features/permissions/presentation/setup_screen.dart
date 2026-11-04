import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/page_intro.dart';
import 'package:air_reply/core/widgets/responsive_center.dart';
import 'package:air_reply/core/widgets/sticky_action_bar.dart';
import 'package:air_reply/features/onboarding/presentation/onboarding_back.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Sender setup. First the Google Play "prominent disclosure" for the notification listener, shown in the app before
/// the system settings screen is ever opened: what is accessed, why, how it is protected and how to stop it, with
/// an explicit accept or decline. Then the permission checklist.
class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(deviceSessionProvider).value;
    final accepted = session?.disclosureAccepted ?? false;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: context.motion(AppMotion.slow),
        child: accepted ? _Checklist(isPaired: session?.isPaired ?? false) : const _Disclosure(),
      ),
    );
  }
}

/// A scrolling page under the glass app bar, with its main actions on a glass panel floating at the bottom; the
/// content scrolls under both.
class _WithActions extends ConsumerWidget {
  const _WithActions({required this.header, required this.content, required this.actions});

  final Widget header;
  final List<Widget> content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paired = ref.watch(deviceSessionProvider.select((s) => s.value?.isPaired ?? false));
    // one row of buttons per action, with the gaps between them
    final reserve = actions.length * (AppDimensions.buttonHeight + AppSpacing.sm) + AppSpacing.xl;
    // unpaired, this is the step after choosing to share: back returns to that choice
    void back() =>
        paired ? context.go(AppRoutes.home) : unawaited(ref.read(deviceSessionProvider.notifier).clearRole());
    return OnboardingBack(
      onBack: paired ? null : back,
      child: Stack(
        children: [
          Positioned.fill(
            child: GlassScrollPage(
              title: Text(context.l10n.setupTitle),
              leading: BackButton(onPressed: back),
              slivers: [
                SliverToBoxAdapter(child: header),
                SliverList.list(
                  children: [
                    for (final (i, w) in content.indexed) FadeSlideIn.staggered(index: i, child: w),
                    SizedBox(height: reserve),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ResponsiveCenter(
              child: StickyActionBar(
                pill: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclosure extends ConsumerWidget {
  const _Disclosure();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(deviceSessionProvider.notifier);
    return _WithActions(
      header: PageIntro(
        eyebrow: context.l10n.disclosureEyebrow,
        title: context.l10n.disclosureTitle,
        subtitle: context.l10n.disclosureIntro,
      ),
      content: [
        CardGroup(
          children: [
            _Point(
              icon: AppIcons.visibility,
              title: context.l10n.disclosureWhatTitle,
              body: context.l10n.disclosureWhatBody,
            ),
            _Point(icon: AppIcons.sync, title: context.l10n.disclosureWhyTitle, body: context.l10n.disclosureWhyBody),
            _Point(
              icon: AppIcons.lockOutline,
              title: context.l10n.disclosureHowTitle,
              body: context.l10n.disclosureHowBody,
            ),
            _Point(
              icon: AppIcons.tune,
              title: context.l10n.disclosureControlTitle,
              body: context.l10n.disclosureControlBody,
            ),
          ],
        ),
      ],
      actions: [
        FilledButton(onPressed: controller.acceptDisclosure, child: Text(context.l10n.actionAgreeAndContinue)),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: controller.clearRole, child: Text(context.l10n.actionNoThanks)),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: c.muted),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.subtitle.copyWith(color: c.ink)),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: AppType.body.copyWith(color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Checklist extends ConsumerStatefulWidget {
  const _Checklist({required this.isPaired});

  final bool isPaired;

  @override
  ConsumerState<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends ConsumerState<_Checklist> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from the system settings: read the grants again.
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(senderPermissionsProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final granted = ref.watch(senderPermissionsProvider).value;
    final controller = ref.read(senderPermissionsProvider.notifier);
    final ready = granted?.notificationAccess ?? false;
    final done = [granted?.notificationAccess, granted?.postNotifications].where((g) => g == true).length;
    final autostart = granted?.restrictions.hasAutostartScreen ?? false;

    return _WithActions(
      header: PageIntro(
        eyebrow: context.l10n.setupProgress(done, 2),
        title: context.l10n.setupPhoneTitle,
        subtitle: context.l10n.setupPhoneSubtitle,
      ),
      content: [
        LinearProgressIndicator(value: done / 2),
        const SizedBox(height: AppSpacing.base),
        CardGroup(
          children: [
            _Step(
              index: 1,
              title: context.l10n.permissionAccessTitle,
              subtitle: context.l10n.setupAccessSubtitle,
              done: granted?.notificationAccess,
              actionLabel: context.l10n.actionOpenSettings,
              onAction: guarded(context, controller.openNotificationAccess),
            ),
            _Step(
              index: 2,
              title: context.l10n.permissionStatusTitle,
              subtitle: context.l10n.setupStatusSubtitle,
              done: granted?.postNotifications,
              actionLabel: context.l10n.actionAllow,
              onAction: guarded(context, controller.requestPostNotifications),
            ),
            if (autostart)
              _Step(
                index: 3,
                title: context.l10n.permissionAutostartTitle,
                subtitle: context.l10n.setupAutostartSubtitle(granted!.restrictions.vendorName),
                actionLabel: context.l10n.actionOpenSettings,
                onAction: guarded(context, controller.openAutostartSettings),
              ),
            _Step(
              index: autostart ? 4 : 3,
              title: context.l10n.permissionBatteryTitle,
              subtitle: context.l10n.setupBatterySubtitle,
              done: granted?.restrictions.ignoringBatteryOptimizations,
              actionLabel: context.l10n.actionOpenSettings,
              onAction: guarded(context, controller.openBatterySettings),
            ),
          ],
        ),
      ],
      actions: [
        FilledButton(
          onPressed: ready ? () => context.go(widget.isPaired ? AppRoutes.home : AppRoutes.pair) : null,
          child: Text(ready ? context.l10n.actionContinue : context.l10n.setupNeedsAccess),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.done,
  });

  final int index;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  /// Null when the state cannot be read (Autostart).
  final bool? done;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final isDone = done ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: AppMotion.medium,
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? c.accent : null,
              border: isDone ? null : Border.all(color: c.line),
            ),
            child: isDone
                ? Icon(AppIcons.check, size: 16, color: c.bg)
                : Text(
                    '$index',
                    style: AppType.supporting.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.subtitle.copyWith(color: c.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppType.supporting.copyWith(color: c.muted)),
                const SizedBox(height: AppSpacing.sm),
                if (isDone)
                  Text(
                    context.l10n.stepDone,
                    style: AppType.supporting.copyWith(color: c.accent, fontWeight: FontWeight.w600),
                  )
                else
                  OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
