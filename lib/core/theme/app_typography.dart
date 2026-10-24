import 'package:flutter/material.dart';

/// The type scale. Instrument Serif for large editorial headlines, DM Sans for everything functional.
/// Line heights are expressed as ratios so system text scaling keeps the rhythm.
abstract final class AppType {
  static const serif = 'InstrumentSerif';
  static const sans = 'DMSans';

  /// Fallbacks while (or if) the bundled fonts cannot be used, e.g. scripts they do not cover.
  static const _serifFallback = ['Georgia', 'Times New Roman', 'Noto Serif', 'serif'];
  static const _sansFallback = ['Roboto', 'Helvetica Neue', 'Segoe UI', 'Noto Sans', 'sans-serif'];

  static TextStyle _serif(double size, double line) => TextStyle(
    fontFamily: serif,
    fontFamilyFallback: _serifFallback,
    fontSize: size,
    height: line / size,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );

  static TextStyle _sans(double size, double line, FontWeight weight, {double tracking = 0}) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: _sansFallback,
    fontSize: size,
    height: line / size,
    fontWeight: weight,
    letterSpacing: tracking,
  );

  /// 36/40 — page titles.
  static final display = _serif(36, 40);

  /// 28/32 — section and detail headlines.
  static final section = _serif(28, 32);

  /// 18/24 — notification titles.
  static final title = _sans(18, 24, FontWeight.w500, tracking: -0.1);

  /// 16/24 — app bar titles, list primary text.
  static final subtitle = _sans(16, 24, FontWeight.w500);

  /// 15/22 — reading text.
  static final body = _sans(15, 22, FontWeight.w400);

  /// 13/18 — supporting text, timestamps, metadata.
  static final supporting = _sans(13, 18, FontWeight.w400);

  /// 11/16 — compact labels (eyebrows, badges), set in caps with tracking.
  static final label = _sans(11, 16, FontWeight.w600, tracking: 0.8);

  /// 14/20 — buttons.
  static final button = _sans(14, 20, FontWeight.w600, tracking: 0.1);

  /// Maps the scale onto Material's roles so every component picks it up.
  static TextTheme textTheme(Color ink, Color secondary) => TextTheme(
    displayLarge: display.copyWith(fontSize: 44, height: 48 / 44, color: ink),
    displayMedium: display.copyWith(color: ink),
    displaySmall: section.copyWith(color: ink),
    headlineLarge: section.copyWith(color: ink),
    headlineMedium: section.copyWith(color: ink),
    headlineSmall: _serif(24, 28).copyWith(color: ink),
    titleLarge: title.copyWith(color: ink),
    titleMedium: subtitle.copyWith(color: ink),
    titleSmall: _sans(14, 20, FontWeight.w600).copyWith(color: ink),
    bodyLarge: _sans(16, 24, FontWeight.w400).copyWith(color: ink),
    bodyMedium: body.copyWith(color: ink),
    bodySmall: supporting.copyWith(color: secondary),
    labelLarge: button.copyWith(color: ink),
    labelMedium: _sans(12, 16, FontWeight.w500).copyWith(color: ink),
    labelSmall: label.copyWith(color: secondary),
  );
}
