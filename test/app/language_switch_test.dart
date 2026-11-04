import 'package:air_reply/core/l10n/app_language.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_flow_test.dart';

void main() {
  testWidgets('Settings switches the language at once, keeps it, and can follow the device again', (tester) async {
    addTearDown(() => chosenLocale = null);
    await launch(tester, role: 'receiver');
    await openTab(tester, 'Settings');
    await reveal(tester, find.text('Language'));
    expect(find.text('Same as this device (English)'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    // every language is listed in itself
    for (final name in languageNames.values) {
      expect(find.text(name), findsOneWidget);
    }
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.text('Einstellungen'), findsWidgets);
    expect(find.text('Sprache'), findsOneWidget);
    expect(await AppLanguageStore(SharedPreferencesAsync()).read(), const Locale('de'));
    // alerts raised without a screen speak it too
    expect(appL10n().actionSend, 'Senden');

    await tester.tap(find.text('Sprache'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wie dieses Gerät'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(await AppLanguageStore(SharedPreferencesAsync()).read(), isNull);
    expect(appL10n().actionSend, 'Send');
    await close(tester);
  });
}
