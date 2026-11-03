import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page transitions used by the router.
///
/// Pushed screens slide a little from the right while fading in (and the screen below eases back), the way a
/// detail opens from a list. Tab roots and replacements fade through. Both are short and become instant when the
/// phone asks for reduced motion.
class AppTransitions {
  const AppTransitions._();

  static const _duration = Duration(milliseconds: 300);

  /// A screen opened on top of another (a job, a chat, a settings page).
  static Page<void> push(GoRouterState state, Widget child) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _duration,
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondary, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      final inCurve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      final outCurve = CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic);
      // the screen underneath eases a little to the left as the new one arrives
      return SlideTransition(
        position: Tween(begin: Offset.zero, end: const Offset(-.06, 0)).animate(outCurve),
        child: FadeTransition(
          opacity: inCurve,
          child: SlideTransition(
            position: Tween(begin: const Offset(.08, 0), end: Offset.zero).animate(inCurve),
            child: child,
          ),
        ),
      );
    },
  );

  /// A screen that replaces another without a "back" relationship (the first screen, a finished flow).
  static Page<void> fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondary, child) => MediaQuery.of(context).disableAnimations
        ? child
        : FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween(
                begin: .985,
                end: 1.0,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
  );
}
