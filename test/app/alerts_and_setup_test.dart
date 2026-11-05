import 'package:air_reply/features/notifications/domain/alert_style.dart';
import 'package:air_reply/features/settings/domain/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_flow_test.dart';

void main() {
  testWidgets('a receiver chooses how alerts appear: other notifications silent, messages still pop up', (
    tester,
  ) async {
    await launch(tester, role: 'receiver');
    await openTab(tester, 'Settings');
    await reveal(tester, find.text('How alerts appear'));
    expect(find.text('Messages: Pop up · Other: In the list'), findsOneWidget);

    await tester.tap(find.text('How alerts appear'));
    await tester.pumpAndSettle();
    final silent = find.text('Silent').last; // the second group: other notifications
    await reveal(tester, silent);
    await tester.tap(silent);
    await tester.pumpAndSettle();

    final saved = AppPreferences.fromJson(
      (await SharedAppPreferencesStore(SharedPreferencesAsync()).load()).toJson(),
    ).alertStyle;
    expect(saved.others, AlertMode.silent);
    expect(saved.messages, AlertMode.popUp);

    // the bar slid away while scrolling: scrolling back a little brings its back button
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 120));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Messages: Pop up · Other: Silent'), findsOneWidget);
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
