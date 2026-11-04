import 'package:air_reply/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Frosted glass: a translucent fill over a backdrop blur, a hairline border that catches the light, and the
/// card/floating shadows. Kept to one blur strength so the app reads as one material and stays fast.
class AppGlass {
  const AppGlass._();

  /// Blur strength (sigma) of every glass surface.
  static const double blur = 18;

  /// The translucent fill. [strong] is for surfaces with a lot of text on them (sheets), so they stay readable.
  static Color fill(BuildContext context, {bool strong = false}) {
    final c = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return c.surface.withValues(alpha: strong ? (dark ? .86 : .9) : (dark ? .7 : .74));
  }

  /// Fill of the bars pinned over scrolling pages (app bar): the page colour, nearly opaque. Big bright text (Home's
  /// headline) races under them on a fast scroll; any thinner and it shows through as a passing glow, so the bar seems
  /// to flick between see-through and frosted.
  static Color barFill(BuildContext context) =>
      context.palette.bg.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .9 : .88);

  /// Fill for a selected card: the brand's soft accent, still translucent.
  static Color selectedFill(BuildContext context) {
    final c = context.palette;
    return c.accentSoft.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .78 : .82);
  }

  static Color border(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: .09)
      : Colors.white.withValues(alpha: .7);

  /// A faint outline under the light border, so glass does not dissolve into a white page.
  static Color edge(BuildContext context) =>
      context.palette.line.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .9 : .7);
}
