import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/glass_container.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';

/// Nothing to show yet, or something went wrong: an icon on its tile, a title, a line of explanation and an optional
/// action, on a glass card that rises in.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.secondaryAction,
    this.tone = Tone.neutral,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final Widget? secondaryAction;

  /// [Tone.error] for failures; otherwise the brand accent.
  final Tone tone;

  static const double _tile = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final error = tone == Tone.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: FadeSlideIn(
            child: GlassContainer(
              borderRadius: AppRadius.xlBorder,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: error ? c.dangerSoft : c.accentSoft,
                      borderRadius: AppRadius.lgBorder,
                    ),
                    child: SizedBox.square(
                      dimension: _tile,
                      child: Icon(icon, color: error ? c.danger : c.accent, size: AppDimensions.iconLg + 6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppType.title.copyWith(color: c.ink),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: AppType.body.copyWith(color: c.muted),
                    ),
                  ],
                  if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
                  if (secondaryAction != null) ...[const SizedBox(height: AppSpacing.sm), secondaryAction!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
