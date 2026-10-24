import 'dart:convert';
import 'dart:typed_data';

import 'package:air_reply/core/crypto/crypto_contracts.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:cryptography/cryptography.dart';

/// X25519 + HKDF-SHA256 + AES-256-GCM, all in pure Dart so the same code runs in the UI isolate, the sender's
/// headless sync isolate, and the push / notification-action background isolates.
final class CryptoService implements KeyAgreement, PayloadCipher {
  CryptoService();

  static const _envelopeVersion = 'v1';
  static const _protocol = 'airreply/v1';

  final _x25519 = X25519();
  final _aesGcm = AesGcm.with256bits();
  final _keyHkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final _sasHkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 4);
  final _hmac = Hmac.sha256();

  // ---------------------------------------------------------------- key agreement

  @override
  Future<PairingKeyPair> generateKeyPair() async {
    final pair = await _x25519.newKeyPair();
    final publicKey = await pair.extractPublicKey();
    return PairingKeyPair(
      privateKey: Uint8List.fromList(await pair.extractPrivateKeyBytes()),
      publicKey: Uint8List.fromList(publicKey.bytes),
    );
  }

  @override
  Future<PairingSecrets> deriveSecrets({
    required PairingKeyPair own,
    required Uint8List peerPublicKey,
    required String code,
    required Uint8List senderPublicKey,
    required Uint8List receiverPublicKey,
  }) async {
    if (peerPublicKey.length != 32) throw const PairingException('The other device sent an invalid key.');

    final shared = await _x25519.sharedSecretKey(
      keyPair: SimpleKeyPairData(
        own.privateKey,
        publicKey: SimplePublicKey(own.publicKey, type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      ),
      remotePublicKey: SimplePublicKey(peerPublicKey, type: KeyPairType.x25519),
    );
    final sharedBytes = await shared.extractBytes();
    if (sharedBytes.every((b) => b == 0)) throw const PairingException('The other device sent an unsafe key.');

    // The salt binds the derived keys to this exact pairing transcript.
    final salt = [...utf8.encode('$_protocol|$code|'), ...senderPublicKey, ...receiverPublicKey];

    final aesKey = await _keyHkdf.deriveKey(secretKey: shared, nonce: salt, info: utf8.encode('$_protocol/aes-key'));
    final sas = await _sasHkdf.deriveKey(secretKey: shared, nonce: salt, info: utf8.encode('$_protocol/sas'));
    final sasValue = ByteData.sublistView(Uint8List.fromList(sas.bytes)).getUint32(0) % 1000000;

    return PairingSecrets(
      sharedKey: Uint8List.fromList(aesKey.bytes),
      verificationCode: sasValue.toString().padLeft(6, '0'),
    );
  }

  // ---------------------------------------------------------------- payloads

  @override
  Future<String> seal(Map<String, Object?> json, {required Uint8List key, required String context}) async {
    try {
      final box = await _aesGcm.encrypt(utf8.encode(jsonEncode(json)), secretKey: SecretKey(key), aad: _aad(context));
      return '$_envelopeVersion.${base64Url.encode(box.concatenation())}';
    } catch (e) {
      throw CryptoException('Could not encrypt the payload.', cause: e);
    }
  }

  @override
  Future<Map<String, Object?>> open(String envelope, {required Uint8List key, required String context}) async {
    final dot = envelope.indexOf('.');
    if (dot < 0 || envelope.substring(0, dot) != _envelopeVersion) {
      throw const CryptoException('Unknown payload format.');
    }
    try {
      final box = SecretBox.fromConcatenation(
        base64Url.decode(envelope.substring(dot + 1)),
        nonceLength: _aesGcm.nonceLength,
        macLength: _aesGcm.macAlgorithm.macLength,
      );
      final clear = await _aesGcm.decrypt(box, secretKey: SecretKey(key), aad: _aad(context));
      return (jsonDecode(utf8.decode(clear)) as Map).cast<String, Object?>();
    } on SecretBoxAuthenticationError catch (e) {
      throw CryptoException('This payload was not made with the pair key, or it was altered.', cause: e);
    } catch (e) {
      throw CryptoException('Could not decrypt the payload.', cause: e);
    }
  }

  @override
  Future<String> blindIndex(String value, {required Uint8List key}) async {
    final indexKey = await _keyHkdf.deriveKey(secretKey: SecretKey(key), info: utf8.encode('$_protocol/index'));
    final mac = await _hmac.calculateMac(utf8.encode(value), secretKey: indexKey);
    return _hex(mac.bytes.take(16));
  }

  List<int> _aad(String context) => utf8.encode('$_protocol/$context');

  static String _hex(Iterable<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
