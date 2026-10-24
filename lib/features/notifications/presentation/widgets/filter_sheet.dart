import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showFilterSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
  builder: (_) => const _FilterSheet(),
);

/// Show (all / unread), time, device and app. Changes apply as they are made; the button closes the sheet.
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final filter = ref.watch(inboxFilterProvider);
    final controller = ref.read(inboxFilterProvider.notifier);
    final devices = ref.watch(pairedDevicesProvider);
    final apps = ref.watch(feedAppsProvider);
    final results = ref.watch(visibleFeedProvider).value?.length ?? 0;
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;

    Widget choice(String label, {required bool selected, required VoidCallback onTap, Widget? avatar}) => ChoiceChip(
      label: Text(label),
      avatar: avatar,
      selected: selected,
      onSelected: (_) {
        ref.tick();
        onTap();
      },
      labelStyle: AppType.supporting.copyWith(color: selected ? c.paper : c.ink, fontWeight: FontWeight.w500),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x3, Space.x2),
            child: Row(
              children: [
                Expanded(child: Text('Filter', style: Theme.of(context).textTheme.headlineSmall)),
                TextButton(
                  onPressed: filter.activeCount == 0 ? null : controller.clearFilters,
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: Space.x6),
              children: [
                const SectionLabel('Show', top: Space.x2),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('All')),
                    ButtonSegment(value: true, label: Text('Unread only')),
                  ],
                  selected: {filter.unreadOnly},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) {
                    ref.tick();
                    controller.unreadOnly(s.first);
                  },
                ),
                const SectionLabel('When', top: Space.x6),
                Wrap(
                  spacing: Space.x2,
                  runSpacing: Space.x2,
                  children: [
                    for (final period in FeedPeriod.values)
                      choice(period.label, selected: filter.period == period, onTap: () => controller.period(period)),
                  ],
                ),
                if (devices.length > 1) ...[
                  SectionLabel(isSender ? 'Shared with' : 'Phone', top: Space.x6),
                  Wrap(
                    spacing: Space.x2,
                    runSpacing: Space.x2,
                    children: [
                      choice('All', selected: filter.pairId == null, onTap: () => controller.device(null)),
                      for (final d in devices)
                        choice(
                          d.peerName,
                          selected: filter.pairId == d.pairId,
                          onTap: () => controller.device(d.pairId),
                        ),
                    ],
                  ),
                ],
                if (apps.isNotEmpty) ...[
                  const SectionLabel('App', top: Space.x6),
                  Wrap(
                    spacing: Space.x2,
                    runSpacing: Space.x2,
                    children: [
                      choice('All apps', selected: filter.packageName == null, onTap: () => controller.app(null)),
                      for (final MapEntry(key: package, value: name) in apps.entries)
                        choice(
                          name,
                          selected: filter.packageName == package,
                          onTap: () => controller.app(package),
                          avatar: MirroredAppIcon(packageName: package, appName: name, size: 18),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Space.x6),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.x6, Space.x2, Space.x6, Space.x4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(results == 1 ? 'Show 1 notification' : 'Show $results notifications'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
