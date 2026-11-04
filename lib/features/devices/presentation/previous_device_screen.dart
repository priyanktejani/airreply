import 'dart:async';

import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_sheet.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/eyebrow.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/features/devices/presentation/previous_devices_screen.dart';
import 'package:air_reply/features/mirror/data/mirror_sync_repository.dart';
import 'package:air_reply/features/mirror/domain/entities/history_query.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/history_providers.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/history_widgets.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_card.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A removed device's history, read from this device a page at a time: to look back at, not to answer. Pairing the
/// same device again brings it back into the inbox.
class PreviousDeviceScreen extends ConsumerStatefulWidget {
  const PreviousDeviceScreen({required this.pairId, super.key});

  final String pairId;

  @override
  ConsumerState<PreviousDeviceScreen> createState() => _PreviousDeviceScreenState();
}

class _PreviousDeviceScreenState extends ConsumerState<PreviousDeviceScreen> {
  late final HistoryScope _scope = previousDeviceHistory(widget.pairId);
  late final HistoryResultsController _history = ref.read(historyResultsProvider(_scope).notifier);
  MirrorSyncRepository? _feed;

  @override
  void initState() {
    super.initState();
    // providers cannot change while the tree builds: open once this frame is done
    scheduleMicrotask(_open);
  }

  Future<void> _open() async {
    final pairs = await ref.read(archivedPairsProvider.future);
    final pair = pairs.where((p) => p.pairId == widget.pairId).firstOrNull;
    if (pair == null || !mounted) return;
    final feed = _feed ??= ref.read(previousHistoryFeedProvider)(pair.credentials);
    await _history.open(const HistoryQuery(), pairIds: [widget.pairId], feeds: {widget.pairId: feed});
  }

  @override
  void dispose() {
    final feed = _feed;
    scheduleMicrotask(() {
      _history.close();
      feed?.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    final pairs = ref.watch(archivedPairsProvider);
    final pair = pairs.value?.where((p) => p.pairId == widget.pairId).firstOrNull;
    final results = ref.watch(historyResultsProvider(_scope));
    final entries = ref.watch(shownResultsProvider(_scope));
    return Scaffold(
      body: GlassScrollPage(
        title: Text(pair?.peerName ?? l10n.previousDevicesTitle),
        actions: [
          if (pair != null)
            IconButton(
              tooltip: l10n.actionDeleteHistory,
              icon: const Icon(AppIcons.delete),
              onPressed: () async {
                if (await deletePreviousDevice(context, ref, pair) && context.mounted) context.pop();
              },
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
        slivers: [
          if (pairs.hasValue && pair == null)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: AppIcons.history,
                title: l10n.notAvailable,
                description: l10n.previousDevicesNoneHint,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pair != null) Eyebrow(l10n.previousDeviceRemoved(formatDayLabel(l10n, pair.unpairedAt))),
                    const SizedBox(height: AppSpacing.xxs),
                    ResultsCount(scope: _scope, shown: entries.length),
                    if (pair != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.previousDeviceContinue(pair.peerName),
                        style: AppType.supporting.copyWith(color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (entries.isEmpty && (results.loading || !results.isActive))
              const SliverToBoxAdapter(child: SkeletonList())
            else if (entries.isEmpty && !results.hasMore)
              SliverToBoxAdapter(
                child: EmptyState(icon: AppIcons.notificationsNone, title: l10n.emptyNothingYet),
              )
            else
              SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) => Padding(
                  key: ValueKey(entries[i].key),
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _PreviousRow(entries[i]),
                ),
              ),
            SliverToBoxAdapter(child: HistoryLoadMore(scope: _scope)),
          ],
        ],
      ),
    );
  }
}

/// One notification of a removed device: as the inbox shows it, without the actions an active pair has. Opens its
/// whole text.
class _PreviousRow extends StatelessWidget {
  const _PreviousRow(this.entry);

  final FeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final content = entry.notification.content;
    final text = messageText(content);
    return NotificationCard(
      leading: (size) => MirroredAppIcon(packageName: content.packageName, appName: content.appName, size: size),
      source: content.appName,
      time: entry.postedAt,
      title: content.title,
      text: text,
      badges: [if (entry.latestReply case final reply?) ReplyStatusBadge(reply: reply, prefix: true)],
      onTap: () => unawaited(showAppSheet<void>(context, builder: (context) => _FullText(entry: entry))),
    );
  }
}

class _FullText extends StatelessWidget {
  const _FullText({required this.entry});

  final FeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final l10n = context.l10n;
    final content = entry.notification.content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${content.appName} · ${formatTimestamp(l10n, entry.postedAt)}',
          style: AppType.supporting.copyWith(color: c.muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (content.title.isNotEmpty) Text(content.title, style: AppType.section.copyWith(color: c.ink)),
        const SizedBox(height: AppSpacing.md),
        SelectableText(messageText(content), style: AppType.bodyLarge.copyWith(color: c.ink)),
        for (final reply in entry.replies) ...[
          const SizedBox(height: AppSpacing.base),
          Text(l10n.youSaid(reply.text), style: AppType.body.copyWith(color: c.muted)),
        ],
        const SizedBox(height: AppSpacing.base),
      ],
    );
  }
}
