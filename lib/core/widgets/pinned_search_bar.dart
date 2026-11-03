import 'dart:ui' show ImageFilter;

import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_glass.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_shadows.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/responsive_center.dart';
import 'package:flutter/material.dart';

/// A search field (a sliver) that stays at the top while the page scrolls under it. At rest it is an ordinary field;
/// once pinned over content it floats as frosted glass with the floating shadow, so the page shows softly through.
/// Used by Home and the category screens; give it a TextField that takes its fill from the theme.
class PinnedSearchBar extends StatelessWidget {
  const PinnedSearchBar({super.key, required this.field, this.maxWidth = AppDimensions.maxContentWidth});

  /// The TextField. Its fill comes from the theme, so it turns to glass by itself when pinned.
  final Widget field;

  /// As wide as the page's content, and no wider.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // the field grows with the phone's text size, and so does the bar, so large text never clips
    final grow = MediaQuery.textScalerOf(context).scale(_line) - _line;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedSearchDelegate(
        field: field,
        maxWidth: maxWidth,
        extent: AppDimensions.fieldHeight + grow + AppSpacing.sm * 2,
      ),
    );
  }

  // the height of one line of the field's text (bodyLarge: 16 × 1.5)
  static const double _line = 24;
}

class _PinnedSearchDelegate extends SliverPersistentHeaderDelegate {
  _PinnedSearchDelegate({required this.field, required this.maxWidth, required this.extent});

  final Widget field;
  final double maxWidth;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      _SearchSurface(raised: overlapsContent || shrinkOffset > 0, maxWidth: maxWidth, child: field);

  @override
  bool shouldRebuild(_PinnedSearchDelegate old) =>
      old.field != field || old.maxWidth != maxWidth || old.extent != extent;
}

class _SearchSurface extends StatelessWidget {
  const _SearchSurface({required this.raised, required this.maxWidth, required this.child});

  final bool raised;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveCenter(
      maxContentWidth: maxWidth,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.sm),
      child: AnimatedContainer(
        duration: context.motion(const Duration(milliseconds: 220)),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdBorder,
          boxShadow: raised ? AppShadows.floating(context) : const [],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.mdBorder,
          child: BackdropFilter(
            enabled: raised,
            filter: ImageFilter.blur(sigmaX: AppGlass.blur, sigmaY: AppGlass.blur),
            child: Theme(
              data: raised
                  ? theme.copyWith(
                      inputDecorationTheme: theme.inputDecorationTheme.copyWith(fillColor: AppGlass.fill(context)),
                    )
                  : theme,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
