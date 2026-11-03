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
import 'package:air_reply/features/mirror/domain/entities/history_query.dart';
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

  /// Set to make every delete (a delivery's acknowledgement) fail.
  Object? refuseDeletes;

  @override
  Future<void> delete(String collection, Iterable<String> ids) async {
    final remove = ids.toList();
    await holdDeletes?.future;
    if (refuseDeletes case final error?) throw error;
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
  MirrorSyncRepository repository(
    String device, {
    required bool collects,
    int window = 2000,
    _FakeMailbox? via,
    String pairId = 'pair',
  }) => MirrorSyncRepository(
    via ?? mailbox,
    MirrorDocuments(cipher),
    MessageHistory(database(device), pairId, maxNotifications: window),
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

  // ---------------------------------------------------------------- delivery

  test('a message delivered twice (the server retrying) is kept once', () async {
    final phone = repository('phone', collects: false);
    final desktop = repository('desktop', collects: true);
    await phone.publish(message('Are you coming?', DateTime(2026, 11, 3, 9)), canReply: true);
    final first = (await feedWhere(desktop, (items) => items.isNotEmpty)).single;
    await settle();

    // the same document again, as a retried delivery would bring it
    await mailbox.create('notifications', first.id, {
      'payload': (await MirrorDocuments(cipher).notification(first.content, canReply: true))['payload'],
      'postedAt': first.postedAt,
      'canReply': true,
    });
    final reopened = repository('desktop', collects: true);
    List<MirroredNotification>? again;
    final watching = reopened.watchNotifications().listen((items) => again = items);
    addTearDown(watching.cancel);
    await settle();
    expect(again!.map((n) => n.id), [first.id]);
    expect(mailbox.waiting('notifications'), isEmpty, reason: 'acknowledged again');
  });

  test(
    'when the acknowledgement fails, the message is kept, stays on the server, and is collected once more',
    () async {
      final phone = repository('phone', collects: false);
      mailbox.refuseDeletes = StateError('unavailable');
      final desktop = repository('desktop', collects: true);
      await phone.publish(message('Keep me', DateTime(2026, 11, 3, 9)), canReply: false);
      expect((await feedWhere(desktop, (items) => items.isNotEmpty)).single.content.text, 'Keep me');
      await settle();
      expect(mailbox.waiting('notifications'), hasLength(1), reason: 'not acknowledged: the server keeps it');

      // the app reopens with the server reachable again: it picks up where it left off
      mailbox.refuseDeletes = null;
      final reopened = repository('desktop', collects: true);
      final items = await feedWhere(reopened, (items) => items.isNotEmpty);
      await settle();
      expect(items.map((n) => n.content.text), ['Keep me']);
      expect(mailbox.waiting('notifications'), isEmpty);
    },
  );

  test('reopening the app collects what arrived while it was closed', () async {
    final phone = repository('phone', collects: false);
    final desktop = repository('desktop', collects: true);
    await phone.publish(message('Before', DateTime(2026, 11, 3, 9)), canReply: false);
    await feedWhere(desktop, (items) => items.length == 1);
    await settle();

    await phone.publish(message('While closed', DateTime(2026, 11, 3, 10)), canReply: false);
    final reopened = await feedWhere(repository('desktop', collects: true), (items) => items.length == 2);
    expect(reopened.map((n) => n.content.text), ['While closed', 'Before']);
  });

  test('each paired device acknowledges its own copy', () async {
    final other = _FakeMailbox();
    final toMac = repository('phone', collects: false);
    final toPc = repository('phone', collects: false, via: other, pairId: 'pair2');
    final at = DateTime(2026, 11, 3, 9);
    await toMac.publish(message('For both', at), canReply: false);
    await toPc.publish(message('For both', at), canReply: false);

    await feedWhere(repository('mac', collects: true), (items) => items.isNotEmpty);
    await settle();
    expect(mailbox.waiting('notifications'), isEmpty, reason: 'the Mac has its copy');
    expect(other.waiting('notifications'), hasLength(1), reason: 'the PC has not collected its own yet');

    await feedWhere(repository('pc', collects: true, via: other, pairId: 'pair2'), (items) => items.isNotEmpty);
    await settle();
    expect(other.waiting('notifications'), isEmpty);
  });

  // ---------------------------------------------------------------- search and browsing

  /// The desktop's history after the phone mirrored [count] notifications: every even one "Order #i shipped" from the
  /// shop app, every odd one "Lunch i?" from WhatsApp, one minute apart.
  Future<void> mirrored(int count) async {
    final phone = repository('phone', collects: false);
    final collector = repository('desktop', collects: true);
    final watching = collector.watchNotifications().listen((_) {});
    for (var i = 0; i < count; i++) {
      final content = i.isEven
          ? NotificationContent(
              key: 'shop-$i',
              packageName: 'com.shop',
              appName: 'Shop',
              title: 'Shop',
              text: 'Order #$i shipped',
              postedAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
            )
          : message('Lunch $i?', DateTime(2026, 1, 1).add(Duration(minutes: i)), key: 'chat-$i');
      await phone.publish(content, canReply: false);
    }
    while (mailbox.waiting('notifications').isNotEmpty) {
      await settle();
    }
    await settle();
    await watching.cancel();
  }

  test('search reads the whole history from the database a page at a time, newest first, each once', () async {
    await mirrored(130);
    // the screens keep only the newest 10 loaded; search is not limited by that
    final desktop = repository('desktop', collects: true, window: 10);
    const query = HistoryQuery(text: 'ORDER');
    expect(await desktop.countHistory(query), 65);

    final seen = <String>[];
    HistoryCursor? cursor;
    var pages = 0;
    do {
      final page = await desktop.browseHistory(query, after: cursor, limit: 50);
      seen.addAll(page.notifications.map((n) => n.content.text));
      cursor = page.next;
      pages++;
    } while (cursor != null);
    expect(pages, 2);
    expect(seen, hasLength(65));
    expect(seen.toSet(), hasLength(65), reason: 'no notification on two pages');
    expect(seen.first, 'Order #128 shipped');
    expect(seen.last, 'Order #0 shipped');

    // filters run in the database too
    expect(await desktop.countHistory(const HistoryQuery(packageName: 'com.whatsapp')), 65);
    expect(await desktop.countHistory(const HistoryQuery(text: '#12')), 6, reason: '#12, #120 … #128');
    expect(await desktop.countHistory(const HistoryQuery(text: 'lu')), 65, reason: 'short queries match too');
    expect(
      await desktop.countHistory(
        HistoryQuery(text: 'order', after: DateTime(2026, 1, 1).add(const Duration(minutes: 119))),
      ),
      5,
    );
  });

  test('a search is a snapshot: what is saved after it stays out of its pages until asked for', () async {
    await mirrored(4);
    final desktop = repository('desktop', collects: true);
    final first = await desktop.browseHistory(const HistoryQuery(text: 'order'));
    expect(first.notifications, hasLength(2));
    final snapshot = const HistoryQuery(text: 'order').saved(upTo: first.saved);

    // sent long before the others, delivered now: still new to this search
    await repository('phone', collects: false).publish(
      NotificationContent(
        key: 'late',
        packageName: 'com.shop',
        appName: 'Shop',
        title: 'Shop',
        text: 'Order #99 shipped',
        postedAt: DateTime(2025),
      ),
      canReply: false,
    );
    await feedWhere(desktop, (items) => items.length == 5);
    expect((await desktop.browseHistory(snapshot)).notifications, hasLength(2));
    expect(await desktop.countHistory(snapshot), 2);
    final added = await desktop.browseHistory(const HistoryQuery(text: 'order').saved(after: first.saved));
    expect(added.notifications.single.content.text, 'Order #99 shipped');
  });

  test('history kept before search existed becomes searchable, with its app', () async {
    final db = database('desktop');
    final documents = MirrorDocuments(cipher);
    final at = DateTime(2026, 3, 1);
    await MessageHistory(db, 'pair').putNotifications([
      StoredNotification(
        id: 'old',
        payload:
            (await documents.notification(message('Boarding pass for Goa', at), canReply: false))['payload']! as String,
        postedAt: at,
      ),
    ]);
    final desktop = MirrorSyncRepository(mailbox, documents, MessageHistory(db, 'pair'), collects: true);
    final watching = desktop.watchNotifications().listen((_) {});
    await settle();
    expect((await desktop.browseHistory(const HistoryQuery(text: 'goa'))).notifications.single.id, 'old');
    expect(await desktop.countHistory(const HistoryQuery(packageName: 'com.whatsapp')), 1);
    await watching.cancel();
  });

  for (final from in [1, 2, 3]) {
    test('a version $from database upgrades in place, and its history becomes searchable', () async {
      final file = File('${files.path}/upgrade.sqlite');
      final old = HistoryDatabase(NativeDatabase(file));
      final documents = MirrorDocuments(cipher);
      final at = DateTime(2026, 3, 1);
      await MessageHistory(old, 'pair').putNotifications([
        StoredNotification(
          id: 'n',
          payload:
              (await documents.notification(message('Parcel arrives Tuesday', at), canReply: false))['payload']!
                  as String,
          postedAt: at,
        ),
      ]);
      // back to how that version left it
      await old.customStatement('DROP INDEX replies_by_notification');
      if (from < 3) {
        await old.customStatement('DROP TABLE history_fts');
        await old.customStatement('DROP INDEX notifications_by_app');
        await old.customStatement('ALTER TABLE history_notifications DROP COLUMN package_name');
      }
      if (from == 2) await old.customStatement('CREATE TABLE history_search (pair_id TEXT, id TEXT, content TEXT)');
      await old.customStatement('PRAGMA user_version = $from');
      await old.close();

      final upgraded = database('upgrade');
      final desktop = MirrorSyncRepository(mailbox, documents, MessageHistory(upgraded, 'pair'), collects: true);
      final watching = desktop.watchNotifications().listen((_) {});
      expect((await desktop.watchNotifications().first).single.content.text, 'Parcel arrives Tuesday');
      await settle();
      expect((await desktop.browseHistory(const HistoryQuery(text: 'parcel'))).notifications, hasLength(1));
      final indexes = await upgraded.customSelect("SELECT name FROM sqlite_master WHERE type = 'index'").get();
      expect([
        for (final r in indexes) r.read<String>('name'),
      ], containsAll(['replies_by_notification', 'notifications_by_app']));
      await watching.cancel();
    });
  }

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
