// End-to-end over the REST transport (what Windows and Linux use) against the Firebase emulators, with the real
// firestore.rules enforced. Run with:
//
//   firebase emulators:exec --only auth,firestore --project demo-airreply "flutter test test/integration"
//
// Skipped when the emulators are not running.
@Tags(['emulator'])
library;

import 'dart:io';

import 'package:air_reply/core/crypto/crypto_service.dart';
import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/firebase/rest/firebase_rest_config.dart';
import 'package:air_reply/core/firebase/rest/firestore_rest_client.dart';
import 'package:air_reply/core/firebase/rest/rest_auth_gateway.dart';
import 'package:air_reply/features/mirror/data/mirror_documents.dart';
import 'package:air_reply/features/mirror/data/rest_sync_repository.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/pairing/data/rest_pairing_repository.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/usecases/receiver_pairing_usecases.dart';
import 'package:air_reply/features/pairing/domain/usecases/sender_pairing_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/fakes.dart';

final _firestoreHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
final _authHost = Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'];

/// One simulated install: its own anonymous user, secrets, backend clients and stored pairs.
final class _Device {
  _Device(this.name, http.Client http) {
    final config = FirebaseRestConfig(
      apiKey: 'fake-api-key',
      projectId: Platform.environment['GCLOUD_PROJECT'] ?? 'demo-airreply',
      authEmulatorHost: _authHost,
      firestoreEmulatorHost: _firestoreHost,
    );
    auth = RestAuthGateway(config, http, MemorySecretStore());
    client = FirestoreRestClient(config, http, auth);
    pairing = RestPairingRepository(client, auth, sessionPollInterval: const Duration(milliseconds: 200));
  }

  final String name;
  late final RestAuthGateway auth;
  late final FirestoreRestClient client;
  late final RestPairingRepository pairing;
  final store = InMemoryCredentialsStore();

  RestSyncRepository mirror(PairingCredentials pair) => RestSyncRepository(
    client,
    pair.pairId,
    MirrorDocuments(PairCipher(cipher: CryptoService(), pairId: pair.pairId, key: pair.sharedKey)),
    feedPollInterval: const Duration(milliseconds: 200),
    pendingPollInterval: const Duration(milliseconds: 200),
  );
}

void main() {
  final skip = _firestoreHost == null || _authHost == null ? 'Firebase emulators are not running' : null;
  final crypto = CryptoService();
  final http.Client httpClient = http.Client();
  tearDownAll(httpClient.close);

  /// Runs the whole handshake: [sender] shows a code, [receiver] types it, both confirm the verification code.
  Future<(PairingCredentials, PairingCredentials)> pair(_Device sender, _Device receiver) async {
    final pending = await StartPairingSession(sender.pairing, crypto, FixedDeviceIdentity(sender.name)).call();
    final joined = await JoinPairingSession(
      receiver.pairing,
      crypto,
      FixedDeviceIdentity(receiver.name),
    ).call(code: pending.session.code, expectedSenderKey: pending.keyPair.publicKey);

    final seenBySender = await sender.pairing.fetchSession(pending.session.code);
    final senderSecrets = await DeriveSenderSecrets(crypto).call(pending, seenBySender!);
    expect(senderSecrets.verificationCode, joined.secrets.verificationCode);

    final senderCredentials = await ConfirmSenderPairing(
      sender.pairing,
      sender.store,
    ).call(seenBySender, senderSecrets);
    final confirmed = await receiver.pairing
        .watchSession(pending.session.code)
        .firstWhere((s) => s?.pairId != null)
        .timeout(const Duration(seconds: 10));
    final receiverCredentials = await FinishReceiverPairing(receiver.store).call(joined, confirmed!);
    return (senderCredentials, receiverCredentials);
  }

  NotificationContent message(String key, String text) => NotificationContent(
    key: key,
    packageName: 'com.whatsapp',
    appName: 'WhatsApp',
    title: 'Alex',
    text: text,
    postedAt: DateTime.now().toUtc(),
  );

  test('phone ↔ desktop: pair, mirror, reply, dismiss, unpair — under the real security rules', () async {
    final phone = _Device('Pixel 9', httpClient);
    final desktop = _Device('Linux PC', httpClient);

    final (phonePair, desktopPair) = await pair(phone, desktop);
    expect(phonePair.pairId, desktopPair.pairId);
    expect(phonePair.sharedKey, desktopPair.sharedKey);
    expect(desktopPair.peerName, 'Pixel 9');

    final phoneMirror = phone.mirror(phonePair);
    final desktopMirror = desktop.mirror(desktopPair);

    // The phone mirrors a notification; the desktop's feed shows it, decrypted.
    const key = '0|com.whatsapp|1|chat|10123';
    await phoneMirror.publish(message(key, 'Are you coming?'), canReply: true);
    final feed = desktopMirror.watchNotifications();
    final shown = await feed
        .map((items) => items.where((n) => n.content.text == 'Are you coming?').toList())
        .firstWhere((items) => items.isNotEmpty)
        .timeout(const Duration(seconds: 10));
    final MirroredNotification notification = shown.single;
    expect(notification.acceptsReplies, isTrue);
    expect(notification.content.key, key);

    // The desktop replies; the phone sees it pending (decrypted, with the notification key) and reports it sent.
    await desktopMirror.send(notificationId: notification.id, notificationKey: key, text: 'On my way');
    final pending = await phoneMirror.fetchPending();
    expect(pending.single.notificationKey, key);
    expect(pending.single.text, 'On my way');
    await phoneMirror.resolve(pending.single.id, ReplyStatus.sent);
    final replies = await desktopMirror
        .watchReplies()
        .firstWhere((r) => r.any((reply) => reply.status == ReplyStatus.sent))
        .timeout(const Duration(seconds: 10));
    expect(replies.single.text, 'On my way');

    // The notification is dismissed on the phone; the desktop keeps it, flagged, through the incremental poll.
    await phoneMirror.markDismissed(key);
    final afterDismiss = await desktopMirror
        .watchNotifications()
        .firstWhere((items) => items.any((n) => n.id == notification.id && n.dismissedOnSender))
        .timeout(const Duration(seconds: 10));
    expect(afterDismiss.single.acceptsReplies, isFalse);

    // The desktop unpairs; the phone notices.
    await desktop.pairing.deactivatePair(desktopPair.pairId);
    expect(await phone.pairing.watchPairActive(phonePair.pairId).first.timeout(const Duration(seconds: 10)), isFalse);
  }, skip: skip);

  test('one phone shares with two desktops, each pair isolated from the other', () async {
    final phone = _Device('Pixel 9', httpClient);
    final mac = _Device('MacBook', httpClient);
    final pc = _Device('Windows PC', httpClient);

    final (phoneToMac, macPair) = await pair(phone, mac);
    final (phoneToPc, pcPair) = await pair(phone, pc);
    expect(phoneToMac.pairId, isNot(phoneToPc.pairId));
    expect(phoneToMac.sharedKey, isNot(phoneToPc.sharedKey));

    await phone.mirror(phoneToMac).publish(message('k1', 'for both'), canReply: false);
    await phone.mirror(phoneToPc).publish(message('k1', 'for both'), canReply: false);

    for (final (device, credentials) in [(mac, macPair), (pc, pcPair)]) {
      final items = await device
          .mirror(credentials)
          .watchNotifications()
          .firstWhere((items) => items.isNotEmpty)
          .timeout(const Duration(seconds: 10));
      expect(items.single.content.text, 'for both');
    }

    // The Mac cannot read the PC's pair at all.
    await expectLater(
      mac.client.runQuery(const RestQuery('notifications'), parent: 'pairs/${pcPair.pairId}'),
      throwsA(isA<RestFirestoreException>().having((e) => e.status, 'status', 'PERMISSION_DENIED')),
    );
  }, skip: skip);

  test('security rules: strangers and wrong roles are refused', () async {
    final phone = _Device('Pixel 9', httpClient);
    final desktop = _Device('Mac', httpClient);
    final stranger = _Device('Stranger', httpClient);
    final (phonePair, desktopPair) = await pair(phone, desktop);
    final pairPath = 'pairs/${phonePair.pairId}';
    Matcher denied() => throwsA(isA<RestFirestoreException>().having((e) => e.status, 'status', 'PERMISSION_DENIED'));

    // A stranger can neither read the pair nor its history.
    await expectLater(stranger.client.get(pairPath), denied());
    await expectLater(stranger.client.runQuery(const RestQuery('notifications'), parent: pairPath), denied());

    // The receiver cannot inject notifications; the sender cannot forge replies.
    await expectLater(desktop.mirror(desktopPair).publish(message('k', 'fake'), canReply: true), throwsA(anything));
    await expectLater(
      phone.mirror(phonePair).send(notificationId: 'n', notificationKey: 'k', text: 'forged'),
      throwsA(anything),
    );

    // Nobody can join a session that is already confirmed.
    final pending = await StartPairingSession(phone.pairing, crypto, const FixedDeviceIdentity('Pixel 9')).call();
    await JoinPairingSession(
      desktop.pairing,
      crypto,
      const FixedDeviceIdentity('Mac'),
    ).call(code: pending.session.code);
    await expectLater(
      JoinPairingSession(
        stranger.pairing,
        crypto,
        const FixedDeviceIdentity('Stranger'),
      ).call(code: pending.session.code),
      throwsA(anything),
    );
  }, skip: skip);
}
