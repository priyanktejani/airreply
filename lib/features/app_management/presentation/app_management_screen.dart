import 'dart:async';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/app_icon.dart';
import 'package:air_reply/core/widgets/editorial.dart';
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
      appBar: AppBar(title: Text(isSender ? 'Apps to share' : 'Muted apps')),
      body: EditorialPage(slivers: isSender ? _senderSlivers() : _receiverSlivers()),
    );
  }

  Widget _search(String hint) => Padding(
    padding: const EdgeInsets.only(top: Space.x4, bottom: Space.x2),
    child: SearchField(hint: hint, value: _typed, onChanged: (q) => setState(() => _typed = q)),
  );

  List<Widget> _senderSlivers() {
    final filter = ref.watch(appFilterProvider);
    final controller = ref.read(appFilterProvider.notifier);
    final c = context.colors;

    return switch (filter) {
      AsyncData(value: final current) => [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose what reaches your devices. This applies even while AirReply is closed.',
                style: AppType.body.copyWith(color: c.secondary),
              ),
              const SizedBox(height: Space.x4),
              SegmentedButton<AppFilterMode>(
                segments: const [
                  ButtonSegment(value: AppFilterMode.all, label: Text('All apps')),
                  ButtonSegment(value: AppFilterMode.selected, label: Text('Only selected')),
                ],
                selected: {current.mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) {
                  ref.tick();
                  unawaited(runGuarded(context, () => controller.setMode(s.first)));
                },
              ),
              if (current.mode == AppFilterMode.selected) ...[
                _search('Search apps'),
                Text(
                  current.packages.isEmpty
                      ? 'Nothing selected: no notifications are shared'
                      : '${current.packages.length} selected',
                  style: AppType.supporting.copyWith(color: current.packages.isEmpty ? c.warning : c.secondary),
                ),
                const SizedBox(height: Space.x2),
              ],
            ],
          ),
        ),
        if (current.mode == AppFilterMode.selected)
          _InstalledAppList(filter: current, matches: _matches)
        else
          const SliverToBoxAdapter(
            child: StateMessage(
              icon: Icons.apps_outlined,
              title: 'Every app is shared',
              message: 'Choose "Only selected" to pick which apps reach your devices.',
            ),
          ),
      ],
      AsyncError(:final error) => [
        SliverToBoxAdapter(
          child: StateMessage(
            icon: Icons.error_outline,
            tone: Tone.error,
            title: 'Could not load your choice',
            message: describeError(error),
            action: OutlinedButton(onPressed: () => ref.invalidate(appFilterProvider), child: const Text('Try again')),
          ),
        ),
      ],
      _ => [const SliverToBoxAdapter(child: SkeletonList())],
    };
  }

  List<Widget> _receiverSlivers() {
    final apps = ref.watch(feedAppsProvider);
    final preferences = ref.watch(appPreferencesProvider).value;
    final c = context.colors;
    final visible = [
      for (final MapEntry(key: package, value: name) in apps.entries)
        if (_matches(name, package)) (package, name),
    ];
    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Muted apps still arrive in Notifications, but never alert you on this device.',
              style: AppType.body.copyWith(color: c.secondary),
            ),
            if (apps.isNotEmpty) _search('Search apps'),
          ],
        ),
      ),
      if (apps.isEmpty)
        const SliverToBoxAdapter(
          child: StateMessage(
            icon: Icons.apps_outlined,
            title: 'No apps yet',
            message: 'Apps appear here once your phone has sent a notification from them.',
          ),
        )
      else
        SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final (package, name) = visible[i];
            final muted = preferences?.mutedApps.contains(package) ?? false;
            return SwitchRow(
              leading: MirroredAppIcon(packageName: package, appName: name, size: 32),
              title: name,
              subtitle: muted ? 'Muted' : 'Alerts on',
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
    final c = context.colors;
    return switch (apps) {
      AsyncData(value: final all) => () {
        final visible = [
          for (final app in all)
            if (matches(app.label, app.packageName)) app,
        ];
        if (visible.isEmpty) {
          return const SliverToBoxAdapter(
            child: StateMessage(icon: Icons.search_off, title: 'No apps match'),
          );
        }
        return SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const Divider(),
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
        child: StateMessage(
          icon: Icons.error_outline,
          tone: Tone.error,
          title: 'Could not list apps',
          message: describeError(error),
          action: OutlinedButton(
            onPressed: () => ref.invalidate(installedAppsProvider),
            child: const Text('Try again'),
          ),
        ),
      ),
      _ => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: Space.x2),
          child: Column(
            children: [
              const SkeletonList(rows: 6),
              Text('Reading installed apps…', style: AppType.supporting.copyWith(color: c.secondary)),
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
