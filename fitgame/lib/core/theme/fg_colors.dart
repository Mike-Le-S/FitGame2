import 'package:flutter/material.dart';

/// FitGame Design System - Colors
abstract class FGColors {
  // Background
  static const Color background = Color(0xFF050505);

  // Glass Surface
  static const Color glassSurface = Color.fromRGBO(26, 26, 26, 0.6);
  static const Color glassBorder = Color.fromRGBO(255, 255, 255, 0.1);

  // Accent
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentGlow = Color.fromRGBO(255, 107, 53, 0.4);

  // Status
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textOnAccent = Color(0xFF000000);
}
