import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_icon.dart';
import 'package:air_reply/core/widgets/app_sheet.dart';
import 'package:air_reply/core/widgets/async_button.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/features/devices/devices_providers.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/devices/presentation/device_status_badge.dart';
import 'package:air_reply/features/devices/presentation/device_status_text.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> showDeviceSheet(BuildContext context, PairingCredentials device) =>
    showAppSheet<void>(context, builder: (_) => _DeviceSheet(device: device));

/// One device: its state, when it last synced, what fixes a problem, and removing it.
class _DeviceSheet extends ConsumerWidget {
  const _DeviceSheet({required this.device});

  final PairingCredentials device;

  /// Asks, then ends the pair on both devices. True once removed.
  static Future<bool> remove(BuildContext context, WidgetRef ref, PairingCredentials device) async {
    final confirmed = await context.confirm(
      title: context.l10n.removeDeviceTitle(device.peerName),
      message: context.l10n.removeDeviceMessage(device.peerName),
      confirmLabel: context.l10n.actionRemove,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return false;
    final messenger = ScaffoldMessenger.of(context);
    // read before the wait: the sheet may close while the device is removed
    final removed = appSnackBar(context, context.l10n.deviceRemoved(device.peerName), icon: AppIcons.linkOff);
    try {
      await ref.read(deviceSessionProvider.notifier).unpair(device.pairId);
    } on Object catch (e) {
      if (context.mounted) context.showError(e);
      return false;
    }
    ref.success();
    messenger.showSnackBar(removed);
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    final status = ref.watch(deviceStatusProvider(device.pairId));
    final last = ref.watch(lastActivityProvider(device.pairId));
    final stillPaired = ref.watch(pairedDevicesProvider).any((p) => p.pairId == device.pairId);
    if (!stillPaired) return const SizedBox(height: AppSpacing.huge + AppSpacing.base);

    final fix = switch (status.fix) {
      DeviceFix.grantNotificationAccess => (
        context.l10n.actionTurnOnAccess,
        ref.read(senderPermissionsProvider.notifier).openNotificationAccess,
      ),
      DeviceFix.resumeSharing => (
        context.l10n.actionResumeSharing,
        () => ref.read(syncStatusProvider.notifier).setEnabled(true),
      ),
      DeviceFix.reconnectListener => (
        context.l10n.actionReconnect,
        ref.read(syncStatusProvider.notifier).reconnectListener,
      ),
      DeviceFix.retrySync => (
        context.l10n.actionRetry,
        () async {
          refreshPair(ref, device.pairId);
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
      ),
      null => null,
    };

    String when(DateTime? t) => t == null ? context.l10n.notYet : formatAgo(context.l10n, t);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _DeviceGlyph(icon: deviceIcon(device.peerName, isPhone: !isSender)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(device.peerName, style: AppType.section.copyWith(color: c.ink)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DeviceStatusBadge(status: status),
        const SizedBox(height: AppSpacing.xs),
        Text(status.detail(context.l10n), style: AppType.body.copyWith(color: c.muted)),
        if (fix case (final label, final action)) ...[
          const SizedBox(height: AppSpacing.base),
          AsyncButton(label: label, onPressed: action, expand: true),
        ],
        const SizedBox(height: AppSpacing.base),
        CardGroup(
          inset: AppSpacing.card,
          children: [
            _Fact(
              context.l10n.factStatus,
              status.state == DeviceState.connected ? context.l10n.factLive : status.label(context.l10n),
            ),
            _Fact(
              context.l10n.factLastSynced,
              status.state == DeviceState.connected ? context.l10n.factNow : when(status.lastSyncedAt),
            ),
            _Fact(isSender ? context.l10n.lastShared : context.l10n.lastNotification, when(last)),
            _Fact(context.l10n.factPaired, formatLongDate(context.l10n, device.pairedAt)),
            _Fact(context.l10n.factEncryption, context.l10n.factEncryptionValue),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () {
            final router = GoRouter.of(context); // the sheet's context goes with it
            Navigator.pop(context);
            unawaited(router.push(AppRoutes.deviceHistory(device.pairId)));
          },
          icon: const Icon(AppIcons.notificationsNone, size: 18),
          label: Text(isSender ? context.l10n.browseShared : context.l10n.browseHistory),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () async {
            if (await remove(context, ref, device) && context.mounted) Navigator.pop(context);
          },
          style: TextButton.styleFrom(foregroundColor: c.danger),
          icon: const Icon(AppIcons.linkOff, size: 18),
          label: Text(context.l10n.actionRemoveDevice),
        ),
      ],
    );
  }
}

/// The device's icon on a large soft tile.
class _DeviceGlyph extends StatelessWidget {
  const _DeviceGlyph({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: AppDimensions.iconTileLg,
      height: AppDimensions.iconTileLg,
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.mdBorder),
      child: Icon(icon, size: 26, color: c.accent),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.card, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppType.body.copyWith(color: c.muted)),
          ),
          Text(value, style: AppType.body.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}
