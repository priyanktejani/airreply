import 'package:air_reply/core/platform/launcher_icon.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart';

/// The system's side, as a phone would answer: the icon showing now, and the choices made.
final class _FakeIcons implements LauncherIcons {
  var showing = LauncherIcon.light;
  final chosen = <LauncherIcon>[];

  @override
  Future<LauncherIcon> current() async => showing;

  @override
  Future<void> set(LauncherIcon icon) async {
    chosen.add(icon);
    showing = icon;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Settings → Appearance → App icon: shows the one on the home screen, and switches it', (tester) async {
    final icons = _FakeIcons();
    await launch(tester, role: 'receiver', overrides: [launcherIconsProvider.overrideWithValue(icons)]);
    await openTab(tester, 'Settings');
    await reveal(tester, find.text('App icon'));
    expect(find.text('Light'), findsWidgets, reason: 'what the system shows now');

    await tester.tap(find.text('App icon'));
    await tester.pumpAndSettle();
    expect(find.text('The icon of AirReply on your home screen.'), findsOneWidget);
    // the dark icon's picture, in the sheet
    final dark = find.byWidgetPredicate(
      (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.endsWith('choice_dark.png'),
    );
    expect(dark, findsOneWidget);
    await tester.tap(dark);
    await tester.pumpAndSettle();

    expect(icons.chosen, [LauncherIcon.dark]);
    expect(find.text('Icon changed. Your home screen may take a moment to show it.'), findsOneWidget);
    await reveal(tester, find.text('App icon'));
    expect(find.text('Dark'), findsWidgets);
    await close(tester);
  });

  test('the native side: the icon by name, both ways', () async {
    const channel = MethodChannel('com.airreply/methods');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'getLauncherIcon' ? 'dark' : null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
    );

    final icons = LauncherIcons();
    expect(await icons.current(), LauncherIcon.dark);
    await icons.set(LauncherIcon.light);
    expect(calls.last.method, 'setLauncherIcon');
    expect(calls.last.arguments, {'name': 'light'});
  });
}
