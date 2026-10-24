import 'package:flutter/material.dart';

/// Colour tokens of the editorial design: warm neutrals for everything, colour only for meaningful states.
/// The single source of truth for colour; read with `context.colors`.
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.secondary,
    required this.border,
    required this.subtle,
    required this.success,
    required this.warning,
    required this.error,
    required this.disabled,
  });

  static const light = AppColors(
    paper: Color(0xFFF8F7F4),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF20201E),
    secondary: Color(0xFF77756F),
    border: Color(0xFFE5E2DC),
    subtle: Color(0xFFF0EEE9),
    success: Color(0xFF38785B),
    warning: Color(0xFF9A6516),
    error: Color(0xFFB13F2E),
    disabled: Color(0xFFB7B4AD),
  );

  static const dark = AppColors(
    paper: Color(0xFF131312),
    surface: Color(0xFF1C1C1A),
    ink: Color(0xFFEFEDE8),
    secondary: Color(0xFF9D9A93),
    border: Color(0xFF2D2C29),
    subtle: Color(0xFF232321),
    success: Color(0xFF6FB18F),
    warning: Color(0xFFD9A955),
    error: Color(0xFFE48672),
    disabled: Color(0xFF5A5853),
  );

  /// Page background.
  final Color paper;

  /// Raised surfaces: sheets, inputs, the occasional card.
  final Color surface;

  /// Primary text and primary actions.
  final Color ink;

  /// Supporting text and icons.
  final Color secondary;

  /// Hairline dividers and outlines.
  final Color border;

  /// Quiet fills: pressed states, selected rows, skeletons.
  final Color subtle;
  final Color success;
  final Color warning;
  final Color error;
  final Color disabled;

  @override
  AppColors copyWith({Color? ink}) => AppColors(
    paper: paper,
    surface: surface,
    ink: ink ?? this.ink,
    secondary: secondary,
    border: border,
    subtle: subtle,
    success: success,
    warning: warning,
    error: error,
    disabled: disabled,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      paper: c(paper, other.paper),
      surface: c(surface, other.surface),
      ink: c(ink, other.ink),
      secondary: c(secondary, other.secondary),
      border: c(border, other.border),
      subtle: c(subtle, other.subtle),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      error: c(error, other.error),
      disabled: c(disabled, other.disabled),
    );
  }
}

/// 4 px spacing scale.
abstract final class Space {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
  static const x16 = 64.0;

  /// Horizontal page padding: 24 on standard phones, tighter on very narrow screens.
  static double page(BuildContext context) => MediaQuery.sizeOf(context).width < 360 ? x4 : x6;

  /// Content never grows wider than this on tablets, desktops and browsers.
  static const maxContentWidth = 680.0;
}

/// Restrained corner radii: controls are softly squared, modal sheets a little rounder.
abstract final class Radii {
  static const control = 8.0;
  static const sheet = 20.0;

  static const controlBorder = BorderRadius.all(Radius.circular(control));
}

/// Motion: short and quiet.
abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);
  static const curve = Curves.easeOutCubic;
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
