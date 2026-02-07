import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';

class GoalSelectorSheet extends StatelessWidget {
  final String currentGoal;
  final Function(String) onSelect;

  const GoalSelectorSheet({
    super.key,
    required this.currentGoal,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Objectif nutritionnel', style: FGTypography.h3),
          const SizedBox(height: Spacing.lg),
          _GoalOption(
            title: 'Prise de masse',
            subtitle: 'Surplus calorique pour développer le muscle',
            icon: Icons.trending_up_rounded,
            isSelected: currentGoal == 'bulk',
            onTap: () => onSelect('bulk'),
          ),
          const SizedBox(height: Spacing.md),
          _GoalOption(
            title: 'Sèche',
            subtitle: 'Déficit calorique pour perdre du gras',
            icon: Icons.trending_down_rounded,
            isSelected: currentGoal == 'cut',
            onTap: () => onSelect('cut'),
          ),
          const SizedBox(height: Spacing.md),
          _GoalOption(
            title: 'Maintien',
            subtitle: 'Équilibre pour maintenir le poids actuel',
            icon: Icons.remove_rounded,
            isSelected: currentGoal == 'maintain',
            onTap: () => onSelect('maintain'),
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isSelected ? FGColors.accent.withValues(alpha: 0.1) : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isSelected ? FGColors.accent : FGColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? FGColors.accent.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Icon(
                icon,
                color: isSelected ? FGColors.accent : FGColors.textSecondary,
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
                      fontWeight: FontWeight.w600,
                      color: isSelected ? FGColors.accent : FGColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: FGColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}

