import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/widgets/underlined_headline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(UnderlinedHeadline.resetPlayed);

  Future<void> show(WidgetTester tester, Key key, {String? playOnce = 'home'}) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: UnderlinedHeadline(key: key, first: 'Your phone,', second: 'Everywhere.', playOnce: playOnce),
      ),
    ),
  );

  /// How far the first line has risen into place: 0 hidden, 1 in place.
  double shown(WidgetTester tester) => tester.widget<Opacity>(find.byType(Opacity).first).opacity;

  testWidgets('plays as the app opens, and is simply there each time it is built again', (tester) async {
    await show(tester, const ValueKey(1));
    await tester.pump(const Duration(milliseconds: 50));
    expect(shown(tester), lessThan(1), reason: 'rising into place');
    await tester.pumpAndSettle();

    // Home built again (back from another page, scrolled back into view): no second animation
    await show(tester, const ValueKey(2));
    await tester.pump();
    expect(shown(tester), 1);
  });

  testWidgets('without playOnce (or after the app starts again) it plays each time', (tester) async {
    await show(tester, const ValueKey(1), playOnce: null);
    await tester.pumpAndSettle();
    await show(tester, const ValueKey(2), playOnce: null);
    await tester.pump(const Duration(milliseconds: 50));
    expect(shown(tester), lessThan(1));
    await tester.pumpAndSettle();
  });
}
