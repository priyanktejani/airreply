import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Editorial minimal: warm paper, ink type, thin rules, restrained radii. Every Material component is styled here
/// from [AppColors] and [AppType], so screens never hand-pick colours or fonts.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.paper,
      primaryContainer: c.subtle,
      onPrimaryContainer: c.ink,
      secondary: c.secondary,
      onSecondary: c.paper,
      secondaryContainer: c.subtle,
      onSecondaryContainer: c.ink,
      tertiary: c.success,
      onTertiary: Colors.white,
      error: c.error,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.secondary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.paper,
      surfaceContainer: c.subtle,
      surfaceContainerHigh: c.subtle,
      surfaceContainerHighest: c.subtle,
      outline: c.border,
      outlineVariant: c.border,
      inverseSurface: c.ink,
      onInverseSurface: c.paper,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
      scrim: Colors.black,
    );
    final text = AppType.textTheme(c.ink, c.secondary);
    const controlShape = RoundedRectangleBorder(borderRadius: Radii.controlBorder);
    const square = WidgetStatePropertyAll<OutlinedBorder>(controlShape);
    final hairline = BorderSide(color: c.border);
    const minTouch = WidgetStatePropertyAll(Size(48, 48));

    Color disabledOr(Set<WidgetState> states, Color color) =>
        states.contains(WidgetState.disabled) ? c.disabled : color;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [c],
      fontFamily: AppType.sans,
      textTheme: text,
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      splashFactory: InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.ink, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: c.paper,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        systemOverlayStyle: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: c.paper,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: c.paper,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.subtle,
        indicatorShape: controlShape,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppType.supporting.copyWith(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? c.ink : c.secondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: 22, color: s.contains(WidgetState.selected) ? c.ink : c.secondary),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.paper,
        indicatorColor: c.subtle,
        indicatorShape: controlShape,
        minWidth: 88,
        selectedIconTheme: IconThemeData(size: 22, color: c.ink),
        unselectedIconTheme: IconThemeData(size: 22, color: c.secondary),
        selectedLabelTextStyle: AppType.supporting.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: c.ink),
        unselectedLabelTextStyle: AppType.supporting.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: c.secondary,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.ink,
        textColor: c.paper,
        textStyle: AppType.label.copyWith(fontSize: 10, letterSpacing: 0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: square,
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Space.x5)),
          textStyle: WidgetStatePropertyAll(AppType.button),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((s) => disabledOr(s, c.ink)),
          foregroundColor: WidgetStatePropertyAll(c.paper),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: square,
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Space.x5)),
          textStyle: WidgetStatePropertyAll(AppType.button),
          side: WidgetStateProperty.resolveWith((s) => BorderSide(color: disabledOr(s, c.border))),
          foregroundColor: WidgetStateProperty.resolveWith((s) => disabledOr(s, c.ink)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: square,
          minimumSize: minTouch,
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Space.x3)),
          textStyle: WidgetStatePropertyAll(AppType.button),
          foregroundColor: WidgetStateProperty.resolveWith((s) => disabledOr(s, c.ink)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(shape: square, minimumSize: minTouch),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: AppType.body.copyWith(color: c.secondary),
        prefixIconColor: c.secondary,
        suffixIconColor: c.secondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: 14),
        border: OutlineInputBorder(borderRadius: Radii.controlBorder, borderSide: hairline),
        enabledBorder: OutlineInputBorder(borderRadius: Radii.controlBorder, borderSide: hairline),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.controlBorder,
          borderSide: BorderSide(color: c.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.controlBorder,
          borderSide: BorderSide(color: c.error),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.paper : (isDark ? c.secondary : c.surface),
        ),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.ink : c.subtle),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.ink : c.border),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        side: BorderSide(color: c.secondary, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.ink : null),
        checkColor: WidgetStatePropertyAll(c.paper),
      ),
      chipTheme: ChipThemeData(
        shape: controlShape,
        side: hairline,
        color: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.ink : c.surface),
        labelStyle: AppType.supporting.copyWith(color: c.ink, fontWeight: FontWeight.w500),
        secondaryLabelStyle: AppType.supporting.copyWith(color: c.paper, fontWeight: FontWeight.w500),
        checkmarkColor: c.paper,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: Space.x2, vertical: Space.x1),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: square,
          minimumSize: minTouch,
          side: WidgetStatePropertyAll(hairline),
          textStyle: WidgetStatePropertyAll(AppType.button),
          backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.ink : c.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.paper : c.ink),
          iconColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.paper : c.secondary),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: Space.x3,
        iconColor: c.secondary,
        titleTextStyle: AppType.subtitle.copyWith(color: c.ink, fontWeight: FontWeight.w400),
        subtitleTextStyle: AppType.supporting.copyWith(color: c.secondary),
        selectedColor: c.ink,
        selectedTileColor: c.subtle,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        showDragHandle: true,
        dragHandleColor: c.border,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Radii.sheet))),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: AppType.body.copyWith(color: c.secondary),
        barrierColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.32),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: Radii.controlBorder, side: hairline),
        textStyle: AppType.body.copyWith(color: c.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: AppType.body.copyWith(color: c.paper),
        actionTextColor: c.paper,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.controlBorder),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.ink, borderRadius: const BorderRadius.all(Radius.circular(6))),
        textStyle: AppType.supporting.copyWith(color: c.paper),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.ink,
        linearTrackColor: c.border,
        linearMinHeight: 2,
        strokeWidth: 2,
      ),
      scrollbarTheme: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(3)),
    );
  }
}
