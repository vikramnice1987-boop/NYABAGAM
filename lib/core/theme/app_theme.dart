import 'package:flutter/material.dart';

import 'ny_colors.dart';
import 'ny_motion.dart';
import 'ny_radius.dart';
import 'ny_spacing.dart';
import 'ny_typography.dart';

/// Material bindings for the Liquid Glass system.
///
/// Material surfaces are deliberately made transparent here: the visible
/// chrome comes from `NyGlass` + `NyAuroraBackground`, so anything Material
/// paints on its own would sit as an opaque slab on top of the wallpaper.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final textPrimary = isDark ? NyColors.textPrimaryDark : NyColors.textPrimaryLight;
    final textSecondary = isDark ? NyColors.textSecondaryDark : NyColors.textSecondaryLight;
    final accent = isDark ? NyColors.primaryDarkTheme : NyColors.primaryLight;
    final onAccent = isDark ? const Color(0xFF090B18) : Colors.white;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: isDark ? NyColors.surfaceSecondaryDark : NyColors.primaryLightTint,
      onPrimaryContainer: isDark ? NyColors.primaryDarkTheme : NyColors.primaryDark,
      secondary: isDark ? NyColors.memoryCyanDark : NyColors.memoryCyan,
      onSecondary: isDark ? const Color(0xFF04141A) : Colors.white,
      tertiary: isDark ? NyColors.aiPurpleDark : NyColors.aiPurple,
      onTertiary: isDark ? const Color(0xFF130524) : Colors.white,
      surface: isDark ? NyColors.surfaceDark : NyColors.surfaceLight,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerHighest: isDark ? NyColors.surfaceSecondaryDark : NyColors.surfaceSecondaryLight,
      outline: isDark ? NyColors.borderDark : NyColors.borderLight,
      outlineVariant: isDark ? NyColors.borderDark : NyColors.borderLight,
      error: NyColors.statusError,
      onError: Colors.white,
    );

    final textTheme = NyTypography.themeFor(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: NyTypography.fontFamily,
      fontFamilyFallback: NyTypography.fallback,
      scaffoldBackgroundColor: isDark
          ? NyColors.wallpaperBaseDark
          : NyColors.wallpaperBaseLight,
      canvasColor: Colors.transparent,

      // The aurora shows through; app bars are drawn by NyScaffold.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: NyTypography.headlineLarge.copyWith(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: NyRadius.borderXl),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: accent.withValues(alpha: 0.28),
          disabledForegroundColor: onAccent.withValues(alpha: 0.55),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: NyRadius.borderLg),
          textStyle: NyTypography.labelLarge,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: NySpacing.space20),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(
            color: isDark ? NyColors.glassEdgeTopDark : NyColors.borderLight,
          ),
          shape: RoundedRectangleBorder(borderRadius: NyRadius.borderLg),
          textStyle: NyTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: NySpacing.space20),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: NyTypography.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? NyColors.glassFillSunkenDark
            : NyColors.glassFillSunkenLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NySpacing.space16,
          vertical: NySpacing.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: NyRadius.borderLg,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: NyRadius.borderLg,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NyRadius.borderLg,
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: NyTypography.bodyMedium.copyWith(
          color: isDark ? NyColors.disabledDark : NyColors.disabledLight,
        ),
        labelStyle: NyTypography.labelMedium.copyWith(color: textSecondary),
      ),

      // The real nav bar is the floating glass one in ScaffoldWithNavBar; this
      // only covers any stray Material NavigationBar.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.18),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return NyTypography.labelSmall.copyWith(
            color: selected ? textPrimary : textSecondary,
          );
        }),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: NySpacing.space24,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: NyRadius.borderPill),
        labelStyle: NyTypography.labelMedium.copyWith(color: textPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: NySpacing.space12,
          vertical: NySpacing.space8,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accent
              : (isDark ? NyColors.glassFillDark : NyColors.surfaceSecondaryLight),
        ),
        trackOutlineColor: WidgetStateProperty.all(colorScheme.outline),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: NyRadius.borderSheet),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? NyColors.surfaceDark : NyColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: NyRadius.borderXl),
        titleTextStyle: NyTypography.headlineSmall.copyWith(color: textPrimary),
        contentTextStyle: NyTypography.bodyMedium.copyWith(color: textSecondary),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? NyColors.surfaceSecondaryDark : NyColors.textPrimaryLight,
        contentTextStyle: NyTypography.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: NyRadius.borderMd),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(NySpacing.space16),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: colorScheme.outline,
        circularTrackColor: Colors.transparent,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.zero,
        titleTextStyle: NyTypography.titleMedium.copyWith(color: textPrimary),
        subtitleTextStyle: NyTypography.bodySmall.copyWith(color: textSecondary),
        iconColor: textSecondary,
      ),

      iconTheme: IconThemeData(color: textPrimary, size: 22),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _GlassPageTransition(),
          TargetPlatform.iOS: _GlassPageTransition(),
          TargetPlatform.windows: _GlassPageTransition(),
          TargetPlatform.macOS: _GlassPageTransition(),
          TargetPlatform.linux: _GlassPageTransition(),
          TargetPlatform.fuchsia: _GlassPageTransition(),
        },
      ),
    );
  }
}

/// Routes rise and settle rather than sliding flatly.
class _GlassPageTransition extends PageTransitionsBuilder {
  const _GlassPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: NyMotion.settle,
      reverseCurve: NyMotion.settle.flipped,
    );

    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(eased),
        child: child,
      ),
    );
  }
}
