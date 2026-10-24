import 'dart:typed_data';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';

/// Backend side of pairing: the handshake session, the resulting pair, and each member's push token.
abstract interface class PairingRepository {
  /// Creates a session under a fresh, unused 6-digit code.
  Future<PairingSession> createSession({required Uint8List senderPublicKey, required String senderName});

  Future<PairingSession?> fetchSession(String code);

  /// Emits null once the session is deleted.
  Stream<PairingSession?> watchSession(String code);

  /// Atomically moves a `waiting` session to `joined` with this receiver's key. Throws [PairingException] if someone
  /// else joined first or the session is no longer waiting.
  Future<PairingSession> joinSession({
    required String code,
    required Uint8List receiverPublicKey,
    required String receiverName,
  });

  /// Creates the pair for a `joined` session and marks the session `confirmed`. Returns the pair id.
  Future<String> confirmSession(PairingSession session);

  Future<void> cancelSession(String code);

  /// Emits false once either device unpaired.
  Stream<bool> watchPairActive(String pairId);

  Future<void> deactivatePair(String pairId);

  /// Lets the backend push to this device (wake the sender for a reply, alert the receiver).
  Future<void> registerPushToken({required String pairId, required DeviceRole role, required String token});
}
