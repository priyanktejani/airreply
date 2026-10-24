import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_icon.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/features/devices/devices_providers.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/devices/presentation/device_status_badge.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> showDeviceSheet(BuildContext context, PairingCredentials device) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
  builder: (_) => _DeviceSheet(device: device),
);

/// One device: its state, when it last synced, what fixes a problem, and removing it.
class _DeviceSheet extends ConsumerWidget {
  const _DeviceSheet({required this.device});

  final PairingCredentials device;

  /// Asks, then ends the pair on both devices. True once removed.
  static Future<bool> remove(BuildContext context, WidgetRef ref, PairingCredentials device) async {
    final confirmed = await context.confirm(
      title: 'Remove ${device.peerName}?',
      message:
          'Syncing with ${device.peerName} stops on both devices, its encryption key is deleted, and the history '
          'you share with it is removed. Other devices are not affected.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return false;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(deviceSessionProvider.notifier).unpair(device.pairId);
    } on Object catch (e) {
      if (context.mounted) context.showError(e);
      return false;
    }
    ref.success();
    messenger.showSnackBar(SnackBar(content: Text('${device.peerName} removed')));
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    final status = ref.watch(deviceStatusProvider(device.pairId));
    final last = ref.watch(lastActivityProvider(device.pairId));
    final stillPaired = ref.watch(pairedDevicesProvider).any((p) => p.pairId == device.pairId);
    if (!stillPaired) return const SizedBox(height: Space.x16);

    final fix = switch (status.fix) {
      DeviceFix.grantNotificationAccess => (
        'Turn on notification access',
        ref.read(senderPermissionsProvider.notifier).openNotificationAccess,
      ),
      DeviceFix.resumeSharing => ('Resume sharing', () => ref.read(syncStatusProvider.notifier).setEnabled(true)),
      DeviceFix.reconnectListener => ('Reconnect', ref.read(syncStatusProvider.notifier).reconnectListener),
      DeviceFix.retrySync => (
        'Retry',
        () async {
          refreshPair(ref, device.pairId);
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
      ),
      null => null,
    };

    String when(DateTime? t) => t == null ? 'Not yet' : formatAgo(t);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(deviceIcon(device.peerName, isPhone: !isSender), size: 28, color: c.ink),
                const SizedBox(width: Space.x3),
                Expanded(child: Text(device.peerName, style: Theme.of(context).textTheme.headlineSmall)),
              ],
            ),
            const SizedBox(height: Space.x3),
            DeviceStatusBadge(status: status),
            const SizedBox(height: Space.x1),
            Text(status.detail, style: AppType.body.copyWith(color: c.secondary)),
            if (fix case (final label, final action)) ...[
              const SizedBox(height: Space.x4),
              AsyncButton(label: label, onPressed: action, expand: true),
            ],
            const SizedBox(height: Space.x4),
            RuledList(
              children: [
                _Fact('Status', status.state == DeviceState.connected ? 'Live' : status.label),
                _Fact('Last synced', status.state == DeviceState.connected ? 'Now' : when(status.lastSyncedAt)),
                _Fact(isSender ? 'Last shared' : 'Last notification', when(last)),
                _Fact('Paired', formatLongDate(device.pairedAt)),
                const _Fact('Encryption', 'End-to-end, AES-256-GCM'),
              ],
            ),
            const SizedBox(height: Space.x6),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(inboxFilterProvider.notifier).set(FeedFilter(pairId: device.pairId));
                Navigator.pop(context);
                context.go(AppRoutes.notifications);
              },
              icon: const Icon(Icons.notifications_none, size: 18),
              label: Text(isSender ? 'Notifications shared with it' : 'Notifications from it'),
            ),
            const SizedBox(height: Space.x2),
            TextButton.icon(
              onPressed: () async {
                if (await remove(context, ref, device) && context.mounted) Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: c.error),
              icon: const Icon(Icons.link_off, size: 18),
              label: const Text('Remove device'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppType.body.copyWith(color: c.secondary)),
          ),
          Text(value, style: AppType.body.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}

/// Removing a device from elsewhere (Settings → data), with the same confirmation.
Future<bool> confirmRemoveDevice(BuildContext context, WidgetRef ref, PairingCredentials device) =>
    _DeviceSheet.remove(context, ref, device);
