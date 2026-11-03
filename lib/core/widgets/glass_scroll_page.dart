import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/utils/app_insets.dart';
import 'package:air_reply/core/widgets/glass_app_bar.dart';
import 'package:air_reply/core/widgets/pinned_search_bar.dart';
import 'package:air_reply/core/widgets/responsive_center.dart';
import 'package:flutter/material.dart';

/// A scrolling page under a pinned frosted-glass app bar: the content scrolls up beneath the bar (and beneath the
/// [search] box, pinned just under it), is centred and never wider than [maxWidth], and ends clear of the floating
/// navigation bar. Pull down to [onRefresh].
class GlassScrollPage extends StatelessWidget {
  const GlassScrollPage({
    required this.slivers,
    this.title,
    this.leading,
    this.actions = const [],
    this.centerTitle = false,
    this.search,
    this.onRefresh,
    this.maxWidth = AppDimensions.maxContentWidth,
    this.controller,
    super.key,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;

  /// A field that stays pinned under the app bar and turns to glass once content passes beneath it.
  final Widget? search;
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  final ScrollController? controller;

  /// The bar's height, a little taller than Material's.
  static const toolbarHeight = kToolbarHeight + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    Widget scroll = CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverAppBar(
          pinned: true,
          toolbarHeight: toolbarHeight,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: const GlassBarBackground(),
          leading: leading,
          centerTitle: centerTitle,
          title: title,
          actions: [
            ...actions,
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        if (search != null) PinnedSearchBar(field: search!, maxWidth: maxWidth),
        for (final sliver in slivers)
          ResponsiveSliverCenter(
            maxContentWidth: maxWidth,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            sliver: sliver,
          ),
        SliverToBoxAdapter(child: SizedBox(height: AppInsets.bottom(context))),
      ],
    );
    if (onRefresh != null) {
      scroll = RefreshIndicator(
        onRefresh: onRefresh!,
        edgeOffset: MediaQuery.paddingOf(context).top + toolbarHeight,
        child: scroll,
      );
    }
    return scroll;
  }
}
