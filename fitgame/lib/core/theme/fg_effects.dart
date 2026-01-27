import 'dart:ui';
import 'package:flutter/material.dart';
import 'fg_colors.dart';

/// FitGame Design System - Effects
abstract class FGEffects {
  // Glass blur effect
  static const double glassBlurSigma = 20.0;

  static ImageFilter get glassBlur => ImageFilter.blur(
    sigmaX: glassBlurSigma,
    sigmaY: glassBlurSigma,
  );

  // Neon glow shadow for accent elements
  static List<BoxShadow> get neonGlow => [
    BoxShadow(
      color: FGColors.accentGlow,
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: FGColors.accent.withValues(alpha: 0.3),
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];

  // Subtle shadow for elevated elements
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Glass card decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 24.0,
  }) => BoxDecoration(
    color: FGColors.glassSurface,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: FGColors.glassBorder,
      width: 1,
    ),
  );
}
