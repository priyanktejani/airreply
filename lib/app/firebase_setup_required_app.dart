import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/app_logo.dart';
import 'package:air_reply/core/widgets/eyebrow.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/section_header.dart';
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Builder(
        builder: (context) {
          final c = context.palette;
          return Scaffold(
            body: GlassScrollPage(
              maxWidth: 560,
              centerTitle: true,
              title: const AppLogo(),
              slivers: [
                SliverList.list(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      eyebrow: context.l10n.firebaseSetupEyebrow,
                      title: context.l10n.firebaseSetupTitle,
                      large: true,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(context.l10n.firebaseSetupBody, style: AppType.bodyLarge.copyWith(color: c.muted)),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: c.line),
                      ),
                      child: SelectableText(
                        command,
                        style: AppType.body.copyWith(
                          color: c.ink,
                          fontFamily: mono,
                          fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => Clipboard.setData(const ClipboardData(text: command)),
                        icon: const Icon(AppIcons.contentCopy, size: 18),
                        label: Text(context.l10n.actionCopyCommand),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    Eyebrow(context.l10n.firebaseSetupDetails),
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText('$error', style: AppType.supporting.copyWith(color: c.muted)),
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
