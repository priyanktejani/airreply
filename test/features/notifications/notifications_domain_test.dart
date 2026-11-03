import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/notifications/data/local_stores.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/inbox_state.dart';
import 'package:air_reply/features/notifications/domain/send_reply.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fakes.dart';

MirroredNotification notification(
  String id,
  DateTime at, {
  bool canReply = true,
  bool dismissed = false,
  String package = 'org.telegram.messenger',
  String? key,
}) => MirroredNotification(
  id: id,
  canReply: canReply,
  dismissedOnSender: dismissed,
  content: NotificationContent(
    key: key ?? 'key-$id',
    packageName: package,
    appName: 'Telegram',
    title: 'Sam',
    text: 'Lunch?',
    postedAt: at,
  ),
);

ReplyCommand reply(String id, String notificationId, DateTime at, ReplyStatus status) =>
    ReplyCommand(id: id, notificationId: notificationId, text: 'Yes', status: status, createdAt: at);

FeedEntry entry(String id, DateTime at, {String pairId = 'pixel', String? key}) => FeedEntry(
  pairId: pairId,
  deviceName: pairId,
  notification: notification(id, at, key: key),
);

void main() {
  final t0 = DateTime(2026, 10, 24, 9);
  bool unread(FeedEntry _) => false;

  group('feed', () {
    test('orders newest first and threads replies oldest first', () {
      final feed = buildFeed(
        [notification('a', t0), notification('b', t0.add(const Duration(minutes: 5)))],
        [
          reply('r2', 'a', t0.add(const Duration(minutes: 2)), ReplyStatus.pending),
          reply('r1', 'a', t0.add(const Duration(minutes: 1)), ReplyStatus.sent),
          reply('x', 'missing', t0, ReplyStatus.sent),
        ],
        pairId: 'p1',
        deviceName: 'Pixel 9',
      );

      expect(feed.map((e) => e.notification.id), ['b', 'a']);
      expect(feed.every((e) => e.pairId == 'p1' && e.deviceName == 'Pixel 9'), isTrue);
      expect(feed[0].replies, isEmpty);
      expect(feed[1].replies.map((r) => r.id), ['r1', 'r2']);
      expect(feed[1].latestReply?.status, ReplyStatus.pending);
      expect(feed[1].key, 'p1/a');
    });

    test('merges several phones by time and filters by phone and app', () {
      final pixel = buildFeed([notification('a', t0)], const [], pairId: 'pixel', deviceName: 'Pixel');
      final galaxy = buildFeed(
        [notification('b', t0.add(const Duration(minutes: 1)), package: 'com.whatsapp')],
        const [],
        pairId: 'galaxy',
        deviceName: 'Galaxy',
      );

      final merged = mergeFeeds([pixel, galaxy]);
      expect(merged.map((e) => e.deviceName), ['Galaxy', 'Pixel']);

      List<String> ids(FeedFilter f) => [
        for (final e in merged)
          if (f.matches(e, isRead: unread, now: t0)) e.notification.id,
      ];
      expect(ids(const FeedFilter(pairId: 'pixel')), ['a']);
      expect(ids(const FeedFilter(packageName: 'com.whatsapp')), ['b']);
      expect(ids(const FeedFilter(pairId: 'pixel', packageName: 'com.whatsapp')), isEmpty);
      expect(ids(FeedFilter.none), hasLength(2));
    });

    test('a sender sees one entry per notification, naming every device and carrying all replies', () {
      // The same capture was published to two devices, each with its own document id; each device replied.
      final mac = buildFeed(
        [notification('m1', t0, key: 'k')],
        [reply('rm', 'm1', t0.add(const Duration(minutes: 2)), ReplyStatus.sent)],
        pairId: 'mac',
        deviceName: 'Mac',
      );
      final ipad = buildFeed(
        [notification('i1', t0, key: 'k')],
        [reply('ri', 'i1', t0.add(const Duration(minutes: 1)), ReplyStatus.pending)],
        pairId: 'ipad',
        deviceName: 'iPad',
      );

      expect(mergeFeeds([mac, ipad]), hasLength(2));
      final merged = mergeFeeds([mac, ipad], dedupe: true);
      expect(merged, hasLength(1));
      expect(merged.single.deviceName, contains('Mac'));
      expect(merged.single.deviceName, contains('iPad'));
      expect(merged.single.replies.map((r) => r.id), ['ri', 'rm']);
    });

    test('search matches title, text, app and phone name, ignoring case', () {
      final feed = buildFeed([notification('a', t0)], const [], pairId: 'pixel', deviceName: 'Pixel 9');
      bool hit(String q) => FeedFilter(query: q).matches(feed.single, isRead: unread, now: t0);

      expect(hit('sam'), isTrue); // title
      expect(hit('LUNCH'), isTrue); // text
      expect(hit('telegram'), isTrue); // app
      expect(hit('pixel'), isTrue); // phone
      expect(hit('dinner'), isFalse);
      expect(hit('   '), isTrue);
    });

    test('unread-only and time filters, and the filter count', () {
      final now = DateTime(2026, 10, 24, 18);
      final today = entry('a', DateTime(2026, 10, 24, 8));
      final lastWeek = entry('b', DateTime(2026, 10, 20, 8));
      final old = entry('c', DateTime(2026, 9, 1));
      bool isRead(FeedEntry e) => e.notification.id == 'a';

      List<String> ids(FeedFilter f) => [
        for (final e in [today, lastWeek, old])
          if (f.matches(e, isRead: isRead, now: now)) e.notification.id,
      ];
      expect(ids(const FeedFilter(period: FeedPeriod.today)), ['a']);
      expect(ids(const FeedFilter(period: FeedPeriod.week)), ['a', 'b']);
      expect(ids(const FeedFilter(unreadOnly: true)), ['b', 'c']);

      const filter = FeedFilter(unreadOnly: true, period: FeedPeriod.week, query: 'x');
      expect(filter.activeCount, 2); // search is not counted as a filter
      expect(filter.isActive, isTrue);
      expect(filter.copyWith(pairId: () => 'p').activeCount, 3);
      expect(filter.copyWith(query: '').copyWith(unreadOnly: false, period: FeedPeriod.all).isActive, isFalse);
    });
  });

  group('inbox state', () {
    final old = entry('old', DateTime(2026, 10, 24, 8));
    final fresh = entry('new', DateTime(2026, 10, 24, 10));
    final start = InboxState(readBefore: DateTime(2026, 10, 24, 9));

    test('everything before the first launch counts as read', () {
      expect(start.isRead(old), isTrue);
      expect(start.isRead(fresh), isFalse);
      expect(const InboxState().isRead(old), isFalse);
    });

    test('marks single notifications read and unread, overriding the cut-off', () {
      final read = start.markRead([fresh.key]);
      expect(read.isRead(fresh), isTrue);
      expect(read.markUnread([fresh.key]).isRead(fresh), isFalse);
      expect(start.markUnread([old.key]).isRead(old), isFalse);
    });

    test('mark all as read moves the cut-off and clears exceptions, but keeps hidden', () {
      final state = start.markUnread([old.key]).hide([fresh.key]).markAllRead(DateTime(2026, 10, 24, 11));
      expect(state.isRead(old), isTrue);
      expect(state.isRead(fresh), isTrue);
      expect(state.unread, isEmpty);
      expect(state.isHidden(fresh), isTrue);
    });

    test('hides, unhides and restores', () {
      final hidden = start.hide([old.key, fresh.key]);
      expect(hidden.isHidden(old) && hidden.isHidden(fresh), isTrue);
      expect(hidden.unhide([old.key]).isHidden(old), isFalse);
      expect(hidden.restoreHidden().hidden, isEmpty);
    });

    test('survives a JSON round trip and stays bounded', () {
      final state = start.markRead(['a']).markUnread(['b']).hide(['c']);
      final back = InboxState.fromJson(state.toJson());
      expect(back.readBefore, state.readBefore);
      expect(back.read, {'a'});
      expect(back.unread, {'b'});
      expect(back.hidden, {'c'});

      final many = start.hide([for (var i = 0; i < InboxState.maxKept + 50; i++) 'k$i']);
      expect(many.hidden, hasLength(InboxState.maxKept));
      expect(many.hidden, contains('k${InboxState.maxKept + 49}')); // the newest are kept
    });

    test('is stored on the device', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final store = PreferencesInboxStateStore(SharedPreferencesAsync());
      expect(await store.load(), isNull);
      await store.save(start.hide(['x']));
      final loaded = await store.load();
      expect(loaded?.readBefore, start.readBefore);
      expect(loaded?.hidden, {'x'});
    });
  });

  test('time labels', () {
    final now = DateTime(2026, 10, 24, 15);
    expect(formatDayLabel(DateTime(2026, 10, 24, 1), now: now), 'Today');
    expect(formatDayLabel(DateTime(2026, 10, 23, 23), now: now), 'Yesterday');
    expect(formatDayLabel(DateTime(2026, 10, 20), now: now), 'Tuesday');
    expect(formatDayLabel(DateTime(2026, 3, 12), now: now), '12 March');
    expect(formatDayLabel(DateTime(2025, 3, 12), now: now), '12 March 2025');
    expect(formatLongDate(DateTime(2026, 10, 24), now: now), 'Saturday, 24 October');
    expect(formatTimestamp(DateTime(2026, 10, 24, 9, 5), now: now), 'Today at 09:05');
    expect(formatAgo(DateTime(2026, 10, 24, 14, 56), now: now), '4 min ago');
    expect(formatAgo(DateTime(2026, 10, 24, 14, 59, 50), now: now), 'just now');
    expect(formatAgo(DateTime(2026, 10, 24, 12), now: now), '3 h ago');
  });

  group('SendReply', () {
    late RecordingMirror outbox;
    late SendReply sendReply;

    setUp(() {
      outbox = RecordingMirror();
      sendReply = SendReply(outbox);
    });

    test('queues the trimmed text with the source notification key', () async {
      await sendReply(notification('a', t0), '  On my way  ');

      expect(outbox.sent.single.notificationId, 'a');
      expect(outbox.sent.single.notificationKey, 'key-a');
      expect(outbox.sent.single.text, 'On my way');
    });

    test('refuses empty text, unanswerable and dismissed notifications', () {
      expect(() => sendReply(notification('a', t0), '   '), throwsA(isA<ValidationException>()));
      expect(() => sendReply(notification('a', t0, canReply: false), 'hi'), throwsA(isA<ValidationException>()));
      expect(() => sendReply(notification('a', t0, dismissed: true), 'hi'), throwsA(isA<ValidationException>()));
      expect(outbox.sent, isEmpty);
    });
  });

  test('ReplyStatus uses the wire values the sender writes', () {
    expect(ReplyStatus.parse('PENDING'), ReplyStatus.pending);
    expect(ReplyStatus.parse('SENT'), ReplyStatus.sent);
    expect(ReplyStatus.parse('FAILED_EXPIRED'), ReplyStatus.expired);
    expect(ReplyStatus.parse('something else'), ReplyStatus.failed);
  });
}
