import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
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

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: _close)),
        body: loading
            ? const Padding(padding: EdgeInsets.all(Space.x6), child: SkeletonList(rows: 2))
            : StateMessage(
                icon: Icons.notifications_off_outlined,
                title: 'Not available',
                message: 'This notification was removed, hidden, or belongs to a device that is no longer paired.',
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

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _close),
        actions: [
          IconButton(
            tooltip: 'Mark as unread',
            onPressed: isRead
                ? () async {
                    await ref.toggleRead(context, entry, isRead: true);
                    if (mounted) _close();
                  }
                : null,
            icon: const Icon(Icons.mark_email_unread_outlined),
          ),
          IconButton(
            tooltip: 'Copy text',
            onPressed: () => ref.copyText(context, entry),
            icon: const Icon(Icons.content_copy_outlined),
          ),
          IconButton(
            tooltip: 'Hide from this device',
            onPressed: () {
              unawaited(ref.hide(context, [entry]));
              _close();
            },
            icon: const Icon(Icons.visibility_off_outlined),
          ),
          const SizedBox(width: Space.x2),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: EditorialPage(
              slivers: [
                SliverToBoxAdapter(
                  child: _Body(entry: entry, isReceiver: isReceiver),
                ),
              ],
            ),
          ),
          if (isReceiver && notification.acceptsReplies)
            ReplyComposer(pairId: entry.pairId, notification: notification),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.entry, required this.isReceiver});

  final FeedEntry entry;
  final bool isReceiver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final notification = entry.notification;
    final content = notification.content;
    final earlier = [
      for (final e in ref.watch(conversationProvider((pairId: entry.pairId, key: content.key))))
        if (e.notification.id != notification.id && e.postedAt.isBefore(entry.postedAt)) e,
    ];
    final title = content.title.isEmpty ? content.appName : content.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Space.x2),
        Row(
          children: [
            MirroredAppIcon(packageName: content.packageName, appName: content.appName, size: 48),
            const SizedBox(width: Space.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(content.appName, style: AppType.subtitle.copyWith(color: c.ink)),
                  Text(
                    '${isReceiver ? 'From' : 'Shared with'} ${entry.deviceName}',
                    style: AppType.supporting.copyWith(color: c.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x6),
        Text(formatTimestamp(entry.postedAt).toUpperCase(), style: AppType.label.copyWith(color: c.secondary)),
        const SizedBox(height: Space.x2),
        SelectableText(title, style: AppType.section.copyWith(color: c.ink)),
        if (content.conversationTitle case final conversation? when conversation != title) ...[
          const SizedBox(height: Space.x1),
          Text(conversation, style: AppType.supporting.copyWith(color: c.secondary)),
        ],
        if (content.text.isNotEmpty) ...[
          const SizedBox(height: Space.x4),
          SelectableText(
            content.text,
            style: AppType.body.copyWith(color: c.ink, fontSize: 16, height: 26 / 16),
          ),
        ],
        const SizedBox(height: Space.x5),
        Wrap(
          spacing: Space.x5,
          runSpacing: Space.x2,
          children: [
            if (notification.dismissedOnSender)
              const StatusBadge(label: 'Dismissed on phone', icon: Icons.phonelink_erase_outlined)
            else if (notification.canReply)
              StatusBadge(
                label: isReceiver ? 'You can reply from here' : 'Can be answered from your devices',
                icon: Icons.reply,
                tone: Tone.success,
              )
            else
              const StatusBadge(label: 'This app does not accept replies', icon: Icons.block),
          ],
        ),
        if (notification.dismissedOnSender && notification.canReply && isReceiver) ...[
          const SizedBox(height: Space.x2),
          Text(
            'It was cleared on your phone, so its reply action is gone. Answer from the phone instead.',
            style: AppType.supporting.copyWith(color: c.secondary),
          ),
        ],
        if (earlier.isNotEmpty) ...[
          SectionLabel('Earlier in this conversation', trailing: Text('${earlier.length}')),
          for (final e in earlier.reversed.take(10))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.x2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(formatClock(e.postedAt), style: AppType.supporting.copyWith(color: c.secondary)),
                  ),
                  Expanded(
                    child: Text(
                      e.notification.content.text.isEmpty ? e.notification.content.title : e.notification.content.text,
                      style: AppType.body.copyWith(color: c.secondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
        SectionLabel(
          isReceiver ? 'Your replies' : 'Replies from your devices',
          trailing: entry.replies.isEmpty ? null : Text('${entry.replies.length}'),
        ),
        if (entry.replies.isEmpty)
          Text(
            notification.acceptsReplies && isReceiver
                ? 'Write below. Your phone sends it through ${content.appName}.'
                : 'No replies yet.',
            style: AppType.supporting.copyWith(color: c.secondary),
          )
        else ...[
          const SizedBox(height: Space.x2),
          for (final reply in entry.replies) ReplyBubble(reply: reply),
        ],
      ],
    );
  }
}
