import 'package:air_reply/app/air_reply_app.dart';
import 'package:air_reply/app/widgets/floating_nav_bar.dart';
import 'package:air_reply/core/widgets/stat_tile.dart';
import 'package:air_reply/demo/demo_mode.dart';
import 'package:air_reply/features/notifications/presentation/conversation_screen.dart';
import 'package:air_reply/features/notifications/presentation/widgets/group_widgets.dart';
import 'package:air_reply/features/notifications/presentation/widgets/notification_card.dart';
import 'package:air_reply/features/notifications/presentation/widgets/swipe_actions.dart';
import 'package:air_reply/features/notifications/presentation/widgets/unread_count.dart';
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
  // Reduced motion, as the design honours it: entrances and pulses are instant, so frames settle at once.
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

Future<void> openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.descendant(of: find.byType(FloatingNavBar), matching: find.text(tab)));
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into the middle of the screen, clear of the floating tab bar and the pinned bars.
Future<void> reveal(WidgetTester tester, Finder finder, {Finder? scrollable}) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: scrollable ?? find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
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

    expect(find.text('Receiving from 2 phones.'), findsOneWidget);
    await reveal(tester, find.text('Latest notifications'));
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('At a glance'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Receiving from 2 phones.'), findsOneWidget);
    // The demo starts with the last 20 minutes unread: six notifications.
    expect(find.byWidgetPredicate((w) => w is Stat && w.label == 'Unread' && w.value == '6'), findsOneWidget);
    // on the tab and on Home's bell
    expect(find.descendant(of: find.byType(FloatingNavBar), matching: find.text('6')), findsOneWidget);
    expect(find.descendant(of: find.byType(Badge), matching: find.text('6')), findsNWidgets(2));
    expect(find.text('Alex Morgan'), findsWidgets);
    // Four tabs.
    for (final tab in ['Home', 'Notifications', 'Devices', 'Settings']) {
      expect(find.descendant(of: find.byType(FloatingNavBar), matching: find.text(tab)), findsOneWidget);
    }
    await close(tester);
  });

  testWidgets('opening a message opens its chat, where a reply can be sent', (tester) async {
    await launch(tester, role: 'receiver');

    // a message from a person (on Home's latest notifications) opens its chat, at that message
    await reveal(tester, find.text('Latest notifications'));
    await tester.tap(find.text('Alex Morgan').first);
    await tester.pumpAndSettle();
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(find.textContaining('I booked the table'), findsOneWidget);
    expect(find.text('Reply to Alex Morgan'), findsOneWidget);

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
    expect(find.text('Latest notifications'), findsOneWidget);
    await close(tester);
  });

  testWidgets('search narrows the inbox and offers to clear', (tester) async {
    await launch(tester, role: 'receiver');
    await openTab(tester, 'Notifications');

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

  testWidgets('notifications group by app, latest activity first, with counts', (tester) async {
    await launch(tester, role: 'receiver');
    await openTab(tester, 'Notifications');

    // One row per app and phone, newest activity first: WhatsApp (2 min), then Telegram (a reply 7 min ago).
    final whatsapp = find.text('WhatsApp · Pixel 9 Pro');
    final telegram = find.text('Telegram · Pixel 9 Pro');
    expect(whatsapp, findsOneWidget);
    expect(tester.getTopLeft(whatsapp).dy, lessThan(tester.getTopLeft(telegram).dy));
    expect(find.text('8 notifications · 3 conversations'), findsOneWidget);
    expect(find.text('Are we still on for 7? I booked the table by the window 🍝'), findsOneWidget);
    // Unread: Alex twice and the family group once.
    expect(find.byWidgetPredicate((w) => w is UnreadCount && w.count == 3), findsOneWidget);

    // Expanding lists the conversations; a number however formatted is one person; app notices stay apart.
    await tester.tap(find.byTooltip('Show conversations').first);
    await tester.pumpAndSettle();
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('3 messages'), findsOneWidget);
    expect(find.text('+91 74052-94614'), findsOneWidget);
    expect(find.text('Chat backup completed'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide conversations'));
    await tester.pumpAndSettle();
    expect(find.text('Family'), findsNothing);
    await close(tester);
  });

  testWidgets('a conversation opens as a chat, in order, with senders, and takes replies', (tester) async {
    await launch(tester, role: 'receiver');
    await openTab(tester, 'Notifications');
    await tester.tap(find.byTooltip('Show conversations').first);
    await tester.pumpAndSettle();

    // A group chat: each message under its sender, without the "Sender:" prefix.
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(find.text('Dad'), findsOneWidget);
    expect(find.text('Riya'), findsOneWidget);
    expect(find.text('Dinner at 8?'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Landed safely ✈️')).dy,
      lessThan(tester.getTopLeft(find.text('Dinner at 8?')).dy),
    );
    expect(find.text('New'), findsOneWidget); // before the unread message

    await tester.enterText(find.byType(TextField), 'Yes, 8 works');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Yes, 8 works'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Sent'), findsOneWidget);

    // Back to the list, where the conversation is now read.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Search notifications'), findsOneWidget);

    // One person's messages, oldest first.
    await tester.tap(find.text('Alex Morgan').last);
    await tester.pumpAndSettle();
    final first = tester.getTopLeft(find.text('Leaving the office now')).dy;
    final second = tester.getTopLeft(find.text('Traffic is light, 15 min')).dy;
    final third = tester.getTopLeft(find.text('Are we still on for 7? I booked the table by the window 🍝')).dy;
    expect(first < second && second < third, isTrue);
    await close(tester);
  });

  testWidgets('tapping an app lists its conversations, each opening every message from that person', (tester) async {
    await launch(tester, role: 'receiver');
    await openTab(tester, 'Notifications');

    await tester.tap(find.text('WhatsApp · Pixel 9 Pro'));
    await tester.pumpAndSettle();
    expect(find.text('3 conversations · 8 notifications · Pixel 9 Pro'), findsOneWidget);
    expect(find.text('Conversations · 3'), findsOneWidget);
    expect(find.text('Other notifications · 1'), findsOneWidget);
    // Latest activity first: Alex, then the family group, then the number.
    final alex = tester.getTopLeft(find.text('Alex Morgan')).dy;
    final family = tester.getTopLeft(find.text('Family')).dy;
    final number = tester.getTopLeft(find.text('+91 74052-94614')).dy;
    expect(alex < family && family < number, isTrue);

    // A number written two ways is one conversation, with both its messages.
    await tester.tap(find.text('+91 74052-94614'));
    await tester.pumpAndSettle();
    expect(find.text('WhatsApp · 2 messages'), findsOneWidget);
    expect(find.text('Is this the right number for the delivery?'), findsOneWidget);
    expect(find.text('I\'m at the gate'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Conversations · 3'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Gmail: two emails, notices rather than chats.
    await tester.scrollUntilVisible(find.text('Gmail · Pixel 9 Pro'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('2 notifications'), findsWidgets);
    final gmailGroup = find.ancestor(of: find.text('Gmail · Pixel 9 Pro'), matching: find.byType(AppGroupTile));
    final expandGmail = find.descendant(of: gmailGroup, matching: find.byTooltip('Show conversations'));
    await tester.ensureVisible(expandGmail); // brings it to the top, clear of the tab bar
    await tester.pumpAndSettle();
    await tester.tap(expandGmail);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Figma'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Figma'));
    await tester.pumpAndSettle();
    expect(find.textContaining('is ready to download'), findsOneWidget);
    expect(find.text('No replies in this app'), findsOneWidget);
    await close(tester);
  });

  testWidgets('swiping a group hides all of it, and Undo brings it back', (tester) async {
    await launch(tester, role: 'receiver');
    await openTab(tester, 'Notifications');

    await tester.drag(find.text('WhatsApp · Pixel 9 Pro'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('WhatsApp · Pixel 9 Pro'), findsNothing);
    expect(find.text('8 notifications hidden'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('WhatsApp · Pixel 9 Pro'), findsOneWidget);

    // Swiping right marks the whole group read.
    await tester.drag(find.text('WhatsApp · Pixel 9 Pro'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is UnreadCount && w.count == 3), findsNothing);
    await close(tester);
  });

  testWidgets('an app\'s conversations are the same cards, swiped the same way, as the notifications screen', (
    tester,
  ) async {
    await launch(tester, role: 'receiver');
    await openTab(tester, 'Notifications');

    // every swipe on both screens is a card's swipe, around a notification card
    void expectCardSwipes() {
      final swipes = tester.widgetList<SwipeActions>(find.byType(SwipeActions));
      expect(swipes, isNotEmpty);
      expect(swipes.every((s) => s.radius == SwipeActions.cardRadius && s.child is! SwipeActions), isTrue);
      expect(find.byType(NotificationCard), findsNWidgets(swipes.length));
    }

    expectCardSwipes();
    await tester.tap(find.text('WhatsApp · Pixel 9 Pro'));
    await tester.pumpAndSettle();
    expectCardSwipes();

    // swiping a conversation hides it, with Undo, as on the notifications screen
    await tester.drag(find.text('Family'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Family'), findsNothing);
    expect(find.text('2 notifications hidden'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Family'), findsOneWidget);
    await close(tester);
  });

  testWidgets('devices show their state, and removing one asks first', (tester) async {
    await launch(tester, role: 'receiver');
    await tester.tap(find.descendant(of: find.byType(FloatingNavBar), matching: find.text('Devices')));
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
    expect(find.text('1 paired'), findsOneWidget);
    await close(tester);
  });

  testWidgets('settings switch the theme, and data actions reflect the inbox', (tester) async {
    await launch(tester, role: 'receiver');
    await tester.tap(find.descendant(of: find.byType(FloatingNavBar), matching: find.text('Settings')));
    await tester.pumpAndSettle();
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Muted apps'), findsOneWidget);

    final scrollable = find.byType(Scrollable).last;
    await reveal(tester, find.text('Dark'), scrollable: scrollable);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Dark'))).brightness, Brightness.dark);

    // The demo starts with the last 20 minutes unread (six notifications) and nothing hidden.
    await reveal(tester, find.text('Restore hidden notifications'), scrollable: scrollable);
    expect(find.text('6 unread'), findsOneWidget);
    expect(find.text('Nothing hidden'), findsOneWidget);
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing unread'), findsOneWidget);
    expect(find.byType(Badge).evaluate().every((e) => !(e.widget as Badge).isLabelVisible), isTrue);
    await close(tester);
  });

  testWidgets('muting an app from Settings', (tester) async {
    await launch(tester, role: 'receiver');
    await tester.tap(find.descendant(of: find.byType(FloatingNavBar), matching: find.text('Settings')));
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

    await reveal(tester, find.text('Resume sharing'));
    await tester.tap(find.text('Resume sharing'));
    await tester.pumpAndSettle();
    expect(find.text('Sharing with 2 devices.'), findsOneWidget);
    await close(tester);
  });

  testWidgets('wide windows use a navigation rail', (tester) async {
    await launch(tester, role: 'receiver', size: const Size(1280, 900));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsNothing);
    await close(tester);
  });
}
