import 'dart:typed_data';

import 'package:air_reply/core/crypto/crypto_contracts.dart';
import 'package:air_reply/core/device/device_identity.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
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

/// Receiver, step 2: the sender confirmed; store the key under the new pair id.
final class FinishReceiverPairing {
  const FinishReceiverPairing(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final PairingCredentialsStore _store;
  final DateTime Function() _clock;

  Future<PairingCredentials> call(JoinedPairing joined, PairingSession confirmed) async {
    final pairId = confirmed.pairId;
    if (confirmed.status != PairingStatus.confirmed || pairId == null) {
      throw const PairingException(AppError.notConfirmedYet);
    }
    final credentials = PairingCredentials(
      pairId: pairId,
      role: DeviceRole.receiver,
      sharedKey: joined.secrets.sharedKey,
      peerName: confirmed.senderName,
      pairedAt: _clock(),
    );
    await _store.save(credentials);
    return credentials;
  }
}
