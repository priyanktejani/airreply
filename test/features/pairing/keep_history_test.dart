import 'dart:typed_data';

import 'package:air_reply/core/crypto/crypto_service.dart';
import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:air_reply/features/mirror/data/mirror_documents.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/pairing/data/secure_archived_pairs_store.dart';
import 'package:air_reply/features/pairing/domain/entities/archived_pair.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/usecases/continue_history.dart';
import 'package:air_reply/features/pairing/domain/usecases/receiver_pairing_usecases.dart';
import 'package:air_reply/features/pairing/domain/usecases/sender_pairing_usecases.dart';
import 'package:air_reply/features/pairing/domain/usecases/unpair.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fakes.dart';

PairingCredentials pair(
  String id, {
  String? peerUid = 'phone-uid',
  DeviceRole role = DeviceRole.receiver,
  int key = 1,
}) => PairingCredentials(
  pairId: id,
  role: role,
  sharedKey: Uint8List(32)..fillRange(0, 32, key),
  peerName: 'Pixel 9',
  pairedAt: DateTime(2026, 3),
  peerUid: peerUid,
);

void main() {
  test('pairing records each side\'s sign-in id, so the same device is recognised when it pairs again', () async {
    final backend = InMemoryPairingRepository();
    final crypto = CryptoService();
    final pending = await StartPairingSession(backend, crypto, const FixedDeviceIdentity('Pixel 9')).call();
    final joined = await JoinPairingSession(
      backend,
      crypto,
      const FixedDeviceIdentity('iPad'),
    ).call(code: pending.session.code);
    final secrets = await DeriveSenderSecrets(crypto).call(pending, joined.session);
    final sender = await ConfirmSenderPairing(backend, InMemoryCredentialsStore()).call(joined.session, secrets);
    final receiver = await FinishReceiverPairing(
      InMemoryCredentialsStore(),
    ).call(joined, backend.sessions[joined.session.code]!);

    expect(sender.peerUid, 'receiver-uid');
    expect(receiver.peerUid, 'sender-uid');
    expect(PairingCredentials.fromJson(receiver.toJson()).peerUid, 'sender-uid');
  });

  group('removing a device', () {
    late InMemoryCredentialsStore store;
    late SecureArchivedPairsStore archive;
    final erased = <String>[];

    setUp(() {
      store = InMemoryCredentialsStore()..pairs.add(pair('old'));
      archive = SecureArchivedPairsStore(MemorySecretStore());
      erased.clear();
    });

    Unpair unpair(int notifications) => Unpair(
      InMemoryPairingRepository(),
      store,
      FakeNotificationBridge(),
      eraseHistory: (id) async => erased.add(id),
      archive: archive,
      historySize: (_) async => (notifications: notifications, replies: 0),
      clock: () => DateTime(2026, 5, 1),
    );

    test('keeps its history, with the key that opens it', () async {
      await unpair(12).call('old');

      expect(store.pairs, isEmpty);
      expect(erased, isEmpty);
      final kept = (await archive.readAll()).single;
      expect(kept.pairId, 'old');
      expect(kept.credentials.sharedKey, pair('old').sharedKey);
      expect(kept.unpairedAt, DateTime(2026, 5, 1));
    });

    test('keeps nothing when it left no history', () async {
      await unpair(0).call('old');

      expect(await archive.readAll(), isEmpty);
      expect(erased, ['old']);
    });
  });

  group('pairing the same device again', () {
    late HistoryDatabase db;
    late ProviderContainer container;
    final cipher = CryptoService();

    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      db = HistoryDatabase(NativeDatabase.memory());
      container = ProviderContainer(overrides: [historyDatabaseProvider.overrideWithValue(db)]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('moves the kept history into the new pair: readable with its key, and still found by search', () async {
      final old = pair('old');
      final next = pair('new', key: 2);
      final oldDocs = MirrorDocuments(PairCipher(cipher: cipher, pairId: 'old', key: old.sharedKey));
      final history = MessageHistory(db, 'old');
      final content = NotificationContent(
        key: 'chat',
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        title: 'Alex',
        text: 'Dinner at 8?',
        postedAt: DateTime(2026, 4, 2, 19),
      );
      final sealed = await oldDocs.notification(content, canReply: true);
      await history.putNotifications([
        StoredNotification(id: 'n1', payload: sealed['payload']! as String, postedAt: content.postedAt, canReply: true),
      ]);
      await history.index({'n1': (content: 'alex dinner at 8? whatsapp', packageName: 'com.whatsapp')});
      final reply = await oldDocs.reply(notificationId: 'n1', notificationKey: 'chat', text: 'Yes!');
      await history.putReplies([
        StoredReply(
          id: 'r1',
          notificationId: 'n1',
          payload: reply['payload']! as String,
          status: ReplyStatus.sent,
          createdAt: DateTime(2026, 4, 2, 19, 5),
        ),
      ]);

      final archive = SecureArchivedPairsStore(MemorySecretStore());
      await archive.save(ArchivedPair(old, unpairedAt: DateTime(2026, 5)));
      // another device, and the same device in the other role: neither is this pair's past
      await archive.save(ArchivedPair(pair('other', peerUid: 'mac-uid'), unpairedAt: DateTime(2026, 5)));
      await archive.save(ArchivedPair(pair('sender', role: DeviceRole.sender), unpairedAt: DateTime(2026, 5)));

      final moved = await ContinueHistory(archive, moveHistory: container.read(moveHistoryProvider)).call(next);

      expect(moved, ['n1']);
      expect([for (final p in await archive.readAll()) p.pairId], ['other', 'sender']);
      expect(await history.size(), (notifications: 0, replies: 0));

      final continued = MessageHistory(db, 'new');
      final newDocs = MirrorDocuments(PairCipher(cipher: cipher, pairId: 'new', key: next.sharedKey));
      final found = await continued.page(text: 'dinner');
      expect(found.map((n) => n.id), ['n1']);
      final read = await newDocs.readNotification('n1', {'payload': found.single.payload, 'canReply': true});
      expect(read?.content.text, 'Dinner at 8?');
      final replies = await continued.repliesTo(['n1']);
      final readReply = await newDocs.readReply('r1', {
        'notificationId': 'n1',
        'payload': replies.single.payload,
        'status': replies.single.status.wire,
        'createdAt': replies.single.createdAt,
      });
      expect(readReply?.text, 'Yes!');
    });

    test('a pair from before sign-in ids were recorded is left under previous devices', () async {
      final archive = SecureArchivedPairsStore(MemorySecretStore());
      await archive.save(ArchivedPair(pair('old', peerUid: null), unpairedAt: DateTime(2026, 5)));

      final moved = await ContinueHistory(
        archive,
        moveHistory: container.read(moveHistoryProvider),
      ).call(pair('new', peerUid: null, key: 2));

      expect(moved, isEmpty);
      expect((await archive.readAll()).single.pairId, 'old');
    });
  });
}
