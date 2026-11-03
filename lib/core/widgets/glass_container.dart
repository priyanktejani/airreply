import 'dart:ui';

import 'package:air_reply/core/theme/app_glass.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_shadows.dart';
import 'package:flutter/material.dart';

/// Frosted glass: content on a translucent surface over a backdrop blur, with a light hairline border and a soft
/// shadow ([AppGlass] tokens). For things that float over content (the navigation bar, floating actions, sheets) and
/// for selected cards. Use sparingly: regular content sits on plain cards.
///
/// [selected] tints it with the brand's soft green; [strong] makes the fill more opaque for text-heavy surfaces;
/// [floating] uses the floating shadow instead of the card one. With [onTap] it becomes a tappable surface. Its content
/// sits on a transparent Material, so ListTiles and InkWells inside show their ink on the glass.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.onTap,
    this.selected = false,
    this.strong = false,
    this.floating = false,
    this.backgroundColor,
    this.boxShadow,
    this.blur = AppGlass.blur,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final VoidCallback? onTap;
  final bool selected;
  final bool strong;
  final bool floating;

  /// Overrides the translucent fill.
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lgBorder;
    final fill =
        backgroundColor ?? (selected ? AppGlass.selectedFill(context) : AppGlass.fill(context, strong: strong));
    final scheme = Theme.of(context).colorScheme;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(
          color: selected ? scheme.primary.withValues(alpha: .55) : AppGlass.border(context),
          width: selected ? 1.4 : 1,
        ),
      ),
      // ink from ListTiles and buttons inside draws on the glass, not on a Material further behind it
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );

    if (onTap != null) {
      surface = Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: radius, child: surface),
      );
    }

    return Container(
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ?? (floating ? AppShadows.floating(context) : AppShadows.card(context)),
        // a faint outer edge so glass never dissolves into a light page
        border: Border.all(color: AppGlass.edge(context), width: .5),
      ),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: surface,
          ),
        ),
      ),
    );
  }
}
