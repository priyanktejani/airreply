import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/firebase/auth_gateway.dart';
import 'package:air_reply/core/firebase/firestore_schema.dart';
import 'package:air_reply/core/firebase/rest/document_polls.dart';
import 'package:air_reply/core/firebase/rest/firestore_rest_client.dart';
import 'package:air_reply/core/firebase/rest/polling.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/pairing/data/pairing_documents.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';

/// [PairingRepository] over the Firestore REST API (Windows, Linux). Transactions become conditional writes on the
/// document version; listeners become polling.
final class RestPairingRepository implements PairingRepository {
  RestPairingRepository(
    this._client,
    this._auth, {
    Random? random,
    DateTime Function()? clock,
    this.sessionPollInterval = const Duration(seconds: 2),
    DocumentPolls? pairPolls,
  }) : _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now,
       _pairPolls = pairPolls ?? DocumentPolls(_client);

  static const _maxCodeAttempts = 6;

  final FirestoreRestClient _client;
  final AuthGateway _auth;
  final Random _random;
  final DateTime Function() _clock;
  final Duration sessionPollInterval;

  /// The pair documents, polled once for this and the connection status alike (see [RestMailbox]).
  final DocumentPolls _pairPolls;

  static String _session(String code) => '${FirestoreSchema.pairingSessions}/$code';

  static String _pair(String pairId) => '${FirestoreSchema.pairs}/$pairId';

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
      try {
        await _client.commit([RestWrite.set(_session(code), data, mustNotExist: true)]);
        return PairingDocuments.session(code, data)!;
      } on RestFirestoreException catch (e) {
        if (e.status != 'ALREADY_EXISTS') throw _mapped(e);
      }
    }
    throw const PairingException(AppError.pairingCodeNotCreated);
  }

  @override
  Future<PairingSession?> fetchSession(String code) async {
    await _auth.ensureSignedIn();
    final doc = await _guard(() => _client.get(_session(code)));
    return PairingDocuments.session(code, doc?.data);
  }

  @override
  Stream<PairingSession?> watchSession(String code) {
    String? lastVersion;
    return pollingStream(() async {
      final doc = await _client.get(_session(code));
      final version = doc?.updateTime.toIso8601String() ?? 'gone';
      if (version == lastVersion) return null;
      lastVersion = version;
      return _Box(PairingDocuments.session(code, doc?.data));
    }, every: sessionPollInterval).map((box) => box.value);
  }

  @override
  Future<PairingSession> joinSession({
    required String code,
    required Uint8List receiverPublicKey,
    required String receiverName,
  }) async {
    final uid = await _auth.ensureSignedIn();
    final doc = await _guard(() => _client.get(_session(code)));
    final session = PairingDocuments.session(code, doc?.data);
    if (session == null || session.status != PairingStatus.waiting || session.isExpiredAt(_clock())) {
      throw const PairingException(AppError.codeUnavailable);
    }
    if (session.senderUid == uid) throw const PairingException(AppError.cannotPairWithItself);

    try {
      // Only succeeds if nobody changed the session since we read it: the REST equivalent of a transaction.
      await _client.commit([
        RestWrite.update(
          _session(code),
          PairingDocuments.joined(receiverUid: uid, receiverName: receiverName, receiverPublicKey: receiverPublicKey),
          ifUpdateTime: doc!.updateTime,
        ),
      ]);
    } on RestFirestoreException catch (e) {
      if (e.status == 'FAILED_PRECONDITION') throw const PairingException(AppError.codeAlreadyUsed);
      throw _mapped(e);
    }
    return PairingDocuments.withReceiver(
      session,
      receiverUid: uid,
      receiverName: receiverName,
      receiverPublicKey: receiverPublicKey,
    );
  }

  @override
  Future<String> confirmSession(PairingSession session) async {
    final uid = await _auth.ensureSignedIn();
    if (session.receiverUid == null || session.senderUid != uid) {
      throw const PairingException(AppError.sessionNotConfirmable);
    }
    final pairId = _client.newId();
    await _guard(
      () => _client.commit([
        RestWrite.set(_pair(pairId), PairingDocuments.pair(session), mustNotExist: true),
        RestWrite.update(_session(session.code), PairingDocuments.confirmed(pairId)),
      ]),
    );
    return pairId;
  }

  @override
  Future<void> cancelSession(String code) => _guard(() => _client.commit([RestWrite.delete(_session(code))]));

  @override
  Stream<bool> watchPairActive(String pairId) => _pairPolls
      .watch(_pair(pairId))
      .expand<bool>(
        (read) => switch (read) {
          (document: final pair?, error: null) => [PairingDocuments.isActive(pair.data)],
          (document: null, error: null) => [false],
          // The pair (and with it our membership) was deleted.
          (error: RestFirestoreException(status: 'PERMISSION_DENIED'), document: _) => [false],
          // offline or a server hiccup: says nothing about the pair
          _ => const [],
        },
      )
      .distinct();

  @override
  Future<void> endPair(String pairId) async {
    // while still a member: the rules let only the pair's devices delete its messages
    try {
      for (final name in FirestoreSchema.mailboxes) {
        for (var docs = await _batch(pairId, name); docs.isNotEmpty; docs = await _batch(pairId, name)) {
          await _client.commit([for (final doc in docs) RestWrite.delete(doc.path)]);
        }
      }
    } on Object {
      // offline: the messages stay, sealed with a key no device holds any more, until they expire
    }
    await _guard(() => _client.commit([RestWrite.update(_pair(pairId), PairingDocuments.deactivated())]));
    await _guard(() => _client.commit([RestWrite.delete(_pair(pairId))]));
  }

  Future<List<RestDocument>> _batch(String pairId, String mailbox) =>
      _client.runQuery(RestQuery(mailbox, limit: 300), parent: _pair(pairId));

  @override
  Future<void> registerPushToken({required String pairId, required DeviceRole role, required String token}) => _guard(
    () => _client.commit([RestWrite.update(_pair(pairId), PairingDocuments.pushToken(role, token, AppPlatform.name))]),
  );

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on RestFirestoreException catch (e) {
      throw _mapped(e);
    }
  }

  static AppException _mapped(RestFirestoreException e) => switch (e.status) {
    'PERMISSION_DENIED' => SyncException(AppError.pairingNotAvailable, cause: e),
    'UNAVAILABLE' => SyncException(AppError.offline, cause: e),
    _ => SyncException(AppError.pairingServerFailed, detail: e.status, cause: e),
  };
}

/// Lets a stream of nullable values go through [pollingStream], where null means "no change".
final class _Box<T> {
  const _Box(this.value);
  final T value;
}
