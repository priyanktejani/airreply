import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/app_insets.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/glass_app_bar.dart';
import 'package:air_reply/core/widgets/responsive_center.dart';
import 'package:air_reply/core/widgets/search_field.dart';
import 'package:air_reply/core/widgets/section_header.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/group_widgets.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One app's notifications as a list of its conversations — one card per person, phone number or group, latest
/// activity first — with the app's other notifications (no known sender) below. Tap a conversation to read every
/// message in it. Cards update and re-sort as notifications arrive.
class AppConversationsScreen extends ConsumerStatefulWidget {
  const AppConversationsScreen({required this.source, required this.packageName, super.key});

  final String source;
  final String packageName;

  @override
  ConsumerState<AppConversationsScreen> createState() => _AppConversationsScreenState();
}

class _AppConversationsScreenState extends ConsumerState<AppConversationsScreen> {
  /// Search is offered once the list is long enough to need it.
  static const _searchFrom = 6;

  var _query = '';

  void _close() => context.canPop() ? context.pop() : context.go(AppRoutes.notifications);

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(appGroupProvider((source: widget.source, packageName: widget.packageName)));
    final loading = ref.watch(allFeedProvider).isLoading;

    if (group == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(leading: BackButton(onPressed: _close)),
        body: loading
            ? Padding(padding: AppInsets.page(context), child: const SkeletonList(rows: 3))
            : EmptyState(
                icon: Icons.forum_outlined,
                title: 'Nothing here now',
                description:
                    'These notifications were hidden, removed, or came from a device that is no longer paired.',
                action: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.notifications),
                  child: const Text('Back to notifications'),
                ),
              ),
      );
    }

    final c = context.palette;
    final matches = group.threads.where((t) => threadMatches(t, _query)).toList();
    final conversations = matches.where((t) => t.kind != ThreadKind.single).toList();
    final others = matches.where((t) => t.kind == ThreadKind.single).toList();
    final conversationCount = group.threads.where((t) => t.kind != ThreadKind.single).length;
    final subtitle = [
      if (conversationCount > 0) conversationCount == 1 ? '1 conversation' : '$conversationCount conversations',
      group.count == 1 ? '1 notification' : '${group.count} notifications',
      if (group.source != AppGroup.allDevices) group.deviceName,
    ].join(' · ');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: BackButton(onPressed: _close),
        titleSpacing: 0,
        title: Row(
          children: [
            MirroredAppIcon(packageName: group.packageName, appName: group.appName, size: 38),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.title.copyWith(color: c.ink),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.supporting.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GroupActionsMenu(
            entries: group.entries,
            packageName: group.packageName,
            appName: group.appName,
            onLeave: _close,
          ),
        ],
      ),
      // a Builder for a context under the Scaffold, which hands down the app bar's height as padding
      body: Builder(
        builder: (context) {
          var n = 0;
          Widget rise(Widget child) => FadeSlideIn.staggered(index: n++, child: child);
          return CustomScrollView(
            slivers: [
              ResponsiveSliverCenter(
                padding: AppInsets.page(context, top: AppSpacing.sm),
                sliver: SliverList.list(
                  children: [
                    if (group.threads.length >= _searchFrom)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: SearchField(
                          hint: 'Search names, numbers and messages',
                          value: _query,
                          onChanged: (q) => setState(() => _query = q),
                        ),
                      ),
                    if (conversations.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.base),
                      rise(
                        SectionHeader(
                          eyebrow: others.isEmpty ? 'Conversations' : 'Conversations · ${conversations.length}',
                          title: 'People and groups',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final thread in conversations) rise(_Card(thread)),
                    ],
                    if (others.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.section),
                      rise(
                        SectionHeader(
                          eyebrow: conversations.isEmpty ? 'Notifications' : 'Other notifications · ${others.length}',
                          title: 'From ${group.appName}',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final thread in others) rise(_Card(thread)),
                    ],
                    if (matches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: Text(
                          'Nothing matches “$_query”.',
                          textAlign: TextAlign.center,
                          style: AppType.body.copyWith(color: c.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A conversation's card, spaced like the cards on the notifications screen.
class _Card extends StatelessWidget {
  const _Card(this.thread);

  final ConversationThread thread;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey(thread.key),
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: ThreadTile(thread: thread),
  );
}
