import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:air_reply/core/crypto/crypto_service.dart';
import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/firebase/server_time.dart';
import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:air_reply/features/mirror/data/mirror_documents.dart';
import 'package:air_reply/features/mirror/data/mirror_sync_repository.dart';
import 'package:air_reply/features/mirror/data/pair_mailbox.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The server side of one pair, in memory: what is waiting in each collection.
final class _FakeMailbox implements PairMailbox {
  final _collections = <String, Map<String, Map<String, Object?>>>{};
  final _changes = StreamController<void>.broadcast();
  var _ids = 0;

  Map<String, Map<String, Object?>> waiting(String collection) => _collections.putIfAbsent(collection, () => {});

  void _changed() => _changes.add(null);

  /// Set to make every write fail, as when the server refuses it.
  Object? refuseWrites;

  @override
  String newId() => 'doc${_ids++}';

  @override
  Future<void> create(String collection, String id, Map<String, Object?> data) async {
    if (refuseWrites case final error?) throw error;
    waiting(collection)[id] = _stamped(data);
    _changed();
  }

  @override
  Future<void> update(String collection, String id, Map<String, Object?> data) async {
    waiting(collection)[id] = {...?waiting(collection)[id], ..._stamped(data)};
    _changed();
  }

  /// Set to hold deletes until it completes, as Firestore does offline (the write waits for the server).
  Completer<void>? holdDeletes;

  @override
  Future<void> delete(String collection, Iterable<String> ids) async {
    final remove = ids.toList();
    await holdDeletes?.future;
    remove.forEach(waiting(collection).remove);
    _changed();
  }

  @override
  Future<MailboxDocument?> get(String collection, String id) async =>
      waiting(collection)[id] == null ? null : (id: id, data: waiting(collection)[id]!);

  @override
  Future<List<MailboxDocument>> fetch(String collection, {MailboxFilter? where}) async => [
    for (final MapEntry(:key, :value) in waiting(collection).entries)
      if (where == null || value[where.field] == where.value) (id: key, data: value),
  ];

  @override
  Stream<List<MailboxDocument>> watch(String collection, {MailboxFilter? where, bool urgent = true}) async* {
    yield await fetch(collection, where: where);
    await for (final _ in _changes.stream) {
      yield await fetch(collection, where: where);
    }
  }

  @override
  Stream<SyncState> watchSyncState() => Stream.value(const SyncState(SyncHealth.live));

  /// Server time, as the backend would set it.
  static Map<String, Object?> _stamped(Map<String, Object?> data) => {
    for (final MapEntry(:key, :value) in data.entries) key: value is ServerTime ? DateTime.now() : value,
  };
}

void main() {
  late _FakeMailbox mailbox;
  late Directory files;
  final open = <HistoryDatabase>[];
  final cipher = PairCipher(cipher: CryptoService(), pairId: 'pair', key: Uint8List(32));

  // Each device, restart and engine opens its own connection to the device's file, as the app does.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    mailbox = _FakeMailbox();
    files = await Directory.systemTemp.createTemp('air_reply_history');
  });

  tearDown(() async {
    for (final db in open) {
      await db.close();
    }
    open.clear();
    await files.delete(recursive: true);
  });

  /// A new connection to [device]'s database.
  HistoryDatabase database(String device) {
    final db = HistoryDatabase(NativeDatabase(File('${files.path}/$device.sqlite')));
    open.add(db);
    return db;
  }

  /// One device's sync of the pair, on a new connection to that device's database; [window] notifications loaded.
  MirrorSyncRepository repository(String device, {required bool collects, int window = 2000}) => MirrorSyncRepository(
    mailbox,
    MirrorDocuments(cipher),
    MessageHistory(database(device), 'pair', maxNotifications: window),
    collects: collects,
    historyCheckInterval: const Duration(milliseconds: 20),
  );

  NotificationContent message(String text, DateTime at, {String key = 'chat-key'}) => NotificationContent(
    key: key,
    packageName: 'com.whatsapp',
    appName: 'WhatsApp',
    title: 'Alex',
    text: text,
    postedAt: at,
  );

  Future<List<MirroredNotification>> feedWhere(
    MirrorSyncRepository repo,
    bool Function(List<MirroredNotification> items) test,
  ) => repo.watchNotifications().firstWhere(test).timeout(const Duration(seconds: 5));

  /// Lets queued history work (saving, then deleting from the mailbox) finish.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  test('the receiver keeps each notification on the device and clears it from the server', () async {
    final phone = repository('phone', collects: false);
    final desktop = repository('desktop', collects: true);
    await phone.publish(message('Are you coming?', DateTime(2026, 11, 3, 9)), canReply: true);
    expect(mailbox.waiting('notifications'), hasLength(1));

    final items = await feedWhere(desktop, (items) => items.isNotEmpty);
    expect(items.single.content.text, 'Are you coming?');
    await settle();
    expect(mailbox.waiting('notifications'), isEmpty);

    // After a restart the history comes from the device alone: the server has nothing left.
    final restarted = repository('desktop', collects: true);
    final again = await feedWhere(restarted, (items) => items.isNotEmpty);
    expect(again.single.content.text, 'Are you coming?');
    expect(again.single.acceptsReplies, isTrue);
  });

  test('the sender keeps its own copy and never empties the mailbox', () async {
    final phone = repository('phone', collects: false);
    await phone.publish(message('Hello', DateTime(2026, 11, 3, 9)), canReply: false);

    final items = await feedWhere(phone, (items) => items.isNotEmpty);
    expect(items.single.content.text, 'Hello');
    await settle();
    expect(mailbox.waiting('notifications'), hasLength(1));
  });

  test("the sender's background engine writing history shows on the sender's screens", () async {
    final screen = repository('phone', collects: false);
    final engine = repository('phone', collects: false);
    final shown = feedWhere(screen, (items) => items.isNotEmpty);
    await settle();
    await engine.publish(message('From the engine', DateTime(2026, 11, 3, 9)), canReply: false);
    expect((await shown).single.content.text, 'From the engine');
  });

  test('a reply waits on the server until the sender reports it, then only the receiver keeps it', () async {
    final phone = repository('phone', collects: false);
    final desktop = repository('desktop', collects: true);
    await phone.publish(message('Are you coming?', DateTime(2026, 11, 3, 9)), canReply: true);
    final notification = (await feedWhere(desktop, (items) => items.isNotEmpty)).single;

    await desktop.send(notificationId: notification.id, notificationKey: 'chat-key', text: 'On my way');
    final replies = desktop.watchReplies();
    final pending = await phone.fetchPending();
    expect(pending.single.text, 'On my way');
    await settle();
    expect(mailbox.waiting('replies'), hasLength(1), reason: 'still pending: the sender has to see it');

    await phone.resolve(pending.single.id, ReplyStatus.sent);
    final sent = await replies
        .firstWhere((r) => r.any((reply) => reply.status == ReplyStatus.sent))
        .timeout(const Duration(seconds: 5));
    expect(sent.single.text, 'On my way');
    await settle();
    expect(mailbox.waiting('replies'), isEmpty);

    // The sender keeps the replies it sent, with how they went.
    final senderReplies = await phone
        .watchReplies()
        .firstWhere((r) => r.isNotEmpty)
        .timeout(const Duration(seconds: 5));
    expect(senderReplies.single.status, ReplyStatus.sent);
  });

  test('a dismissal covers the messages before it, not a later one of the same notification', () async {
    final phone = repository('phone', collects: false);
    final desktop = repository('desktop', collects: true);
    await phone.publish(message('First', DateTime.now().subtract(const Duration(minutes: 1))), canReply: true);
    await phone.markDismissed('chat-key');
    await phone.markDismissed('chat-key'); // removed again before anything new: nothing more to send
    expect(mailbox.waiting('dismissals'), hasLength(1));
    await phone.publish(message('Second', DateTime.now().add(const Duration(minutes: 1))), canReply: true);

    final items = await feedWhere(desktop, (items) => items.length == 2 && items.any((n) => n.dismissedOnSender));
    expect({for (final n in items) n.content.text: n.acceptsReplies}, {'First': false, 'Second': true});
    await settle();
    expect(mailbox.waiting('dismissals'), isEmpty);
  });

  test('a reply shows at once, and as failed when the server refuses it', () async {
    final desktop = repository('desktop', collects: true);
    final replies = desktop.watchReplies();
    mailbox.refuseWrites = StateError('permission-denied');
    await expectLater(desktop.send(notificationId: 'n', notificationKey: 'k', text: 'Hi'), throwsA(isA<StateError>()));
    final shown = await replies.firstWhere((r) => r.isNotEmpty).timeout(const Duration(seconds: 5));
    expect(shown.single.status, ReplyStatus.failed);
  });

  test('a delete waiting for the connection does not hold up what arrives next', () async {
    final phone = repository('phone', collects: false);
    final desktop = repository('desktop', collects: true);
    mailbox.holdDeletes = Completer();
    await phone.publish(message('One', DateTime(2026, 11, 3, 9)), canReply: false);
    final feed = desktop.watchNotifications();
    await settle();
    await phone.publish(message('Two', DateTime(2026, 11, 3, 10)), canReply: false);
    final items = await feed.firstWhere((items) => items.length == 2).timeout(const Duration(seconds: 5));
    expect(items.map((n) => n.content.text), ['Two', 'One']);
    mailbox.holdDeletes!.complete();
  });

  test('removing a notification that was never mirrored writes nothing', () async {
    await repository('phone', collects: false).markDismissed('some-other-app');
    expect(mailbox.waiting('dismissals'), isEmpty);
  });

  test('a push for a notification already delivered is read from the device', () async {
    final phone = repository('phone', collects: false);
    final desktop = repository('desktop', collects: true);
    await phone.publish(message('Large', DateTime(2026, 11, 3, 9)), canReply: false);
    final id = (await feedWhere(desktop, (items) => items.isNotEmpty)).single.id;
    await settle();
    expect(mailbox.waiting('notifications'), isEmpty);

    expect((await repository('desktop', collects: true).fetchNotification(id))?.content.text, 'Large');
  });

  test('search finds notifications further back than the loaded window, with their replies', () async {
    final phone = repository('phone', collects: false);
    final earlier = repository('desktop', collects: true);
    await phone.publish(message('Parcel arrives Tuesday', DateTime(2026, 1, 5), key: 'old'), canReply: true);
    await phone.publish(message('Lunch?', DateTime(2026, 11, 2), key: 'a'), canReply: false);
    await phone.publish(message('parcel picked up', DateTime(2026, 11, 3), key: 'b'), canReply: false);
    final old = (await feedWhere(earlier, (items) => items.length == 3)).last;
    await earlier.send(notificationId: old.id, notificationKey: 'old', text: 'Thanks');
    await settle();

    // The next start loads only the newest two, and the feed stays on screen while searching.
    final desktop = repository('desktop', collects: true, window: 2);
    final feed = StreamController<List<MirroredNotification>>.broadcast();
    final watching = desktop.watchNotifications().listen(feed.add);
    addTearDown(watching.cancel);
    final loaded = await feed.stream.firstWhere((items) => items.isNotEmpty).timeout(const Duration(seconds: 5));
    expect(loaded.map((n) => n.content.text), ['parcel picked up', 'Lunch?']);

    final found = await desktop.searchHistory('PARCEL');
    expect(found.notifications.single.content.text, 'Parcel arrives Tuesday', reason: 'the loaded match is left out');
    expect(found.replies.single.text, 'Thanks');
    expect((await desktop.searchHistory('dinner')).notifications, isEmpty);
    expect((await desktop.searchHistory('whatsapp')).notifications, hasLength(1), reason: 'the app name matches');
  });

  test('history kept before search existed becomes searchable', () async {
    final db = database('desktop');
    final documents = MirrorDocuments(cipher);
    Future<StoredNotification> kept(String id, String text, DateTime at) async => StoredNotification(
      id: id,
      payload: (await documents.notification(message(text, at), canReply: false))['payload']! as String,
      postedAt: at,
    );
    await MessageHistory(db, 'pair').putNotifications([
      await kept('old', 'Boarding pass for Goa', DateTime(2026, 3, 1)),
      await kept('new', 'Hello', DateTime(2026, 11, 3)),
    ]);
    final desktop = MirrorSyncRepository(
      mailbox,
      documents,
      MessageHistory(db, 'pair', maxNotifications: 1),
      collects: true,
    );
    final watching = desktop.watchNotifications().listen((_) {});
    await settle();
    expect((await desktop.searchHistory('goa')).notifications.single.id, 'old');
    await watching.cancel();
  });

  test('a database from before search upgrades in place', () async {
    final file = File('${files.path}/upgrade.sqlite');
    final v1 = HistoryDatabase(NativeDatabase(file));
    await MessageHistory(
      v1,
      'pair',
    ).putNotifications([StoredNotification(id: 'n', payload: 'sealed', postedAt: DateTime(2026, 11, 3))]);
    await v1.customStatement('DROP TABLE history_search');
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    final v2 = database('upgrade');
    final history = MessageHistory(v2, 'pair');
    expect((await history.load()).notifications.keys, ['n']);
    expect((await history.unsearchable()).single.id, 'n');
  });

  test('history keeps everything, the screens get the newest, and it is erased with the pair', () async {
    final db = database('desktop');
    final history = MessageHistory(db, 'pair', maxNotifications: 2);
    await history.putNotifications([
      for (var day = 1; day <= 3; day++)
        StoredNotification(id: 'n$day', payload: 'sealed', postedAt: DateTime(2026, 11, day)),
    ]);
    await MessageHistory(
      db,
      'other',
    ).putNotifications([StoredNotification(id: 'n1', payload: 'sealed', postedAt: DateTime(2026, 11))]);
    expect((await history.load()).notifications.keys, unorderedEquals(['n2', 'n3']));
    expect((await history.notification('n1'))?.postedAt, DateTime(2026, 11), reason: 'older ones are kept');

    await history.erase();
    expect((await history.load()).notifications, isEmpty);
    expect((await MessageHistory(db, 'other').load()).notifications.keys, ['n1'], reason: 'other pairs are untouched');
  });

  test('history kept in SharedPreferences by the first version moves into the database', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(
      'air_reply.history.v1.pair.n.old',
      jsonEncode({'p': 'sealed', 'at': DateTime(2026, 11, 3).millisecondsSinceEpoch, 'r': true}),
    );
    await prefs.setString('air_reply.history.v1.pair.rev', 'x');
    await prefs.setString('air_reply.inbox.v1', 'kept');

    final records = await MessageHistory(database('desktop'), 'pair', legacy: prefs).load();
    expect(records.notifications['old']?.canReply, isTrue);
    expect(await prefs.getKeys(), {'air_reply.inbox.v1'});
  });
}
