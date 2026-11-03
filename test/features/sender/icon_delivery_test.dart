import 'dart:typed_data';

import 'package:air_reply/features/notifications/data/local_stores.dart';
import 'package:air_reply/features/sender/data/icon_delivery.dart';
import 'package:air_reply/features/sender/domain/usecases/relay_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fakes.dart';

void main() {
  final icon = Uint8List.fromList(List.filled(100, 7));

  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('publishing with app icons', () {
    late RecordingMirror mac;
    late RecordingMirror pc;
    late FakeNotificationBridge bridge;
    late MemoryIconLog log;
    late PublishCapturedNotification publish;

    setUp(() {
      mac = RecordingMirror();
      pc = RecordingMirror();
      bridge = FakeNotificationBridge()..icons['com.whatsapp'] = icon;
      log = MemoryIconLog();
      publish = PublishCapturedNotification(
        [PublishTarget('mac', mac), PublishTarget('pc', pc)],
        icons: BridgeAppIconSource(bridge),
        iconLog: log,
      );
    });

    test('attaches the icon the first time each device sees an app, then leaves it out', () async {
      await publish(captured());
      expect(mac.published.single.$1.iconPng, icon);
      expect(pc.published.single.$1.iconPng, icon);
      expect(bridge.iconRequests, 1, reason: 'the icon is read once per notification, not once per device');

      await publish(captured(key: 'second'));
      expect(mac.published.last.$1.iconPng, isNull);
      expect(pc.published.last.$1.iconPng, isNull);
    });

    test('a newly paired device still gets the icon', () async {
      log.sent.add('mac|com.whatsapp');
      await publish(captured());
      expect(mac.published.single.$1.iconPng, isNull);
      expect(pc.published.single.$1.iconPng, icon);
    });

    test('oversized icons are never sent, and are not recorded as sent', () async {
      bridge.icons['com.whatsapp'] = Uint8List(PublishCapturedNotification.maxIconBytes + 1);
      await publish(captured());
      expect(mac.published.single.$1.iconPng, isNull);
      expect(log.sent, isEmpty);
    });

    test('long texts are trimmed to fit the payload limit', () async {
      await publish(captured(text: 'x' * (PublishCapturedNotification.maxTextLength + 500)));
      expect(mac.published.single.$1.text.length, PublishCapturedNotification.maxTextLength + 1); // + ellipsis
    });
  });

  test('the delivery log resends icons after a week', () async {
    var now = DateTime(2026, 10, 1);
    final log = PreferencesIconDeliveryLog(SharedPreferencesAsync(), clock: () => now);

    expect(await log.isDue('mac', 'com.whatsapp'), isTrue);
    await log.recordSent('mac', 'com.whatsapp');
    expect(await log.isDue('mac', 'com.whatsapp'), isFalse);
    expect(await log.isDue('pc', 'com.whatsapp'), isTrue);

    now = now.add(PreferencesIconDeliveryLog.resendAfter + const Duration(minutes: 1));
    expect(await log.isDue('mac', 'com.whatsapp'), isTrue);

    // Persisted: a new log (as after a restart) knows what was sent.
    final reloaded = PreferencesIconDeliveryLog(SharedPreferencesAsync(), clock: () => DateTime(2026, 10, 2));
    expect(await reloaded.isDue('mac', 'com.whatsapp'), isFalse);
  });

  test('receivers keep harvested icons on disk', () async {
    final cache = AppIconCache(SharedPreferencesAsync());
    expect(await cache.load(), isEmpty);
    await cache.save({'com.whatsapp': icon});
    expect((await cache.load())['com.whatsapp'], icon);
  });

  test('records of icons sent to devices since removed are dropped', () async {
    final log = PreferencesIconDeliveryLog(SharedPreferencesAsync(), clock: () => DateTime(2026, 10));
    await log.recordSent('mac', 'com.whatsapp');
    await log.recordSent('pc', 'com.whatsapp');
    await log.keepOnly({'pc'});
    expect(await log.isDue('mac', 'com.whatsapp'), isTrue);
    expect(await log.isDue('pc', 'com.whatsapp'), isFalse);
  });
}
