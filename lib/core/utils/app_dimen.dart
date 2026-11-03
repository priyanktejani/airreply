import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:flutter/widgets.dart';

/// The kind of window the app is in, by width: [mobile] below [AppDimensions.maxMobileWidth], [tablet] below
/// [AppDimensions.maxTabletWidth] (tablets, and phones turned sideways), [desktop] from there up.
enum ScreenType {
  mobile,
  tablet,
  desktop;

  static ScreenType fromWidth(double width) => width < AppDimensions.maxMobileWidth
      ? mobile
      : width < AppDimensions.maxTabletWidth
      ? tablet
      : desktop;
}

/// The window's size and [ScreenType], and values chosen for it.
///
/// Sizes come from the design tokens and stay the same on every screen; what changes with the screen type is the
/// layout (columns, navigation, content width). Use [responsive] to choose such a value:
///
/// ```dart
/// final columns = AppDimen.of(context).responsive(mobile: 1, desktop: 2);
/// ```
class AppDimen {
  const AppDimen._({
    required this.screenWidth,
    required this.screenHeight,
    required this.devicePixelRatio,
    required this.screenType,
  });

  /// The window this [context] is in. Rebuilds the caller only when the window's size changes.
  factory AppDimen.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AppDimen._(
      screenWidth: size.width,
      screenHeight: size.height,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      screenType: ScreenType.fromWidth(size.width),
    );
  }

  final double screenWidth;
  final double screenHeight;
  final double devicePixelRatio;
  final ScreenType screenType;

  bool get isMobile => screenType == ScreenType.mobile;

  /// Wider than a phone held upright: a tablet, a phone turned sideways, or a desktop.
  bool get isWide => screenType != ScreenType.mobile;

  /// [mobile] on phones, [tablet] on tablets (or [mobile]), [desktop] on desktops (or [tablet], or [mobile]).
  T responsive<T>({required T mobile, T? tablet, T? desktop}) => switch (screenType) {
    ScreenType.mobile => mobile,
    ScreenType.tablet => tablet ?? mobile,
    ScreenType.desktop => desktop ?? tablet ?? mobile,
  };
}
