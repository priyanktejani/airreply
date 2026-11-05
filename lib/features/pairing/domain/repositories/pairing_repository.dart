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

  /// A new pair id, made on the device: the sender keeps its credentials under it before the pair exists on the
  /// server, so a confirmation that reaches the server late is never orphaned.
  String newPairId();

  /// Creates the pair [pairId] for a `joined` session and marks the session `confirmed`.
  Future<void> confirmSession(PairingSession session, String pairId);

  /// This device ([role]) has kept the pair: the acknowledgement the other device waits for.
  Future<void> markReady(String pairId, DeviceRole role);

  /// Whether the device of [role] has acknowledged the pair (see [markReady]), each time that changes.
  Stream<bool> watchReady(String pairId, DeviceRole role);

  Future<void> cancelSession(String code);

  /// Emits false once either device unpaired.
  Stream<bool> watchPairActive(String pairId);

  /// The other device's sign-in id in the pair, as the server keeps its members; null once the pair is gone.
  Future<String?> peerUidOf(String pairId);

  /// Ends the pair on the server and removes what it left there: the messages still waiting in its mailbox, then the
  /// pair itself, marked ended first so the other device notices however this goes.
  Future<void> endPair(String pairId);

  /// Lets the backend push to this device (wake the sender for a reply, alert the receiver).
  Future<void> registerPushToken({required String pairId, required DeviceRole role, required String token});
}
