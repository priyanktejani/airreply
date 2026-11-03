import 'package:air_reply/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// The type scale (Geist, as in the iFixxer app): tight, heavy headlines, calm body text, firm labels, and the small
/// green mono label above headings ([eyebrow]). [AppTheme] maps it onto Material's text roles, so plain widgets use it.
abstract final class AppType {
  static const _fallback = ['Roboto', 'Helvetica Neue', 'Segoe UI', 'Noto Sans', 'sans-serif'];

  static TextStyle _geist(double size, double height, FontWeight weight, {double tracking = 0, String family = font}) =>
      TextStyle(
        fontFamily: family,
        fontFamilyFallback: _fallback,
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: tracking,
      );

  /// 52 extra bold — Home's headline, the one deliberate exception to the scale.
  static final hero = _geist(52, 1.0, FontWeight.w800, tracking: -2.6);

  /// 32 extra bold — the largest page text.
  static final display = _geist(32, 1.05, FontWeight.w800, tracking: -1.3);

  /// 26 bold — a page's own title, under the bar.
  static final pageTitle = _geist(26, 1.15, FontWeight.w700, tracking: -.9);

  /// 22 bold — hero card headlines.
  static final headline = _geist(22, 1.18, FontWeight.w700, tracking: -.6);

  /// 20 bold — section titles.
  static final section = _geist(20, 1.25, FontWeight.w700, tracking: -.4);

  /// 16 semibold — card and row titles.
  static final title = _geist(16, 1.3, FontWeight.w600, tracking: -.2);

  /// 15.5 semibold — list row titles and app bar subtitles.
  static final subtitle = _geist(15.5, 1.3, FontWeight.w600, tracking: -.1);

  /// 14 semibold — titles in small tiles, and times on message cards.
  static final titleSmall = _geist(14, 1.3, FontWeight.w600, tracking: -.1);

  /// 16 — longer reading text.
  static final bodyLarge = _geist(16, 1.5, FontWeight.w400);

  /// 15 — body text.
  static final body = _geist(15, 1.48, FontWeight.w400);

  /// 13 — supporting text, times, hints.
  static final supporting = _geist(13, 1.42, FontWeight.w400);

  /// 12 semibold — badges and small labels.
  static final label = _geist(12, 1.3, FontWeight.w600, tracking: .2);

  /// 11 semibold — counts in badges and the nav bar's labels.
  static final caption = _geist(11, 1.2, FontWeight.w600);

  /// 13 semibold — inline green actions and summaries ("Open", "3 notifications").
  static final link = _geist(13, 1.3, FontWeight.w600);

  /// 15 semibold — buttons.
  static final button = _geist(15, 1.3, FontWeight.w600);

  /// 13 mono — the small green label above headings.
  static final eyebrow = _geist(13, 1.3, FontWeight.w500, tracking: .3, family: mono);

  /// The scale as Material's text roles.
  static TextTheme textTheme(AppPalette c) => TextTheme(
    displayLarge: hero.copyWith(color: c.ink),
    displayMedium: display.copyWith(color: c.ink, fontSize: 40),
    displaySmall: display.copyWith(color: c.ink, fontSize: 36),
    headlineLarge: display.copyWith(color: c.ink),
    headlineMedium: _geist(26, 1.12, FontWeight.w700, tracking: -.9).copyWith(color: c.ink),
    headlineSmall: headline.copyWith(color: c.ink),
    titleLarge: section.copyWith(color: c.ink),
    titleMedium: title.copyWith(color: c.ink),
    titleSmall: _geist(14, 1.3, FontWeight.w600, tracking: -.1).copyWith(color: c.ink),
    bodyLarge: bodyLarge.copyWith(color: c.ink),
    bodyMedium: body.copyWith(color: c.ink),
    bodySmall: supporting.copyWith(color: c.muted),
    labelLarge: button.copyWith(color: c.ink),
    labelMedium: _geist(13, 1.3, FontWeight.w600, tracking: .1).copyWith(color: c.ink),
    labelSmall: label.copyWith(color: c.muted),
  );
}
