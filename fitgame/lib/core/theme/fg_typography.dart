import 'package:flutter/material.dart';
import 'fg_colors.dart';

/// FitGame Design System - Typography
abstract class FGTypography {
  // Display - 64px Black Italic with tight tracking
  static const TextStyle display = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    letterSpacing: -0.05 * 64, // -0.05em
    color: FGColors.textPrimary,
    height: 1.1,
  );

  // Heading 1 - 40px Black Italic
  static const TextStyle h1 = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    letterSpacing: -0.05 * 40,
    color: FGColors.textPrimary,
    height: 1.2,
  );

  // Heading 2 - 32px Bold
  static const TextStyle h2 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 32,
    color: FGColors.textPrimary,
    height: 1.2,
  );

  // Heading 3 - 24px Bold
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 24,
    color: FGColors.textPrimary,
    height: 1.3,
  );

  // Numbers - 48px Black for stats/scores
  static const TextStyle numbers = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.02 * 48,
    color: FGColors.textPrimary,
    height: 1.0,
  );

  // Body - 16px Regular
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: FGColors.textPrimary,
    height: 1.5,
  );

  // Body Small - 14px Regular
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: FGColors.textSecondary,
    height: 1.5,
  );

  // Button - 16px Bold Uppercase
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: FGColors.textOnAccent,
    height: 1.0,
  );

  // Caption - 12px Regular
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: FGColors.textSecondary,
    height: 1.4,
  );
}
