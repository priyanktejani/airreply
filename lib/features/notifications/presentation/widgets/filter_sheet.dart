import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/app_sheet.dart';
import 'package:air_reply/core/widgets/eyebrow.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/feed_period_label.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showFilterSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  showDragHandle: false,
  elevation: 0,
  constraints: const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
  builder: (_) => const _FilterSheet(),
);

/// A small accent label over one group of choices.
class _Label extends StatelessWidget {
  const _Label(this.text, {this.top = AppSpacing.xl});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: AppSpacing.md),
    child: Eyebrow(text),
  );
}

/// Show (all / unread), time, device and app. Changes apply as they are made; the button closes the sheet.
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
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
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scroll) => AppSheetFrame(
        child: Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.base, AppSpacing.md, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(context.l10n.filterTitle, style: AppType.section.copyWith(color: c.ink)),
                    ),
                    TextButton(
                      onPressed: filter.activeCount == 0 ? null : controller.clearFilters,
                      child: Text(context.l10n.actionClearAll),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  children: [
                    _Label(context.l10n.filterShow, top: AppSpacing.sm),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text(context.l10n.filterAll)),
                        ButtonSegment(value: true, label: Text(context.l10n.filterUnreadOnly)),
                      ],
                      selected: {filter.unreadOnly},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) {
                        ref.tick();
                        controller.unreadOnly(s.first);
                      },
                    ),
                    _Label(context.l10n.filterWhen),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final period in FeedPeriod.values)
                          choice(
                            period.label(context.l10n),
                            selected: filter.period == period,
                            onTap: () => controller.period(period),
                          ),
                      ],
                    ),
                    if (devices.length > 1) ...[
                      _Label(isSender ? context.l10n.filterSharedWith : context.l10n.filterPhone),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          choice(
                            context.l10n.filterAll,
                            selected: filter.pairId == null,
                            onTap: () => controller.device(null),
                          ),
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
                      _Label(context.l10n.filterApp),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          choice(
                            context.l10n.filterAllApps,
                            selected: filter.packageName == null,
                            onTap: () => controller.app(null),
                          ),
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
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.base),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.l10n.showNotificationsCount(results)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
