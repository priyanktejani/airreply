import 'package:air_reply/features/notifications/domain/feed.dart';

/// What this device remembers about its inbox: which notifications were read, and which were hidden. Kept on the
/// device only; the paired phone and the backend never see it.
///
/// Everything posted before [readBefore] counts as read (so "Mark all as read" is one timestamp, and a large history
/// is not "unread" when first opened); [read] and [unread] are per-notification exceptions to that rule.
final class InboxState {
  const InboxState({this.readBefore, this.read = const {}, this.unread = const {}, this.hidden = const {}});

  factory InboxState.fromJson(Map<String, Object?> json) => InboxState(
    readBefore: switch (json['readBefore']) {
      final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
      _ => null,
    },
    read: {...?(json['read'] as List<Object?>?)?.whereType<String>()},
    unread: {...?(json['unread'] as List<Object?>?)?.whereType<String>()},
    hidden: {...?(json['hidden'] as List<Object?>?)?.whereType<String>()},
  );

  /// Bounds each set, so years of use do not grow the stored state without limit.
  static const maxKept = 1000;

  final DateTime? readBefore;
  final Set<String> read;
  final Set<String> unread;
  final Set<String> hidden;

  bool isRead(FeedEntry entry) {
    if (unread.contains(entry.key)) return false;
    if (read.contains(entry.key)) return true;
    return readBefore != null && !entry.postedAt.isAfter(readBefore!);
  }

  bool isHidden(FeedEntry entry) => hidden.contains(entry.key);

  InboxState markRead(Iterable<String> keys) => _copy(read: _add(read, keys), unread: _remove(unread, keys));

  InboxState markUnread(Iterable<String> keys) => _copy(read: _remove(read, keys), unread: _add(unread, keys));

  /// Everything up to [now] becomes read.
  /// Without the marks of [pairId]'s notifications: that pair has ended.
  InboxState forgetPair(String pairId) {
    bool other(String key) => !key.startsWith('$pairId/');
    return _copy(
      read: read.where(other).toSet(),
      unread: unread.where(other).toSet(),
      hidden: hidden.where(other).toSet(),
    );
  }

  InboxState markAllRead(DateTime now) => InboxState(readBefore: now, read: const {}, unread: const {}, hidden: hidden);

  InboxState hide(Iterable<String> keys) => _copy(hidden: _add(hidden, keys));

  InboxState unhide(Iterable<String> keys) => _copy(hidden: _remove(hidden, keys));

  InboxState restoreHidden() => _copy(hidden: const {});

  Map<String, Object?> toJson() => {
    if (readBefore != null) 'readBefore': readBefore!.millisecondsSinceEpoch,
    'read': read.toList(),
    'unread': unread.toList(),
    'hidden': hidden.toList(),
  };

  InboxState _copy({Set<String>? read, Set<String>? unread, Set<String>? hidden}) => InboxState(
    readBefore: readBefore,
    read: read ?? this.read,
    unread: unread ?? this.unread,
    hidden: hidden ?? this.hidden,
  );

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
