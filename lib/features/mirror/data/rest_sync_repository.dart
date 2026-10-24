import 'dart:async';

import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/firebase/firestore_schema.dart';
import 'package:air_reply/core/firebase/rest/firestore_rest_client.dart';
import 'package:air_reply/core/firebase/rest/polling.dart';
import 'package:air_reply/features/mirror/data/mirror_documents.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';

/// [MirrorRepository] for one pair over the Firestore REST API (Windows, Linux).
///
/// The feed is kept as a local copy refreshed by polling only documents whose server-set `updatedAt` moved, so an
/// idle poll costs a single document read rather than the whole feed.
final class RestSyncRepository implements MirrorRepository {
  RestSyncRepository(
    this._client,
    this._pairId,
    this._documents, {
    this.feedPollInterval = const Duration(seconds: 3),
    this.pendingPollInterval = const Duration(seconds: 4),
    this.syncCheckInterval = const Duration(seconds: 30),
  });

  final FirestoreRestClient _client;
  final String _pairId;
  final MirrorDocuments _documents;
  final Duration feedPollInterval;
  final Duration pendingPollInterval;
  final Duration syncCheckInterval;

  String get _parent => '${FirestoreSchema.pairs}/$_pairId';

  String _doc(String collection, String id) => '$_parent/$collection/$id';

  // ------------------------------------------------------------------ sender

  @override
  Future<void> publish(NotificationContent content, {required bool canReply}) async {
    final data = await _documents.notification(content, canReply: canReply);
    await _guard(
      () => _client.commit([
        RestWrite.set(_doc(FirestoreSchema.notifications, _client.newId()), data, mustNotExist: true),
      ]),
    );
  }

  @override
  Future<void> markDismissed(String notificationKey) async {
    final keyHash = await _documents.keyHash(notificationKey);
    final open = await _guard(
      () => _client.runQuery(
        RestQuery(
          FirestoreSchema.notifications,
          filters: [
            RestFilter('keyHash', RestOperator.equal, keyHash),
            const RestFilter('dismissedOnSender', RestOperator.equal, false),
          ],
        ),
        parent: _parent,
      ),
    );
    if (open.isEmpty) return;
    await _guard(
      () => _client.commit([for (final doc in open) RestWrite.update(doc.path, MirrorDocuments.dismissed())]),
    );
  }

  @override
  Stream<List<PendingReply>> watchPending() {
    String? lastIds;
    return pollingStream(() async {
      final pending = await fetchPending();
      final ids = pending.map((r) => r.id).join(',');
      if (ids == lastIds) return null;
      lastIds = ids;
      return pending;
    }, every: pendingPollInterval);
  }

  @override
  Future<List<PendingReply>> fetchPending() async {
    final docs = await _guard(
      () => _client.runQuery(
        RestQuery(
          FirestoreSchema.replies,
          filters: [RestFilter('status', RestOperator.equal, ReplyStatus.pending.wire)],
        ),
        parent: _parent,
      ),
    );
    final pending = <PendingReply>[];
    for (final doc in docs) {
      final reply = await _documents.readPending(doc.id, doc.data);
      if (reply == null) {
        await resolve(doc.id, ReplyStatus.failed); // never executable: take it out of the queue
      } else {
        pending.add(reply);
      }
    }
    return pending;
  }

  @override
  Future<void> resolve(String replyId, ReplyStatus status) => _guard(
    () => _client.commit([RestWrite.update(_doc(FirestoreSchema.replies, replyId), MirrorDocuments.resolved(status))]),
  );

  // ------------------------------------------------------------------ receiver

  @override
  Stream<List<MirroredNotification>> watchNotifications({int limit = 200}) {
    final mirror = _IncrementalCollection(_client, _parent, FirestoreSchema.notifications, recentFirst: 'postedAt');
    return pollingStream(() async {
      if (!await mirror.refresh(limit)) return null;
      final items = <MirroredNotification>[];
      for (final doc in mirror.documents) {
        if (await _documents.readNotification(doc.id, doc.data) case final item?) items.add(item);
      }
      items.sort((a, b) => b.postedAt.compareTo(a.postedAt));
      return items.take(limit).toList();
    }, every: feedPollInterval);
  }

  @override
  Stream<List<ReplyCommand>> watchReplies({int limit = 300}) {
    final mirror = _IncrementalCollection(_client, _parent, FirestoreSchema.replies, recentFirst: 'createdAt');
    return pollingStream(() async {
      if (!await mirror.refresh(limit)) return null;
      final replies = <ReplyCommand>[];
      for (final doc in mirror.documents) {
        if (await _documents.readReply(doc.id, doc.data) case final reply?) replies.add(reply);
      }
      replies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return replies.take(limit).toList();
    }, every: feedPollInterval);
  }

  @override
  Stream<SyncState> watchSyncState() {
    var state = SyncState.connecting;
    final controller = StreamController<SyncState>();
    Timer? timer;
    Future<void> check() async {
      try {
        await _client.get(_parent);
        state = state.next(fromServer: true, now: DateTime.now());
      } on Object {
        state = state.next(fromServer: false, now: DateTime.now());
      }
      if (controller.isClosed) return;
      controller.add(state);
      timer = Timer(syncCheckInterval, check);
    }

    controller
      ..onListen = check
      ..onCancel = () => timer?.cancel();
    return controller.stream;
  }

  @override
  Future<MirroredNotification?> fetchNotification(String id) async {
    final doc = await _guard(() => _client.get(_doc(FirestoreSchema.notifications, id)));
    return doc == null ? null : _documents.readNotification(id, doc.data);
  }

  @override
  Future<MirroredNotification?> decodePushed({required String id, required String payload, required bool canReply}) =>
      _documents.readPushed(id: id, payload: payload, canReply: canReply);

  @override
  Future<void> send({required String notificationId, required String notificationKey, required String text}) async {
    final data = await _documents.reply(notificationId: notificationId, notificationKey: notificationKey, text: text);
    await _guard(
      () => _client.commit([RestWrite.set(_doc(FirestoreSchema.replies, _client.newId()), data, mustNotExist: true)]),
    );
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on RestFirestoreException catch (e) {
      throw SyncException('Sync with your paired device failed (${e.status}).', cause: e);
    }
  }
}

/// A local copy of the most recent documents of one collection, kept current by polling only documents whose
/// server-set `updatedAt` is at or after the newest one already seen.
final class _IncrementalCollection {
  _IncrementalCollection(this._client, this._parent, this._collection, {required this.recentFirst});

  final FirestoreRestClient _client;
  final String _parent;
  final String _collection;

  /// Field ordering the first, full load (newest first).
  final String recentFirst;

  final _docs = <String, RestDocument>{};
  DateTime? _cursor;
  var _loaded = false;

  Iterable<RestDocument> get documents => _docs.values;

  /// Returns true when the copy changed (always on the first load, so an empty feed is still reported once).
  Future<bool> refresh(int limit) async {
    final changed = await _client.runQuery(
      _cursor == null
          ? RestQuery(_collection, orderBy: recentFirst, descending: true, limit: limit)
          : RestQuery(
              _collection,
              filters: [RestFilter('updatedAt', RestOperator.greaterThanOrEqual, _cursor)],
              orderBy: 'updatedAt',
              limit: 500,
            ),
      parent: _parent,
    );

    var dirty = !_loaded;
    _loaded = true;
    for (final doc in changed) {
      if (_docs[doc.id]?.updateTime == doc.updateTime) continue; // the boundary document, unchanged
      _docs[doc.id] = doc;
      dirty = true;
      if (doc.data['updatedAt'] case final DateTime updatedAt when _cursor == null || updatedAt.isAfter(_cursor!)) {
        _cursor = updatedAt;
      }
    }
    _trim(limit);
    return dirty;
  }

  /// Older documents that were edited (e.g. dismissed) come back through the cursor; keep the copy bounded.
  void _trim(int limit) {
    if (_docs.length <= limit * 2) return;
    final byAge = _docs.values.toList()
      ..sort((a, b) => _time(b.data[recentFirst]).compareTo(_time(a.data[recentFirst])));
    for (final doc in byAge.skip(limit)) {
      _docs.remove(doc.id);
    }
  }

  static DateTime _time(Object? value) => value is DateTime ? value : DateTime.fromMillisecondsSinceEpoch(0);
}
