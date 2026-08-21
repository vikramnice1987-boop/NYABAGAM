import 'package:flutter/material.dart';
import 'ny_colors.dart';
import 'ny_radius.dart';
import 'ny_spacing.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: NyColors.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: NyColors.primaryLightTint,
      onPrimaryContainer: NyColors.primaryDark,
      secondary: NyColors.memoryCyan,
      onSecondary: Colors.white,
      tertiary: NyColors.aiPurple,
      onTertiary: Colors.white,
      surface: NyColors.surfaceLight,
      onSurface: NyColors.textPrimaryLight,
      surfaceContainerHighest: NyColors.surfaceSecondaryLight,
      outline: NyColors.borderLight,
      error: NyColors.statusError,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NyColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: NyColors.surfaceLight,
        foregroundColor: NyColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: NyColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: NyRadius.borderMd,
          side: const BorderSide(color: NyColors.borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NyColors.primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: NyRadius.borderMd),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NyColors.textPrimaryLight,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: NyColors.borderLight),
          shape: RoundedRectangleBorder(borderRadius: NyRadius.borderMd),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NyColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: NySpacing.space16),
        border: OutlineInputBorder(
          borderRadius: NyRadius.borderMd,
          borderSide: const BorderSide(color: NyColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: NyRadius.borderMd,
          borderSide: const BorderSide(color: NyColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NyRadius.borderMd,
          borderSide: const BorderSide(color: NyColors.primaryLight, width: 1.5),
        ),
        hintStyle: const TextStyle(color: NyColors.disabledLight),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NyColors.surfaceLight,
        indicatorColor: NyColors.surfaceSecondaryLight,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NyColors.textPrimaryLight);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: NyColors.textSecondaryLight);
        }),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: NyColors.primaryDarkTheme,
      onPrimary: NyColors.backgroundDark,
      primaryContainer: NyColors.surfaceSecondaryDark,
      onPrimaryContainer: NyColors.primaryDarkTheme,
      secondary: NyColors.memoryCyanDark,
      onSecondary: Colors.black,
      tertiary: NyColors.aiPurpleDark,
      onTertiary: Colors.black,
      surface: NyColors.surfaceDark,
      onSurface: NyColors.textPrimaryDark,
      surfaceContainerHighest: NyColors.surfaceSecondaryDark,
      outline: NyColors.borderDark,
      error: NyColors.statusError,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NyColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: NyColors.surfaceDark,
        foregroundColor: NyColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: NyColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: NyRadius.borderMd,
          side: const BorderSide(color: NyColors.borderDark),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NyColors.primaryDark,
          foregroundColor: NyColors.primaryLight,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: NyRadius.borderMd),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NyColors.textPrimaryDark,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: NyColors.borderDark),
          shape: RoundedRectangleBorder(borderRadius: NyRadius.borderMd),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NyColors.surfaceSecondaryDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: NySpacing.space16, vertical: NySpacing.space16),
        border: OutlineInputBorder(
          borderRadius: NyRadius.borderMd,
          borderSide: const BorderSide(color: NyColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: NyRadius.borderMd,
          borderSide: const BorderSide(color: NyColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NyRadius.borderMd,
          borderSide: const BorderSide(color: NyColors.accentDark, width: 1.5),
        ),
        hintStyle: const TextStyle(color: NyColors.textTertiaryDark),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NyColors.surfaceDark,
        indicatorColor: NyColors.primaryContainerDark,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NyColors.primaryDark);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: NyColors.textSecondaryDark);
        }),
      ),
    );
  }
}