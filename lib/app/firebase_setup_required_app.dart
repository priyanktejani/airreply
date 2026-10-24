import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shown instead of the app when Firebase cannot start (usually: `flutterfire configure` has not been run yet).
class FirebaseSetupRequiredApp extends StatelessWidget {
  const FirebaseSetupRequiredApp({required this.error, super.key});

  static const command = 'flutterfire configure --platforms=android,ios,macos,web,windows';

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Builder(
        builder: (context) {
          final c = context.colors;
          return Scaffold(
            body: EditorialPage(
              maxWidth: 560,
              header: const PageHeader(
                eyebrow: 'Setup required',
                title: 'Connect Firebase',
                subtitle: Text(
                  'AirReply syncs your devices through your own Firebase project. Run this in the project folder, '
                  'then rebuild the app.',
                ),
              ),
              slivers: [
                SliverList.list(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Space.x4),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: Radii.controlBorder,
                        border: Border.all(color: c.border),
                      ),
                      child: SelectableText(
                        command,
                        style: AppType.body.copyWith(
                          color: c.ink,
                          fontFamily: 'monospace',
                          fontFamilyFallback: const ['Menlo', 'Consolas'],
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.x3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => Clipboard.setData(const ClipboardData(text: command)),
                        icon: const Icon(Icons.content_copy_outlined, size: 18),
                        label: const Text('Copy command'),
                      ),
                    ),
                    const SectionLabel('Details'),
                    SelectableText('$error', style: AppType.supporting.copyWith(color: c.secondary)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
