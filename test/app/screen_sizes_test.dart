import 'package:air_reply/app/air_reply_app.dart';
import 'package:air_reply/app/widgets/floating_nav_bar.dart';
import 'package:air_reply/demo/demo_mode.dart';
import 'package:air_reply/features/notifications/presentation/widgets/group_widgets.dart';
import 'package:air_reply/features/push/push_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Phones turned sideways, tablets both ways up, and desktop windows: every screen opened, nothing overflowing.
const sizes = {
  'phone landscape': Size(780, 360),
  'tablet portrait': Size(768, 1024),
  'tablet landscape': Size(1180, 820),
  'desktop': Size(1440, 900),
};

Future<void> open(WidgetTester tester, String role, Size size) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  resetDemoData();
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...demoOverrides(role), pushRegistrationProvider.overrideWith((ref) async {})],
      child: const AirReplyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> scrollAll(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// The tab, on whichever navigation the window has (the bottom bar or the side rail).
Future<void> tab(WidgetTester tester, String name) async {
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phones upright get the bottom bar; turned sideways, tablets and desktops get the rail', (tester) async {
    for (final (size, rail) in [
      (const Size(390, 844), false),
      (const Size(780, 360), true),
      (const Size(768, 1024), true),
      (const Size(1440, 900), true),
    ]) {
      await open(tester, 'receiver', size);
      expect(find.byType(NavigationRail), rail ? findsOneWidget : findsNothing, reason: '$size');
      expect(find.byType(FloatingNavBar), rail ? findsNothing : findsOneWidget, reason: '$size');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Home lays its sections out in two columns on a desktop, one on a tablet', (tester) async {
    for (final (size, columns) in [(const Size(1440, 900), 2), (const Size(768, 1024), 1)]) {
      await open(tester, 'receiver', size);
      // the guides start level with the status card beside them, or below everything else
      final guides = tester.getTopLeft(find.text('How it works')).dy;
      final glance = tester.getTopLeft(find.text('At a glance')).dy;
      expect(columns == 2 ? guides < glance : guides > glance, isTrue, reason: '$size');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  for (final role in ['receiver', 'sender']) {
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('nothing overflows for a $role on a $name', (tester) async {
        await open(tester, role, size);
        await scrollAll(tester);
        for (final t in ['Notifications', 'Devices', 'Settings']) {
          await tab(tester, t);
          await scrollAll(tester);
        }
        await tab(tester, 'Notifications');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await tester.pumpAndSettle();
        // open every app card; each one opened turns its button into "Hide conversations"
        while (find.byTooltip('Show conversations').evaluate().isNotEmpty) {
          final expand = find.byTooltip('Show conversations').first;
          await tester.ensureVisible(expand);
          await tester.pumpAndSettle();
          await tester.tap(expand, warnIfMissed: false);
          await tester.pumpAndSettle();
        }
        final threads = find.byType(ThreadTile).evaluate().length;
        for (var i = 0; i < threads; i++) {
          final tile = find.byType(ThreadTile).at(i);
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          await tester.tap(tile, warnIfMissed: false);
          await tester.pumpAndSettle();
          await scrollAll(tester);
          if (find.byType(BackButton).evaluate().isNotEmpty) {
            await tester.tap(find.byType(BackButton).first);
            await tester.pumpAndSettle();
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      });
    }
  }
}
