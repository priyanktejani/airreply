import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/app_dimen.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_icon.dart';
import 'package:air_reply/core/widgets/app_sheet.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_card.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
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
  /// Opens a notification where it belongs: a message from a person or a group chat opens its chat, scrolled to it;
  /// anything else (an email, an app's own notice) opens on its own.
  void open(BuildContext context, FeedEntry entry) {
    unawaited(read(inboxStateProvider.notifier).markRead([entry.key]));
    final chat = read(chatOfProvider((pairId: entry.pairId, id: entry.notification.id)));
    unawaited(
      context.push(
        chat == null
            ? AppRoutes.notification(entry.pairId, entry.notification.id)
            : AppRoutes.thread(chat.source, chat.packageName, chat.key, at: entry.notification.id),
      ),
    );
  }

  /// Copy, mark unread or delete one notification, from a sheet (a long press in a chat).
  Future<void> showEntryActions(BuildContext context, FeedEntry entry) async {
    final isRead = read(readCheckProvider)(entry);
    final action = await showAppSheet<_RowAction>(
      context,
      builder: (context) => _ActionSheet(isRead: isRead, count: 1),
    );
    if (!context.mounted || action == null) return;
    await NotificationRow._perform(context, this, action, isRead: isRead, targets: [entry]);
  }

  Future<void> toggleRead(BuildContext context, FeedEntry entry, {required bool isRead}) async {
    tick();
    final inbox = read(inboxStateProvider.notifier);
    await (isRead ? inbox.markUnread([entry.key]) : inbox.markRead([entry.key]));
  }

  /// Deletes [entries] from this device for good, with a moment to Undo: they leave every list at once, and the
  /// history when the Undo goes (another action, or its time running out). Everything is taken from [context] first:
  /// a swiped row is gone, and its context unmounted, as soon as the lists update.
  Future<void> delete(BuildContext context, List<FeedEntry> entries) async {
    tick();
    final keys = [for (final e in entries) e.key];
    final deleted = read(deletedEntriesProvider.notifier);
    final inbox = read(inboxStateProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final snack = appSnackBar(
      context,
      context.l10n.notificationDeleted(entries.length),
      icon: AppIcons.delete,
      duration: const Duration(seconds: 5),
      // goes by itself (one with an action would otherwise stay until dismissed): then the delete is final
      persist: false,
      action: SnackBarAction(label: context.l10n.actionUndo, onPressed: () => deleted.remove(keys)),
    );
    deleted.add(keys);
    inbox.dismissAlerts(keys);
    messenger.hideCurrentSnackBar();
    final closed = await messenger.showSnackBar(snack).closed;
    if (closed == SnackBarClosedReason.action) return;
    try {
      await inbox.delete(keys);
    } on Object {
      // not deleted after all (the database could not be written): back in the lists
      deleted.remove(keys);
    }
  }

  /// Marks every notification of a group read, or (when all are read) its newest one from someone else unread again:
  /// your own last message is not what makes a conversation worth coming back to.
  Future<void> toggleReadAll(BuildContext context, List<FeedEntry> entries, {required bool allRead}) async {
    tick();
    final inbox = read(inboxStateProvider.notifier);
    if (!allRead) return inbox.markRead([for (final e in entries) e.key]);
    final theirs = entries.where((e) => !isMarkedAsUser(e.notification.content)).firstOrNull ?? entries.first;
    await inbox.markUnread([theirs.key]);
  }

  /// Opens an app group: its only notification, or the list of its conversations.
  void openGroup(BuildContext context, AppGroup group) {
    if (group.count == 1) return open(context, group.latest);
    unawaited(context.push(AppRoutes.appGroup(group.source, group.packageName)));
  }

  /// Opens a conversation; a lone notification with no known sender opens as itself.
  void openThread(BuildContext context, ConversationThread thread) {
    if (thread.count == 1 && thread.kind == ThreadKind.single) return open(context, thread.latest);
    unawaited(context.push(AppRoutes.thread(thread.source, thread.packageName, thread.key)));
  }

  Future<void> copyText(BuildContext context, FeedEntry entry) async {
    final c = entry.notification.content;
    await Clipboard.setData(ClipboardData(text: [c.title, c.text].where((s) => s.isNotEmpty).join('\n')));
    if (context.mounted) context.showMessage(context.l10n.copied);
  }
}

/// One notification on a [NotificationCard]: the app and source, time, unread count, title, text and the latest
/// reply. Swipe right to mark read or unread, left to delete; long-press (or the menu on wide screens) for these and
/// Copy.
class NotificationRow extends ConsumerWidget {
  const NotificationRow({required this.entry, this.showDevice = false, this.compact = false, super.key});

  final FeedEntry entry;
  final bool showDevice;

  /// Smaller type and one line of text: Home and expanded groups.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final isRead = ref.watch(readCheckProvider)(entry);
    final content = entry.notification.content;
    final latest = entry.latestReply;
    final wide = AppDimen.of(context).isWide;
    final targets = [entry];
    final source = [content.appName, if (showDevice) entry.deviceName].join(' · ');
    final target = (pairId: entry.pairId, id: entry.notification.id);
    // your own message: under the other person's name, as yours
    final own = ref.watch(ownMessageProvider(target));
    final title = own == null ? content.title : ref.watch(conversationNameProvider(target)) ?? content.title;
    final text = own == null ? content.text : context.l10n.youSaid(messageText(content));

    Future<void> showActions() async {
      final action = await showAppSheet<_RowAction>(
        context,
        builder: (context) => _ActionSheet(isRead: isRead, count: targets.length),
      );
      if (!context.mounted || action == null) return;
      await _perform(context, ref, action, isRead: isRead, targets: targets);
    }

    return NotificationCard(
      leading: (size) => MirroredAppIcon(packageName: content.packageName, appName: content.appName, size: size),
      source: source,
      time: entry.postedAt,
      unread: isRead ? 0 : 1,
      title: title,
      text: content.text.isEmpty ? '' : text,
      badges: [
        if (own != null) OwnMessageBadge(own: own, appName: content.appName),
        if (latest != null) ReplyStatusBadge(reply: latest, prefix: true),
        if (entry.notification.dismissedOnSender)
          StatusBadge(label: context.l10n.dismissedOnPhone, icon: AppIcons.phonelinkErase),
      ],
      trailing: wide
          ? PopupMenuButton<_RowAction>(
              tooltip: context.l10n.moreActions,
              icon: Icon(AppIcons.moreHoriz, color: c.muted, size: AppDimensions.iconMd),
              onSelected: (a) => _perform(context, ref, a, isRead: isRead, targets: targets),
              itemBuilder: (_) => _RowAction.menu(context.l10n, isRead: isRead, count: targets.length),
            )
          : null,
      onTap: () => ref.open(context, entry),
      onLongPress: wide ? null : showActions,
      compact: compact,
      swipe: CardSwipe(
        id: entry.key,
        isRead: isRead,
        onToggleRead: () => ref.toggleRead(context, entry, isRead: isRead),
        onDelete: () => ref.delete(context, targets),
      ),
    );
  }

  static Future<void> _perform(
    BuildContext context,
    WidgetRef ref,
    _RowAction action, {
    required bool isRead,
    required List<FeedEntry> targets,
  }) => switch (action) {
    _RowAction.toggleRead => ref.toggleRead(context, targets.first, isRead: isRead),
    _RowAction.delete => ref.delete(context, targets),
    _RowAction.copy => ref.copyText(context, targets.first),
  };
}

enum _RowAction {
  toggleRead,
  delete,
  copy;

  static List<PopupMenuEntry<_RowAction>> menu(AppLocalizations l10n, {required bool isRead, required int count}) => [
    PopupMenuItem(value: toggleRead, child: Text(isRead ? l10n.markAsUnread : l10n.markAsRead)),
    PopupMenuItem(value: copy, child: Text(l10n.copyText)),
    PopupMenuItem(value: delete, child: Text(count > 1 ? l10n.deleteCount(count) : l10n.actionDelete)),
  ];
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.isRead, required this.count});

  final bool isRead;
  final int count;

  @override
  Widget build(BuildContext context) => CardGroup(
    children: [
      InfoRow(
        icon: isRead ? AppIcons.markEmailUnread : AppIcons.markEmailRead,
        title: isRead ? context.l10n.markAsUnread : context.l10n.markAsRead,
        onTap: () => Navigator.pop(context, _RowAction.toggleRead),
      ),
      InfoRow(
        icon: AppIcons.contentCopy,
        title: context.l10n.copyText,
        onTap: () => Navigator.pop(context, _RowAction.copy),
      ),
      InfoRow(
        icon: AppIcons.delete,
        destructive: true,
        title: count > 1 ? context.l10n.deleteCount(count) : context.l10n.deleteFromDevice,
        onTap: () => Navigator.pop(context, _RowAction.delete),
      ),
    ],
  );
}

/// "Sending…", "Sent", "Expired on phone", "Not delivered".
class ReplyStatusBadge extends StatelessWidget {
  const ReplyStatusBadge({required this.reply, this.prefix = false, this.delivered = false, super.key});

  final ReplyCommand reply;

  /// "Reply sent" instead of "Sent", for rows where the reply text is not shown.
  final bool prefix;

  /// The messaging app on the phone has shown the reply in its conversation: two ticks, "Delivered".
  final bool delivered;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, icon, tone) = switch (reply.status) {
      ReplyStatus.pending => (prefix ? l10n.replySendingPrefixed : l10n.replySending, AppIcons.schedule, Tone.neutral),
      ReplyStatus.sent when delivered => (
        prefix ? l10n.replyDeliveredPrefixed : l10n.replyDelivered,
        AppIcons.doneAll,
        Tone.success,
      ),
      ReplyStatus.sent => (prefix ? l10n.replySentPrefixed : l10n.replySent, AppIcons.done, Tone.success),
      ReplyStatus.expired => (prefix ? l10n.replyExpiredPrefixed : l10n.replyExpired, AppIcons.timerOff, Tone.warning),
      ReplyStatus.failed => (
        prefix ? l10n.replyNotDeliveredPrefixed : l10n.replyNotDelivered,
        AppIcons.errorOutline,
        Tone.error,
      ),
    };
    return StatusBadge(label: label, icon: icon, tone: tone, busy: reply.status == ReplyStatus.pending);
  }
}

/// A reply sent from a receiver, with when and whether it was delivered: brand accent on the right, with a small corner
/// towards the sender. One tick once the phone sent it; two once the messaging app shows it there ([echo], its copy
/// of the reply, which is never shown as a message of its own).
class ReplyBubble extends StatelessWidget {
  const ReplyBubble({required this.reply, this.echo, super.key});

  final ReplyCommand reply;
  final FeedEntry? echo;

  static const _round = Radius.circular(AppRadius.lg);
  static const _tail = Radius.circular(AppSpacing.xs);

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Align(
      alignment: Alignment.centerRight,
      // a share of the conversation's width (beside the rail on wide windows), not of the whole window
      child: LayoutBuilder(
        builder: (context, box) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: box.maxWidth * .78),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: _round,
                    topRight: _round,
                    bottomLeft: _round,
                    bottomRight: _tail,
                  ),
                ),
                child: SelectableText(reply.text, style: AppType.body.copyWith(color: c.accentInk)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, 0),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    Text(formatClock(context.l10n, reply.createdAt), style: AppType.label.copyWith(color: c.muted)),
                    ReplyStatusBadge(reply: reply, delivered: echo != null),
                  ],
                ),
              ),
              // the same rhythm as every message in a chat: bubble, its time and state, then the next one
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// On a notification that is the user's own message, so the same words read as theirs rather than as a message from
/// someone else: "Your reply, as WhatsApp shows it", or "Sent from your phone".
class OwnMessageBadge extends StatelessWidget {
  const OwnMessageBadge({required this.own, required this.appName, super.key});

  final OwnMessage own;
  final String appName;

  @override
  Widget build(BuildContext context) => switch (own) {
    OwnMessage.reply => StatusBadge(
      label: context.l10n.yourReplyAsShown(appName),
      icon: AppIcons.reply,
      tone: Tone.success,
    ),
    OwnMessage.phone => StatusBadge(label: context.l10n.sentFromPhone, icon: AppIcons.smartphone),
  };
}
