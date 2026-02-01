import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';

/// Toggle switch for Training vs Rest day selection
class DayTypeToggle extends StatelessWidget {
  final bool isTrainingDay;
  final ValueChanged<bool> onChanged;

  static const _trainingColor = Color(0xFFFF6B35); // Orange
  static const _restColor = Color(0xFF2ECC71); // Green

  const DayTypeToggle({
    super.key,
    required this.isTrainingDay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: 'ENTRAÎNEMENT',
              icon: Icons.fitness_center_rounded,
              isSelected: isTrainingDay,
              color: _trainingColor,
              onTap: () {
                if (!isTrainingDay) {
                  HapticFeedback.selectionClick();
                  onChanged(true);
                }
              },
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: 'REPOS',
              icon: Icons.hotel_rounded,
              isSelected: !isTrainingDay,
              color: _restColor,
              onTap: () {
                if (isTrainingDay) {
                  HapticFeedback.selectionClick();
                  onChanged(false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : FGColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: Spacing.xs),
            Text(
              label,
              style: FGTypography.caption.copyWith(
                color: isSelected ? color : FGColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
