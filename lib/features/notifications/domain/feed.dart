import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';

/// One mirrored notification as the inbox shows it: the notification, the phone it came from, and the replies sent
/// to it from here, oldest first.
final class FeedEntry {
  const FeedEntry({
    required this.pairId,
    required this.deviceName,
    required this.notification,
    this.replies = const [],
  });

  final String pairId;
  final String deviceName;
  final MirroredNotification notification;
  final List<ReplyCommand> replies;

  /// Unique across paired phones.
  String get key => '$pairId/${notification.id}';

  DateTime get postedAt => notification.postedAt;

  ReplyCommand? get latestReply => replies.isEmpty ? null : replies.last;

  /// When anything last happened to it: posted, or answered from a paired device.
  DateTime get lastActivity => switch (latestReply) {
    final reply? when reply.createdAt.isAfter(postedAt) => reply.createdAt,
    _ => postedAt,
  };
}

enum FeedPeriod {
  all('Any time'),
  today('Today'),
  week('Last 7 days');

  const FeedPeriod(this.label);

  final String label;

  bool includes(DateTime time, DateTime now) => switch (this) {
    FeedPeriod.all => true,
    FeedPeriod.today => time.year == now.year && time.month == now.month && time.day == now.day,
    FeedPeriod.week => now.difference(time) <= const Duration(days: 7),
  };
}

/// What the inbox is narrowed to; null / empty / default fields mean "all".
final class FeedFilter {
  const FeedFilter({
    this.pairId,
    this.packageName,
    this.query = '',
    this.unreadOnly = false,
    this.period = FeedPeriod.all,
  });

  static const none = FeedFilter();

  final String? pairId;
  final String? packageName;

  /// Free text, matched against title, text, app and phone name.
  final String query;
  final bool unreadOnly;
  final FeedPeriod period;

  bool get isActive =>
      pairId != null || packageName != null || query.trim().isNotEmpty || unreadOnly || period != FeedPeriod.all;

  /// How many filters (other than search) are on, for the filter button's badge.
  int get activeCount =>
      [pairId != null, packageName != null, unreadOnly, period != FeedPeriod.all].where((b) => b).length;

  FeedFilter copyWith({
    String? Function()? pairId,
    String? Function()? packageName,
    String? query,
    bool? unreadOnly,
    FeedPeriod? period,
  }) => FeedFilter(
    pairId: pairId == null ? this.pairId : pairId(),
    packageName: packageName == null ? this.packageName : packageName(),
    query: query ?? this.query,
    unreadOnly: unreadOnly ?? this.unreadOnly,
    period: period ?? this.period,
  );

  /// [isRead] tells whether an entry was read (only consulted for [unreadOnly]).
  bool matches(FeedEntry entry, {required bool Function(FeedEntry) isRead, DateTime? now}) {
    final content = entry.notification.content;
    if (pairId != null && entry.pairId != pairId) return false;
    if (packageName != null && content.packageName != packageName) return false;
    if (unreadOnly && isRead(entry)) return false;
    if (!period.includes(entry.postedAt, now ?? DateTime.now())) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [content.title, content.text, content.appName, entry.deviceName].any((s) => s.toLowerCase().contains(q));
  }
}

/// Joins one pair's two realtime streams into entries, newest notification first.
List<FeedEntry> buildFeed(
  List<MirroredNotification> notifications,
  List<ReplyCommand> replies, {
  required String pairId,
  required String deviceName,
}) {
  final byNotification = <String, List<ReplyCommand>>{};
  for (final reply in replies) {
    (byNotification[reply.notificationId] ??= []).add(reply);
  }
  for (final thread in byNotification.values) {
    thread.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
  final sorted = [...notifications]..sort((a, b) => b.postedAt.compareTo(a.postedAt));
  // The same message mirrored twice (an app re-posting it): one entry, with the replies sent to either copy. Copies
  // match exactly, down to the message's own time, so two real messages with the same words are never merged.
  final unique = <String, MirroredNotification>{};
  final repliesOf = <String, List<ReplyCommand>>{};
  for (final notification in sorted) {
    final c = notification.content;
    final id = '${c.key}\u0000${c.title}\u0000${c.text}\u0000${c.postedAt.millisecondsSinceEpoch}';
    final kept = unique[id];
    final replies = byNotification[notification.id] ?? const <ReplyCommand>[];
    if (kept == null) {
      unique[id] = notification;
      repliesOf[notification.id] = replies;
    } else if (replies.isNotEmpty) {
      repliesOf[kept.id] = [...repliesOf[kept.id]!, ...replies]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }
  return [
    for (final notification in unique.values)
      FeedEntry(
        pairId: pairId,
        deviceName: deviceName,
        notification: notification,
        replies: repliesOf[notification.id] ?? const [],
      ),
  ];
}

/// Interleaves the feeds of several pairs by time, newest first. With [dedupe] (the sender, which publishes the same
/// notification to every paired device), the copies of one notification collapse into one entry that names every
/// device it went to and carries the replies sent from all of them.
List<FeedEntry> mergeFeeds(Iterable<List<FeedEntry>> feeds, {bool dedupe = false}) {
  final all = [for (final feed in feeds) ...feed]..sort((a, b) => b.postedAt.compareTo(a.postedAt));
  if (!dedupe) return all;
  final merged = <String, FeedEntry>{};
  for (final entry in all) {
    final id = '${entry.notification.content.key}@${entry.postedAt.millisecondsSinceEpoch}';
    final first = merged[id];
    merged[id] = first == null
        ? entry
        : FeedEntry(
            pairId: first.pairId,
            deviceName: '${first.deviceName}, ${entry.deviceName}',
            notification: first.notification,
            replies: [...first.replies, ...entry.replies]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
          );
  }
  return [...merged.values];
}
