import 'dart:convert';

import 'package:air_reply/core/domain/device_role.dart';

import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/background/alert_handlers.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/notifications/domain/alert_style.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/pairing_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fakes.dart';

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

NotificationContent _content({bool? isMessage = true, String title = 'Alex', String? conversationId}) =>
    NotificationContent(
      key: 'chat-key',
      packageName: 'com.whatsapp',
      appName: 'WhatsApp',
      title: title,
      text: 'Dinner at 8?',
      postedAt: DateTime(2026, 11, 5, 19),
      isMessage: isMessage,
      conversationId: conversationId,
    );

MirroredNotification _notification({bool canReply = true, bool? isMessage = true}) => MirroredNotification(
  id: 'n1',
  content: _content(isMessage: isMessage),
  canReply: canReply,
  dismissedOnSender: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'getNotificationChannels' => <Object?>[],
        'getNotificationAppLaunchDetails' => null,
        // what the panel shows: a mirrored alert, and the sharing service's status notification
        'getActiveNotifications' => <Object?>[
          <Object?, Object?>{'id': 7, 'channelId': 'mirrored_popUp_sound_vibrate', 'tag': null},
          <Object?, Object?>{'id': 4201, 'channelId': 'air_reply_sync', 'tag': null},
        ],
        _ => null,
      };
    });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null),
  );

  Map<Object?, Object?> shown() =>
      (calls.singleWhere((c) => c.method == 'show').arguments as Map)['platformSpecifics']! as Map<Object?, Object?>;

  group('AlertStyle', () {
    test('keeps its choices, and starts with messages popping up and the rest in the list', () {
      const style = AlertStyle(
        messages: AlertMode.silent,
        others: AlertMode.off,
        sound: false,
        lockScreen: LockScreenAlerts.hide,
      );
      expect(AlertStyle.fromJson(style.toJson()), style);
      expect(AlertStyle.fromJson(const {}), const AlertStyle());
      expect(const AlertStyle().messages, AlertMode.popUp);
      expect(const AlertStyle().others, AlertMode.normal);
    });

    test('a message is what the phone called one; from older phones, anything naming a conversation or a sender', () {
      const style = AlertStyle(messages: AlertMode.popUp, others: AlertMode.silent);
      expect(style.modeFor(_content()), AlertMode.popUp);
      expect(style.modeFor(_content(isMessage: false)), AlertMode.silent);
      expect(style.modeFor(_content(isMessage: null, conversationId: 'chat')), AlertMode.popUp);
      expect(style.modeFor(_content(isMessage: null)), AlertMode.silent);
    });
  });

  group('alerts follow the chosen style', () {
    final alerts = MirroredAlerts(FlutterLocalNotificationsPlugin());

    test('pop up: on the high-importance channel with sound and vibration, and a Reply action', () async {
      await alerts.show(_notification(), pairId: 'p', style: const AlertStyle());
      final android = shown();
      expect(android['channelId'], 'mirrored_popUp_sound_vibrate');
      expect(android['importance'], Importance.high.value);
      expect(android['playSound'], isTrue);
      expect(android['enableVibration'], isTrue);
      expect(android['visibility'], NotificationVisibility.private.index);
      expect(jsonEncode(android['actions']), contains('reply'));
    });

    test('in the list without sound or vibration: its own channel, default importance', () async {
      await alerts.show(
        _notification(),
        pairId: 'p',
        style: const AlertStyle(messages: AlertMode.normal, sound: false, vibration: false),
      );
      final android = shown();
      expect(android['channelId'], 'mirrored_normal');
      expect(android['importance'], Importance.defaultImportance.value);
      expect(android['playSound'], isFalse);
      expect(android['enableVibration'], isFalse);
    });

    test('silent, and hidden on the lock screen', () async {
      await alerts.show(
        _notification(isMessage: false),
        pairId: 'p',
        style: const AlertStyle(others: AlertMode.silent, lockScreen: LockScreenAlerts.hide),
      );
      final android = shown();
      expect(android['channelId'], 'mirrored_silent');
      expect(android['importance'], Importance.low.value);
      expect(android['silent'], isTrue);
      expect(android['visibility'], NotificationVisibility.secret.index);
    });

    test('off: no alert at all', () async {
      await alerts.show(
        _notification(),
        pairId: 'p',
        style: const AlertStyle(messages: AlertMode.off),
      );
      expect(calls.where((c) => c.method == 'show'), isEmpty);
    });

    test('each style keeps its own channels; the ones no longer used are removed', () async {
      await alerts.tidyChannels(const AlertStyle(messages: AlertMode.normal, others: AlertMode.silent));
      final deleted = {
        for (final c in calls)
          if (c.method == 'deleteNotificationChannel') c.arguments,
      };
      expect(deleted, containsAll(['mirrored', 'mirrored_popUp_sound_vibrate', 'mirrored_normal']));
      expect(deleted, isNot(contains('mirrored_normal_sound_vibrate')));
      expect(deleted, isNot(contains('mirrored_silent')));
      expect(deleted, isNot(contains('mirrored_status')));
    });
  });

  group('a reply typed into an alert', () {
    NotificationResponse response({
      String? input,
      String? actionId = MirroredAlerts.replyActionId,
      bool canReply = true,
    }) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotificationAction,
      actionId: actionId,
      input: input,
      payload: jsonEncode({'pairId': 'pair-1', 'id': 'n1', 'canReply': canReply, 'c': _content().toJson()}),
    );

    test('is read from the alert, with the notification it answers', () {
      final reply = MirroredAlerts.replyFrom(response(input: '  On my way  '))!;
      expect(reply.pairId, 'pair-1');
      expect(reply.text, 'On my way');
      expect(reply.notification.id, 'n1');
      expect(reply.notification.content.key, 'chat-key');
      expect(MirroredAlerts.replyFrom(response(input: '   ')), isNull);
      expect(MirroredAlerts.replyFrom(response(input: 'hi', actionId: null)), isNull, reason: 'a plain tap');
      expect(MirroredAlerts.targetFrom(response(input: 'hi')), isNull, reason: 'a reply is not a tap');
    });

    late ProviderContainer container;
    late _RecordingOutbox outbox;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      outbox = _RecordingOutbox();
      container = ProviderContainer(
        overrides: [
          pairingCredentialsStoreProvider.overrideWithValue(InMemoryCredentialsStore()..pairs.add(_pair)),
          replyOutboxProvider.overrideWith((ref, pairId) => outbox),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('is queued on the pair it came from', () async {
      await sendAlertReply(container, MirroredAlerts.replyFrom(response(input: 'On my way'))!);
      expect(outbox.sent, [('n1', 'chat-key', 'On my way')]);
      expect(calls.where((c) => c.method == 'show'), isEmpty);
    });

    test('that cannot be sent says so, and why, instead of disappearing', () async {
      await sendAlertReply(container, MirroredAlerts.replyFrom(response(input: 'On my way', canReply: false))!);
      expect(outbox.sent, isEmpty);
      final show = calls.singleWhere((c) => c.method == 'show').arguments as Map;
      expect(show['title'], 'Reply to Alex not sent');
      expect(show['body'], 'This notification cannot be answered.');
      expect((show['platformSpecifics']! as Map)['channelId'], 'mirrored_status');
    });

    test('to a device that was removed meanwhile says so too', () async {
      final orphan = MirroredAlerts.replyFrom(response(input: 'hello'))!;
      await sendAlertReply(container, AlertReply(pairId: 'gone', notification: orphan.notification, text: orphan.text));
      expect(outbox.sent, isEmpty);
      expect((calls.singleWhere((c) => c.method == 'show').arguments as Map)['body'], 'This device is not paired yet.');
    });

    test('that started the app is sent, not taken for a tap', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
        call,
      ) async {
        if (call.method == 'getNotificationAppLaunchDetails') {
          return {
            'notificationLaunchedApp': true,
            'notificationResponse': {
              'notificationResponseType': NotificationResponseType.selectedNotificationAction.index,
              'actionId': MirroredAlerts.replyActionId,
              'input': 'Coming!',
              'payload': response().payload,
            },
          };
        }
        return null;
      });
      final reply = await container.read(mirroredAlertsProvider).launchReply();
      expect(reply?.text, 'Coming!');
    });
  });

  group('read in AirReply: its alert leaves the notification panel', () {
    final alerts = MirroredAlerts(FlutterLocalNotificationsPlugin());

    List<Object?> cancelled() => [for (final c in calls.where((c) => c.method == 'cancel')) (c.arguments as Map)['id']];

    test('the alert is taken down by the id it was raised with', () async {
      await alerts.show(_notification(), pairId: 'p', style: const AlertStyle());
      final raised = (calls.singleWhere((c) => c.method == 'show').arguments as Map)['id'];
      await alerts.dismiss(['n1', 'n1']);
      expect(cancelled(), [raised], reason: 'once, by the same id');
      expect(raised, MirroredAlerts.alertId('n1'));
    });

    test('"Mark all as read" takes down every mirrored alert, never the sharing status notification', () async {
      await alerts.dismissAll();
      expect(cancelled(), [7]);
    });

    test('opening, marking or deleting in the inbox takes the alerts down', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(inboxStateProvider, (_, _) {});
      await container.read(inboxStateProvider.future);
      final inbox = container.read(inboxStateProvider.notifier);

      await inbox.markRead(['pixel/n1']);
      inbox.dismissAlerts(['pixel/n2']); // as deleting does, at once
      await pumpEventQueue();
      expect(cancelled(), [MirroredAlerts.alertId('n1'), MirroredAlerts.alertId('n2')]);
    });
  });
}

final _pair = PairingCredentials(
  pairId: 'pair-1',
  role: DeviceRole.receiver,
  sharedKey: Uint8List(32),
  peerName: 'Pixel 9',
  pairedAt: DateTime(2026, 3),
);

final class _RecordingOutbox implements ReplyOutbox {
  final sent = <(String, String, String)>[];

  @override
  Future<void> send({required String notificationId, required String notificationKey, required String text}) async =>
      sent.add((notificationId, notificationKey, text));
}
