import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_icon.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// An app's icon as this device knows it: harvested from mirrored notifications, or the system's on the sender.
class MirroredAppIcon extends ConsumerWidget {
  const MirroredAppIcon({required this.packageName, required this.appName, this.size = 40, super.key});

  final String packageName;
  final String appName;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      AppIconView(appName: appName, png: ref.watch(appIconProvider(packageName)), size: size);
}

/// The actions every notification offers, wherever it is shown (row swipe, long press, menu, detail).
extension EntryActions on WidgetRef {
  void open(BuildContext context, FeedEntry entry) {
    unawaited(read(inboxStateProvider.notifier).markRead([entry.key]));
    unawaited(context.push(AppRoutes.notification(entry.pairId, entry.notification.id)));
  }

  Future<void> toggleRead(BuildContext context, FeedEntry entry, {required bool isRead}) async {
    tick();
    final inbox = read(inboxStateProvider.notifier);
    await (isRead ? inbox.markUnread([entry.key]) : inbox.markRead([entry.key]));
  }

  /// Hides [entries] from this device's inbox, with Undo. The snackbar is shown first: a swiped row is gone (and its
  /// context unmounted) as soon as the inbox updates.
  Future<void> hide(BuildContext context, List<FeedEntry> entries) {
    tick();
    final keys = [for (final e in entries) e.key];
    final inbox = read(inboxStateProvider.notifier);
    context.showUndo(
      entries.length == 1 ? 'Notification hidden' : '${entries.length} notifications hidden',
      () => unawaited(inbox.unhide(keys)),
    );
    return inbox.hide(keys);
  }

  Future<void> copyText(BuildContext context, FeedEntry entry) async {
    final c = entry.notification.content;
    await Clipboard.setData(ClipboardData(text: [c.title, c.text].where((s) => s.isNotEmpty).join('\n')));
    if (context.mounted) context.showMessage('Copied');
  }
}

/// One notification in a list: app and source, time, unread mark, title, text and the latest reply. Swipe right to
/// mark read or unread, left to hide; long-press (or the menu on wide screens) for the same actions.
class NotificationRow extends ConsumerWidget {
  const NotificationRow({
    required this.entry,
    this.showDevice = false,
    this.compact = false,
    this.swipeable = true,
    this.group,
    super.key,
  });

  final FeedEntry entry;
  final bool showDevice;

  /// Smaller type and one line of text: Home and expanded groups.
  final bool compact;
  final bool swipeable;

  /// When this row stands for a whole group, hiding it hides every notification of the group.
  final FeedGroup? group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isRead = ref.watch(readCheckProvider)(entry);
    final content = entry.notification.content;
    final latest = entry.latestReply;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final hideTargets = group?.entries ?? [entry];
    final source = [content.appName, if (showDevice) entry.deviceName].join(' · ');

    Future<void> showActions() async {
      final action = await showModalBottomSheet<_RowAction>(
        context: context,
        useRootNavigator: true,
        builder: (context) => _ActionSheet(isRead: isRead, count: hideTargets.length),
      );
      if (!context.mounted || action == null) return;
      await _perform(context, ref, action, isRead: isRead, hideTargets: hideTargets);
    }

    final row = InkWell(
      onTap: () => ref.open(context, entry),
      onLongPress: wide ? null : showActions,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? Space.x3 : Space.x4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MirroredAppIcon(packageName: content.packageName, appName: content.appName, size: compact ? 32 : 40),
            const SizedBox(width: Space.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          source.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.label.copyWith(color: c.secondary),
                        ),
                      ),
                      const SizedBox(width: Space.x2),
                      Text(formatRelativeTime(entry.postedAt), style: AppType.supporting.copyWith(color: c.secondary)),
                      AnimatedSwitcher(
                        duration: Motion.fast,
                        child: isRead
                            ? const SizedBox(width: 0)
                            : Padding(
                                padding: const EdgeInsets.only(left: Space.x2),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.x1),
                  if (content.title.isNotEmpty)
                    Text(
                      content.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (compact ? AppType.subtitle : AppType.title).copyWith(
                        color: c.ink,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                  if (content.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        content.text,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(color: isRead ? c.secondary : c.ink),
                      ),
                    ),
                  if (latest != null || entry.notification.dismissedOnSender)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.x2),
                      child: Wrap(
                        spacing: Space.x4,
                        runSpacing: Space.x1,
                        children: [
                          if (latest != null) ReplyStatusBadge(reply: latest, prefix: true),
                          if (entry.notification.dismissedOnSender)
                            const StatusBadge(label: 'Dismissed on phone', icon: Icons.phonelink_erase_outlined),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (wide && swipeable)
              PopupMenuButton<_RowAction>(
                tooltip: 'More actions',
                icon: Icon(Icons.more_horiz, color: c.secondary, size: 20),
                onSelected: (a) => _perform(context, ref, a, isRead: isRead, hideTargets: hideTargets),
                itemBuilder: (_) => _RowAction.menu(isRead: isRead, count: hideTargets.length),
              ),
          ],
        ),
      ),
    );

    final semantic = Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: isRead ? 'Mark as unread' : 'Mark as read'): () =>
            ref.toggleRead(context, entry, isRead: isRead),
        const CustomSemanticsAction(label: 'Hide'): () => ref.hide(context, hideTargets),
      },
      child: row,
    );
    if (!swipeable) return semantic;

    return Dismissible(
      key: ValueKey('swipe/${entry.key}'),
      background: _SwipeBackground(
        icon: isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
        label: isRead ? 'Unread' : 'Read',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBackground(
        icon: Icons.visibility_off_outlined,
        label: 'Hide',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await ref.toggleRead(context, entry, isRead: isRead);
          return false; // the row stays, only its read state changes
        }
        return true;
      },
      onDismissed: (_) => ref.hide(context, hideTargets),
      child: semantic,
    );
  }

  static Future<void> _perform(
    BuildContext context,
    WidgetRef ref,
    _RowAction action, {
    required bool isRead,
    required List<FeedEntry> hideTargets,
  }) => switch (action) {
    _RowAction.toggleRead => ref.toggleRead(context, hideTargets.first, isRead: isRead),
    _RowAction.hide => ref.hide(context, hideTargets),
    _RowAction.copy => ref.copyText(context, hideTargets.first),
  };
}

enum _RowAction {
  toggleRead,
  hide,
  copy;

  static List<PopupMenuEntry<_RowAction>> menu({required bool isRead, required int count}) => [
    PopupMenuItem(value: toggleRead, child: Text(isRead ? 'Mark as unread' : 'Mark as read')),
    const PopupMenuItem(value: copy, child: Text('Copy text')),
    PopupMenuItem(value: hide, child: Text(count > 1 ? 'Hide $count notifications' : 'Hide')),
  ];
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.isRead, required this.count});

  final bool isRead;
  final int count;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoRow(
            icon: isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
            title: isRead ? 'Mark as unread' : 'Mark as read',
            onTap: () => Navigator.pop(context, _RowAction.toggleRead),
          ),
          InfoRow(
            icon: Icons.content_copy_outlined,
            title: 'Copy text',
            onTap: () => Navigator.pop(context, _RowAction.copy),
          ),
          InfoRow(
            icon: Icons.visibility_off_outlined,
            title: count > 1 ? 'Hide $count notifications' : 'Hide from this device',
            onTap: () => Navigator.pop(context, _RowAction.hide),
          ),
        ],
      ),
    ),
  );
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.icon, required this.label, required this.alignment});

  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: c.subtle,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: c.ink),
              const SizedBox(width: Space.x2),
              Text(label, style: AppType.button.copyWith(color: c.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Sending…", "Sent", "Expired on phone", "Not delivered".
class ReplyStatusBadge extends StatelessWidget {
  const ReplyStatusBadge({required this.reply, this.prefix = false, super.key});

  final ReplyCommand reply;

  /// "Reply sent" instead of "Sent", for rows where the reply text is not shown.
  final bool prefix;

  @override
  Widget build(BuildContext context) {
    final (label, icon, tone) = switch (reply.status) {
      ReplyStatus.pending => ('Sending', Icons.schedule, Tone.neutral),
      ReplyStatus.sent => ('Sent', Icons.done_all, Tone.success),
      ReplyStatus.expired => ('Expired on phone', Icons.timer_off_outlined, Tone.warning),
      ReplyStatus.failed => ('Not delivered', Icons.error_outline, Tone.error),
    };
    return StatusBadge(
      label: prefix ? 'Reply ${label.toLowerCase()}' : label,
      icon: icon,
      tone: tone,
      busy: reply.status == ReplyStatus.pending,
    );
  }
}

/// A reply sent from a receiver, with its delivery status.
class ReplyBubble extends StatelessWidget {
  const ReplyBubble({required this.reply, super.key});

  final ReplyCommand reply;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(left: Space.x12, bottom: Space.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x3),
              decoration: BoxDecoration(color: c.subtle, borderRadius: Radii.controlBorder),
              child: SelectableText(reply.text, style: AppType.body.copyWith(color: c.ink)),
            ),
            const SizedBox(height: Space.x1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatClock(reply.createdAt), style: AppType.supporting.copyWith(color: c.secondary)),
                const SizedBox(width: Space.x3),
                ReplyStatusBadge(reply: reply),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
