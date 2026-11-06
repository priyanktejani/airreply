import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/l10n/describe_error.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/async_button.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/archived_pair.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// How many notifications a removed device left on this device.
final previousHistorySizeProvider = FutureProvider.autoDispose.family<int, String>(
  (ref, pairId) async => (await ref.watch(historySizeProvider)(pairId)).notifications,
);

/// Devices that were removed, whose history this device kept: each opens its history, and can be deleted.
class PreviousDevicesScreen extends ConsumerWidget {
  const PreviousDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final l10n = context.l10n;
    final pairs = ref.watch(archivedPairsProvider);

    Future<void> deleteAll() async {
      final confirmed = await context.confirm(
        title: l10n.deleteAllHistoryTitle,
        message: l10n.deleteAllHistoryMessage,
        confirmLabel: l10n.actionDeleteAll,
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
      await runGuarded(context, () async {
        await ref.read(archivedPairsProvider.notifier).deleteAll();
        if (context.mounted) context.showMessage(l10n.allHistoryDeleted);
      });
    }

    return Scaffold(
      body: GlassScrollPage(
        title: Text(l10n.previousDevicesTitle),
        slivers: [
          SliverList.list(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.previousDevicesIntro, style: AppType.body.copyWith(color: c.muted)),
              const SizedBox(height: AppSpacing.section),
              switch (pairs) {
                AsyncData(value: final pairs) when pairs.isEmpty => EmptyState(
                  icon: AppIcons.history,
                  title: l10n.previousDevicesNone,
                  description: l10n.previousDevicesNoneHint,
                ),
                AsyncData(value: final pairs) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CardGroup(children: [for (final pair in pairs) _PreviousDeviceRow(pair)]),
                    const SizedBox(height: AppSpacing.xl),
                    AsyncButton(
                      label: l10n.actionDeleteAll,
                      icon: AppIcons.delete,
                      style: AsyncButtonStyle.outlined,
                      destructive: true,
                      onPressed: deleteAll,
                    ),
                  ],
                ),
                AsyncError(:final error) => EmptyState(
                  icon: AppIcons.errorOutline,
                  tone: Tone.error,
                  title: l10n.previousDevicesTitle,
                  description: context.describeError(error),
                ),
                _ => const SkeletonList(rows: 2),
              },
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviousDeviceRow extends ConsumerWidget {
  const _PreviousDeviceRow(this.pair);

  final ArchivedPair pair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final size = ref.watch(previousHistorySizeProvider(pair.pairId)).value;
    final removed = formatDayLabel(l10n, pair.unpairedAt);
    return InfoRow(
      icon: AppIcons.history,
      title: pair.peerName,
      subtitle: size == null
          ? l10n.previousDeviceRemoved(removed)
          : l10n.previousDeviceSummary(removed, l10n.notificationsCount(size)),
      trailing: InfoRow.chevron,
      onTap: () => unawaited(context.push(AppRoutes.previousDevice(pair.pairId))),
    );
  }
}

/// Asks, then deletes a removed device's history. True once deleted.
Future<bool> deletePreviousDevice(BuildContext context, WidgetRef ref, ArchivedPair pair) async {
  final l10n = context.l10n;
  final confirmed = await context.confirm(
    title: l10n.deleteHistoryTitle(pair.peerName),
    message: l10n.deleteHistoryMessage,
    confirmLabel: l10n.actionDeleteHistory,
    destructive: true,
  );
  if (!confirmed || !context.mounted) return false;
  final done = appSnackBar(context, l10n.historyDeleted(pair.peerName), icon: AppIcons.delete);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(archivedPairsProvider.notifier).delete(pair.pairId);
  } on Object catch (e) {
    if (context.mounted) context.showError(e);
    return false;
  }
  messenger.showSnackBar(done);
  return true;
}
