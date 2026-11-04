import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/section_header.dart';
import 'package:air_reply/features/notifications/history_providers.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/history_widgets.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What Home's search finds, as it is typed: paired devices by name, then the notifications that mention it, from the
/// whole history on this device, newest first, a page at a time.
class HomeSearchResults extends ConsumerWidget {
  const HomeSearchResults({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(historyResultsProvider(homeSearch));
    final found = ref.watch(shownResultsProvider(homeSearch));
    final devices = ref.watch(deviceMatchesProvider(query));
    final manyDevices = ref.watch(pairedDevicesProvider).length > 1;
    final reading = results.loading || !results.isActive;

    if (found.isEmpty && devices.isEmpty && !reading && !results.hasMore) {
      return EmptyState(
        icon: AppIcons.searchOff,
        title: context.l10n.searchNoMatches,
        description: context.l10n.searchNoMatchesDetail(query.trim()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeviceResults(query: query),
        SectionHeader(
          eyebrow: context.l10n.searchEyebrow,
          title: context.l10n.tabNotifications,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.xxs),
        ResultsCount(scope: homeSearch, shown: found.length),
        const SizedBox(height: AppSpacing.md),
        const NewResultsPill(scope: homeSearch),
        if (found.isEmpty && reading)
          const SkeletonList()
        else
          for (final (i, e) in found.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            FadeSlideIn.staggered(
              key: ValueKey(e.key),
              index: i,
              child: NotificationRow(entry: e, compact: true, showDevice: manyDevices),
            ),
          ],
        // Home lays its results out at once, so the next page is read on request
        const HistoryLoadMore(scope: homeSearch, auto: false),
      ],
    );
  }
}
