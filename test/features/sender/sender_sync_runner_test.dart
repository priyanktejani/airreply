import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/sender/background/sender_sync_runner.dart';
import 'package:air_reply/features/sender/domain/usecases/relay_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingMirror mac;
  late RecordingMirror pc;
  late FakeNotificationBridge bridge;
  late FakeBackgroundChannel channel;
  late SenderSyncRunner runner;

  SenderPairLink link(String pairId, RecordingMirror mirror) =>
      SenderPairLink(pairId: pairId, inbox: mirror, executeReply: ExecutePendingReply(bridge, mirror));

  setUp(() async {
    mac = RecordingMirror();
    pc = RecordingMirror();
    bridge = FakeNotificationBridge();
    channel = FakeBackgroundChannel();
    runner = SenderSyncRunner(
      channel: channel,
      pairs: [link('mac', mac), link('pc', pc)],
      publish: PublishCapturedNotification([PublishTarget('mac', mac), PublishTarget('pc', pc)]),
      markDismissed: MarkNotificationDismissed([mac, pc]),
    );
    await runner.start();
  });

  tearDown(() => runner.stop());

  PendingReply reply(String id, String key) =>
      PendingReply(id: id, notificationId: 'n-$id', notificationKey: key, text: 'On my way');

  test('attaches to the channel and tells native it is ready', () {
    expect(channel.handler, same(runner));
    expect(channel.ready, isTrue);
  });

  test('publishes each captured notification to every paired device, skipping empty ones', () async {
    await runner.onNotificationPosted(captured());
    await runner.onNotificationPosted(captured(title: '', text: '  '));

    for (final device in [mac, pc]) {
      expect(device.published, hasLength(1));
      final (content, canReply) = device.published.single;
      expect(content.appName, 'WhatsApp');
      expect(content.text, 'Are you coming?');
      expect(canReply, isTrue);
    }
  });

  test('marks removed notifications as dismissed everywhere', () async {
    await runner.onNotificationRemoved('key-1');
    expect(mac.dismissed, ['key-1']);
    expect(pc.dismissed, ['key-1']);
  });

  test('executes each pending reply once and reports the outcome to the pair it came from', () async {
    bridge.replyResults['live'] = ReplyDispatchResult.sent;

    mac.pending.add([reply('r1', 'live')]);
    pc.pending.add([reply('r1', 'gone')]); // same id in another pair is a different reply
    await pumpEventQueue();
    // The same replies again, before the server confirmed the status change.
    mac.pending.add([reply('r1', 'live')]);
    await pumpEventQueue();

    expect(bridge.repliesSent, [('live', 'On my way'), ('gone', 'On my way')]);
    expect(mac.resolved, {'r1': ReplyStatus.sent});
    expect(pc.resolved, {'r1': ReplyStatus.expired});
  });

  test('a wake fetches pending replies of every pair from the server', () async {
    bridge.replyResults['live'] = ReplyDispatchResult.sent;
    mac.serverPending = [reply('r3', 'live')];
    pc.serverPending = [reply('r4', 'live')];

    await runner.onWake();

    expect(mac.resolved, {'r3': ReplyStatus.sent});
    expect(pc.resolved, {'r4': ReplyStatus.sent});
  });

  test('one unreachable device does not stop the others', () async {
    final broken = _FailingPublisher();
    final publish = PublishCapturedNotification([PublishTarget('broken', broken), PublishTarget('mac', mac)]);

    await expectLater(publish(captured()), throwsA(isA<Exception>()));
    expect(mac.published, hasLength(1));
  });
}

final class _FailingPublisher extends RecordingMirror {
  @override
  Future<void> publish(content, {required bool canReply}) async => throw Exception('offline');
}
