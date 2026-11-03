import 'package:flutter/material.dart';

/// Elevation, in two steps: [card] for resting cards, [floating] for things that hover over content (the navigation
/// bar, floating buttons, sheets). Dark mode uses deeper, softer shadows so surfaces still separate.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6), spreadRadius: -4)]
      : const [
          BoxShadow(color: Color(0x0F0F172A), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -6),
          BoxShadow(color: Color(0x080F172A), blurRadius: 4, offset: Offset(0, 1)),
        ];

  static List<BoxShadow> floating(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const [
          BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -6),
          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
        ]
      : const [
          BoxShadow(color: Color(0x1F0F172A), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -8),
          BoxShadow(color: Color(0x0D0F172A), blurRadius: 8, offset: Offset(0, 3)),
        ];
}
