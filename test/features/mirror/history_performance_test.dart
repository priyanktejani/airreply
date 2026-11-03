import 'dart:io';

import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Search and browsing over a large history, in a database file as on a device: every query must stay quick however
/// deep the page. Timings are printed; the limits are generous so a slow test machine does not fail them.
void main() {
  const total = 100000;
  const limit = Duration(milliseconds: 300);
  late Directory dir;
  late HistoryDatabase db;
  late MessageHistory history;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('air_reply_perf');
    db = HistoryDatabase(NativeDatabase(File('${dir.path}/history.sqlite')));
    history = MessageHistory(db, 'pixel');
    // A year and more of notifications, one every five minutes: shop orders, chats and a bank's alerts. The payload
    // stands in for the sealed one; the search index is filled the way indexing fills it.
    final start = DateTime(2025);
    const apps = ['com.shop', 'com.whatsapp', 'com.bank'];
    for (var from = 0; from < total; from += 5000) {
      await history.putNotifications([
        for (var i = from; i < from + 5000; i++)
          StoredNotification(
            id: 'n${i.toString().padLeft(6, '0')}',
            payload: switch (i % 3) {
              0 => 'Shop\nOrder #$i shipped\nShop',
              1 => 'Alex\nLunch at ${i % 24}?\nWhatsApp',
              _ => 'Bank\nYou spent ₹${i % 900} at Café ${i % 50}\nBank',
            },
            postedAt: start.add(Duration(minutes: 5 * i)),
          ),
      ]);
    }
    await db.customStatement(
      'INSERT INTO history_fts (rowid, content) SELECT rowid, lower(payload) FROM history_notifications',
    );
    for (final (i, app) in apps.indexed) {
      await db.customUpdate(
        'UPDATE history_notifications SET package_name = ? WHERE CAST(substr(id, 2) AS INTEGER) % 3 = ?',
        variables: [Variable.withString(app), Variable.withInt(i)],
      );
    }
  });

  tearDownAll(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<T> timed<T>(String what, Future<T> Function() run) async {
    final watch = Stopwatch()..start();
    final result = await run();
    watch.stop();
    // ignore: avoid_print
    print('${what.padRight(48)} ${watch.elapsedMilliseconds} ms');
    expect(watch.elapsed, lessThan(limit), reason: what);
    return result;
  }

  test('searching $total notifications: first page, a deep page and the count stay quick', () async {
    final first = await timed('search "order", first page', () => history.page(text: 'order'));
    expect(first, hasLength(50));
    expect(first.first.id, 'n099999');

    // 600 pages in, by cursor: as quick as the first
    var cursor = (postedAt: first.last.postedAt, id: first.last.id);
    for (var i = 0; i < 600; i++) {
      final page = await history.page(text: 'order', cursor: cursor);
      cursor = (postedAt: page.last.postedAt, id: page.last.id);
    }
    final deep = await timed('search "order", page 602', () => history.page(text: 'order', cursor: cursor));
    expect(deep, hasLength(50));

    expect(await timed('count "order"', () => history.count(text: 'order')), 33334);
    expect(await timed('count "café 7"', () => history.count(text: 'café 7')), greaterThan(0));
    await timed('search a word that is nowhere', () => history.page(text: 'zzzqqq'));
  });

  test('short queries, filters and browsing a phone stay quick', () async {
    expect(await timed('search "lu" (two letters: scanned)', () => history.page(text: 'lu')), hasLength(50));
    expect(
      await timed('search "order", one app', () => history.page(text: 'order', packageName: 'com.shop')),
      hasLength(50),
    );
    expect(
      await timed('one app, no text', () => history.page(packageName: 'com.bank')),
      everyElement(isA<StoredNotification>()),
    );
    expect(
      await timed(
        'last 7 days of "order"',
        () => history.page(
          text: 'order',
          after: DateTime(2025).add(const Duration(minutes: 5 * 98000)),
        ),
      ),
      hasLength(50),
    );
    final browse = await timed('browse the phone, first page', history.page);
    var cursor = (postedAt: browse.last.postedAt, id: browse.last.id);
    for (var i = 0; i < 1500; i++) {
      final page = await history.page(cursor: cursor);
      cursor = (postedAt: page.last.postedAt, id: page.last.id);
    }
    expect(await timed('browse the phone, page 1502', () => history.page(cursor: cursor)), hasLength(50));
    expect(await timed('count everything', history.count), total);
  });

  test('indexing a batch of old history (as the feed opens) is quick per batch', () async {
    final batch = await history.unindexed();
    expect(batch, isEmpty, reason: 'the fixture is indexed');
    final watch = Stopwatch()..start();
    await history.index({
      for (var i = 0; i < 300; i++)
        'n${i.toString().padLeft(6, '0')}': (content: 'reindexed $i', packageName: 'com.shop'),
    });
    watch.stop();
    // ignore: avoid_print
    print('${'index a batch of 300'.padRight(48)} ${watch.elapsedMilliseconds} ms');
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(await history.count(text: 'reindexed'), 300);
  });
}
