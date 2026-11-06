import 'dart:async';

import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/haptics/haptics.dart';
import 'package:air_reply/core/l10n/describe_error.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/widgets/app_icon.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/core/widgets/search_field.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-app control. Senders choose which apps are shared at all (stored natively, so it applies with the app
/// closed); receivers mute apps whose notifications should arrive without an alert.
class AppManagementScreen extends ConsumerStatefulWidget {
  const AppManagementScreen({super.key});

  @override
  ConsumerState<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends ConsumerState<AppManagementScreen> {
  /// What is typed in the search box, as typed.
  var _typed = '';

  bool _matches(String label, String package) {
    final query = _typed.trim().toLowerCase();
    return query.isEmpty || label.toLowerCase().contains(query) || package.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    return Scaffold(
      body: GlassScrollPage(
        title: Text(isSender ? context.l10n.appsToShareTitle : context.l10n.appsMutedTitle),
        slivers: isSender ? _senderSlivers() : _receiverSlivers(),
      ),
    );
  }

  Widget _search(String hint) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.base, bottom: AppSpacing.sm),
    child: SearchField(hint: hint, value: _typed, onChanged: (q) => setState(() => _typed = q)),
  );

  List<Widget> _senderSlivers() {
    final filter = ref.watch(appFilterProvider);
    final controller = ref.read(appFilterProvider.notifier);
    final c = context.palette;

    return switch (filter) {
      AsyncData(value: final current) => [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.appsShareIntro, style: AppType.body.copyWith(color: c.muted)),
              const SizedBox(height: AppSpacing.base),
              SegmentedButton<AppFilterMode>(
                segments: [
                  ButtonSegment(value: AppFilterMode.all, label: Text(context.l10n.filterAllApps)),
                  ButtonSegment(value: AppFilterMode.selected, label: Text(context.l10n.appsOnlySelected)),
                ],
                selected: {current.mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) {
                  ref.tick();
                  unawaited(runGuarded(context, () => controller.setMode(s.first)));
                },
              ),
              if (current.mode == AppFilterMode.selected) ...[
                _search(context.l10n.searchApps),
                Text(
                  current.packages.isEmpty
                      ? context.l10n.appsNothingSelected
                      : context.l10n.appsSelected(current.packages.length),
                  style: AppType.supporting.copyWith(color: current.packages.isEmpty ? c.warnInk : c.muted),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        if (current.mode == AppFilterMode.selected)
          _InstalledAppList(filter: current, matches: _matches)
        else
          SliverToBoxAdapter(
            child: EmptyState(
              icon: AppIcons.apps,
              title: context.l10n.appsAllShared,
              description: context.l10n.appsOnlySelectedHint,
            ),
          ),
      ],
      AsyncError(:final error) => [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: AppIcons.errorOutline,
            tone: Tone.error,
            title: context.l10n.appsChoiceLoadFailed,
            description: context.describeError(error),
            action: OutlinedButton(
              onPressed: () => ref.invalidate(appFilterProvider),
              child: Text(context.l10n.actionTryAgain),
            ),
          ),
        ),
      ],
      _ => [const SliverToBoxAdapter(child: SkeletonList())],
    };
  }

  List<Widget> _receiverSlivers() {
    final apps = ref.watch(feedAppsProvider);
    final preferences = ref.watch(appPreferencesProvider).value;
    final c = context.palette;
    final visible = [
      for (final MapEntry(key: package, value: name) in apps.entries)
        if (_matches(name, package)) (package, name),
    ];
    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.appsMutedIntro, style: AppType.body.copyWith(color: c.muted)),
            if (apps.isNotEmpty) _search(context.l10n.searchApps),
          ],
        ),
      ),
      if (apps.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: AppIcons.apps,
            title: context.l10n.appsNoneYet,
            description: context.l10n.appsNoneYetHint,
          ),
        )
      else
        SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: AppSpacing.card),
          itemBuilder: (context, i) {
            final (package, name) = visible[i];
            final muted = preferences?.mutedApps.contains(package) ?? false;
            return SwitchRow(
              leading: MirroredAppIcon(packageName: package, appName: name, size: 32),
              title: name,
              subtitle: muted ? context.l10n.appMuted : context.l10n.appAlertsOn,
              value: !muted,
              onChanged: preferences == null
                  ? null
                  : (alerts) {
                      ref.tick();
                      unawaited(ref.read(appPreferencesProvider.notifier).setMuted(package, muted: !alerts));
                    },
            );
          },
        ),
    ];
  }
}

class _InstalledAppList extends ConsumerWidget {
  const _InstalledAppList({required this.filter, required this.matches});

  final AppFilter filter;
  final bool Function(String label, String package) matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(installedAppsProvider);
    final c = context.palette;
    return switch (apps) {
      AsyncData(value: final all) => () {
        final visible = [
          for (final app in all)
            if (matches(app.label, app.packageName)) app,
        ];
        if (visible.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyState(icon: AppIcons.searchOff, title: context.l10n.appsNoMatch),
          );
        }
        return SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: AppSpacing.card),
          itemBuilder: (context, i) {
            final app = visible[i];
            final selected = filter.packages.contains(app.packageName);
            return MergeSemantics(
              child: InfoRow(
                leading: AppIconView(appName: app.label, png: app.icon, size: 32),
                title: app.label,
                subtitle: app.packageName,
                onTap: () => _toggle(context, ref, app.packageName),
                trailing: Checkbox(value: selected, onChanged: (_) => _toggle(context, ref, app.packageName)),
              ),
            );
          },
        );
      }(),
      AsyncError(:final error) => SliverToBoxAdapter(
        child: EmptyState(
          icon: AppIcons.errorOutline,
          tone: Tone.error,
          title: context.l10n.appsListFailed,
          description: context.describeError(error),
          action: OutlinedButton(
            onPressed: () => ref.invalidate(installedAppsProvider),
            child: Text(context.l10n.actionTryAgain),
          ),
        ),
      ),
      _ => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            children: [
              const SkeletonList(rows: 6),
              Text(context.l10n.appsReading, style: AppType.supporting.copyWith(color: c.muted)),
            ],
          ),
        ),
      ),
    };
  }

  void _toggle(BuildContext context, WidgetRef ref, String package) {
    ref.tick();
    unawaited(runGuarded(context, () => ref.read(appFilterProvider.notifier).toggle(package)));
  }
}
