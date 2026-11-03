import 'dart:async';
import 'dart:typed_data';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/mirror/domain/entities/history_query.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/history_providers.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

MirroredNotification _notification(int i, String text) => MirroredNotification(
  id: 'n$i',
  content: NotificationContent(
    key: 'key-$i',
    packageName: 'com.shop',
    appName: 'Shop',
    title: 'Shop',
    text: text,
    postedAt: DateTime(2026).add(Duration(minutes: i)),
  ),
  canReply: false,
  dismissedOnSender: false,
);

/// One phone's history on this device: [database] holds everything, the live feed only the newest three.
final class _Phone extends RecordingMirror {
  _Phone(int count)
    : database = [for (var i = 0; i < count; i++) _notification(i, i.isEven ? 'Order #$i shipped' : 'Lunch $i?')];

  final List<MirroredNotification> database;
  final _live = StreamController<List<MirroredNotification>>.broadcast();
  final queries = <String>[];

  /// Holds pages back until it completes: a slow database.
  Completer<void>? slow;

  List<MirroredNotification> get _newest =>
      ([...database]..sort((a, b) => b.postedAt.compareTo(a.postedAt))).take(3).toList();

  /// A notification arrives: saved, and shown live.
  void arrive(MirroredNotification n) {
    database.add(n);
    _live.add(_newest);
  }

  @override
  Stream<List<MirroredNotification>> watchNotifications({int limit = 2000}) async* {
    yield _newest;
    yield* _live.stream;
  }

  @override
  Stream<List<ReplyCommand>> watchReplies({int limit = 1000}) => Stream.value(const []);

  /// Where each notification was saved: its place in [database], from 1.
  int _saved(MirroredNotification n) => database.indexOf(n) + 1;

  Iterable<MirroredNotification> _matching(HistoryQuery q) {
    final text = q.text.toLowerCase();
    return ([...database]..sort((a, b) => b.postedAt.compareTo(a.postedAt))).where(
      (n) =>
          n.content.text.toLowerCase().contains(text) &&
          (q.savedUpTo == null || _saved(n) <= q.savedUpTo!) &&
          (q.savedAfter == null || _saved(n) > q.savedAfter!) &&
          (q.after == null || n.postedAt.isAfter(q.after!)),
    );
  }

  @override
  Future<HistoryPage> browseHistory(HistoryQuery query, {HistoryCursor? after, int limit = 50}) async {
    queries.add(query.text);
    await slow?.future;
    final saved = query.savedUpTo ?? database.length;
    final page = _matching(
      query.savedUpTo == null ? query.saved(upTo: saved, after: query.savedAfter) : query,
    ).where((n) => after == null || n.postedAt.isBefore(after.postedAt)).take(limit).toList();
    return (
      notifications: page,
      replies: const <ReplyCommand>[],
      next: page.length < limit ? null : (postedAt: page.last.postedAt, id: page.last.id),
      saved: saved,
    );
  }

  @override
  Future<int> countHistory(HistoryQuery query) async => _matching(query).length;
}

void main() {
  late _Phone phone;
  late ProviderContainer container;

  setUp(() {
    phone = _Phone(400);
    container = ProviderContainer(
      overrides: [
        pairedDevicesProvider.overrideWithValue([
          PairingCredentials(
            pairId: 'pixel',
            role: DeviceRole.receiver,
            sharedKey: Uint8List(32),
            peerName: 'Pixel 9',
            pairedAt: DateTime(2026),
          ),
        ]),
        deviceRoleProvider.overrideWithValue(DeviceRole.receiver),
        mirrorRepositoryProvider.overrideWith((ref, pairId) => phone),
      ],
    );
    addTearDown(container.dispose);
    // the inbox stays on screen
    for (final provider in [visibleFeedProvider, allFeedProvider]) {
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
    }
  });

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  List<String> inbox() => [
    for (final FeedEntry e in container.read(visibleFeedProvider).value ?? const []) e.notification.id,
  ];

  HistoryResultsController search() => container.read(historyResultsProvider(inboxSearch).notifier);

  test('search reads the database, not the loaded feed: far older matches, a page at a time', () async {
    await settle();
    expect(inbox(), ['n399', 'n398', 'n397'], reason: 'the live feed keeps only the newest');

    container.read(inboxFilterProvider.notifier).search('order');
    await settle();
    expect(inbox(), hasLength(HistoryResultsController.pageSize));
    expect(inbox().first, 'n398');
    expect(container.read(historyResultsProvider(inboxSearch)).total, 200);

    while (container.read(historyResultsProvider(inboxSearch)).hasMore) {
      await search().loadMore();
    }
    expect(inbox(), hasLength(200));
    expect(inbox().toSet(), hasLength(200), reason: 'each once');
    expect(inbox().last, 'n0');

    // a match found far back opens like any other
    expect(
      container.read(feedEntryProvider((pairId: 'pixel', id: 'n0')))?.notification.content.text,
      'Order #0 shipped',
    );
  });

  test('a phone is found as a device, not as every notification it sent', () async {
    container.read(inboxFilterProvider.notifier).search('pixel');
    await settle();
    expect(container.read(deviceMatchesProvider('pixel')).single.peerName, 'Pixel 9');
    expect(inbox(), isEmpty);
    expect(
      const FeedFilter(query: 'pixel').matches(
        FeedEntry(pairId: 'pixel', deviceName: 'Pixel 9', notification: _notification(1, 'hello')),
        isRead: (_) => true,
      ),
      isFalse,
    );
  });

  test('results hold still as notifications arrive; the new ones are offered, then added on top', () async {
    container.read(inboxFilterProvider.notifier).search('order');
    await settle();
    await search().loadMore();
    final before = inbox();
    expect(before, hasLength(100));
    final newCount = container.listen(newResultsProvider(inboxSearch), (_, _) {});
    addTearDown(newCount.close);

    phone
      ..arrive(_notification(1000, 'Order #1000 shipped'))
      ..arrive(_notification(1001, 'Lunch?'));
    await settle();
    expect(inbox(), before, reason: 'nothing moves under the reader');
    expect(newCount.read(), 1, reason: 'only the one that matches');

    await search().includeNew();
    await settle();
    expect(inbox(), ['n1000', ...before], reason: 'the pages read stay, the new one on top');
    expect(container.read(inboxFilterProvider).query, 'order');
    expect(newCount.read(), 0);
  });

  test('a message sent long ago but delivered late is offered too, and slots in by time', () async {
    container.read(inboxFilterProvider.notifier).search('order');
    await settle();
    final newCount = container.listen(newResultsProvider(inboxSearch), (_, _) {});
    addTearDown(newCount.close);
    // sent between the first two shown, delivered after the search started
    final late = MirroredNotification(
      id: 'late',
      content: NotificationContent(
        key: 'k',
        packageName: 'com.shop',
        appName: 'Shop',
        title: 'Shop',
        text: 'Order #late shipped',
        postedAt: DateTime(2026).add(const Duration(minutes: 397, seconds: 30)),
      ),
      canReply: false,
      dismissedOnSender: false,
    );
    phone.arrive(late);
    await settle();
    expect(inbox().take(2), ['n398', 'n396'], reason: 'not shown until asked for');
    expect(newCount.read(), 1);

    await search().includeNew();
    await settle();
    expect(inbox().take(3), ['n398', 'late', 'n396']);
  });

  test('typing on interrupts the search before: its late pages are dropped', () async {
    final first = phone.slow = Completer();
    container.read(inboxFilterProvider.notifier).search('ord');
    await settle();
    phone.slow = null;
    container.read(inboxFilterProvider.notifier).search('lunch');
    await settle();
    first.complete();
    await settle();
    expect(phone.queries, ['ord', 'lunch']);
    expect(inbox(), isNotEmpty);
    expect(inbox().every((id) => int.parse(id.substring(1)).isOdd), isTrue, reason: 'only lunches');
  });

  test("a phone's whole history, paged, joins the feed only while it is open", () async {
    final scope = deviceHistory('pixel');
    final history = container.read(historyResultsProvider(scope).notifier);
    await history.open(const HistoryQuery(), pairIds: ['pixel']);
    expect(container.read(historyEntriesProvider(scope)), hasLength(HistoryResultsController.pageSize));
    await history.loadMore();
    expect(container.read(historyEntriesProvider(scope)), hasLength(100));
    expect(container.read(feedEntryProvider((pairId: 'pixel', id: 'n300'))), isNotNull);
    expect(inbox(), hasLength(3), reason: 'the inbox and its counts are not changed by browsing');

    history.close();
    await settle();
    expect(container.read(feedEntryProvider((pairId: 'pixel', id: 'n300'))), isNull);
  });

  test("Home's search follows its box and reads the database too", () async {
    container.read(homeSearchQueryProvider.notifier).set('lunch');
    await settle();
    final found = container.read(historyEntriesProvider(homeSearch));
    expect(found, hasLength(HistoryResultsController.pageSize));
    expect(found.first.notification.id, 'n399');

    container.read(homeSearchQueryProvider.notifier).set('');
    await settle();
    expect(container.read(historyResultsProvider(homeSearch)).isActive, isFalse);
  });
}
