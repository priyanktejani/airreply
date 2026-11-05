import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/glass_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show FloatingHeaderSnapConfiguration;

/// A scrolling page's frosted app bar that gets out of the way: reading on (the page moving up) slides it away, and
/// scrolling back the other way, anywhere in the page, brings it straight back. Under the status bar a strip of the
/// same glass always stays, so the page never shows through the system's icons, and slivers pinned after this one
/// (a search box) stay just below whatever of the bar is showing.
class GlassSliverAppBar extends StatefulWidget {
  const GlassSliverAppBar({
    this.title,
    this.leading,
    this.actions = const [],
    this.centerTitle = false,
    this.toolbarHeight = defaultHeight,
    super.key,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;
  final double toolbarHeight;

  /// The bar's height, a little taller than Material's.
  static const defaultHeight = kToolbarHeight + AppSpacing.sm;

  @override
  State<GlassSliverAppBar> createState() => _GlassSliverAppBarState();
}

// The floating header disposes its snap animation whenever it is detached (a tab switch, a route transition, the
// page moving in the tree) and makes a new one when it snaps again, from the same provider: so the state provides
// several tickers. A single-ticker provider throws the second time.
class _GlassSliverAppBarState extends State<GlassSliverAppBar> with TickerProviderStateMixin {
  FloatingHeaderSnapConfiguration? _snap;

  /// The same snap while the motion setting stays, so a rebuild does not hand the header a new one each time.
  FloatingHeaderSnapConfiguration _snapFor(Duration duration) {
    final current = _snap;
    if (current != null && current.duration == duration) return current;
    return _snap = FloatingHeaderSnapConfiguration(curve: Curves.easeOutCubic, duration: duration);
  }

  @override
  Widget build(BuildContext context) => SliverPersistentHeader(
    pinned: true,
    floating: true,
    delegate: _GlassBarDelegate(
      bar: widget,
      statusBar: MediaQuery.paddingOf(context).top,
      vsync: this,
      // reduced motion: the bar is either there or not, without the slide
      snap: _snapFor(context.motion(const Duration(milliseconds: 220))),
    ),
  );
}

class _GlassBarDelegate extends SliverPersistentHeaderDelegate {
  _GlassBarDelegate({required this.bar, required this.statusBar, required this.vsync, required this.snap});

  final GlassSliverAppBar bar;
  final double statusBar;
  final FloatingHeaderSnapConfiguration snap;

  @override
  final TickerProvider vsync;

  @override
  FloatingHeaderSnapConfiguration get snapConfiguration => snap;

  /// Only the strip under the status bar stays.
  @override
  double get minExtent => statusBar;

  @override
  double get maxExtent => statusBar + bar.toolbarHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // how much of the toolbar is out of sight: it slides up behind the strip and fades as it goes
    final hidden = (shrinkOffset / bar.toolbarHeight).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        const GlassBarBackground(),
        Positioned(
          top: statusBar,
          left: 0,
          right: 0,
          bottom: 0,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              minHeight: bar.toolbarHeight,
              maxHeight: bar.toolbarHeight,
              child: Opacity(
                opacity: 1 - hidden,
                // out of sight, out of reach: no taps on a bar that is not there
                child: IgnorePointer(
                  ignoring: hidden > .5,
                  child: ExcludeSemantics(
                    excluding: hidden >= 1,
                    child: AppBar(
                      primary: false,
                      toolbarHeight: bar.toolbarHeight,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      // the glass behind is this bar's own; the page scrolling under it changes nothing
                      notificationPredicate: (_) => false,
                      leading: bar.leading,
                      centerTitle: bar.centerTitle,
                      title: bar.title,
                      actions: [
                        ...bar.actions,
                        const SizedBox(width: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(_GlassBarDelegate old) =>
      old.bar != bar || old.statusBar != statusBar || old.vsync != vsync || old.snap != snap;
}
