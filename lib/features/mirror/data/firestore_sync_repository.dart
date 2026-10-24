import 'dart:async';

import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/firebase/firestore_schema.dart';
import 'package:air_reply/core/firebase/sdk_values.dart';
import 'package:air_reply/features/mirror/data/mirror_documents.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// [MirrorRepository] for one pair on FlutterFire (Android, iOS, macOS, web): realtime listeners, offline cache.
/// Firestore only ever sees ciphertext plus the flags needed to query.
final class FirestoreSyncRepository implements MirrorRepository {
  FirestoreSyncRepository(this._db, this._pairId, this._documents);

  final FirebaseFirestore _db;
  final String _pairId;
  final MirrorDocuments _documents;

  DocumentReference<Map<String, dynamic>> get _pair => _db.collection(FirestoreSchema.pairs).doc(_pairId);

  CollectionReference<Map<String, dynamic>> get _notifications => _pair.collection(FirestoreSchema.notifications);

  CollectionReference<Map<String, dynamic>> get _replies => _pair.collection(FirestoreSchema.replies);

  // ------------------------------------------------------------------ sender

  @override
  Future<void> publish(NotificationContent content, {required bool canReply}) async {
    final data = await _documents.notification(content, canReply: canReply);
    await _guard(() => _notifications.add(SdkValues.toSdk(data)));
  }

  @override
  Future<void> markDismissed(String notificationKey) async {
    final keyHash = await _documents.keyHash(notificationKey);
    final open = await _guard(
      () => _notifications.where('keyHash', isEqualTo: keyHash).where('dismissedOnSender', isEqualTo: false).get(),
    );
    if (open.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in open.docs) {
      batch.update(doc.reference, SdkValues.toSdk(MirrorDocuments.dismissed()));
    }
    await _guard(batch.commit);
  }

  Query<Map<String, dynamic>> get _pendingQuery => _replies.where('status', isEqualTo: ReplyStatus.pending.wire);

  @override
  Stream<List<PendingReply>> watchPending() => _pendingQuery.snapshots().asyncMap((s) => _decodePending(s.docs));

  @override
  Future<List<PendingReply>> fetchPending() async =>
      _decodePending((await _guard(() => _pendingQuery.get(const GetOptions(source: Source.server)))).docs);

  @override
  Future<void> resolve(String replyId, ReplyStatus status) =>
      _guard(() => _replies.doc(replyId).update(SdkValues.toSdk(MirrorDocuments.resolved(status))));

  Future<List<PendingReply>> _decodePending(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final pending = <PendingReply>[];
    for (final doc in docs) {
      final reply = await _documents.readPending(doc.id, SdkValues.fromSdk(doc.data()));
      if (reply == null) {
        await resolve(doc.id, ReplyStatus.failed); // never executable: take it out of the queue
      } else {
        pending.add(reply);
      }
    }
    return pending;
  }

  // ------------------------------------------------------------------ receiver

  @override
  Stream<List<MirroredNotification>> watchNotifications({int limit = 200}) => _notifications
      .orderBy('postedAt', descending: true)
      .limit(limit)
      .snapshots()
      .asyncMap(
        (s) async => [
          for (final doc in s.docs) ?await _documents.readNotification(doc.id, SdkValues.fromSdk(doc.data())),
        ],
      );

  @override
  Stream<List<ReplyCommand>> watchReplies({int limit = 300}) => _replies
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .asyncMap(
        (s) async => [for (final doc in s.docs) ?await _documents.readReply(doc.id, SdkValues.fromSdk(doc.data()))],
      );

  @override
  Stream<SyncState> watchSyncState() {
    var state = SyncState.connecting;
    // Cheapest possible listener (one document) whose metadata says whether the server is reachable.
    return _notifications
        .limit(1)
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

  @override
  Future<MirroredNotification?> fetchNotification(String id) async {
    final doc = await _guard(() => _notifications.doc(id).get());
    return doc.exists ? _documents.readNotification(id, SdkValues.fromSdk(doc.data())) : null;
  }

  @override
  Future<MirroredNotification?> decodePushed({required String id, required String payload, required bool canReply}) =>
      _documents.readPushed(id: id, payload: payload, canReply: canReply);

  @override
  Future<void> send({required String notificationId, required String notificationKey, required String text}) async {
    final data = await _documents.reply(notificationId: notificationId, notificationKey: notificationKey, text: text);
    await _guard(() => _replies.add(SdkValues.toSdk(data)));
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseException catch (e) {
      throw SyncException('Sync with your paired device failed (${e.code}).', cause: e);
    }
  }
}
