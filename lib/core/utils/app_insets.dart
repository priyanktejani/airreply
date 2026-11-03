import 'dart:math' as math;

import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// Padding for a screen's scrolling content: the page side margins, and room at the bottom for whatever floats over
/// the content there (the floating navigation bar, or the phone's home indicator). Use it for every page-level list so
/// the last item can scroll clear of the bar. At the top it starts below a see-through GlassAppBar (the Scaffold's
/// `extendBodyBehindAppBar` hands the bar's height down as top padding; with a plain app bar that padding is zero).
///
/// It reads the bottom padding from the [BuildContext] it is given. A Scaffold with `extendBody` adds its bottom bar's
/// height to that padding only for widgets *below* it, so call these with a context under the Scaffold (inside its
/// body, or a [Builder] there), not the context of the widget that builds the Scaffold.
class AppInsets {
  const AppInsets._();

  static EdgeInsets page(
    BuildContext context, {
    double top = AppSpacing.md,
    double bottom = AppSpacing.xl,
    double horizontal = AppSpacing.page,
  }) => EdgeInsets.fromLTRB(
    horizontal,
    top + MediaQuery.paddingOf(context).top,
    horizontal,
    bottom + MediaQuery.paddingOf(context).bottom,
  );

  /// Just the bottom room (for lists that set their own sides, or a column's last spacer).
  static double bottom(BuildContext context, {double extra = AppSpacing.xl}) =>
      extra + MediaQuery.paddingOf(context).bottom;

  /// How far to lift a tab's FloatingActionButton so it floats just above the navigation bar. The tab's Scaffold keeps
  /// the button clear of the phone's own inset only; the bar's height reaches the tab as padding on top of that. Use
  /// with the context that builds the tab's Scaffold: `Padding(padding: EdgeInsets.only(bottom: AppInsets.fabLift(context)))`.
  static double fabLift(BuildContext context) {
    final mq = MediaQuery.of(context);
    return math.max(0.0, mq.padding.bottom - mq.viewPadding.bottom);
  }
}
