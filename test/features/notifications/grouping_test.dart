import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/sender/domain/usecases/relay_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

final t0 = DateTime(2026, 10, 25, 9);

MirroredNotification note(
  String id, {
  String package = 'com.whatsapp',
  String app = 'WhatsApp',
  String title = 'Alex',
  String text = 'Hi',
  int minute = 0,
  bool canReply = true,
  bool? isMessage = true,
  String? chat,
  String? group,
  String? sender,
  String? key,
}) => MirroredNotification(
  id: id,
  canReply: canReply,
  dismissedOnSender: false,
  content: NotificationContent(
    key: key ?? 'key-$id',
    packageName: package,
    appName: app,
    title: title,
    text: sender == null ? text : '$sender: $text',
    postedAt: t0.add(Duration(minutes: minute)),
    conversationTitle: group,
    isGroupConversation: group != null,
    sender: sender,
    conversationId: chat,
    isMessage: isMessage,
  ),
);

FeedEntry entry(MirroredNotification n, {String pairId = 'pixel', List<ReplyCommand> replies = const []}) =>
    FeedEntry(pairId: pairId, deviceName: pairId, notification: n, replies: replies);

void main() {
  group('which conversation a notification belongs to', () {
    test('a one-to-one chat is its conversation id and its person: two contacts are never one chat', () {
      final a = threadIdentity(note('1', title: 'Alex', chat: 'c1'));
      expect(a.kind, ThreadKind.person);
      expect(threadIdentity(note('2', title: 'alex', chat: 'c1')).key, a.key);
      expect(threadIdentity(note('3', title: 'Alex', chat: 'c2')).key, isNot(a.key));
      // an app that reuses one id for every chat still keeps its contacts apart
      expect(threadIdentity(note('4', title: 'Mom', chat: 'c1')).key, isNot(a.key));
      // a group chat is its id, whoever writes in it
      final dad = threadIdentity(note('5', title: 'Family', group: 'Family', sender: 'Dad', chat: 'g'));
      final riya = threadIdentity(note('6', title: 'Family', group: 'Family', sender: 'Riya', chat: 'g'));
      expect(dad.key, riya.key);
      expect(dad.kind, ThreadKind.group);
    });

    test('contacts sharing a conversation id never mix, and your own message joins the only chat that fits', () {
      final threads = groupByApp([
        entry(note('alex', title: 'Alex', text: 'Dinner?', minute: 1, chat: 'shared')),
        entry(note('mom', title: 'Mom', text: 'Call me', minute: 2, chat: 'shared')),
        entry(note('you', title: 'You', text: 'Sure', minute: 3, chat: 'solo')),
        entry(note('sam', title: 'Sam', text: 'Hey', minute: 0, chat: 'solo')),
      ]).single.threads;
      final byTitle = {for (final t in threads) t.title: t.entries.map((e) => e.notification.id).toSet()};
      expect(byTitle['Alex'], {'alex'});
      expect(byTitle['Mom'], {'mom'});
      expect(byTitle['Sam'], {'sam', 'you'});
    });

    test('your own message stays apart when more than one chat could be its home', () {
      // one notification key shared by two chats (some apps post every chat under one)
      final threads = groupByApp([
        entry(note('alex', title: 'Alex', minute: 1, key: 'shared')),
        entry(note('mom', title: 'Mom', minute: 2, key: 'shared')),
        entry(note('you', title: 'You', text: 'Typed on the phone', minute: 3, key: 'shared')),
      ]).single.threads;
      expect(threads, hasLength(3));
      expect(threads.where((t) => t.entries.any((e) => e.notification.id == 'you')).single.count, 1);
    });

    test('group chats by their name, with the sender kept per message', () {
      final dad = note('1', title: 'Family', group: 'Family', sender: 'Dad');
      final riya = note('2', title: 'Family', group: ' family ', sender: 'Riya');
      expect(threadIdentity(dad).key, threadIdentity(riya).key);
      expect(threadIdentity(dad).kind, ThreadKind.group);
      expect(messageText(dad.content), 'Hi');
      expect(messageSender(entry(dad), ThreadKind.group), 'Dad');
    });

    test('messages from one person, however the number is formatted', () {
      final a = threadIdentity(note('1', title: '+91 74052 94614'));
      final b = threadIdentity(note('2', title: '+91 74052-94614'));
      final c = threadIdentity(note('3', title: '+91 (74052) 94614 (2 messages)'));
      expect(a.kind, ThreadKind.person);
      expect({a.key, b.key, c.key}, hasLength(1));
      expect(threadIdentity(note('4', title: 'ALEX  morgan')).key, threadIdentity(note('5', title: 'Alex Morgan')).key);
    });

    test('never groups when the sender is unknown', () {
      // An app's own notices, even with the same title.
      final backup1 = threadIdentity(note('1', title: 'Backup', isMessage: false, canReply: false));
      final backup2 = threadIdentity(note('2', title: 'Backup', isMessage: false, canReply: false));
      expect(backup1.kind, ThreadKind.single);
      expect(backup1.key, isNot(backup2.key));
      // Messages whose title names no one: empty, the app itself, or a count.
      for (final title in ['', 'WhatsApp', '3 new messages', '2 messages']) {
        expect(threadIdentity(note(title, title: title)).kind, ThreadKind.single, reason: title);
      }
    });

    test('notifications mirrored before message metadata existed fall back to "can be answered"', () {
      expect(threadIdentity(note('1', title: 'Sam', isMessage: null)).kind, ThreadKind.person);
      expect(threadIdentity(note('2', title: 'Sam', isMessage: null, canReply: false)).kind, ThreadKind.single);
    });

    test('updates of one notification stay together even without a sender', () {
      final first = threadIdentity(note('1', title: 'Download', isMessage: false));
      final update = MirroredNotification(
        id: '2',
        canReply: false,
        dismissedOnSender: false,
        content: note('1', title: 'Download complete', isMessage: false).content,
      );
      expect(threadIdentity(update).key, first.key);
    });
  });

  group('app groups', () {
    final entries = [
      entry(note('a1', title: 'Alex', minute: 30, chat: 'alex')),
      entry(note('m1', title: 'Mom', minute: 20, chat: 'mom')),
      entry(note('a0', title: 'Alex', minute: 10, chat: 'alex')),
      entry(
        note('s1', package: 'com.Slack', app: 'Slack', title: '#launch', minute: 25, group: '#launch', sender: 'P'),
      ),
      entry(note('g1', package: 'com.google.android.gm', app: 'Gmail', title: 'Stripe', minute: 5, isMessage: false)),
      entry(note('g2', package: 'com.google.android.gm', app: 'Gmail', title: 'Stripe', minute: 4, isMessage: false)),
    ];

    test('one group per app, latest activity first, with threads inside', () {
      final groups = groupByApp(entries);
      expect(groups.map((g) => g.appName), ['WhatsApp', 'Slack', 'Gmail']);

      final whatsapp = groups.first;
      expect(whatsapp.count, 3);
      expect(whatsapp.latest.notification.id, 'a1');
      expect(whatsapp.threads.map((t) => t.title), ['Alex', 'Mom']);
      expect(whatsapp.threads.first.entries.map((e) => e.notification.id), ['a1', 'a0']);
      expect(whatsapp.hasThreads, isTrue);

      // Two emails from the same sender stay two notifications.
      final gmail = groups.last;
      expect(gmail.threads, hasLength(2));
      expect(gmail.threads.every((t) => t.kind == ThreadKind.single), isTrue);
    });

    test('a reply counts as activity and moves its conversation up', () {
      final reply = ReplyCommand(
        id: 'r',
        notificationId: 'm1',
        text: 'On my way',
        status: ReplyStatus.sent,
        createdAt: t0.add(const Duration(minutes: 40)),
      );
      final withReply = [
        for (final e in entries) e.notification.id == 'm1' ? entry(e.notification, replies: [reply]) : e,
      ];
      final whatsapp = groupByApp(withReply).first;
      expect(whatsapp.threads.first.title, 'Mom');
      expect(whatsapp.lastActivity, reply.createdAt);
    });

    test('new notifications merge into their group and conversation', () {
      final later = [entry(note('a2', title: 'Alex', minute: 50, chat: 'alex')), ...entries];
      final whatsapp = groupByApp(later).first;
      expect(whatsapp.count, 4);
      expect(whatsapp.threads.first.count, 3);
      expect(whatsapp.threads.first.latest.notification.id, 'a2');
    });

    test('receivers keep each phone apart; senders gather every device under one group', () {
      final twoPhones = [
        entry(note('1', chat: 'x'), pairId: 'pixel'),
        entry(note('2', chat: 'x', minute: 1), pairId: 'galaxy'),
      ];
      expect(groupByApp(twoPhones), hasLength(2));

      final merged = groupByApp(twoPhones, perDevice: false);
      expect(merged.single.source, AppGroup.allDevices);
      expect(merged.single.threads.single.count, 2);
    });

    test('the reply target is the newest notification that can still be answered', () {
      final thread = groupByApp([
        entry(note('new', title: 'Alex', minute: 9, canReply: false, isMessage: true, chat: 'a')),
        entry(note('old', title: 'Alex', minute: 1, chat: 'a')),
      ]).single.threads.single;
      expect(thread.replyTarget?.notification.id, 'old');
    });
  });

  group('searching an app\'s conversations', () {
    final threads = groupByApp([
      entry(note('1', title: '+91 74052 94614', text: 'At the gate', chat: 'n')),
      entry(note('2', title: 'Family', group: 'Family', sender: 'Riya', text: 'Landed', minute: 1)),
      entry(note('3', title: 'Alex', text: 'See you at 7', minute: 2, chat: 'a')),
    ]).single.threads;

    List<String> search(String q) => [for (final t in threads.where((t) => threadMatches(t, q))) t.title];

    test('by name, sender or message, ignoring case', () {
      expect(search(''), hasLength(3));
      expect(search('ALEX'), ['Alex']);
      expect(search('riya'), ['Family']);
      expect(search('gate'), ['+91 74052 94614']);
      expect(search('nobody'), isEmpty);
    });

    test('by number, however it is written', () {
      expect(search('7405294614'), ['+91 74052 94614']);
      expect(search('74052-946'), ['+91 74052 94614']);
      expect(search('at 7'), ['Alex']); // too few digits to be a number: plain text only
    });
  });

  group('a reply and the app\'s copy of it', () {
    ReplyCommand reply(String text, int minute, {int second = 0, ReplyStatus status = ReplyStatus.sent}) =>
        ReplyCommand(
          id: 'r$minute:$second',
          notificationId: 'x',
          text: text,
          status: status,
          createdAt: t0.add(Duration(minutes: minute, seconds: second)),
        );

    test('the same words within two minutes, either side of the reply, are its copy', () {
      final sent = reply('On my way', 10, second: 20);
      // the phone's clock behind this device's: the copy looks older than the reply
      expect(isEchoOf(entry(note('a', title: 'You', text: 'On my way', minute: 10)), sent), isTrue);
      expect(isEchoOf(entry(note('b', title: 'You', text: ' On my way ', minute: 11)), sent), isTrue);
      expect(isEchoOf(entry(note('c', title: 'You', text: 'See you', minute: 10)), sent), isFalse);
      expect(isEchoOf(entry(note('d', title: 'You', text: 'On my way', minute: 30)), sent), isFalse);
      // in a group, the copy is sent by "You"
      expect(
        isEchoOf(
          entry(note('g', title: 'Family', group: 'Family', sender: 'You', text: 'On my way', minute: 10)),
          sent,
        ),
        isTrue,
      );
    });

    test('the other person answering with the same words is their message, not a copy of yours', () {
      final sent = reply('ok', 10);
      expect(isEchoOf(entry(note('a', title: 'Alex', text: 'ok', minute: 10)), sent), isFalse);
      expect(ownMessage(entry(note('a', title: 'Alex', text: 'ok', minute: 10)), [sent]), isNull);
    });

    test('a reply that was not delivered has no copy', () {
      final copy = entry(note('a', title: 'You', text: 'On my way', minute: 10));
      expect(isEchoOf(copy, reply('On my way', 10, status: ReplyStatus.failed)), isFalse);
      expect(isEchoOf(copy, reply('On my way', 10, status: ReplyStatus.expired)), isFalse);
    });

    test('each reply gets its closest copy, and each copy one reply', () {
      final first = reply('Yes', 10);
      final second = reply('Yes', 11);
      final early = entry(note('e', title: 'You', text: 'Yes', minute: 10));
      final late = entry(note('l', title: 'You', text: 'Yes', minute: 11));
      final other = entry(note('o', title: 'You', text: 'Dinner at 8?', minute: 9));
      final echoes = replyEchoes([late, other, early], [second, first]);
      expect(echoes[first.id]?.notification.id, 'e');
      expect(echoes[second.id]?.notification.id, 'l');
      expect(echoes.values.map((e) => e.notification.id), isNot(contains('o')));
    });
  });

  group('your own messages', () {
    ReplyCommand reply(String text, int minute, {String notificationId = 'a1'}) => ReplyCommand(
      id: 'r$minute',
      notificationId: notificationId,
      text: text,
      status: ReplyStatus.sent,
      createdAt: t0.add(Duration(minutes: minute)),
    );

    test('are the copy of a reply, or a one-to-one message titled "You"', () {
      final sent = reply('On my way', 10);
      expect(ownMessage(entry(note('a', title: 'You', text: 'On my way', minute: 10)), [sent]), OwnMessage.reply);
      expect(ownMessage(entry(note('b', title: 'You', text: 'Typed on the phone')), const []), OwnMessage.phone);
      expect(ownMessage(entry(note('c', title: 'Alex', text: 'Hi')), const []), isNull);
      // in a group chat the title is the group, and "You" can be a sender like anyone
      expect(ownMessage(entry(note('d', title: 'You', group: 'Family', sender: 'You')), const []), isNull);
    });

    test('do not name the conversation: it keeps the other person\'s name', () {
      final thread = groupByApp([
        entry(note('you', title: 'You', text: 'On my way', minute: 11, chat: 'alex')),
        entry(
          note('alex', title: 'Alex Morgan', text: 'Dinner at 8?', minute: 9, chat: 'alex'),
          replies: [reply('On my way', 10)],
        ),
      ]).single.threads.single;
      expect(thread.latest.notification.id, 'you');
      expect(thread.title, 'Alex Morgan');
    });

    test('join the chat they belong to when the app gives no conversation id', () {
      final groups = groupByApp([
        entry(note('you', title: 'You', text: 'Typed on the phone', minute: 11, key: 'chat-alex')),
        entry(note('alex', title: 'Alex Morgan', text: 'Dinner at 8?', minute: 9, key: 'chat-alex')),
        entry(note('mom', title: 'Mom', text: 'Call me', minute: 5, key: 'chat-mom')),
      ]);
      final threads = groups.single.threads;
      expect(threads.map((t) => t.title), ['Alex Morgan', 'Mom']);
      expect(threads.first.count, 2);
    });

    test('with nobody else in the conversation, it is named after the app', () {
      final thread = groupByApp([entry(note('you', title: 'You', text: 'Note to self'))]).single.threads.single;
      expect(thread.title, 'WhatsApp');
    });
  });

  group('the phone side', () {
    test('conversation ids are hashed into short opaque ids', () {
      final id = opaqueId('com.whatsapp|919876543210@s.whatsapp.net');
      expect(id, hasLength(16));
      expect(id, opaqueId('com.whatsapp|919876543210@s.whatsapp.net'));
      expect(id, isNot(opaqueId('com.whatsapp|919876543211@s.whatsapp.net')));
      expect(id, isNot(contains('9198')));
    });

    test('publishing carries sender and message metadata, and only a hash of the conversation id', () async {
      final mac = RecordingMirror();
      await PublishCapturedNotification([PublishTarget('mac', mac)])(
        CapturedNotification.fromMap({
          'key': 'k',
          'packageName': 'com.whatsapp',
          'appName': 'WhatsApp',
          'title': 'Family',
          'text': 'Dad: Dinner at 8?',
          'postedAt': t0.millisecondsSinceEpoch,
          'canReply': true,
          'conversationTitle': 'Family',
          'isGroupConversation': true,
          'sender': 'Dad',
          'conversationId': '1203630@g.us',
          'isMessage': true,
        }),
      );
      final content = mac.published.single.$1;
      expect(content.sender, 'Dad');
      expect(content.isMessage, isTrue);
      expect(content.conversationId, opaqueId('com.whatsapp|1203630@g.us'));

      final back = NotificationContent.fromJson(content.toJson());
      expect(back.sender, 'Dad');
      expect(back.conversationId, content.conversationId);
      expect(back.isMessage, isTrue);
      expect(back.isGroupConversation, isTrue);
    });

    test('content mirrored before this metadata existed reads as unknown', () {
      final legacy = NotificationContent.fromJson({'k': 'k', 'p': 'com.x', 't': 'Hi', 'at': 0});
      expect(legacy.isMessage, isNull);
      expect(legacy.sender, isNull);
      expect(legacy.conversationId, isNull);
    });
  });

  group('the feed', () {
    test('drops a message mirrored twice, but keeps two messages with the same words', () {
      final first = note('1', title: 'Alex', text: 'ok', minute: 1, key: 'chat');
      final repost = note('2', title: 'Alex', text: 'ok', minute: 1, key: 'chat');
      final again = note('3', title: 'Alex', text: 'ok', minute: 4, key: 'chat');
      final reply = ReplyCommand(
        id: 'r',
        notificationId: '2',
        text: 'sure',
        status: ReplyStatus.sent,
        createdAt: t0.add(const Duration(minutes: 2)),
      );
      final feed = buildFeed([first, repost, again], [reply], pairId: 'p', deviceName: 'Pixel');
      expect(feed, hasLength(2));
      // the reply sent to the dropped copy stays with the message
      expect(feed.expand((e) => e.replies).map((r) => r.id), ['r']);
    });
  });
}
