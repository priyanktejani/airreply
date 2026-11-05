import 'package:air_reply/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Lays [child], floating chrome at the bottom of the screen (the navigation bar, the message box, an action panel),
/// over a fade to the page colour. What scrolls under it dissolves towards the screen's edge, instead of showing as a
/// cut-off line of text between the panel and the edge; the glass still shows the page above that.
class BottomFade extends StatelessWidget {
  const BottomFade({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bg = context.palette.bg;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg.withValues(alpha: 0), bg.withValues(alpha: .85), bg],
          stops: const [0, .5, 1],
        ),
      ),
      child: child,
    );
  }
}
