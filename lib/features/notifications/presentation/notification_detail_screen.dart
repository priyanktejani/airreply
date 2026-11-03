import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/animations/skeleton.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/app_insets.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/glass_app_bar.dart';
import 'package:air_reply/core/widgets/responsive_center.dart';
import 'package:air_reply/core/widgets/status_pill.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/notifications/presentation/widgets/reply_composer.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One notification in full: its text, the earlier notifications of the same conversation, the replies sent to it
/// and, on receivers, a reply bar.
class NotificationDetailScreen extends ConsumerStatefulWidget {
  const NotificationDetailScreen({required this.pairId, required this.notificationId, super.key});

  final String pairId;
  final String notificationId;

  @override
  ConsumerState<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends ConsumerState<NotificationDetailScreen> {
  var _markedRead = false;
  var _toChat = false;

  ({String pairId, String id}) get _target => (pairId: widget.pairId, id: widget.notificationId);

  void _close() => context.canPop() ? context.pop() : context.go(AppRoutes.notifications);

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(feedEntryProvider(_target));
    final loading = ref.watch(allFeedProvider).isLoading && entry == null;

    // Opening a notification reads it (also when it arrives after the screen, e.g. from an alert tap).
    if (entry != null && !_markedRead) {
      _markedRead = true;
      // After this frame: providers cannot change while widgets build.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(ref.read(inboxStateProvider.notifier).markRead([entry.key])),
      );
    }

    // A message from a person or a group chat lives in its chat (opened from an alert, a link...): go there instead.
    final chat = ref.watch(chatOfProvider(_target));
    if (chat != null && !_toChat) {
      _toChat = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.replace(AppRoutes.thread(chat.source, chat.packageName, chat.key, at: widget.notificationId));
        }
      });
    }

    if (entry == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(leading: BackButton(onPressed: _close)),
        body: loading
            ? Padding(padding: AppInsets.page(context), child: const SkeletonList(rows: 2))
            : EmptyState(
                icon: AppIcons.notificationsOff,
                title: 'Not available',
                description: 'This notification was removed, hidden, or belongs to a device that is no longer paired.',
                action: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.notifications),
                  child: const Text('Back to notifications'),
                ),
              ),
      );
    }

    final isRead = ref.watch(readCheckProvider)(entry);
    final isReceiver = ref.watch(deviceRoleProvider) == DeviceRole.receiver;
    final notification = entry.notification;

    final composer = isReceiver && notification.acceptsReplies;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: BackButton(onPressed: _close),
        title: Text(
          ref.watch(conversationNameProvider((pairId: entry.pairId, id: notification.id))) ??
              notification.content.appName,
        ),
        actions: [
          IconButton(
            tooltip: 'Mark as unread',
            onPressed: isRead
                ? () async {
                    await ref.toggleRead(context, entry, isRead: true);
                    if (mounted) _close();
                  }
                : null,
            icon: const Icon(AppIcons.markEmailUnread),
          ),
          IconButton(
            tooltip: 'Copy text',
            onPressed: () => ref.copyText(context, entry),
            icon: const Icon(AppIcons.contentCopy),
          ),
          IconButton(
            tooltip: 'Hide from this device',
            onPressed: () {
              unawaited(ref.hide(context, [entry]));
              _close();
            },
            icon: const Icon(AppIcons.visibilityOff),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      // the notification scrolls under the frosted bar and under the floating message box
      body: Stack(
        children: [
          Positioned.fill(
            child: Builder(
              builder: (context) => CustomScrollView(
                slivers: [
                  ResponsiveSliverCenter(
                    padding: AppInsets.page(context, top: AppSpacing.sm, bottom: composer ? 112 : AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: _Body(entry: entry, isReceiver: isReceiver),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (composer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ReplyComposer(
                pairId: entry.pairId,
                notification: notification,
                recipient: ref.watch(conversationNameProvider((pairId: entry.pairId, id: notification.id))),
              ),
            ),
        ],
      ),
    );
  }
}

/// The conversation the notification belongs to, as cards, newest first: each incoming notification and each reply
/// you sent has its own card, all alike: who, what, when and where. Your replies carry one thing more, "Your reply"
/// and whether it went out. The messaging app's copy of a reply is not a card of its own: it marks the reply delivered.
class _Body extends ConsumerWidget {
  const _Body({required this.entry, required this.isReceiver});

  final FeedEntry entry;
  final bool isReceiver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = [
      ...ref.watch(conversationProvider((pairId: entry.pairId, key: entry.notification.content.key))),
    ];
    // the opened notification, should it not be in its conversation (yet)
    if (!conversation.any((e) => e.notification.id == entry.notification.id)) conversation.add(entry);
    final sent = [
      for (final e in conversation)
        for (final r in e.replies) (reply: r, to: e),
    ];
    final echoes = replyEchoes(conversation, [for (final s in sent) s.reply]);
    final echoKeys = {for (final e in echoes.values) e.key};

    final cards = <(DateTime, Widget)>[
      for (final e in conversation)
        if (!echoKeys.contains(e.key))
          (
            e.postedAt,
            _MessageCard.notification(e, own: ownMessage(e, [for (final s in sent) s.reply]), isReceiver: isReceiver),
          ),
      for (final s in sent) (s.reply.createdAt, _MessageCard.reply(s.reply, to: s.to, echo: echoes[s.reply.id])),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (_, card)) in cards.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          FadeSlideIn.staggered(index: i, child: card),
        ],
      ],
    );
  }
}

/// One message on a card: the app's icon, who wrote it, the app and device, the time and day, the message, and its
/// state. Notifications and your replies look the same; a reply is labelled "Your reply".
class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.packageName,
    required this.appName,
    required this.who,
    required this.where,
    required this.at,
    required this.text,
    required this.pills,
    this.group,
  });

  /// An incoming notification (or a message you wrote on the phone, [own]).
  factory _MessageCard.notification(FeedEntry entry, {required OwnMessage? own, required bool isReceiver}) {
    final notification = entry.notification;
    final content = notification.content;
    final group = content.isGroupConversation ? content.conversationTitle?.trim() : null;
    final sender = content.sender?.trim();
    final text = messageText(content);
    return _MessageCard(
      packageName: content.packageName,
      appName: content.appName,
      // in a group chat, the person who wrote it; the group is named under it
      who: own != null
          ? 'You'
          : group != null && sender != null && sender.isNotEmpty
          ? sender
          : content.title.isEmpty
          ? content.appName
          : content.title,
      group: group,
      where: '${content.appName} · ${entry.deviceName}',
      at: entry.postedAt,
      text: text.isEmpty ? content.title : text,
      pills: [
        if (own != null)
          const StatusPill('Sent from your phone', tone: PillTone.good)
        else if (notification.dismissedOnSender)
          const StatusPill('Cleared on phone', tone: PillTone.warn)
        else if (notification.canReply)
          StatusPill(isReceiver ? 'Can reply' : 'Can be answered', tone: PillTone.good)
        else
          const StatusPill('No replies in this app'),
      ],
    );
  }

  /// A reply you sent from AirReply, to [to]; [echo] is the app's copy of it on the phone, once it went out.
  factory _MessageCard.reply(ReplyCommand reply, {required FeedEntry to, FeedEntry? echo}) {
    final content = to.notification.content;
    final (state, tone) = switch (reply.status) {
      ReplyStatus.pending => ('Sending', PillTone.neutral),
      ReplyStatus.sent when echo != null => ('Delivered', PillTone.good),
      ReplyStatus.sent => ('Sent', PillTone.good),
      ReplyStatus.expired => ('Expired on phone', PillTone.warn),
      ReplyStatus.failed => ('Not delivered', PillTone.bad),
    };
    return _MessageCard(
      packageName: content.packageName,
      appName: content.appName,
      who: 'You',
      group: content.isGroupConversation ? content.conversationTitle?.trim() : null,
      where: '${content.appName} · ${to.deviceName}',
      at: reply.createdAt,
      text: reply.text,
      pills: [
        const StatusPill('Your reply', tone: PillTone.good),
        StatusPill(state, tone: tone),
      ],
    );
  }

  final String packageName;
  final String appName;
  final String who;
  final String? group;
  final String where;
  final DateTime at;
  final String text;
  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MirroredAppIcon(packageName: packageName, appName: appName, size: AppDimensions.iconTileSm),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      who,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.title.copyWith(color: c.ink),
                    ),
                    Text(
                      group != null && group!.isNotEmpty && group != who ? '$group · $where' : where,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.supporting.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatClock(at), style: AppType.titleSmall.copyWith(color: c.ink)),
                  Text(formatDayLabel(at), style: AppType.supporting.copyWith(color: c.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SelectableText(text, style: AppType.bodyLarge.copyWith(color: c.ink)),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: pills),
        ],
      ),
    );
  }
}
