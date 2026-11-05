import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/platform/notification_permission.dart';
import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/features/notifications/alert_delivery_provider.dart';
import 'package:air_reply/features/notifications/domain/alert_delivery.dart';
import 'package:air_reply/features/notifications/domain/alert_style.dart';
import 'package:air_reply/features/notifications/presentation/widgets/alert_delivery.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fakes.dart';

const _popUp = 'mirrored_popUp_sound_vibrate';
const _normal = 'mirrored_normal_sound_vibrate';

/// As this OnePlus had them: lowered to the list, sound taken away.
const _held = (shown: true, popsUp: false, sounds: false);
const _fine = (shown: true, popsUp: true, sounds: true);
const _list = (shown: true, popsUp: false, sounds: true);

final class _Fixed extends AlertDeliveryController {
  _Fixed(this.delivery);

  final AlertDelivery? delivery;

  @override
  Future<AlertDelivery?> build() async => delivery;
}

void main() {
  group('the channels the choices alert on', () {
    test('the defaults: messages pop up, others in the list, pop-up first', () {
      final uses = alertChannelsFor(const AlertStyle());
      expect(uses.map((u) => u.channelId), [_popUp, _normal]);
      expect(uses.first.wantsPopUp, isTrue);
      expect(uses.last.wantsPopUp, isFalse);
      expect(uses.every((u) => u.wantsSound), isTrue);
    });

    test('silent and off need nothing from the phone; one mode for both is one channel', () {
      expect(alertChannelsFor(const AlertStyle(messages: AlertMode.silent, others: AlertMode.off)), isEmpty);
      expect(alertChannelsFor(const AlertStyle(others: AlertMode.popUp)), hasLength(1));
    });

    test('sound off in the app: no sound expected of the channel', () {
      final uses = alertChannelsFor(const AlertStyle(sound: false));
      expect(uses.first.channelId, 'mirrored_popUp_vibrate');
      expect(uses.any((u) => u.wantsSound), isFalse);
    });
  });

  group('judging what the phone does', () {
    test(
      'a phone that holds the app back (OnePlus): neither pops up nor sounds; the pop-up channel is fixed first',
      () {
        final d = judgeAlertDelivery(const AlertStyle(), {_popUp: _held, _normal: _held}, vendor: 'oneplus')!;
        expect(d.works, isFalse);
        expect((d.popsUp, d.sounds), (false, false));
        expect(d.fixChannelId, _popUp);
      },
    );

    test('everything as asked: works, nothing to fix', () {
      final d = judgeAlertDelivery(const AlertStyle(), {_popUp: _fine, _normal: _fine})!;
      expect(d.works, isTrue);
      expect(d.fixChannelId, isNull);
    });

    test('pops up but the list channel lost its sound: only sound to fix, on that channel', () {
      final d = judgeAlertDelivery(const AlertStyle(), {_popUp: _fine, _normal: _held})!;
      expect(d.popsUp, isTrue, reason: 'the list channel is not meant to pop up');
      expect(d.sounds, isFalse);
      expect(d.fixChannelId, _normal);
    });

    test('the person chose no sound: a silent pop-up channel is fine', () {
      const style = AlertStyle(sound: false, others: AlertMode.silent);
      final d = judgeAlertDelivery(style, {'mirrored_popUp_vibrate': (shown: true, popsUp: true, sounds: false)})!;
      expect(d.works, isTrue);
    });

    test('what each kind of alert will do, for the banner', () {
      final fine = judgeAlertDelivery(const AlertStyle(), {_popUp: _fine, _normal: _list})!;
      expect((fine.messages, fine.others), (AlertExpectation.popUp, AlertExpectation.list));
      final held = judgeAlertDelivery(const AlertStyle(), {_popUp: _list, _normal: _held})!;
      expect((held.messages, held.others), (AlertExpectation.list, AlertExpectation.quiet));
      const off = (shown: false, popsUp: false, sounds: false);
      final switchedOff = judgeAlertDelivery(const AlertStyle(), {_popUp: off, _normal: _list})!;
      expect(switchedOff.messages, AlertExpectation.off);
      expect(switchedOff.fixChannelId, _popUp);
      expect(switchedOff.fixOnAppPage, isFalse, reason: 'only messages are off: their own page');
      final allOff = judgeAlertDelivery(const AlertStyle(), {_popUp: off, _normal: off})!;
      expect(allOff.fixOnAppPage, isTrue, reason: "everything off: the app's own switch");
    });

    test('nothing to judge (no channel known, or nothing that pops up or sounds): null, no prompt', () {
      expect(judgeAlertDelivery(const AlertStyle(), {}), isNull);
      expect(judgeAlertDelivery(const AlertStyle(messages: AlertMode.silent, others: AlertMode.silent), {}), isNull);
    });
  });

  group('telling the person', () {
    late _Permission permission;

    Future<void> pump(WidgetTester tester, AlertDelivery? delivery, Widget child) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertDeliveryProvider.overrideWith(() => _Fixed(delivery)),
            notificationPermissionProvider.overrideWithValue(permission),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() => permission = _Permission());

    testWidgets('held back on a OnePlus: what to expect, why, and the steps on its own page', (tester) async {
      await pump(
        tester,
        const AlertDelivery(
          popsUp: false,
          sounds: false,
          fixChannelId: _popUp,
          vendor: 'oneplus',
          messages: AlertExpectation.quiet,
          others: AlertExpectation.quiet,
        ),
        const AlertExpectationBanner(),
      );
      expect(find.text('Messages arrive silently'), findsOneWidget);
      expect(find.textContaining('Other notifications: in the list, silently.'), findsOneWidget);
      expect(find.textContaining('OnePlus lets only a few apps'), findsOneWidget);
      expect(find.textContaining("On AirReply's page, turn on Banner, Ring and Vibrate"), findsOneWidget);
      expect(find.textContaining('open Messages and turn on Banner there too'), findsOneWidget);
      expect(find.text('Open alert settings'), findsOneWidget);
    });

    testWidgets('all as it should be: says so, with no button', (tester) async {
      await pump(
        tester,
        const AlertDelivery(
          popsUp: true,
          sounds: true,
          messages: AlertExpectation.popUp,
          others: AlertExpectation.list,
        ),
        const AlertExpectationBanner(),
      );
      expect(find.text('Messages pop up with sound'), findsOneWidget);
      expect(find.textContaining('Other notifications: in the list, with a sound.'), findsOneWidget);
      expect(find.text('Open alert settings'), findsNothing);
    });

    testWidgets('messages switched off in the system: says so, not that the phone holds them back', (tester) async {
      await pump(
        tester,
        const AlertDelivery(
          popsUp: false,
          sounds: false,
          fixChannelId: _popUp,
          vendor: 'oneplus',
          messages: AlertExpectation.off,
          others: AlertExpectation.list,
        ),
        const AlertExpectationBanner(),
      );
      expect(find.text('Message alerts are off'), findsOneWidget);
      expect(find.textContaining('switched off in this device'), findsOneWidget);
      expect(find.textContaining('lets only a few apps'), findsNothing);
    });

    testWidgets('alerts not allowed: says they are off, with Allow', (tester) async {
      permission.granted = false;
      await pump(tester, null, const AlertExpectationBanner());
      expect(find.text('Alerts are off on this device'), findsOneWidget);
      expect(find.text('Allow'), findsOneWidget);
    });

    testWidgets('nothing known (not Android, nothing read yet): nothing shown', (tester) async {
      await pump(tester, null, const AlertExpectationBanner());
      expect(find.byType(FilledButton), findsNothing);
      expect(find.textContaining('Messages'), findsNothing);
    });

    testWidgets("Home's prompt: the switch, or not now", (tester) async {
      const delivery = AlertDelivery(popsUp: false, sounds: false, fixChannelId: _popUp, vendor: 'xiaomi');
      await pump(
        tester,
        delivery,
        Consumer(
          builder: (context, ref, _) =>
              TextButton(onPressed: () => showAlertDeliveryPrompt(context, ref, delivery), child: const Text('ask')),
        ),
      );
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      expect(find.text('Make alerts pop up'), findsOneWidget);
      expect(find.textContaining('Floating notifications, then Sound'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text('Make alerts pop up'), findsNothing);
    });
  });

  group('reading the phone', () {
    late FakeNotificationBridge bridge;
    late _Permission permission;
    late ProviderContainer container;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      bridge = FakeNotificationBridge();
      permission = _Permission();
      container = ProviderContainer(
        overrides: [
          notificationBridgeProvider.overrideWithValue(bridge),
          notificationPermissionProvider.overrideWithValue(permission),
          deviceRoleProvider.overrideWithValue(DeviceRole.receiver),
        ],
      );
      addTearDown(container.dispose);
    });

    /// The check, kept alive as Home keeps it while open, started once the fake phone is set up.
    Future<AlertDelivery?> check() {
      container.listen(alertDeliveryProvider, (_, _) {});
      return container.read(alertDeliveryProvider.future);
    }

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('a phone that lowered the channels: judged held back, with the pop-up channel to open', () async {
      bridge.channelState = _held;
      final delivery = (await check())!;
      expect((delivery.popsUp, delivery.sounds, delivery.fixChannelId), (false, false, _popUp));
      expect((delivery.messages, delivery.others), (AlertExpectation.quiet, AlertExpectation.quiet));
    });

    test(
      "the switch: AirReply's notification page on OnePlus (Banner, Ring, Vibrate live there), else the channel's",
      () async {
        bridge
          ..channelState = _held
          ..restrictions = const BackgroundRestrictions(
            vendor: 'oneplus',
            hasAutostartScreen: true,
            ignoringBatteryOptimizations: false,
          );
        expect((await check())!.fixOnAppPage, isTrue);
        await container.read(alertDeliveryProvider.notifier).openSettings();
        bridge.restrictions = BackgroundRestrictions.none;
        await container.read(alertDeliveryProvider.notifier).refresh();
        await container.read(alertDeliveryProvider.notifier).openSettings();
        expect(bridge.settingsOpened, [(_popUp, true), (_popUp, false)]);
      },
    );

    test('alerts not allowed at all: not this step (the alerts permission comes first)', () async {
      bridge.channelState = _held;
      permission.granted = false;
      expect(await check(), isNull);
    });

    test('fixed in the system settings: judged again on coming back', () async {
      bridge.channelState = _held;
      expect((await check())!.works, isFalse);
      bridge.channelState = _fine;
      final again = await container.read(alertDeliveryProvider.notifier).refresh();
      expect(again!.works, isTrue);
    });

    test('a device that shares: nothing to check', () async {
      bridge.channelState = _held;
      final sender = ProviderContainer(
        overrides: [
          notificationBridgeProvider.overrideWithValue(bridge),
          deviceRoleProvider.overrideWithValue(DeviceRole.sender),
        ],
      );
      addTearDown(sender.dispose);
      sender.listen(alertDeliveryProvider, (_, _) {});
      expect(await sender.read(alertDeliveryProvider.future), isNull);
    });

    test('elsewhere than Android: nothing to check', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      bridge.channelState = _held;
      expect(await check(), isNull);
    });
  });
}

final class _Permission implements NotificationPermission {
  var granted = true;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async => granted;
}
