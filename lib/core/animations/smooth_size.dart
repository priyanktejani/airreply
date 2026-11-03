import 'package:flutter/material.dart';

/// Grows or shrinks smoothly when its child changes size (an error appearing, a section opening). With reduced motion
/// the child simply changes: no [AnimatedSize] at all, since one with a zero duration cannot lay out a change.
class SmoothSize extends StatelessWidget {
  const SmoothSize({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.alignment = Alignment.topCenter,
  });
  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => MediaQuery.of(context).disableAnimations
      ? child
      : AnimatedSize(duration: duration, curve: Curves.easeOutCubic, alignment: alignment, child: child);
}
