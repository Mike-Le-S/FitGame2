import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';

/// Compact pill widget for displaying macro values with color coding
class MacroPill extends StatelessWidget {
  final String value;
  final Color color;

  const MacroPill({
    super.key,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: FGColors.textPrimary,
        ),
      ),
    );
  }
}
