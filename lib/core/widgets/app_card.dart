import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/animations/pressable_scale.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/glass_container.dart';
import 'package:flutter/material.dart';

/// The app's card: a surface with the standard radius, hairline and soft shadow (from the theme's CardTheme), standard
/// inner padding, and — with [onTap] or [onLongPress] — ink and a light press response.
///
/// A [selected] card turns into frosted glass tinted with the brand's soft accent and an accent edge: chosen trades,
/// chosen options, the current item.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.padding = const EdgeInsets.all(AppSpacing.card),
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tappable = onTap != null || onLongPress != null;
    Widget card = selected
        ? GlassContainer(
            key: const ValueKey(true),
            selected: true,
            borderRadius: AppRadius.lgBorder,
            padding: padding,
            onTap: onTap,
            child: child,
          )
        : Card(
            key: const ValueKey(false),
            child: !tappable
                ? Padding(padding: padding, child: child)
                : InkWell(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: Padding(padding: padding, child: child),
                  ),
          );
    // choosing a card cross-fades it into the glass and back, instead of snapping
    card = AnimatedSwitcher(
      duration: context.motion(const Duration(milliseconds: 180)),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      // passthrough: the card keeps the size its parent gives it (a Stack would let it shrink to its content)
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.passthrough, alignment: Alignment.center, children: [...previous, ?current]),
      child: card,
    );
    if (tappable) card = PressableScale(child: card);
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}
