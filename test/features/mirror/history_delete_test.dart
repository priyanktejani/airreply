import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HistoryDatabase db;
  late MessageHistory pixel;
  late MessageHistory galaxy;
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  StoredNotification n(String id) => StoredNotification(id: id, payload: 'sealed', postedAt: DateTime(2026, 11, 6));
  StoredReply r(String id, String to) => StoredReply(
    id: id,
    notificationId: to,
    payload: 'sealed',
    status: ReplyStatus.sent,
    createdAt: DateTime(2026, 11, 6),
  );

  setUp(() async {
    db = HistoryDatabase(NativeDatabase.memory());
    pixel = MessageHistory(db, 'pixel');
    galaxy = MessageHistory(db, 'galaxy');
    await pixel.putNotifications([n('n1'), n('n2'), n('n3')]);
    await pixel.putReplies([r('r1', 'n1'), r('r2', 'n2')]);
    await pixel.putDismissals({'k1': DateTime(2026, 11, 6)});
    await pixel.index({
      'n1': (content: 'otp 4821', packageName: 'com.bank'),
      'n2': (content: 'dinner at 8', packageName: 'com.whatsapp'),
      'n3': (content: 'parcel', packageName: 'com.amazon'),
    });
    await galaxy.putNotifications([n('n1')]); // the same id on another pair
  });
  tearDown(() => db.close());

  test('deleting removes the notification, its replies and its search entry for good, nothing else', () async {
    await pixel.deleteNotifications(['n1', 'n3']);

    final left = await pixel.load();
    expect(left.notifications.keys, ['n2']);
    expect(left.replies.keys, ['r2'], reason: "the deleted one's reply goes with it");
    expect(await pixel.count(text: 'otp'), 0, reason: 'no longer found by search');
    expect(await pixel.count(text: 'dinner'), 1);
    expect((await galaxy.load()).notifications.keys, ['n1'], reason: 'only this pair');
  });

  test('Clear all deletes every notification and reply of the pair; what the phone did is kept', () async {
    await pixel.deleteAllNotifications();

    final left = await pixel.load();
    expect(left.notifications, isEmpty);
    expect(left.replies, isEmpty);
    expect(left.dismissals.keys, ['k1']);
    expect(await pixel.count(), 0);
    expect((await galaxy.load()).notifications.keys, ['n1']);
  });

  test("deleting many at once (past SQLite's variable limit) works", () async {
    await pixel.putNotifications([for (var i = 0; i < 1200; i++) n('bulk$i')]);
    await pixel.deleteNotifications([for (var i = 0; i < 1200; i++) 'bulk$i']);
    expect((await pixel.load()).notifications.keys, unorderedEquals(['n1', 'n2', 'n3']));
  });
}
