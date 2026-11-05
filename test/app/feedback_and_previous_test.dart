import 'package:air_reply/core/config/support.dart';
import 'package:air_reply/features/settings/domain/feedback.dart';
import 'package:air_reply/features/settings/feedback_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart';

void main() {
  test('feedback becomes an email in plain words, spaces kept as spaces', () {
    final uri = const FeedbackMessage(
      kind: FeedbackKind.idea,
      area: FeedbackArea.replies,
      message: '  Quick replies, please & thanks  ',
      details: {'Platform': 'android'},
    ).mailto('dev@example.com');

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'dev@example.com');
    expect(uri.toString(), contains('subject=%5BAirReply%5D%20Feature%20idea%20%C2%B7%20Replies'));
    expect(uri.queryParameters['body'], 'Quick replies, please & thanks\n\n-- Device details --\nPlatform: android');
  });

  testWidgets('Report a problem: pick, type, send; the email app gets it and the person sees thanks', (tester) async {
    final sent = <Uri>[];
    await launch(
      tester,
      role: 'receiver',
      overrides: [
        openEmailProvider.overrideWithValue((uri) async {
          sent.add(uri);
          return true;
        }),
        deviceDetailsProvider.overrideWithValue(() async => {'Platform': 'test'}),
      ],
    );
    await openTab(tester, 'Settings');
    await reveal(tester, find.text('Report a problem'));
    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();

    // too short: says so, sends nothing
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Write a little more (at least 10 characters).'), findsOneWidget);
    expect(sent, isEmpty);

    await tester.tap(find.text('Pairing'));
    await tester.enterText(find.byType(TextField), 'The QR code does not scan on my iPad.');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(sent.single.path, supportEmail);
    expect(sent.single.queryParameters['subject'], '[AirReply] Problem · Pairing');
    expect(sent.single.queryParameters['body'], startsWith('The QR code does not scan on my iPad.'));
    expect(sent.single.queryParameters['body'], contains('Role: views and replies'));
    // the address is never shown in the app
    expect(find.textContaining(supportEmail), findsNothing);
    expect(find.text('Thanks! Your email app is ready: tap send there to finish.'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget); // back on Settings
    await close(tester);
  });

  testWidgets('Suggest a feature opens the form as an idea; Previous devices opens from Devices', (tester) async {
    await launch(tester, role: 'sender');
    await openTab(tester, 'Settings');
    await reveal(tester, find.text('Suggest a feature'));
    await tester.tap(find.text('Suggest a feature'));
    await tester.pumpAndSettle();
    expect(find.text('What would you like AirReply to do, and how would it help you?'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await openTab(tester, 'Devices');
    await reveal(tester, find.text('Previous devices'));
    await tester.tap(find.text('Previous devices'));
    await tester.pumpAndSettle();
    expect(find.text('No previous devices'), findsOneWidget);
    await close(tester);
  });
}
