import 'dart:async';

import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/firebase/firestore_schema.dart';
import 'package:air_reply/core/firebase/sdk_values.dart';
import 'package:air_reply/features/mirror/data/pair_mailbox.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// [PairMailbox] for one pair on FlutterFire (Android, iOS, macOS, web): realtime listeners, offline cache.
final class FirestoreMailbox implements PairMailbox {
  FirestoreMailbox(this._db, this._pairId);

  /// Documents taken per snapshot; once they are delivered and deleted, the listener brings the next ones.
  static const batchSize = 300;

  /// Firestore's limit on writes in one batch.
  static const _maxBatchWrites = 500;

  final FirebaseFirestore _db;
  final String _pairId;

  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _db.collection(FirestoreSchema.pairs).doc(_pairId).collection(name);

  Query<Map<String, dynamic>> _query(String collection, MailboxFilter? where) {
    Query<Map<String, dynamic>> query = _collection(collection);
    if (where != null) query = query.where(where.field, isEqualTo: where.value);
    return query.limit(batchSize);
  }

  @override
  String newId() => _db.collection(FirestoreSchema.pairs).doc().id;

  @override
  Future<void> create(String collection, String id, Map<String, Object?> data) =>
      _guard(() => _collection(collection).doc(id).set(SdkValues.toSdk(data)));

  @override
  Future<void> update(String collection, String id, Map<String, Object?> data) =>
      _guard(() => _collection(collection).doc(id).update(SdkValues.toSdk(data)));

  @override
  Future<void> delete(String collection, Iterable<String> ids) async {
    final all = ids.toList();
    for (var start = 0; start < all.length; start += _maxBatchWrites) {
      final batch = _db.batch();
      for (final id in all.skip(start).take(_maxBatchWrites)) {
        batch.delete(_collection(collection).doc(id));
      }
      await _guard(batch.commit);
    }
  }

  @override
  Future<MailboxDocument?> get(String collection, String id) async {
    final doc = await _guard(() => _collection(collection).doc(id).get());
    return doc.exists ? (id: doc.id, data: SdkValues.fromSdk(doc.data())) : null;
  }

  @override
  Stream<List<MailboxDocument>> watch(String collection, {MailboxFilter? where, bool urgent = true}) =>
      _query(collection, where).snapshots().map(_documents);

  @override
  Future<List<MailboxDocument>> fetch(String collection, {MailboxFilter? where}) async =>
      _documents(await _guard(() => _query(collection, where).get(const GetOptions(source: Source.server))));

  @override
  Stream<SyncState> watchSyncState() {
    var state = SyncState.connecting;
    // The pair's own document, whose metadata says whether the server is reachable: the app listens to it anyway
    // (whether the pair is still active), so this adds no reads, and it rarely changes. A listener on the mailbox
    // would be read again for every message.
    return _db
        .collection(FirestoreSchema.pairs)
        .doc(_pairId)
        .snapshots(includeMetadataChanges: true)
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (s, sink) =>
                sink.add(state = state.next(fromServer: !s.metadata.isFromCache, now: DateTime.now())),
            // A listener the server refused (pair ended, rules) cannot sync: show it as offline, not as an error.
            handleError: (_, _, sink) => sink.add(state = state.next(fromServer: false, now: DateTime.now())),
          ),
        );
  }

  static List<MailboxDocument> _documents(QuerySnapshot<Map<String, dynamic>> snapshot) => [
    for (final doc in snapshot.docs) (id: doc.id, data: SdkValues.fromSdk(doc.data())),
  ];

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseException catch (e) {
      throw SyncException(AppError.syncFailed, detail: e.code, cause: e);
    }
  }
}
