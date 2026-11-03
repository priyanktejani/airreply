import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('badge in a row, as the chat had it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('02:12'),
                    SizedBox(width: 12),
                    StatusBadge(label: 'Sent from your phone', icon: Icons.smartphone_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
}
