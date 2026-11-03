import 'package:flutter/material.dart';

/// Fades its child in while it rises a few pixels into place: cards, list rows and sections as they appear.
///
/// Use [FadeSlideIn.staggered] in lists so rows arrive one after another (capped, so long lists do not crawl).
/// Nothing moves when the phone asks for reduced motion.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 360),
    this.offset = 14,
  });

  /// For the [index]th item of a list: 45 ms apart, at most the first 8 are delayed.
  FadeSlideIn.staggered({
    super.key,
    required int index,
    required this.child,
    this.duration = const Duration(milliseconds: 360),
    this.offset = 14,
  }) : delay = Duration(milliseconds: 45 * (index.clamp(0, 8)));

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// How far below its place the child starts, in logical pixels.
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
    ),
  );
}
