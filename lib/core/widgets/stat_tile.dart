import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// A figure on its own card: the icon in a rounded square, the number, and its label under it (like a trade tile).
/// Tappable when [onTap] is set; the number rolls when it changes.
class Stat extends StatelessWidget {
  const Stat({required this.value, required this.label, this.icon, this.onTap, super.key});

  final String value;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  static const double _iconBox = 44;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Semantics(
      button: onTap != null,
      label: '$value $label',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: _iconBox,
                height: _iconBox,
                decoration: BoxDecoration(color: c.soft, borderRadius: AppRadius.mdBorder),
                child: Icon(icon, size: AppDimensions.iconLg, color: c.accent),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                value,
                key: ValueKey(value),
                style: AppType.headline.copyWith(color: c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.supporting.copyWith(color: c.muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
