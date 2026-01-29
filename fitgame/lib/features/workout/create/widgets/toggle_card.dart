import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';

/// A glass card with an icon, title, subtitle and toggle switch
class ToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const ToggleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? FGColors.accent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: FGGlassCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: value
                    ? color.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.md),
              ),
              child: Icon(
                icon,
                color: value ? color : FGColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    subtitle,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: value ? color : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: value ? FGColors.textOnAccent : FGColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
