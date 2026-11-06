import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/haptics/haptics.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/clock_provider.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:air_reply/core/widgets/app_icon.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/features/devices/devices_providers.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/devices/presentation/device_status_badge.dart';
import 'package:air_reply/features/devices/presentation/device_status_text.dart';
import 'package:air_reply/features/permissions/presentation/permission_notices.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Receivers: are notifications arriving, from which phones, and how fresh is the data.
class ReceivingStatusCard extends ConsumerWidget {
  const ReceivingStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(pairedDevicesProvider);
    final status = ref.watch(overallStatusProvider);
    final lastSynced = ref.watch(lastSyncedProvider);
    ref.watch(clockProvider); // keeps "Last synced 5m ago" current
    final names = devices.length == 1 ? devices.single.peerName : context.l10n.phonesCount(devices.length);
    return _StatusCard(
      status: status,
      headline: switch (status?.state) {
        DeviceState.connected => context.l10n.statusReceivingFrom(names),
        DeviceState.connecting => context.l10n.statusConnectingTo(names),
        _ => context.l10n.statusShowingSaved(names),
      },
      detail: switch (status?.state) {
        DeviceState.connected => context.l10n.statusLive,
        _ when lastSynced != null => context.l10n.statusLastSynced(formatAgo(context.l10n, lastSynced)),
        _ => status?.detail(context.l10n) ?? '',
      },
      footer: devices.isEmpty
          ? null
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final d in devices) _DeviceChip(name: d.peerName, pairId: d.pairId)],
            ),
    );
  }
}

/// Senders: the main switch, and whether sharing actually works.
class SharingStatusCard extends ConsumerWidget {
  const SharingStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final sharing = ref.watch(syncStatusProvider).value ?? SyncStatus.off;
    final access = ref.watch(senderPermissionsProvider.select((p) => p.value?.notificationAccess)) ?? true;
    final devices = ref.watch(pairedDevicesProvider);
    final status = ref.watch(overallStatusProvider);
    final names = devices.length == 1 ? devices.single.peerName : context.l10n.devicesCount(devices.length);
    return _StatusCard(
      status: status,
      headline: switch (status?.state) {
        _ when !access => context.l10n.statusNeedsAccess,
        _ when !sharing.enabled => context.l10n.statusPaused,
        DeviceState.connected => context.l10n.statusSharingWith(names),
        DeviceState.connecting => context.l10n.statusConnectingTo(names),
        _ => status?.detail(context.l10n) ?? context.l10n.statusNotWorking,
      },
      detail: sharing.enabled && access ? context.l10n.statusEncryptedDetail : context.l10n.statusOffDetail,
      footer: Material(
        color: c.soft,
        borderRadius: AppRadius.mdBorder,
        clipBehavior: Clip.antiAlias,
        child: SwitchRow(
          icon: AppIcons.podcasts,
          title: context.l10n.shareNotificationsTitle,
          subtitle: sharing.label(context.l10n),
          value: sharing.enabled,
          onChanged: access
              ? (on) {
                  ref.tick();
                  runGuarded(context, () => ref.read(syncStatusProvider.notifier).setEnabled(on));
                }
              : null,
        ),
      ),
    );
  }
}

/// The card: the state as a pill, the headline (cross-fading as it changes), what it means, and a footer.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.headline, required this.detail, this.footer});

  final DeviceStatus? status;
  final String headline;
  final String detail;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // the state takes the room there is, and only shortens on a phone too narrow for both
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: status == null ? const SizedBox.shrink() : DeviceStatusBadge(status: status!),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(AppIcons.lock, size: 14, color: c.muted),
              const SizedBox(width: AppSpacing.xs),
              Text(context.l10n.encrypted, style: AppType.supporting.copyWith(color: c.muted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: context.motion(AppMotion.slow),
            switchInCurve: const Interval(.4, 1, curve: Curves.easeOut),
            switchOutCurve: const Interval(.4, 1, curve: Curves.easeIn),
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
            child: Text(
              headline,
              key: ValueKey(headline),
              style: AppType.headline.copyWith(color: c.ink),
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(detail, style: AppType.body.copyWith(color: c.muted)),
          ],
          if (footer != null) ...[const SizedBox(height: AppSpacing.base), footer!],
        ],
      ),
    );
  }
}

/// A paired phone on the status card, dotted in its own state's colour.
class _DeviceChip extends ConsumerWidget {
  const _DeviceChip({required this.name, required this.pairId});

  final String name;
  final String pairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final state = ref.watch(deviceStatusProvider(pairId)).state;
    final dot = switch (state) {
      DeviceState.connected => c.accent,
      DeviceState.connecting => c.muted,
      DeviceState.disconnected => c.warnInk,
      DeviceState.permissionRequired => c.danger,
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: c.soft, borderRadius: AppRadius.fullBorder),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs + 2, AppSpacing.md, AppSpacing.xs + 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(deviceIcon(name, isPhone: true), size: 16, color: c.ink),
            const SizedBox(width: AppSpacing.xs + 2),
            // a long name, or large text, shortens rather than running off the card
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.supporting.copyWith(color: c.ink, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            LiveDot(color: dot, live: state == DeviceState.connected, size: 7),
          ],
        ),
      ),
    );
  }
}
