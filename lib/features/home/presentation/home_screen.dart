import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/features/devices/devices_providers.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/devices/presentation/device_status_badge.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/permissions/presentation/permission_notices.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The day at a glance: whether notifications are flowing, how many came in, what needs attention, and the latest
/// few.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String greeting(DateTime now) => switch (now.hour) {
    < 5 => 'Good night',
    < 12 => 'Good morning',
    < 17 => 'Good afternoon',
    _ => 'Good evening',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    final recent = ref.watch(recentEntriesProvider);
    final devices = ref.watch(pairedDevicesProvider);

    void openInbox(FeedFilter filter) {
      ref.read(inboxFilterProvider.notifier).set(filter);
      context.go(AppRoutes.notifications);
    }

    return Scaffold(
      body: EditorialPage(
        onRefresh: () async {
          for (final pair in devices) {
            refreshPair(ref, pair.pairId);
          }
          if (isSender) {
            ref
              ..invalidate(syncStatusProvider)
              ..invalidate(senderPermissionsProvider);
          }
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        header: PageHeader(eyebrow: formatLongDate(now), title: greeting(now)),
        slivers: [
          SliverToBoxAdapter(child: isSender ? const _SharingStatus() : const _ReceivingStatus()),
          SliverToBoxAdapter(
            child: _Stats(
              onToday: () => openInbox(const FeedFilter(period: FeedPeriod.today)),
              onUnread: () => openInbox(const FeedFilter(unreadOnly: true)),
              onDevices: () => context.go(AppRoutes.devices),
            ),
          ),
          const SliverToBoxAdapter(child: AttentionNotices()),
          SliverToBoxAdapter(
            child: SectionLabel(
              'Recent activity',
              top: 0,
              trailing: ArrowLink(label: 'View all', onTap: () => openInbox(FeedFilter.none)),
            ),
          ),
          SliverToBoxAdapter(
            child: switch (recent) {
              AsyncData(value: final entries) when entries.isEmpty => Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.x4),
                child: Text(
                  isSender
                      ? 'Nothing shared yet. New notifications on this phone will appear here.'
                      : 'Nothing yet. New notifications from your phone will appear here.',
                  style: AppType.body.copyWith(color: context.colors.secondary),
                ),
              ),
              AsyncData(value: final entries) => RuledList(
                children: [
                  for (final e in entries)
                    NotificationRow(entry: e, compact: true, swipeable: false, showDevice: devices.length > 1),
                ],
              ),
              AsyncError() => Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.x4),
                child: Text(
                  'Recent notifications could not be loaded.',
                  style: AppType.body.copyWith(color: context.colors.secondary),
                ),
              ),
              _ => const SkeletonList(rows: 3),
            },
          ),
          if (isSender) const SliverToBoxAdapter(child: _SenderShortcuts()),
        ],
      ),
    );
  }
}

/// Receivers: are notifications arriving, from which phones, and how fresh is the data.
class _ReceivingStatus extends ConsumerWidget {
  const _ReceivingStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final devices = ref.watch(pairedDevicesProvider);
    final status = ref.watch(overallStatusProvider);
    final lastSynced = ref.watch(lastSyncedProvider);
    final names = devices.length == 1 ? devices.single.peerName : '${devices.length} phones';
    final headline = switch (status?.state) {
      DeviceState.connected => 'Receiving from $names.',
      DeviceState.connecting => 'Connecting to $names…',
      _ => 'Showing saved notifications from $names.',
    };
    return _StatusBlock(
      badge: status == null ? null : DeviceStatusBadge(status: status),
      headline: headline,
      detail: switch (status?.state) {
        DeviceState.connected => 'Live. New notifications appear within seconds.',
        _ when lastSynced != null => 'Last synced ${formatAgo(lastSynced)}.',
        _ => status?.detail ?? '',
      },
      color: c,
    );
  }
}

/// Senders: the main switch, and whether sharing actually works.
class _SharingStatus extends ConsumerWidget {
  const _SharingStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final sharing = ref.watch(syncStatusProvider).value ?? SyncStatus.off;
    final access = ref.watch(senderPermissionsProvider.select((p) => p.value?.notificationAccess)) ?? true;
    final devices = ref.watch(pairedDevicesProvider);
    final status = ref.watch(overallStatusProvider);
    final names = devices.length == 1 ? devices.single.peerName : '${devices.length} devices';

    final headline = switch (status?.state) {
      _ when !access => 'Sharing needs notification access.',
      _ when !sharing.enabled => 'Sharing is paused.',
      DeviceState.connected => 'Sharing with $names.',
      DeviceState.connecting => 'Connecting to $names…',
      _ => status?.detail ?? 'Sharing is not working right now.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusBlock(
          badge: status == null ? null : DeviceStatusBadge(status: status),
          headline: headline,
          detail: sharing.enabled && access
              ? 'Notifications are end-to-end encrypted on this phone before they leave it.'
              : 'Nothing from this phone reaches your devices until sharing is on.',
          color: c,
        ),
        // The stats below draw the closing rule.
        RuledList(
          top: false,
          bottom: false,
          children: [
            SwitchRow(
              icon: Icons.podcasts_outlined,
              title: 'Share notifications',
              subtitle: sharing.label,
              value: sharing.enabled,
              onChanged: access
                  ? (on) {
                      ref.tick();
                      runGuarded(context, () => ref.read(syncStatusProvider.notifier).setEnabled(on));
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.headline, required this.detail, required this.color, this.badge});

  final Widget? badge;
  final String headline;
  final String detail;
  final AppColors color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.x5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?badge,
        const SizedBox(height: Space.x2),
        AnimatedSwitcher(
          duration: Motion.medium,
          layoutBuilder: (current, previous) =>
              Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
          child: Text(
            headline,
            key: ValueKey(headline),
            style: AppType.section.copyWith(fontSize: 24, height: 30 / 24, color: color.ink),
          ),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: Space.x1),
          Text(detail, style: AppType.supporting.copyWith(color: color.secondary)),
        ],
      ],
    ),
  );
}

class _Stats extends ConsumerWidget {
  const _Stats({required this.onToday, required this.onUnread, required this.onDevices});

  final VoidCallback onToday;
  final VoidCallback onUnread;
  final VoidCallback onDevices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayCountProvider);
    final unread = ref.watch(unreadCountProvider);
    final devices = ref.watch(pairedDevicesProvider).length;
    final c = context.colors;
    Widget rule() => Container(
      width: 1,
      height: 48,
      color: c.border,
      margin: const EdgeInsets.only(right: Space.x4),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: c.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x2),
          child: Row(
            children: [
              Expanded(
                child: Stat(value: '$today', label: 'Today', onTap: onToday),
              ),
              rule(),
              Expanded(
                child: Stat(value: '$unread', label: 'Unread', onTap: onUnread),
              ),
              rule(),
              Expanded(
                child: Stat(value: '$devices', label: devices == 1 ? 'Device' : 'Devices', onTap: onDevices),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SenderShortcuts extends ConsumerWidget {
  const _SenderShortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(appFilterProvider).value;
    final subtitle = switch (filter) {
      null => 'Loading…',
      AppFilter(mode: AppFilterMode.all) => 'Every app is shared',
      AppFilter(:final packages) when packages.isEmpty => 'No apps selected: nothing is shared',
      AppFilter(:final packages) => '${packages.length} selected ${packages.length == 1 ? 'app' : 'apps'}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Sharing'),
        RuledList(
          children: [
            InfoRow(
              icon: Icons.apps_outlined,
              title: 'Apps to share',
              subtitle: subtitle,
              trailing: InfoRow.chevron,
              onTap: () => context.push(AppRoutes.apps),
            ),
            InfoRow(
              icon: Icons.add_link,
              title: 'Add a device',
              subtitle: 'iPhone, iPad, Mac, Windows, Linux, browser or another Android',
              trailing: InfoRow.chevron,
              onTap: () => context.push(AppRoutes.pair),
            ),
          ],
        ),
      ],
    );
  }
}
