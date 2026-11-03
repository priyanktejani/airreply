import 'package:flutter/material.dart';

/// The colours, from the iFixxer design (its website's tokens): a calm page and surface, ink and muted text, hairline
/// lines, one brand accent for what matters, a warm glow, and soft fills for states. Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.soft,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.glow,
    required this.deep,
    required this.deepInk,
    required this.deepMuted,
    required this.danger,
    required this.dangerSoft,
    required this.warnSoft,
    required this.warnInk,
    required this.disabled,
    required this.scrim,
  });

  final Color bg,
      surface,
      ink,
      muted,
      line,
      soft,
      accent,
      accentInk,
      accentSoft,
      glow,
      deep,
      deepInk,
      deepMuted,
      danger,
      dangerSoft,
      warnSoft,
      warnInk;

  /// Controls and text that cannot be used right now.
  final Color disabled;

  /// A dark veil behind sheets and dialogs.
  final Color scrim;

  static const light = AppPalette(
    bg: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF0F172A),
    muted: Color(0xFF56657A),
    line: Color(0xFFE6E9EE),
    soft: Color(0xFFF0F2F5),
    accent: Color(0xFF0B6BCB),
    accentInk: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE3EFFB),
    glow: Color(0xFFFFE7A3),
    deep: Color(0xFF0F172A),
    deepInk: Color(0xFFEEF2F7),
    deepMuted: Color(0xFF9AA8BD),
    danger: Color(0xFFB3261E),
    dangerSoft: Color(0xFFFBE6E4),
    warnSoft: Color(0xFFFDF0D5),
    warnInk: Color(0xFF5A3B00),
    disabled: Color(0xFFA9B3C1),
    scrim: Color(0x8A000000),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0A0E14),
    surface: Color(0xFF10161F),
    ink: Color(0xFFEEF2F7),
    muted: Color(0xFF8B99AD),
    line: Color(0xFF1D2633),
    soft: Color(0xFF151C27),
    accent: Color(0xFF5CB2FF),
    accentInk: Color(0xFF03203A),
    accentSoft: Color(0xFF10283F),
    glow: Color(0xFFFFD36B),
    deep: Color(0xFF10161F),
    deepInk: Color(0xFFEEF2F7),
    deepMuted: Color(0xFF8B99AD),
    danger: Color(0xFFFF9A92),
    dangerSoft: Color(0xFF40201D),
    warnSoft: Color(0xFF3A2D0F),
    warnInk: Color(0xFFF0C36A),
    disabled: Color(0xFF4A5566),
    scrim: Color(0x99000000),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) => t < .5 || other is! AppPalette ? this : other;
}

extension AppPaletteX on BuildContext {
  /// The colours for the current light or dark theme.
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// The typefaces: Geist for everything, Geist Mono for the small accent labels.
const font = 'Geist';
const mono = 'GeistMono';
