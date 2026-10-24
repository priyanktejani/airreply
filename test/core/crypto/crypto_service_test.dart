import 'dart:typed_data';

import 'package:air_reply/core/crypto/crypto_contracts.dart';
import 'package:air_reply/core/crypto/crypto_service.dart';
import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final crypto = CryptoService();

  Future<(PairingSecrets, PairingSecrets)> agree({String code = '482913'}) async {
    final sender = await crypto.generateKeyPair();
    final receiver = await crypto.generateKeyPair();
    final onSender = await crypto.deriveSecrets(
      own: sender,
      peerPublicKey: receiver.publicKey,
      code: code,
      senderPublicKey: sender.publicKey,
      receiverPublicKey: receiver.publicKey,
    );
    final onReceiver = await crypto.deriveSecrets(
      own: receiver,
      peerPublicKey: sender.publicKey,
      code: code,
      senderPublicKey: sender.publicKey,
      receiverPublicKey: receiver.publicKey,
    );
    return (onSender, onReceiver);
  }

  group('key agreement', () {
    test('both devices derive the same 256-bit key and verification code', () async {
      final (sender, receiver) = await agree();

      expect(sender.sharedKey, hasLength(32));
      expect(sender.sharedKey, receiver.sharedKey);
      expect(sender.verificationCode, receiver.verificationCode);
      expect(sender.verificationCode, matches(RegExp(r'^\d{6}$')));
    });

    test('a different session code gives a different key', () async {
      final sender = await crypto.generateKeyPair();
      final receiver = await crypto.generateKeyPair();
      Future<Uint8List> keyFor(String code) async => (await crypto.deriveSecrets(
        own: sender,
        peerPublicKey: receiver.publicKey,
        code: code,
        senderPublicKey: sender.publicKey,
        receiverPublicKey: receiver.publicKey,
      )).sharedKey;

      expect(await keyFor('111111'), isNot(await keyFor('222222')));
    });

    test('rejects a malformed peer key', () async {
      final own = await crypto.generateKeyPair();
      expect(
        () => crypto.deriveSecrets(
          own: own,
          peerPublicKey: Uint8List(5),
          code: '000000',
          senderPublicKey: own.publicKey,
          receiverPublicKey: Uint8List(5),
        ),
        throwsA(isA<PairingException>()),
      );
    });
  });

  group('payload encryption', () {
    test('seal then open returns the original JSON', () async {
      final (secrets, _) = await agree();
      final json = {'t': 'Alex', 'x': 'Are you coming? 🙂', 'n': 3};

      final envelope = await crypto.seal(json, key: secrets.sharedKey, context: 'pair/notification');

      expect(envelope, startsWith('v1.'));
      expect(envelope, isNot(contains('Alex')));
      expect(await crypto.open(envelope, key: secrets.sharedKey, context: 'pair/notification'), json);
    });

    test('fails with another key, another context, or altered bytes', () async {
      final (secrets, _) = await agree();
      final (other, _) = await agree();
      final envelope = await crypto.seal({'a': 1}, key: secrets.sharedKey, context: 'pair/reply');
      final tampered = '${envelope.substring(0, envelope.length - 3)}${envelope.endsWith('A') ? 'B' : 'A'}AA';

      expect(() => crypto.open(envelope, key: other.sharedKey, context: 'pair/reply'), throwsA(isA<CryptoException>()));
      expect(
        () => crypto.open(envelope, key: secrets.sharedKey, context: 'pair/notification'),
        throwsA(isA<CryptoException>()),
      );
      expect(
        () => crypto.open(tampered, key: secrets.sharedKey, context: 'pair/reply'),
        throwsA(isA<CryptoException>()),
      );
      expect(
        () => crypto.open('v2.abc', key: secrets.sharedKey, context: 'pair/reply'),
        throwsA(isA<CryptoException>()),
      );
    });

    test('blind index is stable per key and differs between keys', () async {
      final (a, _) = await agree();
      final (b, _) = await agree();
      const value = '0|com.whatsapp|1|chat|10123';

      final first = await crypto.blindIndex(value, key: a.sharedKey);
      expect(first, await crypto.blindIndex(value, key: a.sharedKey));
      expect(first, isNot(await crypto.blindIndex(value, key: b.sharedKey)));
      expect(first, isNot(contains('whatsapp')));
    });
  });

  test('PairCipher keeps notification and reply envelopes apart', () async {
    final (secrets, _) = await agree();
    final cipher = PairCipher(cipher: crypto, pairId: 'pair-1', key: secrets.sharedKey);
    final envelope = await cipher.encrypt({'k': 'key', 't': 'hi'}, CipherPurpose.reply);

    expect(await cipher.decrypt(envelope, CipherPurpose.reply), {'k': 'key', 't': 'hi'});
    expect(() => cipher.decrypt(envelope, CipherPurpose.notification), throwsA(isA<CryptoException>()));
  });
}
