import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';

// Smart grouping: every notification belongs to its app's group, and within it to a thread: one person, one group
// chat, or, when the metadata does not say who it is from, just that notification (with its own updates). Two
// notifications only share a thread when the phone says they belong to the same conversation, or both are messages
// with the same named sender; anything less certain stays apart.

enum ThreadKind {
  /// Messages from one person (a contact or a phone number).
  person,

  /// A group chat.
  group,

  /// A notification with no reliable sender: an app's own notice, or a message whose sender is unknown.
  single,
}

/// Which thread a notification belongs to within its app.
final class ThreadIdentity {
  const ThreadIdentity(this.key, this.kind);

  /// Unique within the app (and device). Prefixed by how it was decided: `id:`, `group:`, `person:` or `note:`.
  final String key;
  final ThreadKind kind;
}

ThreadIdentity threadIdentity(MirroredNotification notification) {
  final content = notification.content;
  final groupTitle = content.conversationTitle?.trim() ?? '';
  final isGroup = content.isGroupConversation && groupTitle.isNotEmpty;

  // 1. The app's own conversation id (Android shortcutId, hashed on the phone): the most reliable.
  if (content.conversationId case final id? when id.isNotEmpty) {
    return ThreadIdentity('id:$id', isGroup || content.isGroupConversation ? ThreadKind.group : ThreadKind.person);
  }
  // 2. A group chat, by its name.
  if (isGroup) return ThreadIdentity('group:${normalizeName(groupTitle)}', ThreadKind.group);

  // 3. A message from a named person. Notifications mirrored before the phone reported message-ness fall back to
  //    "can be answered", which only messaging apps offer.
  final isMessage = content.isMessage ?? (notification.canReply || content.conversationTitle != null);
  final person = isMessage ? personName(content) : null;
  if (person != null) return ThreadIdentity('person:${normalizeName(person)}', ThreadKind.person);
  // 4. Unknown sender: never merged with anything but its own updates.
  return ThreadIdentity('note:${content.key}', ThreadKind.single);
}

final _messageCount = RegExp(r'\s*\(\d+\s+(new\s+)?messages?\)\s*$', caseSensitive: false);
final _countOnly = RegExp(r'^\d+\s+(new\s+)?(messages?|notifications?)$', caseSensitive: false);
final _phoneLike = RegExp(r'^\+?[\d\s\-().]+$');

/// The person a message is from, from its title: "Alex Morgan", "+91 74052 94614". Null when the title names no one
/// (empty, the app's own name, or "3 new messages").
String? personName(NotificationContent content) {
  final title = content.title.replaceFirst(_messageCount, '').trim();
  if (title.isEmpty || title.toLowerCase() == content.appName.trim().toLowerCase() || _countOnly.hasMatch(title)) {
    return null;
  }
  return title;
}

/// Compares names loosely: case and spacing do not matter, and phone numbers match however they are formatted.
String normalizeName(String name) {
  final trimmed = name.trim();
  if (_phoneLike.hasMatch(trimmed)) {
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 5) return '${trimmed.startsWith('+') ? '+' : ''}$digits';
  }
  return trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Who wrote one message, for chat-style views: the sender the phone reported, else the person of a one-to-one
/// thread. Null when unknown.
String? messageSender(FeedEntry entry, ThreadKind kind) {
  final content = entry.notification.content;
  if (content.sender case final sender? when sender.trim().isNotEmpty) return sender.trim();
  return kind == ThreadKind.person ? personName(content) : null;
}

/// The message text without the "Sender: " prefix group chats put in front of it.
String messageText(NotificationContent content) {
  final sender = content.sender;
  if (sender != null && content.text.startsWith('$sender: ')) return content.text.substring(sender.length + 2);
  return content.text;
}

/// How far apart a reply and the app's copy of it can be and still be taken for one message.
const echoWindow = Duration(minutes: 2);

/// Whether [entry] is the messaging app's copy of [reply].
///
/// After a reply is sent, the messaging app on the phone usually posts the conversation again with that message in it,
/// and the copy is mirrored like any other notification. It has the reply's words and comes within [echoWindow] of it
/// (the phone's clock and this device's can differ, so either may look first).
bool isEchoOf(FeedEntry entry, ReplyCommand reply) {
  if (reply.status == ReplyStatus.failed || reply.status == ReplyStatus.expired) return false;
  final text = messageText(entry.notification.content).trim();
  return text.isNotEmpty && text == reply.text.trim() && entry.postedAt.difference(reply.createdAt).abs() <= echoWindow;
}

/// How a notification is the phone user's own message.
enum OwnMessage {
  /// The messaging app's copy of a reply sent from AirReply.
  reply,

  /// A message written on the phone itself.
  phone,
}

/// What messaging apps call the phone's user as a sender. When the newest message of a one-to-one chat is the
/// user's own, Android titles the notification after that sender, so the title is "You" rather than the contact.
const _selfNames = {'you'};

/// Whether [entry] is a message the phone's user wrote, and how; null for anyone else's. [replies] are the replies
/// sent in the same conversation.
OwnMessage? ownMessage(FeedEntry entry, Iterable<ReplyCommand> replies) {
  if (replies.any((r) => isEchoOf(entry, r))) return OwnMessage.reply;
  if (isTitledAsUser(entry.notification.content)) return OwnMessage.phone;
  return null;
}

/// A one-to-one message titled as the phone's user ("You"): the user's own words, whoever the chat is with.
bool isTitledAsUser(NotificationContent content) =>
    !content.isGroupConversation && _selfNames.contains(content.title.trim().toLowerCase());

/// The app's copy of each reply among [entries], by reply id: the closest match in time, each notification used once.
/// A chat shows a reply once, with its copy as the sign that the phone sent it.
Map<String, FeedEntry> replyEchoes(Iterable<FeedEntry> entries, Iterable<ReplyCommand> replies) {
  final echoes = <String, FeedEntry>{};
  final taken = <String>{};
  for (final reply in replies.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt))) {
    FeedEntry? best;
    Duration? gap;
    for (final entry in entries) {
      if (taken.contains(entry.key) || !isEchoOf(entry, reply)) continue;
      final d = entry.postedAt.difference(reply.createdAt).abs();
      if (gap == null || d < gap) (best, gap) = (entry, d);
    }
    if (best != null) {
      echoes[reply.id] = best;
      taken.add(best.key);
    }
  }
  return echoes;
}

/// One conversation within an app: all its notifications, newest first.
final class ConversationThread {
  ConversationThread({
    required this.source,
    required this.packageName,
    required this.appName,
    required this.identity,
    required this.entries,
  });

  /// The device the thread's notifications came from, or [AppGroup.allDevices].
  final String source;
  final String packageName;
  final String appName;
  final ThreadIdentity identity;

  /// Newest first.
  final List<FeedEntry> entries;

  String get key => identity.key;
  ThreadKind get kind => identity.kind;
  FeedEntry get latest => entries.first;
  int get count => entries.length;

  /// Its latest notification, or a later reply to one of them.
  late final DateTime lastActivity = entries.map((e) => e.lastActivity).reduce((a, b) => a.isAfter(b) ? a : b);

  /// The replies sent in this conversation.
  late final List<ReplyCommand> replies = [for (final e in entries) ...e.replies];

  /// The person or group name, from the newest notification that names them; the user's own messages are skipped,
  /// as their title is the user ("You"), not the other side. The app's name when nobody is known.
  late final String title = _title();

  String _title() {
    for (final entry in entries) {
      if (kind == ThreadKind.person && ownMessage(entry, replies) != null) continue;
      final content = entry.notification.content;
      final name = switch (kind) {
        ThreadKind.group => content.conversationTitle?.trim(),
        ThreadKind.person => content.isGroupConversation ? content.conversationTitle?.trim() : personName(content),
        ThreadKind.single => content.title.trim(),
      };
      if (name != null && name.isNotEmpty) return name;
    }
    return appName;
  }

  /// The newest notification that can still be answered from here.
  FeedEntry? get replyTarget => entries.where((e) => e.notification.acceptsReplies).firstOrNull;
}

/// Every notification of one app (on one device, or on all of them for a sender), in threads by latest activity.
final class AppGroup {
  AppGroup({
    required this.source,
    required this.packageName,
    required this.appName,
    required this.deviceName,
    required this.threads,
  });

  /// [source] of a sender's groups, which gather the copies sent to every device.
  static const allDevices = '*';

  final String source;
  final String packageName;
  final String appName;
  final String deviceName;

  /// Latest activity first.
  final List<ConversationThread> threads;

  String get id => '$source|$packageName';

  /// Newest first.
  late final List<FeedEntry> entries = [for (final t in threads) ...t.entries]
    ..sort((a, b) => b.postedAt.compareTo(a.postedAt));

  FeedEntry get latest => entries.first;
  int get count => entries.length;
  DateTime get lastActivity => threads.first.lastActivity;

  /// Holds several conversations worth listing separately.
  bool get hasThreads => threads.length > 1;
}

/// Whether [thread] matches a search: its name, a sender or a message containing [query], ignoring case. A query
/// with digits also matches phone numbers however they are formatted ("74052 94614" finds "+91 74052-94614").
bool threadMatches(ConversationThread thread, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final digits = q.replaceAll(RegExp(r'\D'), '');
  bool has(String? text) {
    if (text == null || text.isEmpty) return false;
    if (text.toLowerCase().contains(q)) return true;
    return digits.length >= 3 && text.replaceAll(RegExp(r'\D'), '').contains(digits);
  }

  return has(thread.title) ||
      thread.entries.any((e) {
        final content = e.notification.content;
        return has(content.title) || has(content.sender) || has(content.text);
      });
}

/// The thread a one-to-one message titled "You" would make on its own (see [_selfNames]).
const _ownThread = 'person:you';

/// Gathers [entries] into app groups and threads, both ordered by latest activity. With [perDevice] (receivers),
/// the same app on two phones makes two groups; senders gather the copies sent to every device under one.
List<AppGroup> groupByApp(Iterable<FeedEntry> entries, {bool perDevice = true}) {
  final apps = <String, Map<String, List<FeedEntry>>>{};
  final identities = <String, ThreadIdentity>{};
  final firstOfApp = <String, FeedEntry>{};

  // Your own messages titled "You" in apps without a conversation id: placed once the chats are known.
  final own = <(String, FeedEntry)>[];
  for (final entry in entries) {
    final source = perDevice ? entry.pairId : AppGroup.allDevices;
    final appKey = '$source|${entry.notification.content.packageName}';
    final identity = threadIdentity(entry.notification);
    firstOfApp.putIfAbsent(appKey, () => entry);
    if (identity.key == _ownThread) {
      own.add((appKey, entry));
      continue;
    }
    identities['$appKey|${identity.key}'] = identity;
    ((apps[appKey] ??= {})[identity.key] ??= []).add(entry);
  }
  // ...in the chat whose notification they updated (the app posts one notification per chat), else on their own
  for (final (appKey, entry) in own) {
    final threads = apps[appKey] ??= {};
    final home = threads.entries
        .where((t) => t.value.any((e) => e.notification.content.key == entry.notification.content.key))
        .firstOrNull
        ?.key;
    final key = home ?? _ownThread;
    identities.putIfAbsent('$appKey|$key', () => const ThreadIdentity(_ownThread, ThreadKind.person));
    (threads[key] ??= []).add(entry);
  }

  int byActivity(DateTime a, DateTime b) => b.compareTo(a);

  final groups = [
    for (final MapEntry(key: appKey, value: threads) in apps.entries)
      () {
        final first = firstOfApp[appKey]!;
        final source = perDevice ? first.pairId : AppGroup.allDevices;
        final content = first.notification.content;
        return AppGroup(
          source: source,
          packageName: content.packageName,
          appName: content.appName,
          deviceName: first.deviceName,
          threads: [
            for (final MapEntry(key: threadKey, value: list) in threads.entries)
              ConversationThread(
                source: source,
                packageName: content.packageName,
                appName: content.appName,
                identity: identities['$appKey|$threadKey']!,
                entries: list..sort((a, b) => b.postedAt.compareTo(a.postedAt)),
              ),
          ]..sort((a, b) => byActivity(a.lastActivity, b.lastActivity)),
        );
      }(),
  ]..sort((a, b) => byActivity(a.lastActivity, b.lastActivity));
  return groups;
}
