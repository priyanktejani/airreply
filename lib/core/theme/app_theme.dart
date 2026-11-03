import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The light and dark themes, built from [AppPalette] and [AppType] in the iFixxer design: pill buttons, soft 16
/// fields, 20 cards with a hairline and a soft shadow, frosted sheets and dialogs, and the brand accent for what is
/// selected. Screens use plain Material widgets and they already look right.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final c = dark ? AppPalette.dark : AppPalette.light;
    final scheme = ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: c.accentInk,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.ink,
      secondary: c.ink,
      onSecondary: c.surface,
      // selected chips, segments and tonal buttons: soft accent with the brand accent edge
      secondaryContainer: c.accentSoft,
      onSecondaryContainer: c.ink,
      error: c.danger,
      onError: c.surface,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.muted,
      outline: c.line,
      outlineVariant: c.line,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.bg,
      surfaceContainer: c.soft,
      surfaceContainerHigh: c.soft,
      surfaceContainerHighest: c.soft,
      inverseSurface: c.deep,
      onInverseSurface: c.deepInk,
      surfaceTint: Colors.transparent,
    );
    final text = AppType.textTheme(c);
    const pill = StadiumBorder();
    const pad = EdgeInsets.symmetric(horizontal: 24, vertical: 15);
    final label = AppType.button;
    OutlineInputBorder field(Color color) => OutlineInputBorder(
      borderRadius: AppRadius.mdBorder,
      borderSide: BorderSide(color: color, width: 1.5),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: font,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      extensions: [c],
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      // back and close buttons draw the app's icons rather than Material's
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(AppIcons.back),
        closeButtonIconBuilder: (_) => const Icon(AppIcons.close),
      ),
      // a light touch on every tap: the default grey wash reads heavy on white cards and murky on dark ones
      splashColor: c.ink.withValues(alpha: dark ? .08 : .06),
      highlightColor: c.ink.withValues(alpha: dark ? .05 : .035),
      hoverColor: c.ink.withValues(alpha: .03),
      focusColor: c.accent.withValues(alpha: .12),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.section.copyWith(fontSize: 19, color: c.ink, letterSpacing: -.3),
        systemOverlayStyle: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.accentInk,
          disabledBackgroundColor: c.soft,
          disabledForegroundColor: c.disabled,
          shape: pill,
          padding: pad,
          textStyle: label,
          minimumSize: const Size(0, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          disabledForegroundColor: c.disabled,
          shape: pill,
          padding: pad,
          textStyle: label,
          side: BorderSide(color: c.line, width: 1.5),
          minimumSize: const Size(0, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          disabledForegroundColor: c.disabled,
          textStyle: label.copyWith(fontSize: 14),
          minimumSize: const Size(48, 48),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: c.ink)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: AppType.bodyLarge.copyWith(color: c.muted),
        prefixIconColor: c.muted,
        suffixIconColor: c.muted,
        border: field(c.line),
        enabledBorder: field(c.line),
        focusedBorder: field(c.accent),
        errorBorder: field(c.danger),
        focusedErrorBorder: field(c.danger),
        labelStyle: TextStyle(color: c.muted),
        floatingLabelStyle: TextStyle(color: c.accent),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: .3),
        selectionHandleColor: c.accent,
      ),
      // resting cards: 20 radius, a hairline and a soft shadow
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: dark ? 0 : 1.5,
        shadowColor: const Color(0x330F172A),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: BorderSide(color: c.line.withValues(alpha: dark ? 1 : .8)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 12,
        iconColor: c.accent,
        titleTextStyle: AppType.subtitle.copyWith(color: c.ink),
        subtitleTextStyle: AppType.supporting.copyWith(color: c.muted, height: 1.35),
        // rows sit edge to edge on a card that rounds the outer corners, so a row's own highlight stays square
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: c.accent,
        collapsedIconColor: c.muted,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      // sheets and dialogs: large soft corners (showAppSheet and showAppDialog add the frosted glass)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        showDragHandle: true,
        dragHandleColor: c.line,
        modalBarrierColor: Colors.black.withValues(alpha: dark ? .55 : .32),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface.withValues(alpha: dark ? .88 : .9),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlBorder,
          side: BorderSide(color: dark ? Colors.white.withValues(alpha: .09) : c.line.withValues(alpha: .8)),
        ),
        titleTextStyle: AppType.section.copyWith(color: c.ink),
        contentTextStyle: AppType.body.copyWith(color: c.muted, height: 1.45),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x330F172A),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
          side: BorderSide(color: c.line),
        ),
        textStyle: AppType.body.copyWith(color: c.ink),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accentInk : c.muted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.soft),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.line),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.accentInk),
        side: BorderSide(color: c.muted, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.muted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.accentSoft,
        shape: pill,
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.selected) ? c.accent : c.line),
        ),
        labelStyle: AppType.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: c.ink),
        checkmarkColor: c.accent,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.accentSoft : c.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.ink : c.muted),
          // one neutral outline for the whole group; the selected part is shown by its accent fill
          side: WidgetStatePropertyAll(BorderSide(color: c.line)),
          textStyle: WidgetStatePropertyAll(label.copyWith(fontSize: 14)),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.ink, size: 22),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: c.accentSoft,
        indicatorShape: pill,
        minWidth: 88,
        selectedIconTheme: IconThemeData(size: 22, color: c.accent),
        unselectedIconTheme: IconThemeData(size: 22, color: c.muted),
        selectedLabelTextStyle: AppType.label.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: c.accent),
        unselectedLabelTextStyle: AppType.label.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: c.muted),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.accent,
        textColor: c.accentInk,
        textStyle: AppType.label.copyWith(fontSize: 10, letterSpacing: 0),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.accentInk,
        elevation: 3,
        highlightElevation: 5,
        shape: pill,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.deep,
        contentTextStyle: AppType.body.copyWith(color: c.deepInk, fontSize: 14.5, height: 1.35),
        actionTextColor: c.accent,
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.deep, borderRadius: AppRadius.xsBorder),
        textStyle: AppType.supporting.copyWith(color: c.deepInk),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.soft,
        refreshBackgroundColor: c.surface,
      ),
    );
  }
}
