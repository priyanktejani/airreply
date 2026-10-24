import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/firebase/auth_gateway.dart';
import 'package:air_reply/core/firebase/firestore_schema.dart';
import 'package:air_reply/core/firebase/sdk_values.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/pairing/data/pairing_documents.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// [PairingRepository] on FlutterFire (Android, iOS, macOS, web): realtime listeners and transactions.
final class FirestorePairingRepository implements PairingRepository {
  FirestorePairingRepository(this._db, this._auth, {Random? random, DateTime Function()? clock})
    : _random = random ?? Random.secure(),
      _clock = clock ?? DateTime.now;

  static const _maxCodeAttempts = 6;

  final FirebaseFirestore _db;
  final AuthGateway _auth;
  final Random _random;
  final DateTime Function() _clock;

  CollectionReference<Map<String, dynamic>> get _sessions => _db.collection(FirestoreSchema.pairingSessions);

  CollectionReference<Map<String, dynamic>> get _pairs => _db.collection(FirestoreSchema.pairs);

  @override
  Future<PairingSession> createSession({required Uint8List senderPublicKey, required String senderName}) async {
    final uid = await _auth.ensureSignedIn();
    final expiresAt = _clock().add(PairingSession.lifetime);
    final data = PairingDocuments.waitingSession(
      senderUid: uid,
      senderName: senderName,
      senderPublicKey: senderPublicKey,
      expiresAt: expiresAt,
    );
    for (var attempt = 0; attempt < _maxCodeAttempts; attempt++) {
      final code = _random.nextInt(1000000).toString().padLeft(6, '0');
      final ref = _sessions.doc(code);
      final created = await _guard(
        () => _db.runTransaction((tx) async {
          if ((await tx.get(ref)).exists) return false;
          tx.set(ref, SdkValues.toSdk(data));
          return true;
        }),
      );
      if (created) return PairingDocuments.session(code, data)!;
    }
    throw const PairingException('Could not create a pairing code. Please try again.');
  }

  @override
  Future<PairingSession?> fetchSession(String code) async {
    await _auth.ensureSignedIn();
    final snapshot = await _guard(() => _sessions.doc(code).get(const GetOptions(source: Source.server)));
    return PairingDocuments.session(code, snapshot.exists ? SdkValues.fromSdk(snapshot.data()) : null);
  }

  @override
  Stream<PairingSession?> watchSession(String code) => _sessions
      .doc(code)
      .snapshots()
      .map((s) => PairingDocuments.session(code, s.exists ? SdkValues.fromSdk(s.data()) : null));

  @override
  Future<PairingSession> joinSession({
    required String code,
    required Uint8List receiverPublicKey,
    required String receiverName,
  }) async {
    final uid = await _auth.ensureSignedIn();
    final ref = _sessions.doc(code);
    return _guard(
      () => _db.runTransaction((tx) async {
        final snapshot = await tx.get(ref);
        final session = PairingDocuments.session(code, snapshot.exists ? SdkValues.fromSdk(snapshot.data()) : null);
        _ensureJoinable(session, uid);
        tx.update(
          ref,
          PairingDocuments.joined(receiverUid: uid, receiverName: receiverName, receiverPublicKey: receiverPublicKey),
        );
        return PairingDocuments.withReceiver(
          session!,
          receiverUid: uid,
          receiverName: receiverName,
          receiverPublicKey: receiverPublicKey,
        );
      }),
    );
  }

  @override
  Future<String> confirmSession(PairingSession session) async {
    final uid = await _auth.ensureSignedIn();
    if (session.receiverUid == null || session.senderUid != uid) {
      throw const PairingException('This session cannot be confirmed.');
    }
    final pair = _pairs.doc();
    final batch = _db.batch()
      ..set(pair, SdkValues.toSdk(PairingDocuments.pair(session)))
      ..update(_sessions.doc(session.code), PairingDocuments.confirmed(pair.id));
    await _guard(batch.commit);
    return pair.id;
  }

  @override
  Future<void> cancelSession(String code) => _guard(() => _sessions.doc(code).delete());

  @override
  Stream<bool> watchPairActive(String pairId) => _pairs
      .doc(pairId)
      .snapshots(includeMetadataChanges: true)
      // A missing document read from the offline cache proves nothing; only trust the server.
      .where((s) => s.exists || !s.metadata.isFromCache)
      .map((s) => PairingDocuments.isActive(s.data()))
      .transform(
        StreamTransformer<bool, bool>.fromHandlers(
          handleError: (error, stackTrace, sink) {
            // The pair (and with it our membership) was deleted.
            if (error is FirebaseException && error.code == 'permission-denied') {
              sink.add(false);
            } else {
              sink.addError(error, stackTrace);
            }
          },
        ),
      )
      .distinct();

  @override
  Future<void> deactivatePair(String pairId) =>
      _guard(() => _pairs.doc(pairId).update(SdkValues.toSdk(PairingDocuments.deactivated())));

  @override
  Future<void> registerPushToken({required String pairId, required DeviceRole role, required String token}) =>
      _guard(() => _pairs.doc(pairId).update(PairingDocuments.pushToken(role, token, AppPlatform.name)));

  void _ensureJoinable(PairingSession? session, String uid) {
    if (session == null || session.status != PairingStatus.waiting || session.isExpiredAt(_clock())) {
      throw const PairingException('This code is no longer available. Make a new one on the other phone.');
    }
    if (session.senderUid == uid) throw const PairingException('A device cannot pair with itself.');
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw SyncException(switch (e.code) {
        'unavailable' => 'You appear to be offline. Check your connection and try again.',
        'permission-denied' => 'This pairing session is not available to this device.',
        _ => 'The server could not complete pairing (${e.code}).',
      }, cause: e);
    }
  }
}
