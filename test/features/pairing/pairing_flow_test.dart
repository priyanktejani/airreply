import 'dart:async';

import 'dart:typed_data';

import 'package:air_reply/core/crypto/crypto_service.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_invite.dart';
import 'package:air_reply/features/pairing/domain/usecases/receiver_pairing_usecases.dart';
import 'package:air_reply/features/pairing/domain/usecases/sender_pairing_usecases.dart';
import 'package:air_reply/features/pairing/domain/usecases/unpair.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late InMemoryPairingRepository backend;
  late InMemoryCredentialsStore senderStore;
  late InMemoryCredentialsStore receiverStore;
  final crypto = CryptoService();

  setUp(() {
    backend = InMemoryPairingRepository();
    senderStore = InMemoryCredentialsStore();
    receiverStore = InMemoryCredentialsStore();
  });

  JoinPairingSession join({DateTime Function()? clock}) =>
      JoinPairingSession(backend, crypto, const FixedDeviceIdentity('iPad'), clock: clock);

  test('sender and receiver end up with the same pair and key (QR path)', () async {
    final pending = await StartPairingSession(backend, crypto, const FixedDeviceIdentity('Pixel 9')).call();

    // The receiver scans the QR the sender renders.
    final invite = PairingInvite.tryParse(pending.invite.toUri())!;
    final joined = await join().call(code: invite.code, expectedSenderKey: invite.senderPublicKey);

    final senderSecrets = await DeriveSenderSecrets(crypto).call(pending, joined.session);
    expect(senderSecrets.verificationCode, joined.secrets.verificationCode);

    final senderCredentials = await ConfirmSenderPairing(backend, senderStore).call(joined.session, senderSecrets);
    final confirmed = backend.sessions[joined.session.code]!;
    final receiverCredentials = await FinishReceiverPairing(receiverStore).call(joined, confirmed);

    expect(senderCredentials.role, DeviceRole.sender);
    expect(receiverCredentials.role, DeviceRole.receiver);
    expect(senderCredentials.pairId, receiverCredentials.pairId);
    expect(senderCredentials.sharedKey, receiverCredentials.sharedKey);
    expect(senderCredentials.peerName, 'iPad');
    expect(receiverCredentials.peerName, 'Pixel 9');
    expect(senderStore.single, same(senderCredentials));
    expect(receiverStore.single, same(receiverCredentials));
  });

  test('typed code works without the QR key', () async {
    final pending = await StartPairingSession(backend, crypto, const FixedDeviceIdentity('Pixel 9')).call();
    final joined = await join().call(code: pending.session.code);
    expect(joined.session.receiverName, 'iPad');
  });

  test('refuses a QR whose key differs from the session (swapped key)', () async {
    final pending = await StartPairingSession(backend, crypto, const FixedDeviceIdentity('Pixel 9')).call();
    final attacker = await crypto.generateKeyPair();

    await expectLater(
      join().call(code: pending.session.code, expectedSenderKey: attacker.publicKey),
      throwsA(isA<PairingException>()),
    );
  });

  test('refuses expired, used, unknown and malformed codes', () async {
    final pending = await StartPairingSession(backend, crypto, const FixedDeviceIdentity('Pixel 9')).call();
    final code = pending.session.code;

    await expectLater(
      join(clock: () => DateTime.now().add(const Duration(hours: 1))).call(code: code),
      throwsA(isA<PairingException>()),
    );
    await join().call(code: code);
    await expectLater(join().call(code: code), throwsA(isA<PairingException>()));
    await expectLater(join().call(code: '999999'), throwsA(isA<PairingException>()));
    await expectLater(join().call(code: '12ab'), throwsA(isA<ValidationException>()));
  });

  /// Pairs the sender with one more receiver and returns the sender's credentials for it.
  Future<String> pairSenderWith(String receiverName) async {
    final pending = await StartPairingSession(backend, crypto, const FixedDeviceIdentity('Pixel 9')).call();
    final joined = await JoinPairingSession(
      backend,
      crypto,
      FixedDeviceIdentity(receiverName),
    ).call(code: pending.session.code);
    final secrets = await DeriveSenderSecrets(crypto).call(pending, joined.session);
    final credentials = await ConfirmSenderPairing(backend, senderStore).call(joined.session, secrets);
    return credentials.pairId;
  }

  test('one phone can share with several devices, each with its own key', () async {
    final mac = await pairSenderWith('MacBook');
    final pc = await pairSenderWith('Windows PC');

    expect(senderStore.pairs.map((p) => p.peerName), ['MacBook', 'Windows PC']);
    expect(senderStore.pairs.map((p) => p.pairId), [mac, pc]);
    expect(senderStore.pairs.first.sharedKey, isNot(senderStore.pairs.last.sharedKey));
  });

  test('unpairing one device keeps the others and reloads sync', () async {
    final mac = await pairSenderWith('MacBook');
    final pc = await pairSenderWith('Windows PC');
    final bridge = FakeNotificationBridge();

    await Unpair(backend, senderStore, bridge).call(mac);

    expect(backend.pairs[mac], isFalse);
    expect(senderStore.pairs.map((p) => p.pairId), [pc]);
    expect(bridge.syncReloaded, isTrue);
    expect(bridge.syncStopped, isFalse);
  });

  test('unpairing the last device stops native sync and wipes the key', () async {
    final only = await pairSenderWith('iPad');
    final bridge = FakeNotificationBridge();

    await Unpair(backend, senderStore, bridge).call(only);

    expect(bridge.syncStopped, isTrue);
    expect(backend.pairs[only], isFalse);
    expect(senderStore.pairs, isEmpty);
  });

  test('a pair the other device ended is forgotten without notifying it again', () async {
    final only = await pairSenderWith('iPad');
    backend.pairs[only] = false;
    backend.pairs.remove(only); // the backend already deleted it

    await Unpair(backend, senderStore, FakeNotificationBridge()).call(only, notifyPeer: false);

    expect(senderStore.pairs, isEmpty);
    expect(backend.pairs.containsKey(only), isFalse);
  });

  test('unpairing ends the pair on the server, takes its doorbell, then erases it here, in that order', () async {
    final mac = await pairSenderWith('MacBook');
    final steps = <String>[];
    await Unpair(
      backend,
      senderStore,
      FakeNotificationBridge(),
      eraseHistory: (pairId) async => steps.add('history $pairId'),
      removeDoorbell: (pair) async => steps.add('doorbell ${pair.pairId}'),
    ).call(mac);
    expect(backend.pairs[mac], isFalse);
    expect(steps, ['doorbell $mac', 'history $mac']);
    expect(senderStore.pairs, isEmpty);
  });

  test('offline, unpairing does not wait on the server: the key and history go anyway', () async {
    final mac = await pairSenderWith('MacBook');
    final erased = <String>[];
    await Unpair(
      _HangingBackend(),
      senderStore,
      FakeNotificationBridge(),
      eraseHistory: (pairId) async => erased.add(pairId),
      removeDoorbell: (_) => Completer<void>().future,
      serverTimeout: const Duration(milliseconds: 20),
    ).call(mac);
    expect(erased, [mac]);
    expect(senderStore.pairs, isEmpty);
  });

  group('PairingInvite', () {
    test('round-trips through its URI', () {
      final invite = PairingInvite(code: '004213', senderPublicKey: Uint8List.fromList(List.generate(32, (i) => i)));
      final parsed = PairingInvite.tryParse(invite.toUri())!;
      expect(parsed.code, '004213');
      expect(parsed.senderPublicKey, invite.senderPublicKey);
    });

    test('ignores other QR codes', () {
      expect(PairingInvite.tryParse('https://example.com'), isNull);
      expect(PairingInvite.tryParse('airreply://pair?c=12345&k=AAAA'), isNull);
      expect(PairingInvite.tryParse('airreply://pair?c=123456&k=AAAA'), isNull);
    });
  });
}

/// A server that never answers: Firestore offline, waiting for the connection.
final class _HangingBackend extends InMemoryPairingRepository {
  @override
  Future<void> endPair(String pairId) => Completer<void>().future;
}
