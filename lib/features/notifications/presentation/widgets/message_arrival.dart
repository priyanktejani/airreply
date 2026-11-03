import 'package:flutter/material.dart';

/// A new message slides in from its side (mine from the right, theirs from the left) while it fades in. Messages that
/// were already there when the conversation opened appear at once ([animate] false). Still when the phone asks for
/// reduced motion.
class MessageArrival extends StatefulWidget {
  const MessageArrival({super.key, required this.fromRight, required this.child, this.animate = true, this.onShown});

  final bool fromRight;
  final bool animate;
  final Widget child;

  /// Called once the arrival has started, so it is not played again when the row is rebuilt after scrolling.
  final VoidCallback? onShown;

  @override
  State<MessageArrival> createState() => _MessageArrivalState();
}

class _MessageArrivalState extends State<MessageArrival> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.value == 1 || _c.isAnimating) return;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else {
      _c.forward();
    }
    widget.onShown?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _t,
    child: SlideTransition(
      position: Tween(begin: Offset(widget.fromRight ? .18 : -.18, .08), end: Offset.zero).animate(_t),
      child: widget.child,
    ),
  );
}
