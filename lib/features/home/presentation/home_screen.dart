import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/app_insets.dart';
import 'package:air_reply/core/widgets/app_logo.dart';
import 'package:air_reply/core/widgets/glass_app_bar.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/pinned_search_bar.dart';
import 'package:air_reply/core/widgets/responsive_center.dart';
import 'package:air_reply/core/widgets/search_field.dart';
import 'package:air_reply/core/widgets/section_header.dart';
import 'package:air_reply/core/widgets/underlined_headline.dart';
import 'package:air_reply/core/widgets/window_class_layout.dart';
import 'package:air_reply/features/home/presentation/widgets/glance_stats.dart';
import 'package:air_reply/features/home/presentation/widgets/home_search_results.dart';
import 'package:air_reply/features/home/presentation/widgets/how_it_works.dart';
import 'package:air_reply/features/home/presentation/widgets/sharing_shortcuts.dart';
import 'package:air_reply/features/home/presentation/widgets/status_card.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/permissions/presentation/permission_notices.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home, the first screen: the headline and what AirReply does, then a search box that stays pinned (as frosted
/// glass) under the glass app bar while the page scrolls beneath both. Below it: the live status, the day at a
/// glance, what needs attention, the latest notifications, and how it works. Typing in the search
/// box shows the matching notifications instead. The page ends clear of the floating navigation bar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refresh() async {
    for (final pair in ref.read(pairedDevicesProvider)) {
      refreshPair(ref, pair.pairId);
    }
    if (ref.read(deviceRoleProvider) == DeviceRole.sender) {
      ref
        ..invalidate(syncStatusProvider)
        ..invalidate(senderPermissionsProvider);
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  void _openInbox(FeedFilter filter) {
    ref.read(inboxFilterProvider.notifier).set(filter);
    context.go(AppRoutes.notifications);
  }

  @override
  Widget build(BuildContext context) {
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    return Scaffold(
      // phones and tablets: one column; a desktop: the sections side by side, on a wider page
      body: WindowClassLayout(
        mobile: (context) => _page(context, isSender: isSender, maxWidth: AppDimensions.maxContentWidth, columns: 1),
        desktop: (context) =>
            _page(context, isSender: isSender, maxWidth: AppDimensions.maxWideContentWidth, columns: 2),
      ),
    );
  }

  Widget _page(BuildContext context, {required bool isSender, required double maxWidth, required int columns}) {
    final c = context.palette;
    final query = ref.watch(homeSearchQueryProvider);
    final searching = query.trim().isNotEmpty;
    const margin = EdgeInsets.symmetric(horizontal: AppSpacing.page);
    return RefreshIndicator(
      onRefresh: _refresh,
      edgeOffset: MediaQuery.paddingOf(context).top + GlassScrollPage.toolbarHeight,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // the glass app bar, pinned, with the search box pinned just under it; the page scrolls under both
          SliverAppBar(
            pinned: true,
            toolbarHeight: GlassScrollPage.toolbarHeight,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: const GlassBarBackground(),
            centerTitle: true,
            title: const AppLogo(),
            actions: const [
              _BellButton(),
              SizedBox(width: AppSpacing.sm),
            ],
          ),
          ResponsiveSliverCenter(
            maxContentWidth: maxWidth,
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.lg, AppSpacing.page, AppSpacing.sm),
            sliver: SliverList.list(
              children: [
                UnderlinedHeadline(
                  first: context.l10n.welcomeHeadlineFirst,
                  second: isSender ? context.l10n.homeHeadlineSender : context.l10n.welcomeHeadlineSecond,
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  isSender ? context.l10n.homeIntroSender : context.l10n.homeIntroReceiver,
                  style: AppType.bodyLarge.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          PinnedSearchBar(
            maxWidth: maxWidth,
            field: SearchField(
              hint: context.l10n.searchNotificationsHint,
              value: query,
              onChanged: ref.read(homeSearchQueryProvider.notifier).set,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: AppSpacing.base, bottom: AppInsets.bottom(context)),
            sliver: SliverToBoxAdapter(
              child: ResponsiveCenter(
                maxContentWidth: maxWidth,
                padding: margin,
                child: AnimatedSwitcher(
                  duration: context.motion(const Duration(milliseconds: 280)),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (current, previous) =>
                      Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                  child: searching
                      ? HomeSearchResults(key: const ValueKey('results'), query: query)
                      : _HomeSections(
                          key: const ValueKey('sections'),
                          columns: columns,
                          isSender: isSender,
                          onOpenInbox: _openInbox,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Home below the search box: each section rises in after the one before. [AppSpacing.section] between sections,
/// [AppSpacing.md] between a heading and its content. In two [columns] (a desktop), what is happening (status, counts,
/// the latest notifications) takes the wider left column and the guides sit on the right.
class _HomeSections extends ConsumerWidget {
  const _HomeSections({required this.columns, required this.isSender, required this.onOpenInbox, super.key});

  final int columns;
  final bool isSender;
  final ValueChanged<FeedFilter> onOpenInbox;

  static const _gap = SizedBox(height: AppSpacing.section);
  static const _headGap = SizedBox(height: AppSpacing.md);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentEntriesProvider);
    final devices = ref.watch(pairedDevicesProvider);
    final c = context.palette;
    const header = EdgeInsets.zero;

    final activity = <Widget>[
      isSender ? const SharingStatusCard() : const ReceivingStatusCard(),
      _gap,
      SectionHeader(eyebrow: context.l10n.homeTodayEyebrow, title: context.l10n.homeGlanceTitle, padding: header),
      _headGap,
      GlanceStats(
        onToday: () => onOpenInbox(const FeedFilter(period: FeedPeriod.today)),
        onUnread: () => onOpenInbox(const FeedFilter(unreadOnly: true)),
        onDevices: () => context.go(AppRoutes.devices),
      ),
      _gap,
      const AttentionNotices(bottom: AppSpacing.section),
      SectionHeader(
        eyebrow: context.l10n.homeRecentEyebrow,
        title: context.l10n.homeLatestTitle,
        actionLabel: context.l10n.actionSeeAll,
        onActionPressed: () => onOpenInbox(FeedFilter.none),
        padding: header,
      ),
      _headGap,
      switch (recent) {
        AsyncData(value: final entries) when entries.isEmpty => Text(
          isSender ? context.l10n.homeRecentEmptySender : context.l10n.homeRecentEmptyReceiver,
          style: AppType.body.copyWith(color: c.muted),
        ),
        AsyncData(value: final entries) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, e) in entries.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              FadeSlideIn.staggered(
                index: i,
                child: NotificationRow(entry: e, compact: true, showDevice: devices.length > 1),
              ),
            ],
          ],
        ),
        AsyncError() => Text(context.l10n.homeRecentFailed, style: AppType.body.copyWith(color: c.muted)),
        _ => const SkeletonList(rows: 3, itemHeight: 76),
      },
    ];
    final guides = <Widget>[
      if (isSender) ...[
        SectionHeader(
          eyebrow: context.l10n.homeSharingEyebrow,
          title: context.l10n.homeThisPhoneTitle,
          padding: header,
        ),
        _headGap,
        const SharingShortcuts(),
        _gap,
      ],
      SectionHeader(
        eyebrow: context.l10n.howItWorksEyebrow,
        title: isSender ? context.l10n.howItWorksSenderTitle : context.l10n.howItWorksReceiverTitle,
        padding: header,
      ),
      _headGap,
      HowItWorks(items: isSender ? HowItWorks.senderSteps(context.l10n) : HowItWorks.steps(context.l10n)),
    ];

    var n = 0;
    Widget column(List<Widget> sections) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final s in sections) s is SizedBox ? s : FadeSlideIn.staggered(index: n++, child: s)],
    );
    if (columns == 1) return column([...activity, _gap, ...guides]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: column(activity)),
        const SizedBox(width: AppSpacing.xl),
        Expanded(flex: 2, child: column(guides)),
      ],
    );
  }
}

/// The bell in Home's app bar: unread notifications as an accent count; opens Notifications.
class _BellButton extends ConsumerWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return IconButton(
      tooltip: context.l10n.bellUnread(unread),
      onPressed: () => context.go(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(AppIcons.notificationsNone),
      ),
    );
  }
}
