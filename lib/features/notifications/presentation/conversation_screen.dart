import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/app_insets.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/glass_app_bar.dart';
import 'package:air_reply/core/widgets/responsive_center.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/core/widgets/status_pill.dart';
import 'package:air_reply/core/widgets/sticky_action_bar.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/group_widgets.dart';
import 'package:air_reply/features/notifications/presentation/widgets/message_arrival.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/notifications/presentation/widgets/reply_composer.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Every notification of one conversation (a person, a phone number or a group), oldest to newest like a chat,
/// opening at the newest. New notifications merge in as they arrive. A conversation that can still be answered gets a
/// reply bar.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    required this.source,
    required this.packageName,
    required this.threadKey,
    this.at,
    super.key,
  });

  final String source;
  final String packageName;
  final String threadKey;

  /// The notification that was opened: the chat scrolls to it and points it out.
  final String? at;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  /// Room under the newest message for the floating message box (one line of text) and a gap.
  static const _bottomRoom = 96.0;

  /// What was on screen when it opened, so only messages arriving later slide in.
  Set<String>? _shownAtOpen;

  /// What was unread when the screen opened, so the "New" divider stays put after everything is marked read.
  Set<String>? _unreadAtOpen;

  /// Set once the screen is closing: "Mark as unread" must not be undone by the screen reading everything again.
  var _leaving = false;

  void _close() {
    _leaving = true;
    context.canPop() ? context.pop() : context.go(AppRoutes.notifications);
  }

  /// Everything on screen counts as read, including notifications that arrive while it is open.
  void _markRead(List<FeedEntry> entries) {
    final isRead = ref.read(readCheckProvider);
    final unread = [
      for (final e in entries)
        if (!isRead(e)) e.key,
    ];
    _unreadAtOpen ??= {...unread};
    if (unread.isEmpty || _leaving) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_leaving) unawaited(ref.read(inboxStateProvider.notifier).markRead(unread));
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(
      threadProvider((source: widget.source, packageName: widget.packageName, key: widget.threadKey)),
    );
    final loading = ref.watch(allFeedProvider).isLoading;
    final isReceiver = ref.watch(deviceRoleProvider) == DeviceRole.receiver;

    if (view == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(leading: BackButton(onPressed: _close)),
        body: loading
            ? Padding(padding: AppInsets.page(context), child: const SkeletonList(rows: 3))
            : EmptyState(
                icon: AppIcons.forum,
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

    _markRead(view.entries);
    final c = context.palette;
    final replyTarget = view.replyTarget;
    final isConversation = view.kind != ThreadKind.single;
    final subtitle = [view.appName, view.count == 1 ? '1 message' : '${view.count} messages'].join(' · ');

    final Widget? bottom = isReceiver && replyTarget != null
        ? ReplyComposer(
            key: ValueKey(replyTarget.key),
            pairId: replyTarget.pairId,
            notification: replyTarget.notification,
            recipient: view.kind == ThreadKind.single ? null : view.title,
          )
        : isReceiver && isConversation
        ? _Footnote(
            view.entries.first.notification.dismissedOnSender
                ? 'These notifications were cleared on your phone, so they can no longer be answered from here.'
                : '${view.appName} does not accept replies for this conversation.',
          )
        : null;

    // the conversation scrolls under the frosted app bar and under the floating message box
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: BackButton(onPressed: _close),
        titleSpacing: 0,
        title: Row(
          children: [
            ConversationAvatar(title: view.title, kind: view.kind, size: 38),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.title,
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
            entries: view.entries,
            packageName: widget.packageName,
            appName: view.appName,
            onLeave: _close,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _Timeline(
              entries: view.entries,
              kind: view.kind,
              unreadAtOpen: _unreadAtOpen ?? const {},
              shownAtOpen: _shownAtOpen ??= {
                for (final e in view.entries) ...[e.key, for (final r in e.replies) r.id],
              },
              room: bottom == null ? AppSpacing.xl : _bottomRoom,
              highlight: widget.at,
            ),
          ),
          if (bottom != null) Positioned(left: 0, right: 0, bottom: 0, child: bottom),
        ],
      ),
    );
  }
}

sealed class _Item {
  const _Item();
}

final class _DayItem extends _Item {
  const _DayItem(this.date);
  final DateTime date;
}

final class _NewItem extends _Item {
  const _NewItem();
}

final class _MessageItem extends _Item {
  const _MessageItem(this.entry, {required this.showSender, this.mine = false});
  final FeedEntry entry;
  final bool showSender;

  /// Written by the user on the phone: shown on their side.
  final bool mine;
}

final class _ReplyItem extends _Item {
  const _ReplyItem(this.reply, {this.echo});
  final ReplyCommand reply;

  /// The messaging app's copy of it, once the phone has sent it.
  final FeedEntry? echo;
}

/// The chat: day dividers, a "New" divider before what was unread, incoming notifications on the left and replies
/// sent from this device on the right. Built newest-first in a reversed list, so it opens at the bottom and stays
/// there as messages arrive.
class _Timeline extends StatefulWidget {
  const _Timeline({
    required this.entries,
    required this.kind,
    required this.unreadAtOpen,
    required this.shownAtOpen,
    required this.room,
    this.highlight,
  });

  /// The opened notification (or the copy of a reply): scrolled to and pointed out once.
  final String? highlight;

  /// Newest first.
  final List<FeedEntry> entries;

  final ThreadKind kind;

  /// Messages and replies already there when the screen opened: they appear at once; later ones slide in.
  final Set<String> shownAtOpen;

  /// Space under the newest message, for the floating message box.
  final double room;
  final Set<String> unreadAtOpen;

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline> {
  final _scroll = ScrollController();
  final _target = GlobalKey();
  var _found = false;

  List<FeedEntry> get entries => widget.entries;
  ThreadKind get kind => widget.kind;
  Set<String> get unreadAtOpen => widget.unreadAtOpen;
  Set<String> get shownAtOpen => widget.shownAtOpen;
  double get room => widget.room;

  @override
  void initState() {
    super.initState();
    if (widget.highlight != null) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(0));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Brings the opened message into the middle of the screen. Messages far up are not built yet: the list moves
  /// towards where it should be, and tries again.
  void _reveal(int attempt) {
    if (!mounted || _found || attempt > 8) return;
    final target = _target.currentContext;
    if (target != null) {
      _found = true;
      unawaited(
        Scrollable.ensureVisible(
          target,
          alignment: .5,
          duration: context.motion(AppMotion.slow),
          curve: AppMotion.curve,
        ),
      );
      return;
    }
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    _scroll.jumpTo((position.pixels + position.viewportDimension).clamp(0, position.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(attempt + 1));
  }

  /// Oldest first, as read.
  List<_Item> _items() {
    final replies = [for (final e in entries) ...e.replies];
    // the app's copy of a reply is not a second message: it shows on the reply, as the sign the phone sent it
    final echoes = replyEchoes(entries, replies);
    final echoKeys = {for (final e in echoes.values) e.key};
    final events = <(DateTime, Object)>[
      for (final e in entries)
        if (!echoKeys.contains(e.key)) (e.postedAt, e),
      for (final r in replies) (r.createdAt, r),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final items = <_Item>[];
    DateTime? day;
    String? lastSender;
    var newShown = false;
    for (final (at, event) in events) {
      final date = DateTime(at.year, at.month, at.day);
      if (date != day) {
        items.add(_DayItem(date));
        day = date;
        lastSender = null;
      }
      switch (event) {
        case final FeedEntry entry:
          if (!newShown && unreadAtOpen.contains(entry.key)) {
            items.add(const _NewItem());
            newShown = true;
            lastSender = null;
          }
          if (ownMessage(entry, replies) != null) {
            items.add(_MessageItem(entry, showSender: false, mine: true));
            lastSender = null;
            break;
          }
          final sender = _senderOf(entry);
          items.add(_MessageItem(entry, showSender: sender != null && sender != lastSender));
          lastSender = sender;
        case final ReplyCommand reply:
          items.add(_ReplyItem(reply, echo: echoes[reply.id]));
          lastSender = null;
      }
    }
    return items;
  }

  /// Who to name above a message: its sender, in a group. A one-to-one chat already names the person at the top.
  String? _senderOf(FeedEntry entry) => kind == ThreadKind.group ? messageSender(entry, kind) : null;

  @override
  Widget build(BuildContext context) {
    final items = _items().reversed.toList();
    final highlight = widget.highlight;
    bool isTarget(_Item item) =>
        highlight != null &&
        switch (item) {
          _MessageItem(:final entry) => entry.notification.id == highlight,
          _ReplyItem(:final echo) => echo?.notification.id == highlight,
          _ => false,
        };
    // newest at the bottom: the list runs upwards from the message box
    return CustomScrollView(
      controller: _scroll,
      reverse: true,
      slivers: [
        ResponsiveSliverCenter(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            MediaQuery.paddingOf(context).top + AppSpacing.base,
            AppSpacing.page,
            MediaQuery.paddingOf(context).bottom + room,
          ),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) =>
                isTarget(items[i]) ? _Pointed(key: _target, child: _row(items[i])) : _row(items[i]),
          ),
        ),
      ],
    );
  }

  Widget _row(_Item item) => switch (item) {
    _DayItem(:final date) => _Divider(formatDayLabel(date)),
    _NewItem() => const _Divider('New', emphasis: true),
    _MessageItem(:final entry, :final showSender, :final mine) => MessageArrival(
      fromRight: mine,
      animate: !shownAtOpen.contains(entry.key),
      child: _MessageBubble(
        entry: entry,
        sender: showSender ? _senderOf(entry) : null,
        showTitle: kind == ThreadKind.single,
        mine: mine,
      ),
    ),
    _ReplyItem(:final reply, :final echo) => MessageArrival(
      fromRight: true,
      animate: !shownAtOpen.contains(reply.id),
      child: ReplyBubble(reply: reply, echo: echo),
    ),
  };
}

/// The opened message, pointed out: a soft accent glow behind it that fades away.
class _Pointed extends StatelessWidget {
  const _Pointed({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: context.motion(const Duration(milliseconds: 2600)),
      curve: const Interval(.4, 1, curve: Curves.easeOut),
      builder: (context, t, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: .16 * t),
          borderRadius: AppRadius.lgBorder,
        ),
        child: child,
      ),
      child: child,
    );
  }
}

/// A day, or where the unread messages begin, as a small pill in the middle of the conversation.
class _Divider extends StatelessWidget {
  const _Divider(this.label, {this.emphasis = false});

  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
    child: Center(child: StatusPill(label, tone: emphasis ? PillTone.good : PillTone.neutral)),
  );
}

/// One incoming notification: who sent it (when it changes), the text, the time, and whether it is still on the
/// phone. Tap for the full notification and its actions.
class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.entry, required this.sender, required this.showTitle, this.mine = false});

  final FeedEntry entry;
  final String? sender;

  /// The user's own message, written on the phone: on the right, soft accent, marked as sent from the phone.
  final bool mine;

  /// A notification that is not a chat message keeps its own title (an email subject, an app's headline).
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final content = entry.notification.content;
    final title = content.title.trim();
    final text = messageText(content);
    const round = Radius.circular(AppRadius.lg);
    const tail = Radius.circular(AppSpacing.xs);
    final radius = BorderRadius.only(
      topLeft: round,
      topRight: round,
      bottomLeft: mine ? round : tail,
      bottomRight: mine ? tail : round,
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      // a share of the conversation's width (beside the rail on wide windows), not of the whole window
      child: LayoutBuilder(
        builder: (context, box) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: box.maxWidth * .78),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (sender != null && sender!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
                  child: Text(
                    sender!,
                    style: AppType.supporting.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                  ),
                ),
              // theirs: the card surface with a hairline and the card theme's own shadow, a small corner towards the sender
              Material(
                color: mine ? c.accentSoft : c.surface,
                elevation: mine ? 0 : Theme.of(context).cardTheme.elevation ?? 0,
                shadowColor: Theme.of(context).cardTheme.shadowColor,
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(color: mine ? c.accent.withValues(alpha: .35) : c.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onLongPress: () => ref.showEntryActions(context, entry),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showTitle && !mine && title.isNotEmpty && title != sender)
                          Text(title, style: AppType.subtitle.copyWith(color: c.ink)),
                        if (text.isNotEmpty) Text(text, style: AppType.body.copyWith(color: c.ink)),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, 0),
                // wraps onto a second line rather than running past the bubble's side of the screen
                child: Wrap(
                  alignment: mine ? WrapAlignment.end : WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    Text(formatClock(entry.postedAt), style: AppType.label.copyWith(color: c.muted)),
                    if (mine)
                      const StatusBadge(label: 'Sent from your phone', icon: AppIcons.smartphone)
                    // only messages to you can be answered, so only theirs say they can no longer be
                    else if (entry.notification.dismissedOnSender)
                      const StatusBadge(label: 'Cleared on phone', icon: AppIcons.phonelinkErase),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// Why this conversation cannot be answered from here, on a floating glass panel where the message box would be.
class _Footnote extends StatelessWidget {
  const _Footnote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return StickyActionBar(
      pill: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(AppIcons.infoOutline, size: 18, color: c.muted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(text, style: AppType.supporting.copyWith(color: c.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
