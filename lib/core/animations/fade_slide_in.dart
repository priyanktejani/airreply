import 'package:flutter/material.dart';

/// Fades its child in while it rises a few pixels into place: cards, list rows and sections as they appear.
///
/// Use [FadeSlideIn.staggered] in lists so the first rows arrive one after another; rows further down, built as they
/// scroll into view, simply appear (a lazily built list would otherwise replay the entrance on every scroll). Nothing
/// moves when the phone asks for reduced motion.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 360),
    this.offset = 14,
  }) : animate = true;

  /// For the [index]th item of a list: the first [staggeredRows] arrive 45 ms apart, the rest without animating.
  FadeSlideIn.staggered({
    super.key,
    required int index,
    required this.child,
    this.duration = const Duration(milliseconds: 360),
    this.offset = 14,
  }) : delay = Duration(milliseconds: 45 * index.clamp(0, staggeredRows)),
       animate = index < staggeredRows;

  /// How many rows of a list arrive one after another: about a screenful.
  static const staggeredRows = 8;

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// How far below its place the child starts, in logical pixels.
  final double offset;

  /// False to show the child in place at once.
  final bool animate;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // FadeTransition fades without rebuilding the child or painting it offscreen, as Opacity would on every frame.
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _t,
    child: AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
    ),
  );
}
