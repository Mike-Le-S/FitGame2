import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Step 2: Goal selection (bulk/cut/maintain)
class GoalStep extends StatelessWidget {
  final String selectedGoal;
  final ValueChanged<String> onGoalChanged;

  const GoalStep({
    super.key,
    required this.selectedGoal,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Ton objectif',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Choisis la direction de ta nutrition',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xxl),
          _GoalCard(
            title: 'Prise de masse',
            subtitle: 'Surplus calorique pour développer le muscle',
            icon: Icons.trending_up_rounded,
            color: FGColors.accent,
            isSelected: selectedGoal == 'bulk',
            onTap: () {
              HapticFeedback.selectionClick();
              onGoalChanged('bulk');
            },
          ),
          const SizedBox(height: Spacing.md),
          _GoalCard(
            title: 'Sèche',
            subtitle: 'Déficit calorique pour perdre du gras',
            icon: Icons.trending_down_rounded,
            color: const Color(0xFF3498DB),
            isSelected: selectedGoal == 'cut',
            onTap: () {
              HapticFeedback.selectionClick();
              onGoalChanged('cut');
            },
          ),
          const SizedBox(height: Spacing.md),
          _GoalCard(
            title: 'Maintien',
            subtitle: 'Équilibre pour maintenir le poids actuel',
            icon: Icons.remove_rounded,
            color: const Color(0xFF2ECC71),
            isSelected: selectedGoal == 'maintain',
            onTap: () {
              HapticFeedback.selectionClick();
              onGoalChanged('maintain');
            },
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isSelected ? color : FGColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.md),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : FGColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FGTypography.h3.copyWith(
                      color: isSelected ? color : FGColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    subtitle,
                    style: FGTypography.bodySmall.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
