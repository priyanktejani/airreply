import 'package:air_reply/features/mirror/domain/entities/history_query.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';

// One backend, four narrow roles (interface segregation): the sender publishes notifications and works through its
// reply inbox; the receiver reads the feed and writes to its reply outbox. Each side only sees what it uses.
// Implementations encrypt and decrypt on the way in and out, so nothing above the data layer handles ciphertext.

/// Sender: mirrors what the listener captured.
abstract interface class NotificationPublisher {
  Future<void> publish(NotificationContent content, {required bool canReply});

  /// Flags every mirrored post of [notificationKey] as gone from the sender (history stays on the receiver).
  Future<void> markDismissed(String notificationKey);
}

/// Sender: replies waiting to be executed.
abstract interface class ReplyInbox {
  /// Emits the batch of pending replies each time it changes.
  Stream<List<PendingReply>> watchPending();

  /// One-off read straight from the server, for when a push wakes the sender.
  Future<List<PendingReply>> fetchPending();

  Future<void> resolve(String replyId, ReplyStatus status);
}

/// Receiver: the mirrored history.
abstract interface class NotificationFeed {
  Stream<List<MirroredNotification>> watchNotifications({int limit});

  Stream<List<ReplyCommand>> watchReplies({int limit});

  /// Whether this pair is currently syncing with the server (drives connection status in the UI).
  Stream<SyncState> watchSyncState();

  /// One mirrored notification, decrypted; null if it is gone or unreadable.
  Future<MirroredNotification?> fetchNotification(String id);

  /// A page of the whole history on this device matching [query], newest first, after the [after] of the previous
  /// page: for search and for browsing beyond what [watchNotifications] keeps loaded.
  Future<HistoryPage> browseHistory(HistoryQuery query, {HistoryCursor? after, int limit});

  /// How many notifications [browseHistory] goes through for [query], over all its pages.
  Future<int> countHistory(HistoryQuery query);

  /// Decrypts the copy of a notification that arrived inside a push, without a Firestore read.
  Future<MirroredNotification?> decodePushed({required String id, required String payload, required bool canReply});
}

/// Receiver: queues a reply for the sender to execute.
abstract interface class ReplyOutbox {
  Future<void> send({required String notificationId, required String notificationKey, required String text});
}

/// All four roles of one pair, as a backend implements them.
abstract interface class MirrorRepository implements NotificationPublisher, ReplyInbox, NotificationFeed, ReplyOutbox {}
