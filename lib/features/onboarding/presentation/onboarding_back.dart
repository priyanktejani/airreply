import 'package:flutter/widgets.dart';

/// While nothing is paired, the steps after choosing what this device does are the app's first screens, so the system
/// back gesture would close it. With [onBack], back (gesture, key or the app bar's button) goes to the step before.
class OnboardingBack extends StatelessWidget {
  const OnboardingBack({required this.child, this.onBack, super.key});

  /// Null to leave back to the navigator.
  final VoidCallback? onBack;
  final Widget child;

  // Always the same widget, whether [onBack] is set or not: the screen it wraps keeps its state (a running camera) when
  // the device list loads and the screen learns it is paired.
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: onBack == null,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onBack?.call();
    },
    child: child,
  );
}
