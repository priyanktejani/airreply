import 'dart:async';

import 'package:air_reply/core/crypto/crypto_contracts.dart';
import 'package:air_reply/core/device/device_identity.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_invite.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';

/// A session the sender opened, with the private half of its key pair (memory only).
final class PendingPairing {
  const PendingPairing({required this.keyPair, required this.session});

  final PairingKeyPair keyPair;
  final PairingSession session;

  PairingInvite get invite => PairingInvite(code: session.code, senderPublicKey: keyPair.publicKey);
}

/// Sender, step 1: new key pair + new session; the result's [PendingPairing.invite] is rendered as a QR.
final class StartPairingSession {
  const StartPairingSession(this._repository, this._keys, this._device);

  final PairingRepository _repository;
  final KeyAgreement _keys;
  final DeviceIdentity _device;

  Future<PendingPairing> call() async {
    final keyPair = await _keys.generateKeyPair();
    final session = await _repository.createSession(
      senderPublicKey: keyPair.publicKey,
      senderName: await _device.displayName(),
    );
    return PendingPairing(keyPair: keyPair, session: session);
  }
}

/// Sender, step 2: a receiver joined; derive the shared key and the code to compare on both screens.
final class DeriveSenderSecrets {
  const DeriveSenderSecrets(this._keys);

  final KeyAgreement _keys;

  Future<PairingSecrets> call(PendingPairing pending, PairingSession joined) {
    final receiverKey = joined.receiverPublicKey;
    if (joined.status != PairingStatus.joined || receiverKey == null) {
      throw const PairingException(AppError.noDeviceJoined);
    }
    return _keys.deriveSecrets(
      own: pending.keyPair,
      peerPublicKey: receiverKey,
      code: joined.code,
      senderPublicKey: pending.keyPair.publicKey,
      receiverPublicKey: receiverKey,
    );
  }
}

/// Sender, step 3: the person confirmed both screens show the same code. Creates the pair and stores the key.
///
/// The key is kept before the pair exists on the server: a confirmation that reaches the server late (a slow or
/// dropped connection) then never leaves the receiver paired with a phone that gave up. A confirmation the server
/// refuses takes the key away again. Then this phone acknowledges the pair, and waits for the receiver's
/// acknowledgement (see `PairingRepository.watchReady`) before calling it done.
final class ConfirmSenderPairing {
  const ConfirmSenderPairing(
    this._repository,
    this._store, {
    DateTime Function()? clock,
    this.serverTimeout = const Duration(seconds: 20),
  }) : _clock = clock ?? DateTime.now;

  final PairingRepository _repository;
  final PairingCredentialsStore _store;
  final DateTime Function() _clock;

  /// How long the confirmation may take before pairing carries on waiting for the receiver instead: FlutterFire keeps
  /// the write and sends it once it can, and the receiver's acknowledgement says whether it arrived.
  final Duration serverTimeout;

  Future<PairingCredentials> call(PairingSession joined, PairingSecrets secrets) async {
    final pairId = _repository.newPairId();
    final credentials = PairingCredentials(
      pairId: pairId,
      role: DeviceRole.sender,
      sharedKey: secrets.sharedKey,
      peerName: joined.receiverName ?? 'Paired device',
      pairedAt: _clock(),
      peerUid: joined.receiverUid,
    );
    await _store.save(credentials);
    try {
      await _repository.confirmSession(joined, pairId).timeout(serverTimeout);
    } on TimeoutException {
      // still on its way: the receiver's acknowledgement tells
    } on Object {
      await _store.remove(pairId);
      rethrow;
    }
    try {
      await _repository.markReady(pairId, DeviceRole.sender).timeout(serverTimeout);
    } on Object {
      // the receiver does not wait for this one; the pair works without it
    }
    return credentials;
  }
}
