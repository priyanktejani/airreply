import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:air_reply/core/widgets/app_icon.dart';
import 'package:air_reply/core/widgets/async_button.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/eyebrow.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/section_header.dart';
import 'package:air_reply/features/devices/devices_providers.dart';
import 'package:air_reply/features/devices/presentation/device_sheet.dart';
import 'package:air_reply/features/devices/presentation/device_status_badge.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paired devices with their live state, adding and removing devices, and help when something does not work.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(pairedDevicesProvider);
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;

    return Scaffold(
      body: GlassScrollPage(
        onRefresh: () async {
          for (final pair in devices) {
            refreshPair(ref, pair.pairId);
          }
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        title: const Text('Devices'),
        actions: [
          IconButton(
            tooltip: isSender ? 'Add a device' : 'Add a phone',
            onPressed: () => context.push(AppRoutes.pair),
            icon: const Icon(AppIcons.add),
          ),
        ],
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow('${devices.length} paired'),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isSender
                        ? 'This phone shares its notifications with these devices.'
                        : 'This device shows notifications from these phones.',
                    style: AppType.body.copyWith(color: context.palette.muted),
                  ),
                ],
              ),
            ),
          ),
          if (devices.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: AppIcons.devices,
                title: 'No devices',
                description: 'Pair a device to start.',
                action: FilledButton(onPressed: () => context.push(AppRoutes.pair), child: const Text('Pair')),
              ),
            )
          else
            SliverList.separated(
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) => FadeSlideIn.staggered(
                index: i,
                child: _DeviceRow(device: devices[i], isSender: isSender),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.pair),
                icon: const Icon(AppIcons.addLink, size: 18),
                label: Text(isSender ? 'Add a device' : 'Add another phone'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeSlideIn.staggered(
              index: devices.length + 1,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.section),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(eyebrow: 'Help', title: 'Troubleshooting', padding: EdgeInsets.zero),
                    const SizedBox(height: AppSpacing.md),
                    if (isSender) const _SenderHelp() else const _ReceiverHelp(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends ConsumerWidget {
  const _DeviceRow({required this.device, required this.isSender});

  final PairingCredentials device;
  final bool isSender;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final status = ref.watch(deviceStatusProvider(device.pairId));
    final last = ref.watch(lastActivityProvider(device.pairId));
    final facts = [
      if (last != null) '${isSender ? 'Last shared' : 'Last notification'} ${formatAgo(last)}',
      'Paired ${formatRelativeTime(device.pairedAt)}',
    ];
    return AppCard(
      onTap: () => showDeviceSheet(context, device),
      child: Row(
        children: [
          Container(
            width: AppDimensions.iconTileLg,
            height: AppDimensions.iconTileLg,
            decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.mdBorder),
            child: Icon(deviceIcon(device.peerName, isPhone: !isSender), size: 26, color: c.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.peerName, style: AppType.title.copyWith(color: c.ink)),
                const SizedBox(height: AppSpacing.xs),
                DeviceStatusBadge(status: status),
                const SizedBox(height: AppSpacing.xs),
                Text(facts.join(' · '), style: AppType.supporting.copyWith(color: c.muted)),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight, color: c.muted, size: AppDimensions.iconMd),
        ],
      ),
    );
  }
}

/// A question that opens to an answer and the actions that help.
class _Help extends StatefulWidget {
  const _Help({required this.question, required this.answer, this.actions = const []});

  final String question;
  final String answer;
  final List<Widget> actions;

  @override
  State<_Help> createState() => _HelpState();
}

class _HelpState extends State<_Help> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final _Help(:question, :answer, :actions) = widget;
    return ExpansionTile(
      onExpansionChanged: (open) => setState(() => _open = open),
      // the app's own caret, turning as the answer opens (the tile's built-in arrow is from another icon set)
      trailing: AnimatedRotation(
        turns: _open ? 0.5 : 0,
        duration: context.motion(AppMotion.medium),
        curve: AppMotion.curve,
        child: Icon(AppIcons.keyboardArrowDown, color: _open ? c.accent : c.muted),
      ),
      title: Text(question, style: AppType.subtitle.copyWith(color: c.ink)),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.card, 0, AppSpacing.card, AppSpacing.base),
      children: [
        Text(answer, style: AppType.body.copyWith(color: c.muted)),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions),
        ],
      ],
    );
  }
}

class _ReceiverHelp extends ConsumerWidget {
  const _ReceiverHelp();

  @override
  Widget build(BuildContext context, WidgetRef ref) => CardGroup(
    inset: AppSpacing.card,
    children: [
      _Help(
        question: 'Notifications are not arriving',
        answer:
            'On the phone, open AirReply and check that "Share notifications" is on and the app is allowed to run in '
            'the background. Both devices need an internet connection. Then retry here.',
        actions: [
          OutlinedButton(
            onPressed: () {
              for (final pair in ref.read(pairedDevicesProvider)) {
                refreshPair(ref, pair.pairId);
              }
            },
            child: const Text('Retry sync'),
          ),
        ],
      ),
      _Help(
        question: 'No alerts on this device',
        answer:
            'New notifications always reach the Notifications tab. To be alerted too, allow notifications for '
            'AirReply, and check that the app is not muted in Settings → Muted apps.',
        actions: [
          AsyncButton(
            label: 'Allow alerts',
            style: AsyncButtonStyle.outlined,
            onPressed: ref.read(alertPermissionProvider.notifier).request,
          ),
          OutlinedButton(onPressed: () => context.push(AppRoutes.apps), child: const Text('Muted apps')),
        ],
      ),
      const _Help(
        question: 'A reply says "Expired on phone"',
        answer:
            'Replies are sent through the notification on the phone. Once it is cleared there, or the app replaced '
            'it, it can no longer be answered. Reply to a newer notification, or from the phone.',
      ),
    ],
  );
}

class _SenderHelp extends ConsumerWidget {
  const _SenderHelp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.read(senderPermissionsProvider.notifier);
    final restrictions = ref.watch(senderPermissionsProvider.select((p) => p.value?.restrictions));
    return CardGroup(
      inset: AppSpacing.card,
      children: [
        _Help(
          question: 'Devices are not receiving notifications',
          answer:
              'Check that notification access is on and sharing is not paused. If Android stopped AirReply\'s '
              'listener, reconnect it.',
          actions: [
            AsyncButton(
              label: 'Reconnect listener',
              style: AsyncButtonStyle.outlined,
              onPressed: ref.read(syncStatusProvider.notifier).reconnectListener,
            ),
            OutlinedButton(
              onPressed: guarded(context, permissions.openNotificationAccess),
              child: const Text('Notification access'),
            ),
          ],
        ),
        _Help(
          question: 'Sharing stops after a while',
          answer: restrictions?.hasAutostartScreen ?? false
              ? 'On ${restrictions!.vendorName} phones, turn on Autostart for AirReply and set its battery use to '
                    '"Unrestricted", or the phone stops it in the background.'
              : 'Set AirReply\'s battery use to "Unrestricted" so Android does not pause it in the background.',
          actions: [
            if (restrictions?.hasAutostartScreen ?? false)
              OutlinedButton(
                onPressed: guarded(context, permissions.openAutostartSettings),
                child: const Text('Autostart'),
              ),
            OutlinedButton(
              onPressed: guarded(context, permissions.openBatterySettings),
              child: const Text('Battery settings'),
            ),
          ],
        ),
        const _Help(
          question: 'Replies are not delivered',
          answer:
              'A reply is sent through the notification it answers, so that notification must still be in this '
              'phone\'s status bar. Messaging apps that offer "Reply" in their notifications work best.',
        ),
      ],
    );
  }
}
