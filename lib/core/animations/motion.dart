import 'package:flutter/widgets.dart';

/// The app's motion: quick to respond, soft to settle, and never longer than 400 ms. Use `context.motion(d)` for these
/// so they become instant with reduced motion.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;
}

/// Durations that become instant when the phone asks for reduced motion. Use `context.motion(d)` for any animation
/// duration you write; [SmoothSize] instead of AnimatedSize (which cannot lay out a change with a zero duration).
extension MotionX on BuildContext {
  bool get stillMotion => MediaQuery.of(this).disableAnimations;

  /// [d], or zero with reduced motion.
  Duration motion(Duration d) => stillMotion ? Duration.zero : d;
}
