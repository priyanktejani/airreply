import 'dart:async';

import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/eyebrow.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/search_field.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/history_providers.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/filter_sheet.dart';
import 'package:air_reply/features/notifications/presentation/widgets/group_widgets.dart';
import 'package:air_reply/features/notifications/presentation/widgets/history_widgets.dart';
import 'package:air_reply/features/permissions/presentation/permission_notices.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every notification across paired devices, with search and filters: one card per app, latest activity first,
/// showing the newest notification, counts and unread state; its conversations (people, group chats) list beneath it
/// on demand, and each opens as a chat.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  /// App groups whose conversations are listed, by group id.
  final _expandedApps = <String>{};

  Future<void> _refresh() async {
    for (final pair in ref.read(pairedDevicesProvider)) {
      refreshPair(ref, pair.pairId);
    }
    // Give the listeners a moment to answer, so the indicator reflects real work.
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _markAllRead() async {
    final previous = ref.read(inboxStateProvider).value;
    final inbox = ref.read(inboxStateProvider.notifier);
    ref.success();
    await inbox.markAllRead();
    if (!mounted || previous == null) return;
    context.showUndo('All marked as read', () => unawaited(inbox.restore(previous)));
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(pairedDevicesProvider);
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    final unread = ref.watch(unreadCountProvider);
    final filter = ref.watch(inboxFilterProvider);
    final inboxLoaded = ref.watch(inboxStateProvider).hasValue;
    final groups = ref.watch(groupedInboxProvider);
    final everything = ref.watch(liveFeedProvider).value ?? const [];
    final search = ref.watch(historyResultsProvider(inboxSearch));
    final matchedDevices = ref.watch(deviceMatchesProvider(filter.query)).isNotEmpty;

    final source = switch ((isSender, devices)) {
      (true, [final only]) => 'Shared with ${only.peerName}',
      (true, _) => 'Shared with ${devices.length} devices',
      (false, [final only]) => 'From ${only.peerName}',
      (false, _) => 'From ${devices.length} phones',
    };

    final count = filter.activeCount;
    return Scaffold(
      body: GlassScrollPage(
        onRefresh: _refresh,
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: unread == 0 ? null : _markAllRead,
            icon: const Icon(AppIcons.doneAll),
          ),
        ],
        // the search box stays pinned under the bar, as frosted glass, while the notifications scroll beneath it
        search: Row(
          children: [
            Expanded(
              child: SearchField(
                hint: 'Search notifications',
                value: filter.query,
                onChanged: ref.read(inboxFilterProvider.notifier).search,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: count > 0 ? 'Filters, $count on' : 'Filters',
              onPressed: () => showFilterSheet(context),
              style: IconButton.styleFrom(
                fixedSize: const Size(AppDimensions.fieldHeight, AppDimensions.fieldHeight),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              ),
              // on the icon, as on the bell and the nav bar: inside the button, clear of the pinned bar's edge
              icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(AppIcons.tune)),
            ),
          ],
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(unread == 0 ? 'All read' : '$unread unread'),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(source, style: AppType.body.copyWith(color: context.palette.muted)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: AttentionNotices(connection: false, bottom: AppSpacing.base)),
          if (filter.activeCount > 0) SliverToBoxAdapter(child: _ActiveFilters(filter: filter)),
          // searching: matching devices first, then notifications from the whole history, which hold still while new
          // ones arrive (the pill adds them)
          if (search.isActive) ...[
            SliverToBoxAdapter(child: DeviceResults(query: filter.query)),
            const SliverToBoxAdapter(child: NewResultsPill(scope: inboxSearch)),
          ],
          ...switch (groups) {
            _ when !inboxLoaded => [const SliverToBoxAdapter(child: SkeletonList())],
            AsyncData(value: final list) when list.isEmpty && search.isActive && (search.loading || search.hasMore) => [
              const SliverToBoxAdapter(child: SkeletonList()),
            ],
            AsyncData(value: final list) when list.isEmpty && search.isActive && matchedDevices => [],
            AsyncData(value: final list) when list.isEmpty => [
              SliverToBoxAdapter(
                child: filter.isActive
                    ? EmptyState(
                        icon: AppIcons.filterAltOff,
                        title: 'No matches',
                        description: 'Nothing matches this search or filter.',
                        action: OutlinedButton(
                          onPressed: ref.read(inboxFilterProvider.notifier).clear,
                          child: const Text('Clear search and filters'),
                        ),
                      )
                    : EmptyState(
                        icon: everything.isEmpty ? AppIcons.notificationsNone : AppIcons.inbox,
                        title: everything.isEmpty ? 'Nothing here yet' : 'All caught up',
                        description: everything.isEmpty
                            ? (isSender
                                  ? 'Notifications this phone shares appear here, with the replies sent from your '
                                        'devices.'
                                  : 'Notifications from your phone appear here the moment they arrive.')
                            : 'Every notification is hidden. Restore them from Settings.',
                      ),
              ),
            ],
            AsyncData(value: final groups) => [
              _GroupsList(
                groups: groups,
                showDevice: devices.length > 1,
                expanded: _expandedApps,
                onToggle: (id) =>
                    setState(() => _expandedApps.contains(id) ? _expandedApps.remove(id) : _expandedApps.add(id)),
              ),
              // the next page of results is read as the end of the list scrolls near
              if (search.isActive) const SliverToBoxAdapter(child: HistoryLoadMore(scope: inboxSearch)),
            ],
            AsyncError(:final error) => [
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: AppIcons.cloudOff,
                  tone: Tone.error,
                  title: 'Could not load notifications',
                  description: describeError(error),
                  action: OutlinedButton(onPressed: _refresh, child: const Text('Try again')),
                ),
              ),
            ],
            _ => [const SliverToBoxAdapter(child: SkeletonList())],
          },
        ],
      ),
    );
  }
}

/// The filters that are on, each removable on its own.
class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters({required this.filter});

  final FeedFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(inboxFilterProvider.notifier);
    final devices = ref.watch(pairedDevicesProvider);
    final apps = ref.watch(feedAppsProvider);
    Widget chip(String label, VoidCallback onDeleted) => InputChip(
      label: Text(label),
      selected: true,
      onPressed: onDeleted,
      onDeleted: onDeleted,
      deleteButtonTooltipMessage: 'Remove filter',
      deleteIcon: const Icon(AppIcons.close, size: 16),
      deleteIconColor: context.palette.accent,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          if (filter.unreadOnly) chip('Unread', () => controller.unreadOnly(false)),
          if (filter.period != FeedPeriod.all) chip(filter.period.label, () => controller.period(FeedPeriod.all)),
          if (filter.pairId case final pairId?)
            chip(
              devices.where((d) => d.pairId == pairId).firstOrNull?.peerName ?? 'Device',
              () => controller.device(null),
            ),
          if (filter.packageName case final package?) chip(apps[package] ?? package, () => controller.app(null)),
        ],
      ),
    );
  }
}

/// One frosted card per app group, latest activity first; expanded groups list their conversations inside.
class _GroupsList extends StatelessWidget {
  const _GroupsList({required this.groups, required this.showDevice, required this.expanded, required this.onToggle});

  final List<AppGroup> groups;
  final bool showDevice;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => SliverList.builder(
    itemCount: groups.length,
    itemBuilder: (context, i) {
      final group = groups[i];
      return Padding(
        key: ValueKey('app/${group.id}'),
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: FadeSlideIn.staggered(
          index: i,
          child: AppGroupTile(
            group: group,
            showDevice: showDevice,
            expanded: expanded.contains(group.id),
            onToggleExpanded: () => onToggle(group.id),
          ),
        ),
      );
    },
  );
}
