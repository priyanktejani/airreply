import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';

/// Something that needs the person's attention, on the tone's soft ground: an icon, a title, a sentence, and the
/// actions that fix it.
class Notice extends StatelessWidget {
  const Notice({
    required this.title,
    required this.message,
    this.tone = Tone.warning,
    this.icon,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String message;
  final Tone tone;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final (ground, ink) = switch (tone) {
      Tone.error => (c.dangerSoft, c.danger),
      Tone.warning => (c.warnSoft, c.warnInk),
      Tone.success => (c.accentSoft, c.accent),
      Tone.neutral => (c.soft, c.ink),
    };
    // as wide as its column, whatever its words: notices line up with each other and with the cards around them
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(color: ground, borderRadius: AppRadius.lgBorder),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.md),
          child: Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon ?? (tone == Tone.error ? AppIcons.errorOutline : AppIcons.warningAmber),
                      size: 22,
                      color: ink,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppType.title.copyWith(color: ink)),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(message, style: AppType.supporting.copyWith(color: c.ink.withValues(alpha: .8))),
                        ],
                      ),
                    ),
                  ],
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(left: 22 + AppSpacing.md),
                    child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
