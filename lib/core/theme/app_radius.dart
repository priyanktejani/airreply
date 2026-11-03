import 'package:flutter/material.dart';

/// Corner radii. One small scale for the whole app (from the Home screen and the website's cards):
/// [sm] 12 small chips and thumbnails, [md] 16 fields, tiles and inner panels, [lg] 20 cards,
/// [xl] 24 sheets and hero cards, [full] pills and buttons.
class AppRadius {
  const AppRadius._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double full = 999.0;

  static const BorderRadius xsBorder = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlBorder = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius fullBorder = BorderRadius.all(Radius.circular(full));
}
