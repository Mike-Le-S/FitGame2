import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';

/// Quick action button widget for nutrition screen shortcuts
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          color: FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: FGColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
