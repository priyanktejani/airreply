// End-to-end over the REST transport (what Windows and Linux use) against the Firebase emulators, with the real
// firestore.rules enforced. Run with:
//
//   firebase emulators:exec --only auth,firestore,database --project demo-airreply "flutter test test/integration"
//
// Skipped when the emulators are not running.
@Tags(['emulator'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:air_reply/core/crypto/crypto_service.dart';
import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/firebase/rest/firebase_rest_config.dart';
import 'package:air_reply/core/firebase/rest/firestore_rest_client.dart';
import 'package:air_reply/core/firebase/rest/rest_auth_gateway.dart';
import 'package:air_reply/features/mirror/data/doorbell.dart';
import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:air_reply/features/mirror/data/mirror_documents.dart';
import 'package:air_reply/features/mirror/data/mirror_sync_repository.dart';
import 'package:air_reply/features/mirror/data/rest_mailbox.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/pairing/data/rest_pairing_repository.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/usecases/receiver_pairing_usecases.dart';
import 'package:air_reply/features/pairing/domain/usecases/sender_pairing_usecases.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/fakes.dart';

final _firestoreHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
final _authHost = Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'];
final _databaseHost = Platform.environment['FIREBASE_DATABASE_EMULATOR_HOST'];

/// One simulated install: its own anonymous user, secrets, backend clients and stored pairs.
final class _Device {
  _Device(this.name, http.Client http) {
    config = FirebaseRestConfig(
      apiKey: 'fake-api-key',
      projectId: Platform.environment['GCLOUD_PROJECT'] ?? 'demo-airreply',
      authEmulatorHost: _authHost,
      firestoreEmulatorHost: _firestoreHost,
      databaseEmulatorHost: _databaseHost,
    );
    _http = http;
    auth = RestAuthGateway(config, http, MemorySecretStore());
    client = FirestoreRestClient(config, http, auth);
    pairing = RestPairingRepository(client, auth, sessionPollInterval: const Duration(milliseconds: 200));
  }

  final String name;
  late final FirebaseRestConfig config;
  late final http.Client _http;
  late final RestAuthGateway auth;
  late final FirestoreRestClient client;
  late final RestPairingRepository pairing;
  final store = InMemoryCredentialsStore();
  final history = HistoryDatabase(NativeDatabase.memory());

  /// The pair's doorbell, as the app builds it.
  Doorbell doorbell(PairingCredentials pair) => Doorbell(
    config: config,
    client: _http,
    idToken: auth.idToken,
    name: () =>
        PairCipher(cipher: CryptoService(), pairId: pair.pairId, key: pair.sharedKey).blindIndex('air_reply.doorbell'),
  );

  /// The pair's sync as the app builds it, with this install's history. [poll] is how often the mailbox is read when
  /// no doorbell is live.
  MirrorSyncRepository mirror(
    PairingCredentials pair, {
    Duration poll = const Duration(milliseconds: 200),
    Doorbell? bell,
  }) => MirrorSyncRepository(
    RestMailbox(client, pair.pairId, pollInterval: poll, doorbell: bell),
    MirrorDocuments(PairCipher(cipher: CryptoService(), pairId: pair.pairId, key: pair.sharedKey)),
    MessageHistory(history, pair.pairId),
    collects: pair.role == DeviceRole.receiver,
    historyCheckInterval: const Duration(milliseconds: 200),
    ring: bell?.ring,
  );
}

void main() {
  final skip = _firestoreHost == null || _authHost == null ? 'Firebase emulators are not running' : null;
  final crypto = CryptoService();
  final http.Client httpClient = http.Client();
  tearDownAll(httpClient.close);
  // one database per simulated install
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

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

    // Delivered: the desktop keeps it, and the server no longer holds it.
    await _eventually(
      () async => (await desktop.client.runQuery(
        const RestQuery('notifications'),
        parent: 'pairs/${desktopPair.pairId}',
      )).isEmpty,
    );

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
    await _eventually(
      () async =>
          (await desktop.client.runQuery(const RestQuery('replies'), parent: 'pairs/${desktopPair.pairId}')).isEmpty,
    );

    // The notification is dismissed on the phone; the desktop keeps it, flagged by the dismissal it picks up.
    await phoneMirror.markDismissed(key);
    final afterDismiss = await desktopMirror
        .watchNotifications()
        .firstWhere((items) => items.any((n) => n.id == notification.id && n.dismissedOnSender))
        .timeout(const Duration(seconds: 10));
    expect(afterDismiss.single.acceptsReplies, isFalse);
    await _eventually(
      () async =>
          (await desktop.client.runQuery(const RestQuery('dismissals'), parent: 'pairs/${desktopPair.pairId}')).isEmpty,
    );

    // The desktop unpairs; the phone notices.
    await desktop.pairing.endPair(desktopPair.pairId);
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

  test('the doorbell: a desktop reads its mailbox the moment the phone rings, not on its next check', () async {
    final phone = _Device('Pixel 9', httpClient);
    final desktop = _Device('Linux PC', httpClient);
    final (phonePair, desktopPair) = await pair(phone, desktop);
    final desktopBell = desktop.doorbell(desktopPair);
    addTearDown(desktopBell.dispose);

    // without a ring, this desktop would not look again for five minutes
    final feed = desktop
        .mirror(desktopPair, poll: const Duration(minutes: 5), bell: desktopBell)
        .watchNotifications()
        .asBroadcastStream();
    await feed.first.timeout(const Duration(seconds: 10));
    await _eventually(() async => desktopBell.live);

    final sent = DateTime.now();
    await phone.mirror(phonePair, bell: phone.doorbell(phonePair)).publish(message('k', 'Rang'), canReply: false);
    final items = await feed.firstWhere((items) => items.isNotEmpty).timeout(const Duration(seconds: 10));
    expect(items.single.content.text, 'Rang');
    expect(DateTime.now().difference(sent), lessThan(const Duration(seconds: 5)));
  }, skip: _databaseHost == null ? 'The Realtime Database emulator is not running' : skip);

  test('doorbell rules: only signed-in installs, only bell-shaped names, only the server time', () async {
    final device = _Device('Pixel 9', httpClient);
    final token = await device.auth.idToken();
    const bell = '0123456789abcdef0123456789abcdef';
    Future<int> put(String path, String body, {String? auth}) async => (await httpClient.put(
      auth == null
          ? Uri.parse('http://$_databaseHost/$path.json?ns=${device.config.projectId}-default-rtdb')
          : device.config.database(path, auth: auth),
      body: body,
    )).statusCode;
    Future<int> get(String path, {String? auth}) async => (await httpClient.get(
      auth == null
          ? Uri.parse('http://$_databaseHost/$path.json?ns=${device.config.projectId}-default-rtdb')
          : device.config.database(path, auth: auth),
    )).statusCode;

    expect(await put('doorbells/$bell', '{".sv":"timestamp"}', auth: token), 200);
    expect(await get('doorbells/$bell', auth: token), 200);
    expect(await put('doorbells/$bell', '{".sv":"timestamp"}'), 401, reason: 'not signed in');
    expect(await get('doorbells/$bell'), 401);
    expect(await put('doorbells/$bell', '"hello"', auth: token), 401, reason: 'only the server time');
    expect(await put('doorbells/$bell', '42', auth: token), 401);
    expect(await put('doorbells/not-a-bell', '{".sv":"timestamp"}', auth: token), 401);
    expect(await get('doorbells', auth: token), 401, reason: 'nobody lists the doorbells');
    expect(await put('elsewhere', '{".sv":"timestamp"}', auth: token), 401);

    // and it is taken away when the pair ends
    expect((await httpClient.delete(device.config.database('doorbells/$bell', auth: token))).statusCode, 200);
    expect((await httpClient.get(device.config.database('doorbells/$bell', auth: token))).body, 'null');
  }, skip: _databaseHost == null ? 'The Realtime Database emulator is not running' : skip);

  test('ending a pair removes what it left on the server, and the other device notices', () async {
    final phone = _Device('Pixel 9', httpClient);
    final desktop = _Device('Linux PC', httpClient);
    final stranger = _Device('Stranger', httpClient);
    final (phonePair, desktopPair) = await pair(phone, desktop);
    final path = 'pairs/${phonePair.pairId}';

    // never collected: waiting on the server when the pair ends
    await phone.mirror(phonePair).publish(message('k1', 'one'), canReply: true);
    await phone.mirror(phonePair).publish(message('k2', 'two'), canReply: true);
    await desktop.mirror(desktopPair).send(notificationId: 'n', notificationKey: 'k1', text: 'pending reply');
    expect(await _adminCount('$path/notifications'), 2);

    // a stranger cannot end it, nor can a member delete it while it is active
    await expectLater(stranger.pairing.endPair(phonePair.pairId), throwsA(anything));
    await expectLater(desktop.client.commit([RestWrite.delete(path)]), throwsA(anything));

    await desktop.pairing.endPair(desktopPair.pairId);
    expect(await _adminCount('$path/notifications'), 0);
    expect(await _adminCount('$path/replies'), 0);
    expect(await _adminExists(path), isFalse);
    expect(await phone.pairing.watchPairActive(phonePair.pairId).first.timeout(const Duration(seconds: 10)), isFalse);
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

/// Polls [check] until it holds, for server-side effects of background work.
Future<void> _eventually(Future<bool> Function() check) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!await check()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting for the server');
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

/// Documents in a collection, read past the rules (the emulator's owner token).
Future<int> _adminCount(String collection) async {
  final response = await http.get(
    Uri.parse(
      'http://$_firestoreHost/v1/projects/${Platform.environment['GCLOUD_PROJECT'] ?? 'demo-airreply'}/databases/(default)/documents/$collection',
    ),
    headers: {'authorization': 'Bearer owner'},
  );
  return ((jsonDecode(response.body) as Map)['documents'] as List?)?.length ?? 0;
}

/// Whether a document exists, read past the rules.
Future<bool> _adminExists(String document) async {
  final response = await http.get(
    Uri.parse(
      'http://$_firestoreHost/v1/projects/${Platform.environment['GCLOUD_PROJECT'] ?? 'demo-airreply'}/databases/(default)/documents/$document',
    ),
    headers: {'authorization': 'Bearer owner'},
  );
  return response.statusCode == 200;
}
