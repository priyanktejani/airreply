import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/utils/app_insets.dart';
import 'package:air_reply/core/widgets/bottom_fade.dart';
import 'package:air_reply/core/widgets/glass_container.dart';
import 'package:flutter/material.dart';

/// A screen's main action kept at the bottom ("Continue", "Save", "Pay £120 securely"): a frosted-glass panel that
/// floats clear of the screen edges and the phone's home indicator, so the content scrolls underneath it.
///
/// Two ways to place it:
/// - as a Scaffold's `bottomNavigationBar` with `extendBody: true`; lists below that Scaffold pad with
///   `AppInsets.page`, which then includes the bar;
/// - at the bottom of a Stack over the scrolling content, which ends with [room] (or adds [reserve]).
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({super.key, required this.child, this.pill = true});

  /// The buttons. They get the bar's full width.
  final Widget child;

  /// A pill around one row of buttons, like the navigation bar; false for a panel with a line of text under them.
  final bool pill;

  /// Height the bar takes above the home indicator with one row of buttons.
  static const double reserve = AppDimensions.buttonHeight + AppSpacing.sm * 2 + AppSpacing.md;

  /// Space to end content with when the bar floats over it in a Stack: the bar, the home indicator and a gap.
  static double room(BuildContext context) => AppInsets.bottom(context, extra: reserve + AppSpacing.xl);

  @override
  Widget build(BuildContext context) => BottomFade(
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: GlassContainer(
        strong: true,
        floating: true,
        borderRadius: pill ? AppRadius.fullBorder : AppRadius.xlBorder,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}
