import 'dart:async';

import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/eyebrow.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/features/mirror/domain/entities/history_query.dart';
import 'package:air_reply/features/notifications/history_providers.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/history_widgets.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every notification of one paired device, newest first, read from the history on this device a page at a time as
/// the list scrolls: years of it, not only what the inbox keeps loaded. What arrives meanwhile waits behind the "new
/// notifications" pill, so the list does not move under the reader.
class DeviceHistoryScreen extends ConsumerStatefulWidget {
  const DeviceHistoryScreen({required this.pairId, super.key});

  final String pairId;

  @override
  ConsumerState<DeviceHistoryScreen> createState() => _DeviceHistoryScreenState();
}

class _DeviceHistoryScreenState extends ConsumerState<DeviceHistoryScreen> {
  late final HistoryScope _scope = deviceHistory(widget.pairId);
  late final HistoryResultsController _history = ref.read(historyResultsProvider(_scope).notifier);

  @override
  void initState() {
    super.initState();
    // providers cannot change while the tree builds: open once this frame is done
    scheduleMicrotask(() => unawaited(_history.open(const HistoryQuery(), pairIds: [widget.pairId])));
  }

  @override
  void dispose() {
    // what was read leaves the feed with the screen
    scheduleMicrotask(_history.close);
    super.dispose();
  }

  Future<void> _refresh() => _history.open(const HistoryQuery(), pairIds: [widget.pairId]);

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(pairedDevicesProvider).where((p) => p.pairId == widget.pairId).firstOrNull;
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    final results = ref.watch(historyResultsProvider(_scope));
    final entries = ref.watch(shownResultsProvider(_scope));
    return Scaffold(
      body: GlassScrollPage(
        title: Text(device?.peerName ?? context.l10n.historyTitle),
        onRefresh: _refresh,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(isSender ? context.l10n.historySharedWithIt : context.l10n.historyTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  ResultsCount(scope: _scope, shown: entries.length),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: NewResultsPill(scope: _scope)),
          if (entries.isEmpty && (results.loading || !results.isActive))
            const SliverToBoxAdapter(child: SkeletonList())
          else if (entries.isEmpty && !results.hasMore)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: AppIcons.notificationsNone,
                title: context.l10n.emptyNothingYet,
                description: isSender
                    ? context.l10n.historyEmptySender(device?.peerName ?? context.l10n.itDevice)
                    : context.l10n.historyEmptyReceiver(device?.peerName ?? context.l10n.thisPhone),
              ),
            )
          else
            SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) => Padding(
                key: ValueKey(entries[i].key),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: NotificationRow(entry: entries[i]),
              ),
            ),
          SliverToBoxAdapter(child: HistoryLoadMore(scope: _scope)),
        ],
      ),
    );
  }
}
