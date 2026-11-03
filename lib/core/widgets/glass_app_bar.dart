import 'dart:ui' show ImageFilter;

import 'package:air_reply/core/theme/app_glass.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// The app bar on frosted glass: the page scrolls up underneath it and shows softly through a backdrop blur, under a
/// translucent fill of the page colour (so at rest it looks like the page) and a hairline.
///
/// Use it with `extendBodyBehindAppBar: true` on the Scaffold. The Scaffold then gives its body the bar's height as
/// top padding, so lists padded with `AppInsets.page` (or with no padding of their own) start below the bar.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle,
    this.titleSpacing,
    this.toolbarHeight,
    this.automaticallyImplyLeading = true,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;
  final double? titleSpacing;
  final double? toolbarHeight;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight((toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) => AppBar(
    title: title,
    leading: leading,
    actions: actions,
    bottom: bottom,
    centerTitle: centerTitle,
    titleSpacing: titleSpacing,
    toolbarHeight: toolbarHeight,
    automaticallyImplyLeading: automaticallyImplyLeading,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    flexibleSpace: const GlassBarBackground(),
  );
}

/// The frosted backdrop of [GlassAppBar], for a SliverAppBar's `flexibleSpace` (with a transparent background).
class GlassBarBackground extends StatelessWidget {
  const GlassBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppGlass.blur, sigmaY: AppGlass.blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // the page colour, translucent: invisible at rest, frosted once content passes under it
              color: c.bg.withValues(alpha: dark ? .78 : .8),
              border: Border(bottom: BorderSide(color: AppGlass.edge(context).withValues(alpha: .55), width: .5)),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
