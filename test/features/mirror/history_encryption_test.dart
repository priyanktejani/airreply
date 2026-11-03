import 'dart:convert';
import 'dart:io';

import 'package:air_reply/features/mirror/data/history_connection_io.dart';
import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/data/history_key.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// The history file at rest: what someone copying it off the device would get.
void main() {
  late Directory dir;
  late String path;
  final key = 'a1' * 32;
  final otherKey = 'b2' * 32;
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('air_reply_crypt');
    path = '${dir.path}/history.sqlite';
  });
  tearDown(() => dir.delete(recursive: true));

  /// A connection as the app opens one, with [hexKey] (none: plain SQLite, as the previous version kept it).
  HistoryDatabase open({String? hexKey}) =>
      HistoryDatabase(NativeDatabase(File(path), setup: hexKey == null ? null : historyOptions(hexKey).setup));

  Future<void> keep(HistoryDatabase db, String text) async {
    final history = MessageHistory(db, 'pixel');
    await history.putNotifications([StoredNotification(id: 'n1', payload: 'sealed', postedAt: DateTime(2026))]);
    await history.index({'n1': (content: text, packageName: 'com.bank')});
    await db.close();
  }

  bool fileMentions(String text) {
    final bytes = File(path).readAsBytesSync();
    return latin1.decode(bytes, allowInvalid: true).contains(text);
  }

  test('the file, search index included, is unreadable without the key', () async {
    await keep(open(hexKey: key), 'otp 482913 for your card');
    expect(fileMentions('482913'), isFalse);
    expect(fileMentions('SQLite format 3'), isFalse);
    expect(fileMentions('com.bank'), isFalse);

    final reopened = open(hexKey: key);
    expect(await MessageHistory(reopened, 'pixel').count(text: '482913'), 1);
    await reopened.close();
  });

  test('history kept before encryption is encrypted in place, nothing lost', () async {
    await keep(open(), 'parcel arrives tuesday'); // plain SQLite, as the previous version kept it
    expect(fileMentions('parcel arrives tuesday'), isTrue);

    final encrypted = open(hexKey: key);
    expect(await MessageHistory(encrypted, 'pixel').count(text: 'parcel'), 1);
    await encrypted.close();
    expect(fileMentions('parcel arrives tuesday'), isFalse);
    expect(fileMentions('SQLite format 3'), isFalse);
  });

  test('a file whose key is gone is started afresh rather than breaking the app', () async {
    await keep(open(hexKey: key), 'old secret');
    final fresh = open(hexKey: otherKey);
    final history = MessageHistory(fresh, 'pixel');
    expect((await history.load()).notifications, isEmpty);
    await history.putNotifications([StoredNotification(id: 'n2', payload: 'sealed', postedAt: DateTime(2026))]);
    await fresh.close();

    // the fresh history is encrypted with the new key, and kept
    expect(fileMentions('SQLite format 3'), isFalse);
    final reopened = open(hexKey: otherKey);
    expect((await MessageHistory(reopened, 'pixel').load()).notifications.keys, ['n2']);
    await reopened.close();
  });

  test('two connections at once, as the app and the background engine open it', () async {
    await keep(open(hexKey: key), 'shared');
    final app = open(hexKey: key);
    final engine = open(hexKey: key);
    await MessageHistory(
      engine,
      'pixel',
    ).putNotifications([StoredNotification(id: 'n2', payload: 'sealed', postedAt: DateTime(2026, 2))]);
    expect((await MessageHistory(app, 'pixel').load()).notifications.keys, unorderedEquals(['n1', 'n2']));
    await app.close();
    await engine.close();
  });

  test('one key per install, made once and kept by the system keystore', () async {
    final store = MemorySecretStore();
    final first = await HistoryKey(store).hex();
    expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(await HistoryKey(store).hex(), first);
    expect(await HistoryKey(MemorySecretStore()).hex(), isNot(first));
  });

  test('only a 64-digit hex key ever reaches SQL', () {
    expect(() => historyOptions("x'; DROP TABLE t; --"), throwsArgumentError);
  });
}
