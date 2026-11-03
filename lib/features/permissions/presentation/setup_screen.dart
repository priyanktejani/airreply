import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/animations/motion.dart';
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
    return Stack(
      children: [
        Positioned.fill(
          child: GlassScrollPage(
            title: const Text('Set up'),
            leading: paired ? BackButton(onPressed: () => context.go(AppRoutes.home)) : null,
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
    );
  }
}

class _Disclosure extends ConsumerWidget {
  const _Disclosure();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(deviceSessionProvider.notifier);
    return _WithActions(
      header: const PageIntro(
        eyebrow: 'Before you start',
        title: 'AirReply needs access to your notifications',
        subtitle:
            'To share this phone\'s notifications with your paired devices, AirReply uses Android\'s Notification '
            'Access permission.',
      ),
      content: const [
        CardGroup(
          children: [
            _Point(
              icon: AppIcons.visibility,
              title: 'What is accessed',
              body:
                  'The notifications shown on this phone: app name, title, text, time, and the reply action of '
                  'messaging apps. This works in the background, even when AirReply is closed.',
            ),
            _Point(
              icon: AppIcons.sync,
              title: 'Why',
              body:
                  'Only to show those notifications on the devices you pair, and to send the replies you type there '
                  'through the original app on this phone.',
            ),
            _Point(
              icon: AppIcons.lockOutline,
              title: 'How it is protected',
              body:
                  'Each notification is encrypted on this phone with AES-256-GCM, using a key that only this phone '
                  'and the paired device hold. Our servers relay ciphertext they cannot read.',
            ),
            _Point(
              icon: AppIcons.tune,
              title: 'You stay in control',
              body:
                  'Choose which apps are shared, pause from the status notification at any time, or remove a device '
                  'to stop sharing and delete the synced history. Notification content is never sold, shared with '
                  'third parties, or used for ads or analytics.',
            ),
          ],
        ),
      ],
      actions: [
        FilledButton(onPressed: controller.acceptDisclosure, child: const Text('Agree and continue')),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: controller.clearRole, child: const Text('No thanks')),
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
        eyebrow: '$done of 2 required steps done',
        title: 'Set up this phone',
        subtitle: 'Two permissions let AirReply share notifications and keep running in the background.',
      ),
      content: [
        LinearProgressIndicator(value: done / 2),
        const SizedBox(height: AppSpacing.base),
        CardGroup(
          children: [
            _Step(
              index: 1,
              title: 'Notification access',
              subtitle: 'Required. Find AirReply in the list and switch it on.',
              done: granted?.notificationAccess,
              actionLabel: 'Open settings',
              onAction: guarded(context, controller.openNotificationAccess),
            ),
            _Step(
              index: 2,
              title: 'Status notification',
              subtitle: 'Shows "Notification Sync Active" with a Pause button while sharing is on.',
              done: granted?.postNotifications,
              actionLabel: 'Allow',
              onAction: guarded(context, controller.requestPostNotifications),
            ),
            if (autostart)
              _Step(
                index: 3,
                title: 'Autostart',
                subtitle:
                    'Required on ${granted!.restrictions.vendorName}. Without it the phone stops AirReply from '
                    'listening once the app is closed. Find AirReply and switch Autostart on.',
                actionLabel: 'Open settings',
                onAction: guarded(context, controller.openAutostartSettings),
              ),
            _Step(
              index: autostart ? 4 : 3,
              title: 'Battery optimisation',
              subtitle: 'Recommended. Set AirReply to "Unrestricted" so Android never pauses sharing.',
              done: granted?.restrictions.ignoringBatteryOptimizations,
              actionLabel: 'Open settings',
              onAction: guarded(context, controller.openBatterySettings),
            ),
          ],
        ),
      ],
      actions: [
        FilledButton(
          onPressed: ready ? () => context.go(widget.isPaired ? AppRoutes.home : AppRoutes.pair) : null,
          child: Text(ready ? 'Continue' : 'Turn on notification access to continue'),
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
                    'Done',
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
