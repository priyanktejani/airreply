import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Shows a dialog over a frosted page: the page behind softly blurs and dims as the dialog fades in, and the dialog
/// itself is a translucent glass panel (from the theme's DialogTheme). Use it instead of `showDialog` for every dialog.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: (c) => _FrostedBackdrop(child: Builder(builder: builder)),
);

/// A light blur, below the glass of bars and sheets: enough to set the dialog apart, cheap to animate.
const double _blur = 6;

class _FrostedBackdrop extends StatelessWidget {
  const _FrostedBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) return child;
    final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      child: child,
      builder: (context, child) => curve.value == 0
          ? child!
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _blur * curve.value, sigmaY: _blur * curve.value),
              child: child,
            ),
    );
  }
}
