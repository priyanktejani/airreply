import 'package:air_reply/app/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'app_flow_test.dart' show close, launch;

/// Removes every paired device from the Devices tab, each with its confirmation.
Future<void> removeAllDevices(WidgetTester tester, List<String> names) async {
  await tester.tap(find.descendant(of: find.byType(FloatingNavBar), matching: find.text('Devices')));
  await tester.pumpAndSettle();
  for (final name in names) {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
  }
}

void main() {
  const share = 'Share my notifications';
  const receive = 'View and reply here';

  testWidgets('removing the last device returns to choosing what this device does; back returns there', (tester) async {
    await launch(tester, role: 'receiver');
    await removeAllDevices(tester, ['Galaxy S25', 'Pixel 9 Pro']);
    expect(find.text(share), findsOneWidget);
    expect(find.text(receive), findsOneWidget);

    await tester.tap(find.text(receive));
    await tester.pumpAndSettle();
    expect(find.text('Pair'), findsOneWidget);
    expect(find.text(receive), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(receive), findsOneWidget, reason: 'the app bar\'s back button');

    // the system back gesture does the same, rather than closing the app
    await tester.tap(find.text(receive));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(receive), findsOneWidget);
    await close(tester);
  });

  testWidgets('on a phone, back from setup or from pairing returns to the choice', (tester) async {
    await launch(tester, role: 'sender');
    await removeAllDevices(tester, ['iPad Air', 'MacBook Pro']);
    expect(find.text(share), findsOneWidget);

    // the permission checklist keeps checking, so the screen never settles: step through frames instead
    Future<void> frames() async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // privacy already agreed to: straight to pairing
    await tester.tap(find.text(share));
    await frames();
    expect(find.text('Pair'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await frames();
    expect(find.text(share), findsOneWidget);

    // the permission checklist, reached from the choice, steps back to it too
    await tester.tap(find.text(share));
    await frames();
    GoRouter.of(tester.element(find.text('Pair'))).go('/setup');
    await frames();
    expect(find.text('Set up'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await frames();
    expect(find.text(share), findsOneWidget);
    await close(tester);
    // only Android shares notifications
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
