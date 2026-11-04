import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/stat_tile.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day in three tiles: today's notifications, unread ones and paired devices; each opens what it counts.
class GlanceStats extends ConsumerWidget {
  const GlanceStats({required this.onToday, required this.onUnread, required this.onDevices, super.key});

  final VoidCallback onToday;
  final VoidCallback onUnread;
  final VoidCallback onDevices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayCountProvider);
    final unread = ref.watch(unreadCountProvider);
    final devices = ref.watch(pairedDevicesProvider).length;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stat(value: '$today', label: context.l10n.statToday, icon: AppIcons.bolt, onTap: onToday),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Stat(
              value: '$unread',
              label: context.l10n.statUnread,
              icon: AppIcons.markChatUnread,
              onTap: onUnread,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Stat(
              value: '$devices',
              label: context.l10n.statDevices(devices),
              icon: AppIcons.devices,
              onTap: onDevices,
            ),
          ),
        ],
      ),
    );
  }
}
