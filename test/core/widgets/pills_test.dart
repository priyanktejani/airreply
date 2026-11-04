import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/widgets/status_pill.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/devices/presentation/device_status_badge.dart';
import 'package:air_reply/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pills keep their own size at the start of a column that stretches its children', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DeviceStatusBadge(status: DeviceStatus(DeviceState.connected, DeviceCondition.receiving)),
              StatusPill('Sent', tone: PillTone.good),
            ],
          ),
        ),
      ),
    );
    for (final pill in [find.byType(DeviceStatusBadge), find.byType(StatusPill)]) {
      final box = tester.getRect(find.descendant(of: pill, matching: find.byType(DecoratedBox)).first);
      expect(box.width, lessThan(150));
      expect(box.left, 0);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
