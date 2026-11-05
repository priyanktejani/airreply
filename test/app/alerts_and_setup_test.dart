import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart';

void main() {
  testWidgets("a receiver's Settings: alerts first, the system's settings for how they appear, then the rest", (
    tester,
  ) async {
    await launch(tester, role: 'receiver');
    await openTab(tester, 'Settings');
    expect(find.text('How alerts appear'), findsNothing, reason: "the system's settings decide that now");
    for (final row in ['Notification settings', 'Muted apps', 'Show message text in alerts', 'Send a test alert']) {
      await reveal(tester, find.text(row));
      expect(find.text(row), findsOneWidget);
    }
    for (final section in ['Alerts', 'Sync', 'Privacy and data', 'Help and about']) {
      await reveal(tester, find.text(section));
      expect(find.text(section), findsWidgets);
    }
    expect(find.text('Sharing'), findsNothing, reason: 'a phone that shares has that section');
    await close(tester);
  });

  testWidgets("a phone's Settings: sharing and what it needs first", (tester) async {
    await launch(tester, role: 'sender');
    await openTab(tester, 'Settings');
    for (final row in ['Share notifications', 'Apps to share', 'Notification access']) {
      await reveal(tester, find.text(row));
      expect(find.text(row), findsOneWidget);
    }
    expect(find.text('Notification settings'), findsNothing);
    await close(tester);
  });

  testWidgets('the setup assistant lists what this device needs, from Settings', (tester) async {
    for (final role in ['sender', 'receiver']) {
      await launch(tester, role: role);
      await openTab(tester, 'Settings');
      await reveal(tester, find.text('Setup assistant'));
      await tester.tap(find.text('Setup assistant'));
      await tester.pumpAndSettle();
      expect(find.text('Keep AirReply working'), findsOneWidget);
      expect(find.text(role == 'sender' ? 'Notification access' : 'Alerts'), findsWidgets);
      await close(tester);
    }
  });
}
