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

/// Opens the app on a narrow phone ([width] wide), with reduced motion so frames settle.
Future<void> go(WidgetTester tester, String role, double width) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  resetDemoData();
  tester.view
    ..physicalSize = Size(width, 640)
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

/// Scrolls the screen's main list a long way down.
Future<void> scrollAll(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// Every screen on narrow phones: the tabs scrolled through, every conversation opened. A layout that runs past the
/// screen's edge fails the test (Flutter reports overflow as an error).
void main() {
  for (final role in ['receiver', 'sender']) {
    for (final width in [320.0, 360.0]) {
      testWidgets('nothing overflows for a $role at $width px', (tester) async {
        await go(tester, role, width);
        await scrollAll(tester);
        for (final tab in ['Notifications', 'Devices', 'Settings']) {
          await tester.tap(find.descendant(of: find.byType(FloatingNavBar), matching: find.text(tab)));
          await tester.pumpAndSettle();
          await scrollAll(tester);
        }
        await tester.tap(find.descendant(of: find.byType(FloatingNavBar), matching: find.text('Notifications')));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await tester.pumpAndSettle();
        for (final expand in find.byTooltip('Show conversations').evaluate().toList()) {
          await tester.ensureVisible(find.byWidget(expand.widget));
          await tester.tap(find.byWidget(expand.widget), warnIfMissed: false);
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
