import 'dart:async';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/filter_sheet.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/permissions/presentation/permission_notices.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every notification across paired devices, by day, with search and filters. Notifications of one conversation on
/// one day fold into a single row that expands.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  /// Groups opened by the person, by their latest entry's key.
  final _expanded = <String>{};

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
    final days = ref.watch(feedDaysProvider);
    final everything = ref.watch(allFeedProvider).value ?? const [];

    final source = switch ((isSender, devices)) {
      (true, [final only]) => 'Shared with ${only.peerName}',
      (true, _) => 'Shared with ${devices.length} devices',
      (false, [final only]) => 'From ${only.peerName}',
      (false, _) => 'From ${devices.length} phones',
    };

    return Scaffold(
      body: EditorialPage(
        onRefresh: _refresh,
        header: PageHeader(
          eyebrow: unread == 0 ? 'All read' : '$unread unread',
          title: 'Notifications',
          subtitle: Text(source),
          actions: [
            IconButton(
              tooltip: 'Mark all as read',
              onPressed: unread == 0 ? null : _markAllRead,
              icon: const Icon(Icons.done_all),
            ),
          ],
        ),
        slivers: [
          const SliverToBoxAdapter(child: AttentionNotices(connection: false)),
          SliverToBoxAdapter(child: _SearchBar(filter: filter)),
          if (filter.activeCount > 0) SliverToBoxAdapter(child: _ActiveFilters(filter: filter)),
          const SliverToBoxAdapter(child: SizedBox(height: Space.x2)),
          ...switch (days) {
            _ when !inboxLoaded => [const SliverToBoxAdapter(child: SkeletonList())],
            AsyncData(value: final list) when list.isEmpty => [
              SliverToBoxAdapter(
                child: filter.isActive
                    ? StateMessage(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'No matches',
                        message: 'Nothing matches this search or filter.',
                        action: OutlinedButton(
                          onPressed: ref.read(inboxFilterProvider.notifier).clear,
                          child: const Text('Clear search and filters'),
                        ),
                      )
                    : StateMessage(
                        icon: everything.isEmpty ? Icons.notifications_none : Icons.inbox_outlined,
                        title: everything.isEmpty ? 'Nothing here yet' : 'All caught up',
                        message: everything.isEmpty
                            ? (isSender
                                  ? 'Notifications this phone shares appear here, with the replies sent from your '
                                        'devices.'
                                  : 'Notifications from your phone appear here the moment they arrive.')
                            : 'Every notification is hidden. Restore them from Settings.',
                      ),
              ),
            ],
            AsyncData(value: final list) => [
              _DaysList(
                days: list,
                showDevice: devices.length > 1,
                expanded: _expanded,
                onToggle: (key) => setState(() => _expanded.contains(key) ? _expanded.remove(key) : _expanded.add(key)),
              ),
            ],
            AsyncError(:final error) => [
              SliverToBoxAdapter(
                child: StateMessage(
                  icon: Icons.cloud_off_outlined,
                  tone: Tone.error,
                  title: 'Could not load notifications',
                  message: describeError(error),
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

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.filter});

  final FeedFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = filter.activeCount;
    return Row(
      children: [
        Expanded(
          child: SearchField(
            hint: 'Search notifications',
            value: filter.query,
            onChanged: ref.read(inboxFilterProvider.notifier).search,
          ),
        ),
        const SizedBox(width: Space.x2),
        Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: IconButton.outlined(
            tooltip: count > 0 ? 'Filters, $count on' : 'Filters',
            onPressed: () => showFilterSheet(context),
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              side: BorderSide(color: context.colors.border),
              shape: const RoundedRectangleBorder(borderRadius: Radii.controlBorder),
            ),
            icon: const Icon(Icons.tune, size: 20),
          ),
        ),
      ],
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
      onDeleted: onDeleted,
      deleteButtonTooltipMessage: 'Remove filter',
      deleteIconColor: context.colors.secondary,
    );
    return Padding(
      padding: const EdgeInsets.only(top: Space.x3),
      child: Wrap(
        spacing: Space.x2,
        runSpacing: Space.x2,
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

sealed class _Item {
  const _Item();
}

final class _DayItem extends _Item {
  const _DayItem(this.day);
  final FeedDay day;
}

final class _EntryItem extends _Item {
  const _EntryItem(this.entry, {this.group, this.nested = false});
  final FeedEntry entry;
  final FeedGroup? group;
  final bool nested;
}

final class _ToggleItem extends _Item {
  const _ToggleItem(this.group, {required this.expanded});
  final FeedGroup group;
  final bool expanded;
}

class _DaysList extends StatelessWidget {
  const _DaysList({required this.days, required this.showDevice, required this.expanded, required this.onToggle});

  final List<FeedDay> days;
  final bool showDevice;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;

  List<_Item> get _items => [
    for (final day in days) ...[
      _DayItem(day),
      for (final group in day.groups) ...[
        _EntryItem(group.latest, group: group.isGroup && !expanded.contains(group.latest.key) ? group : null),
        if (group.isGroup) _ToggleItem(group, expanded: expanded.contains(group.latest.key)),
        if (group.isGroup && expanded.contains(group.latest.key))
          for (final e in group.entries.skip(1)) _EntryItem(e, nested: true),
      ],
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final c = context.colors;
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => switch (items[i]) {
        _DayItem(:final day) => SectionLabel(
          formatDayLabel(day.date),
          top: i == 0 ? Space.x4 : Space.x8,
          trailing: Text('${day.count}', style: AppType.label.copyWith(color: c.secondary)),
        ),
        _EntryItem(:final entry, :final group, :final nested) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: nested ? Space.x10 + Space.x4 : 0),
            child: NotificationRow(
              key: ValueKey(entry.key),
              entry: entry,
              group: group,
              compact: nested,
              showDevice: showDevice,
            ),
          ),
        ),
        _ToggleItem(:final group, :final expanded) => Padding(
          padding: const EdgeInsets.only(left: Space.x10 + Space.x2, bottom: Space.x2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onToggle(group.latest.key),
              style: TextButton.styleFrom(foregroundColor: c.secondary),
              icon: AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: Motion.medium,
                child: const Icon(Icons.expand_more, size: 18),
              ),
              label: Text(expanded ? 'Show less' : '${group.count - 1} earlier from this conversation'),
            ),
          ),
        ),
      },
    );
  }
}
