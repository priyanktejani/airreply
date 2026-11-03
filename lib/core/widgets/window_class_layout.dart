import 'package:air_reply/core/utils/app_dimen.dart';
import 'package:flutter/material.dart';

/// Builds [mobile], [tablet] or [desktop] for the [ScreenType] of the space this widget is given (so inside the
/// navigation rail's layout it goes by the width beside the rail). A missing [desktop] falls back to [tablet], and a
/// missing [tablet] to [mobile].
class WindowClassLayout extends StatelessWidget {
  const WindowClassLayout({required this.mobile, this.tablet, this.desktop, super.key});

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final builder = switch (ScreenType.fromWidth(constraints.maxWidth)) {
        ScreenType.mobile => mobile,
        ScreenType.tablet => tablet ?? mobile,
        ScreenType.desktop => desktop ?? tablet ?? mobile,
      };
      return builder(context);
    },
  );
}

/// Builds [portrait], or [landscape] (when given) while the device is on its side.
class OrientationLayout extends StatelessWidget {
  const OrientationLayout({required this.portrait, this.landscape, super.key});

  final WidgetBuilder portrait;
  final WidgetBuilder? landscape;

  @override
  Widget build(BuildContext context) => OrientationBuilder(
    builder: (context, orientation) =>
        orientation == Orientation.landscape && landscape != null ? landscape!(context) : portrait(context),
  );
}
