import 'package:air_reply/features/notifications/domain/feed.dart';

/// What this device remembers about its inbox: which notifications were read. Kept on the device only; the paired
/// phone and the backend never see it. (Deleting a notification takes it out of the history itself.)
///
/// Everything posted before [readBefore] counts as read (so "Mark all as read" is one timestamp, and a large history
/// is not "unread" when first opened); [read] and [unread] are per-notification exceptions to that rule.
final class InboxState {
  const InboxState({this.readBefore, this.read = const {}, this.unread = const {}, this.legacyHidden = const {}});

  factory InboxState.fromJson(Map<String, Object?> json) => InboxState(
    readBefore: switch (json['readBefore']) {
      final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
      _ => null,
    },
    read: {...?(json['read'] as List<Object?>?)?.whereType<String>()},
    unread: {...?(json['unread'] as List<Object?>?)?.whereType<String>()},
    legacyHidden: {...?(json['hidden'] as List<Object?>?)?.whereType<String>()},
  );

  /// Bounds each set, so years of use do not grow the stored state without limit.
  static const maxKept = 1000;

  final DateTime? readBefore;
  final Set<String> read;
  final Set<String> unread;

  /// What an earlier version hid instead of deleting: deleted on the next start, then forgotten (never saved again).
  final Set<String> legacyHidden;

  bool isRead(FeedEntry entry) {
    if (unread.contains(entry.key)) return false;
    if (read.contains(entry.key)) return true;
    return readBefore != null && !entry.postedAt.isAfter(readBefore!);
  }

  InboxState markRead(Iterable<String> keys) => _copy(read: _add(read, keys), unread: _remove(unread, keys));

  InboxState markUnread(Iterable<String> keys) => _copy(read: _remove(read, keys), unread: _add(unread, keys));

  /// Without the marks of [pairId]'s notifications: that pair has ended.
  InboxState forgetPair(String pairId) {
    bool other(String key) => FeedEntry.parseKey(key)?.pairId != pairId;
    return _copy(read: read.where(other).toSet(), unread: unread.where(other).toSet());
  }

  /// Everything up to [now] becomes read.
  InboxState markAllRead(DateTime now) => InboxState(readBefore: now);

  /// Without the marks of [keys]: those notifications were deleted.
  InboxState forget(Iterable<String> keys) => _copy(read: _remove(read, keys), unread: _remove(unread, keys));

  Map<String, Object?> toJson() => {
    if (readBefore != null) 'readBefore': readBefore!.millisecondsSinceEpoch,
    'read': read.toList(),
    'unread': unread.toList(),
  };

  InboxState _copy({Set<String>? read, Set<String>? unread}) =>
      InboxState(readBefore: readBefore, read: read ?? this.read, unread: unread ?? this.unread);

  static Set<String> _add(Set<String> set, Iterable<String> keys) {
    final next = {...set.where((k) => !keys.contains(k)), ...keys};
    return next.length <= maxKept ? next : next.skip(next.length - maxKept).toSet();
  }

  static Set<String> _remove(Set<String> set, Iterable<String> keys) => {...set.where((k) => !keys.contains(k))};
}

abstract interface class InboxStateStore {
  /// Null on first use.
  Future<InboxState?> load();

  Future<void> save(InboxState state);
}
