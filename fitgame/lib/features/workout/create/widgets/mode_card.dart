import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// A selectable card for training mode selection
class ModeCard extends StatelessWidget {
  final String mode;
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ModeCard({
    super.key,
    required this.mode,
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.accent.withValues(alpha: 0.15),
                    FGColors.accent.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: isSelected ? null : FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isSelected ? FGColors.accent : FGColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: FGColors.accent.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? FGColors.accent.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.md),
              ),
              child: Icon(
                icon,
                color: isSelected ? FGColors.accent : FGColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? FGColors.accent : FGColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    description,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: FGColors.accent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
