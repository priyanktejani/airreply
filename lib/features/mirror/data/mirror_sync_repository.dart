import 'dart:async';

import 'package:air_reply/core/firebase/firestore_schema.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:air_reply/features/mirror/data/mirror_documents.dart';
import 'package:air_reply/features/mirror/data/pair_mailbox.dart';
import 'package:air_reply/features/mirror/domain/entities/history_query.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';

/// [MirrorRepository] for one pair, working as WhatsApp does: history lives on the devices ([MessageHistory]) and the
/// backend is only a mailbox ([PairMailbox]).
///
/// * The sender drops each notification into the mailbox and keeps its own copy.
/// * The receiver ([collects]) keeps every document it finds there, then deletes it: a notification or a dismissal at
///   once, a reply once the sender has reported how it went. Nothing stays on the server after delivery, and what is
///   never picked up expires (`expireAt`).
///
/// Both sides keep the payloads sealed with the pair's key, and read their history from the device, never the server.
final class MirrorSyncRepository implements MirrorRepository {
  MirrorSyncRepository(
    this._mailbox,
    this._documents,
    this._history, {
    required this.collects,
    this.historyCheckInterval = const Duration(seconds: 2),
    this._ring,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _updates = StreamController<HistoryRecords>.broadcast(onListen: _open, onCancel: _close);
  }

  final PairMailbox _mailbox;
  final MirrorDocuments _documents;
  final MessageHistory _history;

  /// This device receives the pair's notifications, so it empties the mailbox.
  final bool collects;

  /// How often a sender's screens check history for writes made elsewhere: its background engine publishes from
  /// another isolate. A receiver writes its history only here, so it never needs to.
  final Duration historyCheckInterval;
  final DateTime Function() _clock;

  /// Rings the pair's doorbell (see Doorbell): a desktop then reads the mailbox at once instead of on its next check.
  final Future<void> Function()? _ring;

  late final StreamController<HistoryRecords> _updates;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _historyCheck;

  /// History as loaded, kept current with this instance's own writes; null until something watches it.
  HistoryRecords? _records;

  /// The last [MessageHistory.revision] this instance wrote or read.
  String? _revision;

  /// Pending replies as the sender read them, until it reports their outcome.
  final _pending = <String, StoredReply>{};

  /// Mailbox work and history reloads run one at a time, so snapshots arriving together do not interleave.
  Future<void> _queue = Future.value();

  /// Counts each start and stop of watching, so work queued for an earlier watch does nothing.
  var _generation = 0;
  var _watching = false;
  var _deleteRefused = false;

  // ------------------------------------------------------------------ sender

  @override
  Future<void> publish(NotificationContent content, {required bool canReply}) async {
    final data = await _documents.notification(content, canReply: canReply);
    final id = _mailbox.newId();
    await _mailbox.create(FirestoreSchema.notifications, id, data);
    final keyHash = data['keyHash']! as String;
    await _saveNotifications([
      StoredNotification(
        id: id,
        payload: data['payload']! as String,
        postedAt: content.postedAt,
        keyHash: keyHash,
        canReply: canReply,
      ),
    ]);
    await _history.notePublished(keyHash);
    _ringBell();
  }

  @override
  Future<void> markDismissed(String notificationKey) async {
    final keyHash = await _documents.keyHash(notificationKey);
    // Only notifications that were mirrored, and only once per post: most removals are of other apps' notices.
    if (!await _history.takePublished(keyHash)) return;
    final at = _clock();
    await _mailbox.create(FirestoreSchema.dismissals, _mailbox.newId(), _documents.dismissal(keyHash, at));
    await _save(() => _history.putDismissals({keyHash: at}), (records) => records.dismissals[keyHash] = at);
    _ringBell();
  }

  static final _pendingFilter = (field: 'status', value: ReplyStatus.pending.wire);

  @override
  Stream<List<PendingReply>> watchPending() =>
      _mailbox.watch(FirestoreSchema.replies, where: _pendingFilter).asyncMap(_decodePending);

  @override
  Future<List<PendingReply>> fetchPending() async =>
      _decodePending(await _mailbox.fetch(FirestoreSchema.replies, where: _pendingFilter));

  @override
  Future<void> resolve(String replyId, ReplyStatus status) async {
    await _mailbox.update(FirestoreSchema.replies, replyId, MirrorDocuments.resolved(status));
    _ringBell();
    if (_pending.remove(replyId) case final reply?) await _saveReplies([reply.withStatus(status)]);
  }

  Future<List<PendingReply>> _decodePending(List<MailboxDocument> docs) async {
    final pending = <PendingReply>[];
    final kept = <StoredReply>[];
    for (final doc in docs) {
      final reply = await _documents.readPending(doc.id, doc.data);
      if (reply == null) {
        await resolve(doc.id, ReplyStatus.failed); // never executable: take it out of the queue
        continue;
      }
      pending.add(reply);
      if (_pending.containsKey(doc.id)) continue; // kept already, from an earlier snapshot
      if (_storedReply(doc) case final stored?) {
        _pending[doc.id] = stored;
        kept.add(stored);
      }
    }
    // the sender keeps the replies it was asked to send, as the receiver does
    await _saveReplies(kept);
    return pending;
  }

  // ------------------------------------------------------------------ receiver

  @override
  Stream<List<MirroredNotification>> watchNotifications({int limit = 2000}) =>
      _watchHistory().asyncMap((records) async {
        final stored = records.notifications.values.toList()..sort((a, b) => b.postedAt.compareTo(a.postedAt));
        return [for (final n in stored.take(limit)) ?await _readNotification(n, dismissed: records.isDismissed(n))];
      });

  @override
  Stream<List<ReplyCommand>> watchReplies({int limit = 1000}) => _watchHistory().asyncMap((records) async {
    final stored = records.replies.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [for (final r in stored.take(limit)) ?await _readReply(r)];
  });

  @override
  Stream<SyncState> watchSyncState() => _mailbox.watchSyncState();

  @override
  Future<MirroredNotification?> fetchNotification(String id) async {
    // Delivered already: it is only on this device now.
    if (await _history.notification(id) case final stored?) {
      return _readNotification(stored, dismissed: stored.dismissed);
    }
    final doc = await _mailbox.get(FirestoreSchema.notifications, id);
    return doc == null ? null : _documents.readNotification(doc.id, doc.data);
  }

  @override
  Future<HistoryPage> browseHistory(HistoryQuery query, {HistoryCursor? after, int limit = 50}) async {
    final saved = await _history.saved();
    final stored = await _history.page(
      text: query.text.trim().toLowerCase(),
      packageName: query.packageName,
      after: query.after,
      savedUpTo: query.savedUpTo ?? saved,
      savedAfter: query.savedAfter,
      cursor: after,
      limit: limit,
    );
    final dismissed = HistoryRecords(dismissals: _records?.dismissals ?? await _history.dismissals());
    final replies = await _history.repliesTo(stored.map((n) => n.id));
    return (
      notifications: [for (final n in stored) ?await _readNotification(n, dismissed: dismissed.isDismissed(n))],
      replies: [for (final r in replies) ?await _readReply(r)],
      next: stored.length < limit ? null : (postedAt: stored.last.postedAt, id: stored.last.id),
      saved: query.savedUpTo ?? saved,
    );
  }

  @override
  Future<int> countHistory(HistoryQuery query) => _history.count(
    text: query.text.trim().toLowerCase(),
    packageName: query.packageName,
    after: query.after,
    savedUpTo: query.savedUpTo,
    savedAfter: query.savedAfter,
  );

  @override
  Future<MirroredNotification?> decodePushed({required String id, required String payload, required bool canReply}) =>
      _documents.readPushed(id: id, payload: payload, canReply: canReply);

  @override
  Future<void> send({required String notificationId, required String notificationKey, required String text}) async {
    final data = await _documents.reply(notificationId: notificationId, notificationKey: notificationKey, text: text);
    final reply = _storedReply((id: _mailbox.newId(), data: data))!;
    // Shown at once, as waiting: offline, the server write only completes once the connection is back.
    await _saveReplies([reply]);
    try {
      await _mailbox.create(FirestoreSchema.replies, reply.id, data);
    } on Object {
      await _saveReplies([reply.withStatus(ReplyStatus.failed)]);
      rethrow;
    }
  }

  // ------------------------------------------------------------------ collecting the mailbox

  void _collectNotifications(List<MailboxDocument> docs) => _serially(() async {
    if (docs.isEmpty) return;
    final known = _records?.notifications ?? const {};
    await _saveNotifications([
      for (final doc in docs)
        if (!known.containsKey(doc.id)) ?_storedNotification(doc),
    ]);
    await _deliver(FirestoreSchema.notifications, docs.map((d) => d.id));
  });

  void _collectReplies(List<MailboxDocument> docs) => _serially(() async {
    if (docs.isEmpty) return;
    final known = _records?.replies ?? const {};
    final stored = [for (final doc in docs) ?_storedReply(doc)];
    await _saveReplies([
      for (final r in stored)
        if (known[r.id]?.status != r.status) r,
    ]);
    // A reply waits in the mailbox until the sender has said how it went; then only this device needs it.
    await _deliver(FirestoreSchema.replies, [
      for (final r in stored)
        if (r.status.isFinal) r.id,
    ]);
  });

  void _collectDismissals(List<MailboxDocument> docs) => _serially(() async {
    if (docs.isEmpty) return;
    final dismissals = <String, DateTime>{
      for (final doc in docs)
        if ((doc.data['keyHash'], doc.data['at']) case (final String keyHash, final DateTime at)) keyHash: at,
    };
    if (dismissals.isNotEmpty) {
      await _save(() => _history.putDismissals(dismissals), (records) => records.dismissals.addAll(dismissals));
    }
    await _deliver(FirestoreSchema.dismissals, docs.map((d) => d.id));
  });

  /// Deletes what this device now keeps, without waiting: offline, a delete only completes once the connection is
  /// back, and the next snapshot already leaves it out. If the server refuses, the history is safe here anyway, and
  /// the document is collected again and deleted next time.
  Future<void> _deliver(String collection, Iterable<String> ids) async {
    final all = ids.toList();
    if (all.isEmpty) return;
    unawaited(
      _mailbox.delete(collection, all).catchError((Object e) {
        if (!_deleteRefused) appLog('Could not clear delivered $collection: $e', name: 'air_reply.sync');
        _deleteRefused = true;
      }),
    );
  }

  // ------------------------------------------------------------------ history

  /// The history, now and each time it changes. Watching it is what starts collecting the mailbox.
  Stream<HistoryRecords> _watchHistory() {
    late final StreamController<HistoryRecords> out;
    StreamSubscription<HistoryRecords>? updates;
    out = StreamController<HistoryRecords>(
      onListen: () {
        updates = _updates.stream.listen(out.add, onError: out.addError);
        if (_records case final records?) out.add(records);
      },
      onCancel: () => updates?.cancel(),
    );
    return out.stream;
  }

  void _open() {
    _watching = true;
    final generation = ++_generation;
    bool current() => _watching && generation == _generation;
    _serially(() async {
      if (!current()) return;
      try {
        await _reload();
      } on Object catch (e, st) {
        _updates.addError(e, st);
        return;
      }
      if (!current()) return;
      if (collects) {
        void log(Object e) => appLog('Mailbox unavailable: $e', name: 'air_reply.sync');
        _subscriptions.addAll([
          _mailbox.watch(FirestoreSchema.notifications).listen(_collectNotifications, onError: log),
          // a dismissal only greys out the reply box: no hurry
          _mailbox.watch(FirestoreSchema.dismissals, urgent: false).listen(_collectDismissals, onError: log),
          _mailbox.watch(FirestoreSchema.replies).listen(_collectReplies, onError: log),
        ]);
      }
      if (!collects) _historyCheck = Timer.periodic(historyCheckInterval, (_) => _serially(_reloadIfChanged));
      _serially(_indexUnsearchable);
    });
  }

  void _close() {
    _watching = false;
    _generation++;
    _historyCheck?.cancel();
    _historyCheck = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _records = null;
  }

  /// After the server has a write: a lost ring only delays the desktop until its next check.
  void _ringBell() {
    final ring = _ring;
    if (ring == null) return;
    unawaited(
      ring().catchError((Object e) {
        appLog('Could not ring the doorbell: $e', name: 'air_reply.sync');
      }),
    );
  }

  /// Stops everything this sync runs; it is not used again.
  void dispose() {
    _close();
    unawaited(_updates.close());
  }

  Future<void> _reload() async {
    final records = await _history.load();
    _revision = await _history.revision();
    if (!_watching) return;
    _records = records;
    _updates.add(records);
  }

  Future<void> _reloadIfChanged() async {
    if (_records == null || await _history.revision() == _revision) return;
    await _reload();
  }

  Future<void> _saveNotifications(List<StoredNotification> items) async {
    if (items.isEmpty) return;
    await _save(() => _history.putNotifications(items), (records) {
      for (final n in items) {
        records.notifications[n.id] = n;
      }
    });
    await _makeSearchable(items);
  }

  /// Indexes [items] for search: their text and app. An unreadable one gets an empty app, so it is not tried again.
  Future<void> _makeSearchable(List<StoredNotification> items) async => _history.index({
    for (final n in items)
      n.id: switch (await _readNotification(n, dismissed: false)) {
        final notification? => (
          content: searchText(notification.content),
          packageName: notification.content.packageName,
        ),
        null => (content: '', packageName: ''),
      },
  });

  /// History kept before search existed becomes searchable, newest first, a batch at a time.
  Future<void> _indexUnsearchable() async {
    for (var batch = await _history.unindexed(); batch.isNotEmpty; batch = await _history.unindexed()) {
      if (!_watching) return;
      await _makeSearchable(batch);
    }
  }

  /// What a notification is found by: as the inbox's search matches it (title, text and app), lower-cased.
  static String searchText(NotificationContent content) =>
      '${content.title}\n${content.text}\n${content.appName}'.toLowerCase();

  Future<void> _saveReplies(List<StoredReply> items) async {
    if (items.isEmpty) return;
    await _save(() => _history.putReplies(items), (records) {
      for (final r in items) {
        records.replies[r.id] = r;
      }
    });
  }

  /// Writes to the device, then to the loaded copy (when something is watching it) and tells the watchers.
  Future<void> _save(Future<String> Function() write, void Function(HistoryRecords records) apply) async {
    final revision = await write();
    final records = _records;
    if (records == null) return;
    apply(records);
    _revision = revision;
    _updates.add(records);
  }

  void _serially(Future<void> Function() task) {
    _queue = _queue.then((_) => task()).catchError((Object e, StackTrace st) {
      appLog('History sync failed', error: e, stackTrace: st, name: 'air_reply.sync');
    });
  }

  // ------------------------------------------------------------------ documents

  Future<MirroredNotification?> _readNotification(StoredNotification n, {required bool dismissed}) =>
      _documents.readNotification(n.id, {'payload': n.payload, 'canReply': n.canReply, 'dismissedOnSender': dismissed});

  Future<ReplyCommand?> _readReply(StoredReply r) => _documents.readReply(r.id, {
    'notificationId': r.notificationId,
    'payload': r.payload,
    'status': r.status.wire,
    'createdAt': r.createdAt,
  });

  StoredNotification? _storedNotification(MailboxDocument doc) {
    final payload = doc.data['payload'];
    if (payload is! String) return null;
    return StoredNotification(
      id: doc.id,
      payload: payload,
      postedAt: doc.data['postedAt'] as DateTime? ?? _clock(),
      keyHash: doc.data['keyHash'] as String?,
      canReply: doc.data['canReply'] == true,
      dismissed: doc.data['dismissedOnSender'] == true,
    );
  }

  StoredReply? _storedReply(MailboxDocument doc) {
    final (payload, notificationId) = (doc.data['payload'], doc.data['notificationId']);
    if (payload is! String || notificationId is! String) return null;
    return StoredReply(
      id: doc.id,
      notificationId: notificationId,
      payload: payload,
      status: ReplyStatus.parse(doc.data['status']),
      createdAt: doc.data['createdAt'] as DateTime? ?? _clock(),
    );
  }
}
