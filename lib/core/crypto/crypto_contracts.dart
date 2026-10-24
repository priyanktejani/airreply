import 'dart:typed_data';

/// An X25519 key pair made for one pairing attempt. It lives only in memory until both devices hold the shared key.
final class PairingKeyPair {
  const PairingKeyPair({required this.privateKey, required this.publicKey});

  final Uint8List privateKey;
  final Uint8List publicKey;
}

/// What both devices end up with after a successful key agreement.
///
/// [verificationCode] is a short code derived from the same secret: both screens show it so the person can confirm
/// that nobody in the middle (including the backend) swapped a public key.
final class PairingSecrets {
  const PairingSecrets({required this.sharedKey, required this.verificationCode});

  /// 256-bit AES-GCM key.
  final Uint8List sharedKey;

  /// Six digits, e.g. `482913`.
  final String verificationCode;
}

/// Agrees on a shared secret over an untrusted channel (Firestore) using each side's public key.
abstract interface class KeyAgreement {
  Future<PairingKeyPair> generateKeyPair();

  /// Both sides call this with the same [code], [senderPublicKey] and [receiverPublicKey] (one of which is [own]'s)
  /// and get the same [PairingSecrets].
  Future<PairingSecrets> deriveSecrets({
    required PairingKeyPair own,
    required Uint8List peerPublicKey,
    required String code,
    required Uint8List senderPublicKey,
    required Uint8List receiverPublicKey,
  });
}

/// Authenticated encryption of small JSON payloads with a raw 256-bit key.
abstract interface class PayloadCipher {
  /// Encrypts [json] and returns a printable envelope. [context] is bound as associated data, so an envelope made for
  /// one purpose (or one pair) cannot be replayed as another.
  Future<String> seal(Map<String, Object?> json, {required Uint8List key, required String context});

  /// Reverses [seal]. Throws [CryptoException] when the key, context or bytes do not match.
  Future<Map<String, Object?>> open(String envelope, {required Uint8List key, required String context});

  /// A keyed, deterministic hash of [value]: lets the server match records (e.g. "all posts of this notification key")
  /// without learning the value itself.
  Future<String> blindIndex(String value, {required Uint8List key});
}
