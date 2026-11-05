import 'dart:convert';
import 'dart:typed_data';

import 'package:air_reply/core/crypto/crypto_contracts.dart';
import 'package:air_reply/core/device/device_identity.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_invite.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';

/// The receiver's side of a session it joined, waiting for the sender to confirm.
final class JoinedPairing {
  const JoinedPairing({required this.session, required this.secrets});

  final PairingSession session;
  final PairingSecrets secrets;
}

/// Receiver, step 1: join by QR (code + sender key) or by typed code, and derive the shared key.
final class JoinPairingSession {
  const JoinPairingSession(this._repository, this._keys, this._device, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final PairingRepository _repository;
  final KeyAgreement _keys;
  final DeviceIdentity _device;
  final DateTime Function() _clock;

  Future<JoinedPairing> call({required String code, Uint8List? expectedSenderKey}) async {
    if (!PairingInvite.isValidCode(code)) throw const ValidationException(AppError.codeFormat);

    final existing = await _repository.fetchSession(code);
    if (existing == null || existing.status == PairingStatus.cancelled) {
      throw const PairingException(AppError.codeNotFound);
    }
    if (existing.isExpiredAt(_clock())) throw const PairingException(AppError.codeExpired);
    if (existing.status != PairingStatus.waiting) throw const PairingException(AppError.codeAlreadyUsed);
    if (expectedSenderKey != null && !_sameBytes(existing.senderPublicKey, expectedSenderKey)) {
      throw const PairingException(AppError.qrMismatch);
    }

    final keyPair = await _keys.generateKeyPair();
    final joined = await _repository.joinSession(
      code: code,
      receiverPublicKey: keyPair.publicKey,
      receiverName: await _device.displayName(),
    );
    final secrets = await _keys.deriveSecrets(
      own: keyPair,
      peerPublicKey: joined.senderPublicKey,
      code: code,
      senderPublicKey: joined.senderPublicKey,
      receiverPublicKey: keyPair.publicKey,
    );
    return JoinedPairing(session: joined, secrets: secrets);
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// Receiver, step 2: the sender confirmed; store the key under the new pair id, then acknowledge it, so the phone
/// shows paired only once this device kept the pair too. The acknowledgement is retried a few times; if it never
/// gets through, the phone asks its person what to do.
final class FinishReceiverPairing {
  const FinishReceiverPairing(
    this._store,
    this._repository, {
    DateTime Function()? clock,
    this.retryDelay = const Duration(seconds: 2),
    this.serverTimeout = const Duration(seconds: 10),
  }) : _clock = clock ?? DateTime.now;

  final PairingCredentialsStore _store;
  final PairingRepository _repository;
  final DateTime Function() _clock;
  final Duration retryDelay;
  final Duration serverTimeout;

  Future<PairingCredentials> call(JoinedPairing joined, PairingSession confirmed) =>
      finish(joined.secrets.sharedKey, confirmed);

  /// [sharedKey] is the key agreed when this device joined [confirmed].
  Future<PairingCredentials> finish(Uint8List sharedKey, PairingSession confirmed) async {
    final pairId = confirmed.pairId;
    if (confirmed.status != PairingStatus.confirmed || pairId == null) {
      throw const PairingException(AppError.notConfirmedYet);
    }
    final credentials = PairingCredentials(
      pairId: pairId,
      role: DeviceRole.receiver,
      sharedKey: sharedKey,
      peerName: confirmed.senderName,
      pairedAt: _clock(),
      peerUid: confirmed.senderUid,
    );
    await _store.save(credentials);
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _repository.markReady(pairId, DeviceRole.receiver).timeout(serverTimeout);
        break;
      } on Object catch (e) {
        appLog('Pair $pairId not acknowledged yet (attempt $attempt): $e', name: 'air_reply.pairing');
        if (attempt < 3) await Future<void>.delayed(retryDelay * attempt);
      }
    }
    return credentials;
  }
}

/// A join this device made, kept until the sender confirms it: if the app is closed meanwhile, the next start finishes
/// pairing (see [ResumeReceiverPairing]) instead of leaving the phone paired with a device that never knew.
final class PendingJoin {
  const PendingJoin({required this.code, required this.sharedKey});

  factory PendingJoin.fromJson(Map<String, Object?> json) =>
      PendingJoin(code: json['code']! as String, sharedKey: base64.decode(json['key']! as String));

  final String code;
  final Uint8List sharedKey;

  Map<String, Object?> toJson() => {'code': code, 'key': base64.encode(sharedKey)};
}

/// Where the [PendingJoin] waits, beside the pairs' keys.
abstract interface class PendingJoinStore {
  Future<PendingJoin?> read();

  Future<void> save(PendingJoin join);

  Future<void> clear();
}

/// On start: a pairing this device joined, which the sender confirmed while the app was closed, is finished now.
/// One that was cancelled, expired or is gone is forgotten; one still waiting for the sender is kept.
final class ResumeReceiverPairing {
  const ResumeReceiverPairing(this._pending, this._repository, this._finish, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final PendingJoinStore _pending;
  final PairingRepository _repository;
  final FinishReceiverPairing _finish;
  final DateTime Function() _clock;

  /// The pair, when one was finished.
  Future<PairingCredentials?> call() async {
    final join = await _pending.read();
    if (join == null) return null;
    final PairingSession? session;
    try {
      session = await _repository.fetchSession(join.code);
    } on Object {
      return null; // offline: next start
    }
    if (session != null && session.status == PairingStatus.confirmed && session.pairId != null) {
      final credentials = await _finish.finish(join.sharedKey, session);
      await _pending.clear();
      try {
        await _repository.cancelSession(join.code);
      } on Object {
        // left for its expiry
      }
      return credentials;
    }
    final waiting = session != null && session.status == PairingStatus.joined && !session.isExpiredAt(_clock());
    if (!waiting) await _pending.clear();
    return null;
  }
}
