/// Recurring sizes.
class AppDimensions {
  const AppDimensions._();

  /// Smallest comfortable touch target.
  static const double touchTarget = 48.0;
  static const double buttonHeight = 52.0;
  static const double buttonHeightSmall = 40.0;
  static const double fieldHeight = 54.0;

  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;

  /// The square tile behind a feature icon: [iconTileSm] in dense rows, [iconTile] in lists and cards, [iconTileLg] at
  /// the top of a page.
  static const double iconTileSm = 40.0;
  static const double iconTile = 44.0;
  static const double iconTileLg = 52.0;

  /// The floating navigation bar: its height and its distance from the screen edges.
  static const double navBarHeight = 64.0;
  static const double navBarMargin = 12.0;

  /// Content never grows wider than this on tablets, desktops and browsers.
  static const double maxContentWidth = 680.0;

  /// A dashboard's content (Home) on a desktop, where it lays out in two columns.
  static const double maxWideContentWidth = 1080.0;

  /// Window widths below this are phones (Material's compact window class): one column, the bottom navigation bar.
  static const double maxMobileWidth = 600.0;

  /// Window widths below this, and from [maxMobileWidth], are tablets and phones turned sideways (Material's medium
  /// class): the navigation rail. From here up it is a desktop (expanded): the rail and wider layouts.
  static const double maxTabletWidth = 840.0;
}
