import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fg_colors.dart';
import 'fg_typography.dart';

/// FitGame App Theme
class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Colors
    scaffoldBackgroundColor: FGColors.background,
    colorScheme: const ColorScheme.dark(
      surface: FGColors.background,
      primary: FGColors.accent,
      secondary: FGColors.accent,
      error: FGColors.error,
      onPrimary: FGColors.textOnAccent,
      onSurface: FGColors.textPrimary,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: FGTypography.h3,
      iconTheme: const IconThemeData(
        color: FGColors.textPrimary,
      ),
    ),

    // Text
    textTheme: TextTheme(
      displayLarge: FGTypography.display,
      headlineLarge: FGTypography.h1,
      headlineMedium: FGTypography.h2,
      headlineSmall: FGTypography.h3,
      bodyLarge: FGTypography.body,
      bodyMedium: FGTypography.body,
      bodySmall: FGTypography.bodySmall,
      labelLarge: FGTypography.button,
      labelSmall: FGTypography.caption,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FGColors.accent,
        foregroundColor: FGColors.textOnAccent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: FGTypography.button,
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FGColors.glassSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: FGColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: FGColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FGColors.accent),
      ),
      hintStyle: FGTypography.body.copyWith(color: FGColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: FGColors.glassSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: FGColors.glassBorder),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: FGColors.glassBorder,
      thickness: 1,
    ),
  );
}
