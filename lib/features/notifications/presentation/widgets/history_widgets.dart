import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/pressable_scale.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/core/widgets/section_header.dart';
import 'package:air_reply/features/notifications/history_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Shared by the searches and a phone's history: results are pages from the database, a snapshot that new
// notifications do not reshuffle.

/// "3 new notifications": what arrived since [scope]'s results were taken. Tapping adds them at the top; the search
/// text, the pages read and the place in the list stay.
class NewResultsPill extends ConsumerWidget {
  const NewResultsPill({required this.scope, super.key});

  final HistoryScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(newResultsProvider(scope));
    final c = context.palette;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: count == 0
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Center(
                child: PressableScale(
                  child: Material(
                    color: c.accentSoft,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: ref.read(historyResultsProvider(scope).notifier).includeNew,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AppIcons.refresh, size: AppDimensions.iconSm, color: c.accent),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                count == 1 ? '1 new notification' : '$count new notifications',
                                style: AppType.link.copyWith(color: c.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// The end of [scope]'s results: reads the next page as it comes into view ([auto]) or on a tap, shows that it is
/// reading, or offers to try again.
class HistoryLoadMore extends ConsumerWidget {
  const HistoryLoadMore({required this.scope, this.auto = true, super.key});

  final HistoryScope scope;

  /// Read the next page once this is built: in a lazily built list, that is when it scrolls near.
  final bool auto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(historyResultsProvider(scope));
    final controller = ref.read(historyResultsProvider(scope).notifier);
    if (!results.isActive || (!results.hasMore && results.error == null)) return const SizedBox.shrink();
    if (results.error != null && !results.loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Column(
          children: [
            Text(
              describeError(results.error!),
              textAlign: TextAlign.center,
              style: AppType.supporting.copyWith(color: context.palette.muted),
            ),
            TextButton(onPressed: controller.loadMore, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (auto && !results.loading) {
      SchedulerBinding.instance.addPostFrameCallback((_) => controller.loadMore());
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Center(
        child: results.loading || auto
            ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
            : OutlinedButton(onPressed: controller.loadMore, child: const Text('Show more')),
      ),
    );
  }
}

/// Paired devices whose name matches [query], each opening its whole history: search finds a phone itself, not every
/// notification it sent.
class DeviceResults extends ConsumerWidget {
  const DeviceResults({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceMatchesProvider(query));
    if (devices.isEmpty) return const SizedBox.shrink();
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: 'Devices',
            title: devices.length == 1 ? '1 device' : '${devices.length} devices',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          CardGroup(
            children: [
              for (final device in devices)
                InfoRow(
                  icon: isSender ? AppIcons.devices : AppIcons.smartphone,
                  title: device.peerName,
                  subtitle: isSender ? 'Browse what you shared with it' : 'Browse its notification history',
                  trailing: InfoRow.chevron,
                  onTap: () => context.push(AppRoutes.deviceHistory(device.pairId)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Showing 50 of 1,240": how much of the results the pages cover.
class ResultsCount extends ConsumerWidget {
  const ResultsCount({required this.scope, required this.shown, super.key});

  final HistoryScope scope;
  final int shown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(historyResultsProvider(scope).select((r) => r.total));
    final label = switch (total) {
      null => shown == 1 ? '1 notification' : '$shown notifications',
      1 => '1 notification',
      final t => '$t notifications',
    };
    return Text(label, style: AppType.supporting.copyWith(color: context.palette.muted));
  }
}
