import 'package:air_reply/app/air_reply_app.dart';
import 'package:air_reply/demo/demo_mode.dart';
import 'package:air_reply/features/push/push_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The real app (router, screens, controllers, use cases) on the in-memory demo backend.
Future<void> launch(WidgetTester tester, {required String role, Size size = const Size(420, 900)}) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  resetDemoData();
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...demoOverrides(role), pushRegistrationProvider.overrideWith((ref) async {})],
      child: const AirReplyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Unmounts the app so its streams and timers stop before the test ends.
Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('a receiver lands on Home with the day at a glance', (tester) async {
    await launch(tester, role: 'receiver');

    expect(find.text('RECENT ACTIVITY'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('UNREAD'), findsOneWidget);
    expect(find.text('Receiving from 2 phones.'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2)); // the Unread figure and the Notifications tab badge
    expect(find.text('Alex Morgan'), findsOneWidget);
    // Four tabs.
    for (final tab in ['Home', 'Notifications', 'Devices', 'Settings']) {
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)), findsOneWidget);
    }
    await close(tester);
  });

  testWidgets('opening a notification shows it in full and sends a reply', (tester) async {
    await launch(tester, role: 'receiver');

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Notifications')));
    await tester.pumpAndSettle();
    expect(find.text('Search notifications'), findsOneWidget);

    await tester.tap(find.text('Alex Morgan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('I booked the table'), findsOneWidget);
    expect(find.text('You can reply from here'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'See you at 7');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byWidgetPredicate((w) => w is SelectableText && w.data == 'See you at 7'), findsOneWidget);
    expect(find.text('Sending'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Sent'), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Search notifications'), findsOneWidget);
    await close(tester);
  });

  testWidgets('search narrows the inbox and offers to clear', (tester) async {
    await launch(tester, role: 'receiver');
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Notifications')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'payout');
    await tester.pumpAndSettle();
    expect(find.text('Stripe'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing like this');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);
    await tester.tap(find.text('Clear search and filters'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    await close(tester);
  });

  testWidgets('swiping hides a notification, and Undo brings it back', (tester) async {
    await launch(tester, role: 'receiver');
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Notifications')));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Alex Morgan'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Alex Morgan'), findsNothing);
    expect(find.text('Notification hidden'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Morgan'), findsOneWidget);
    await close(tester);
  });

  testWidgets('devices show their state, and removing one asks first', (tester) async {
    await launch(tester, role: 'receiver');
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Devices')));
    await tester.pumpAndSettle();

    expect(find.text('Pixel 9 Pro'), findsOneWidget);
    expect(find.text('Galaxy S25'), findsOneWidget);
    expect(find.text('Connected'), findsNWidgets(2));

    await tester.tap(find.text('Galaxy S25'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove device'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Galaxy S25?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Galaxy S25'), findsNothing);
    expect(find.text('1 paired'.toUpperCase()), findsOneWidget);
    await close(tester);
  });

  testWidgets('settings switch the theme, and data actions reflect the inbox', (tester) async {
    await launch(tester, role: 'receiver');
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Settings')));
    await tester.pumpAndSettle();
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Muted apps'), findsOneWidget);

    final scrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('Dark'), 200, scrollable: scrollable);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Dark'))).brightness, Brightness.dark);

    // The demo starts with the last 20 minutes unread (three notifications) and nothing hidden.
    await tester.scrollUntilVisible(find.text('Restore hidden notifications'), 200, scrollable: scrollable);
    expect(find.text('3 unread'), findsOneWidget);
    expect(find.text('Nothing hidden'), findsOneWidget);
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing unread'), findsOneWidget);
    expect(find.byType(Badge).evaluate().every((e) => !(e.widget as Badge).isLabelVisible), isTrue);
    await close(tester);
  });

  testWidgets('muting an app from Settings', (tester) async {
    await launch(tester, role: 'receiver');
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muted apps'));
    await tester.pumpAndSettle();

    expect(find.text('WhatsApp'), findsOneWidget);
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.text('Muted'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('1 muted: they arrive silently'), findsOneWidget);
    await close(tester);
  });

  testWidgets('a sender can pause and resume sharing from Home', (tester) async {
    await launch(tester, role: 'sender');

    expect(find.text('Share notifications'), findsOneWidget);
    expect(find.text('Sharing with 2 devices.'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Sharing is paused.'), findsOneWidget);
    expect(find.text('Resume sharing'), findsOneWidget);

    await tester.tap(find.text('Resume sharing'));
    await tester.pumpAndSettle();
    expect(find.text('Sharing with 2 devices.'), findsOneWidget);
    await close(tester);
  });

  testWidgets('wide windows use a navigation rail', (tester) async {
    await launch(tester, role: 'receiver', size: const Size(1280, 900));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await close(tester);
  });
}
