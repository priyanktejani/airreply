import 'package:flutter/material.dart';

/// A light "press" response for a tappable card or button: the child shrinks a touch while a finger is on it.
///
/// It only adds the visual feedback; the child keeps its own tap handling and semantics (wrap an InkWell, a Card with
/// an InkWell, or a button — do not use this instead of one).
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.scale = .97});

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !still ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
