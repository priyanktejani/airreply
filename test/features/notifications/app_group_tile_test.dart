import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/demo/demo_mode.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/presentation/widgets/group_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'conversation_screen_test.dart' show message;

void main() {
  testWidgets("a closed app card's tap area covers the whole card", (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final group = groupByApp([message('1', 'Asha', 'Hi', 1), message('2', 'Asha', 'Are you there?', 2)]).single;

    await tester.pumpWidget(
      ProviderScope(
        overrides: demoOverrides('receiver'),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            // in a list, as on the inbox
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [AppGroupTile(group: group, expanded: false, onToggleExpanded: () {})],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = tester.getRect(find.descendant(of: find.byType(AppGroupTile), matching: find.byType(Card)));
    final ink = tester.getRect(find.descendant(of: find.byType(Card), matching: find.byType(InkWell)).first);
    expect(ink, card);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
