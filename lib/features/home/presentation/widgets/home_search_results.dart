import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/section_header.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What Home's search finds, as it is typed: the matching notifications, newest first.
class HomeSearchResults extends ConsumerWidget {
  const HomeSearchResults({required this.query, super.key});

  final String query;

  static const _shown = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final found = ref.watch(searchFeedProvider(query));
    final devices = ref.watch(pairedDevicesProvider).length;
    if (found.isEmpty) {
      return EmptyState(
        icon: AppIcons.searchOff,
        title: 'No matches',
        description: 'No notification mentions “${query.trim()}”.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          eyebrow: 'Search',
          title: found.length == 1 ? '1 notification' : '${found.length} notifications',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (i, e) in found.take(_shown).indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          FadeSlideIn.staggered(
            index: i,
            child: NotificationRow(entry: e, compact: true, showDevice: devices > 1),
          ),
        ],
      ],
    );
  }
}
