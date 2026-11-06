import 'package:air_reply/app/widgets/floating_nav_bar.dart';
import 'package:air_reply/core/haptics/haptics.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:air_reply/features/notifications/presentation/widgets/swipe_actions.dart';
import 'package:air_reply/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The haptics asked of the system, as `HapticFeedback.vibrate` method arguments (null for a long press).
final List<Object?> haptics = [];

void main() {
  setUp(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
        return null;
      },
    );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  Widget wrap(Widget child, {bool hapticsOn = true}) => ProviderScope(
    overrides: [hapticsEnabledProvider.overrideWithValue(hapticsOn)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('switching tabs makes no haptic (getting around is silent)', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => FloatingNavBar(
            selectedIndex: selected,
            onSelected: (i) => setState(() => selected = i),
            items: const [
              FloatingNavItem(icon: AppIcons.home, selectedIcon: AppIcons.home, label: 'Home'),
              FloatingNavItem(icon: AppIcons.settings, selectedIcon: AppIcons.settings, label: 'Settings'),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(haptics, isEmpty);
  });

  Widget swipe() => SizedBox(
    width: 400,
    child: SwipeActions(
      id: 'a',
      isRead: false,
      onToggleRead: () async {},
      onDelete: () async {},
      child: const SizedBox(height: 80, child: Text('row')),
    ),
  );

  testWidgets('a swipe ticks once as it reaches its threshold, not on every frame', (tester) async {
    await tester.pumpWidget(wrap(swipe()));
    final gesture = await tester.startGesture(tester.getCenter(find.text('row')));
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(12, 0));
      await tester.pump();
    }
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    // back under the threshold: one more tick
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(-12, 0));
      await tester.pump();
    }
    expect(haptics, hasLength(2));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a long press gives one firmer haptic', (tester) async {
    var held = false;
    await tester.pumpWidget(wrap(AppCard(onLongPress: () => held = true, child: const Text('card'))));
    await tester.longPress(find.text('card'));
    await tester.pumpAndSettle();

    expect(held, isTrue);
    expect(haptics, hasLength(1));
  });

  testWidgets('with Haptic feedback off, nothing vibrates', (tester) async {
    var held = false;
    await tester.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCard(onLongPress: () => held = true, child: const Text('card')),
            swipe(),
          ],
        ),
        hapticsOn: false,
      ),
    );
    await tester.longPress(find.text('card'));
    final gesture = await tester.startGesture(tester.getCenter(find.text('row')));
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(12, 0));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(held, isTrue);
    expect(haptics, isEmpty);
  });
}
