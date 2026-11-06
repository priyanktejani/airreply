import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/notice.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, Widget child, {double width = 400}) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('message boxes are as wide as each other, whatever their words', (tester) async {
    await _show(
      tester,
      const Column(
        children: [
          EmptyState(icon: AppIcons.errorOutline, tone: Tone.error, title: 'Oops'),
          EmptyState(
            icon: AppIcons.cloudOff,
            tone: Tone.error,
            title: 'Could not load notifications',
            description: 'You appear to be offline. Check your connection and try again.',
          ),
        ],
      ),
    );
    final boxes = find.byType(EmptyState);
    expect(tester.getSize(boxes.at(0)).width, tester.getSize(boxes.at(1)).width);

    await _show(
      tester,
      const Column(
        children: [
          Notice(title: 'Short', message: 'Hi'),
          Notice(title: 'A much longer title for a notice', message: 'With a long explanation under it, too.'),
        ],
      ),
    );
    final notices = find.byType(Notice);
    expect(tester.getSize(notices.at(0)).width, 400);
    expect(tester.getSize(notices.at(1)).width, 400);
  });

  testWidgets('bottom messages: the same width on a phone, centred and capped on a big screen', (tester) async {
    for (final (screen, expected) in [(400.0, 400.0 - 32), (1200.0, maxSnackBarWidth)]) {
      await _show(tester, const SizedBox(), width: screen);
      final context = tester.element(find.byType(Scaffold));
      for (final message in ['Done', 'Something went wrong. Please try again, or check your connection first.']) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(appSnackBar(context, message));
        await tester.pumpAndSettle();
        // the bar itself, inside its margins
        final bar = tester.getRect(find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first);
        expect(bar.width, expected, reason: '$message at $screen');
        expect(bar.center.dx, screen / 2);
      }
    }
  });
}
