import 'dart:async';

import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_card.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_widgets.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A person's initials or a group icon in green on the soft green circle; a plain notification mark on grey.
class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({required this.title, required this.kind, this.size = 32, super.key});

  final String title;
  final ThreadKind kind;
  final double size;

  static String initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'\p{L}', unicode: true).hasMatch(w));
    final letters = [for (final w in words.take(2)) w.characters.first.toUpperCase()];
    return letters.join();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final letters = kind == ThreadKind.person ? initials(title) : '';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kind == ThreadKind.single ? c.soft : c.accentSoft, shape: BoxShape.circle),
      child: letters.isNotEmpty
          ? Text(
              letters,
              style: AppType.title.copyWith(color: c.accent, fontSize: size * 0.38, letterSpacing: 0, height: 1),
            )
          : Icon(
              switch (kind) {
                ThreadKind.group => Icons.group_rounded,
                ThreadKind.person => Icons.person_rounded,
                ThreadKind.single => Icons.notifications_none_rounded,
              },
              size: size * 0.5,
              color: kind == ThreadKind.single ? c.muted : c.accent,
            ),
    );
  }
}

/// One app's notifications on a [NotificationCard]: its icon, the app (and phone), the latest notification and how
/// many there are. Tap to open the group; the chevron lists its conversations inside the card, each opening as a chat.
/// Swipe the card to mark the whole group read or hide it; swipe a conversation to do the same for just that one.
class AppGroupTile extends ConsumerWidget {
  const AppGroupTile({
    required this.group,
    required this.expanded,
    required this.onToggleExpanded,
    this.showDevice = false,
    super.key,
  });

  final AppGroup group;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final bool showDevice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final isRead = ref.watch(readCheckProvider);
    final unread = group.entries.where((e) => !isRead(e)).length;
    final allRead = unread == 0;
    final latest = group.latest;
    final conversations = group.threads.where((t) => t.kind != ThreadKind.single).length;
    final open = expanded && group.hasThreads;
    return NotificationCard(
      leading: (size) => MirroredAppIcon(packageName: group.packageName, appName: group.appName, size: size),
      source: [group.appName, if (showDevice) group.deviceName].join(' · '),
      time: group.lastActivity,
      unread: unread,
      title: _heading(group.threads.first, latest),
      text: _previewText(ref, latest),
      summary: [
        group.count == 1 ? '1 notification' : '${group.count} notifications',
        if (conversations > 1) '$conversations conversations',
      ].join(' · '),
      action: group.hasThreads
          ? IconButton(
              tooltip: expanded ? 'Hide conversations' : 'Show conversations',
              onPressed: () {
                ref.tick();
                onToggleExpanded();
              },
              style: IconButton.styleFrom(
                backgroundColor: expanded ? c.accentSoft : c.soft,
                foregroundColor: expanded ? c.accent : c.muted,
                minimumSize: const Size(36, 36),
                fixedSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
              icon: AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: context.motion(AppMotion.slow),
                curve: AppMotion.curve,
                child: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
              ),
            )
          : null,
      onTap: () => ref.openGroup(context, group),
      swipe: CardSwipe(
        id: 'group/${group.id}',
        isRead: allRead,
        onToggleRead: () => ref.toggleReadAll(context, group.entries, allRead: allRead),
        onHide: () => ref.hide(context, group.entries),
      ),
      semanticLabel: '${group.appName}, ${group.count} notifications${unread > 0 ? ', $unread unread' : ''}',
      expansion: open
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, thread) in group.threads.indexed) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: AppSpacing.card + AppDimensions.iconTileSm + AppSpacing.md),
                  FadeSlideIn.staggered(
                    index: i,
                    offset: 8,
                    child: ThreadTile.row(thread: thread),
                  ),
                ],
              ],
            )
          : null,
    );
  }
}

/// The actions for a set of notifications on screen: mark them unread, hide them, or mute the app. Marking unread and
/// hiding both leave the screen via [onLeave].
class GroupActionsMenu extends ConsumerWidget {
  const GroupActionsMenu({
    required this.entries,
    required this.packageName,
    required this.appName,
    required this.onLeave,
    super.key,
  });

  final List<FeedEntry> entries;
  final String packageName;
  final String appName;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = ref.watch(readCheckProvider);
    final isReceiver = ref.watch(deviceRoleProvider) == DeviceRole.receiver;
    final muted = ref.watch(appPreferencesProvider.select((p) => p.value?.mutedApps.contains(packageName) ?? false));
    final allRead = entries.every(isRead);
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      onSelected: (action) {
        switch (action) {
          case 'unread':
            unawaited(ref.toggleReadAll(context, entries, allRead: allRead));
            onLeave(); // back to the list, where the conversation now shows as unread
          case 'hide':
            unawaited(ref.hide(context, entries));
            onLeave();
          case 'mute':
            ref.tick();
            unawaited(ref.read(appPreferencesProvider.notifier).setMuted(packageName, muted: !muted));
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'unread', child: Text('Mark as unread')),
        PopupMenuItem(
          value: 'hide',
          child: Text(entries.length == 1 ? 'Hide from this device' : 'Hide ${entries.length} notifications'),
        ),
        if (isReceiver)
          PopupMenuItem(
            value: 'mute',
            child: Text(muted ? 'Unmute alerts from $appName' : 'Mute alerts from $appName'),
          ),
      ],
    );
  }
}

/// One conversation (a person, a group or the app's own notices) on a [NotificationCard], on its app's screen; with
/// [ThreadTile.row], the same layout as a row inside its app's card on the notifications screen.
class ThreadTile extends ConsumerWidget {
  const ThreadTile({required this.thread, super.key}) : _row = false;

  const ThreadTile.row({required this.thread, super.key}) : _row = true;

  final ConversationThread thread;
  final bool _row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = ref.watch(readCheckProvider);
    final unread = thread.entries.where((e) => !isRead(e)).length;
    final allRead = unread == 0;
    final latest = thread.latest;
    final noun = thread.kind == ThreadKind.single ? 'notification' : 'message';
    // the conversation's name leads; in a group, who wrote last goes on the line above it
    final source = switch (thread.kind) {
      ThreadKind.person => 'Chat',
      ThreadKind.group => ['Group', ?messageSender(latest, thread.kind)].join(' · '),
      ThreadKind.single => 'Notification',
    };
    final title = thread.kind == ThreadKind.single ? latest.notification.content.title : thread.title;
    final summary = thread.count == 1 ? '1 $noun' : '${thread.count} ${noun}s';
    final swipe = CardSwipe(
      id: 'thread/${thread.source}/${thread.packageName}/${thread.key}',
      isRead: allRead,
      onToggleRead: () => ref.toggleReadAll(context, thread.entries, allRead: allRead),
      onHide: () => ref.hide(context, thread.entries),
    );
    final label = '${thread.title}, $summary${unread > 0 ? ', $unread unread' : ''}';
    Widget avatar(double size) => ConversationAvatar(title: thread.title, kind: thread.kind, size: size);
    void onTap() => ref.openThread(context, thread);

    return _row
        ? NotificationCard.row(
            leading: avatar,
            source: source,
            time: thread.lastActivity,
            unread: unread,
            title: title,
            text: _previewText(ref, latest),
            summary: summary,
            onTap: onTap,
            swipe: swipe,
            semanticLabel: label,
          )
        : NotificationCard(
            leading: avatar,
            source: source,
            time: thread.lastActivity,
            unread: unread,
            title: title,
            text: _previewText(ref, latest),
            summary: summary,
            onTap: onTap,
            swipe: swipe,
            semanticLabel: label,
          );
  }
}

/// What a group's card says about its latest notification: who (a person or group name) and what.
String _heading(ConversationThread thread, FeedEntry latest) => switch (thread.kind) {
  ThreadKind.group => [?messageSender(latest, thread.kind), thread.title].join(' · '),
  ThreadKind.person => thread.title,
  ThreadKind.single => latest.notification.content.title,
};

/// The latest notification's text as a card shows it: your reply, or the app's copy of a message you sent, reads as
/// yours rather than as a message from someone else.
String _previewText(WidgetRef ref, FeedEntry entry) {
  final text = messageText(entry.notification.content);
  final reply = entry.latestReply;
  if (reply != null && ref.watch(deviceRoleProvider) == DeviceRole.receiver) return 'You: ${reply.text}';
  final own = ref.watch(ownMessageProvider((pairId: entry.pairId, id: entry.notification.id))) != null;
  return own && text.isNotEmpty ? 'You: $text' : text;
}
