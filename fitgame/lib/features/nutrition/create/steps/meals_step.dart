import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Meal names by count
const Map<int, List<String>> mealNamesByCount = {
  3: ['Petit-déjeuner', 'Déjeuner', 'Dîner'],
  4: ['Petit-déjeuner', 'Déjeuner', 'Collation', 'Dîner'],
  5: ['Petit-déjeuner', 'Collation AM', 'Déjeuner', 'Collation PM', 'Dîner'],
  6: [
    'Petit-déjeuner',
    'Collation AM',
    'Déjeuner',
    'Collation PM',
    'Dîner',
    'Collation soir'
  ],
};

/// Step 5: Number of meals per day
class MealsStep extends StatelessWidget {
  final int mealsPerDay;
  final ValueChanged<int> onMealsChanged;

  const MealsStep({
    super.key,
    required this.mealsPerDay,
    required this.onMealsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mealNames = mealNamesByCount[mealsPerDay] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Repas par\njour',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Organise ta journée alimentaire',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xxl),
          // Meal count selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [3, 4, 5, 6].map((count) {
              final isSelected = mealsPerDay == count;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onMealsChanged(count);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2ECC71).withValues(alpha: 0.2)
                          : FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.md),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2ECC71)
                            : FGColors.glassBorder,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2ECC71)
                                    .withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: FGTypography.display.copyWith(
                          fontSize: 28,
                          color: isSelected
                              ? const Color(0xFF2ECC71)
                              : FGColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.xxl),
          // Preview of meal names
          Text(
            'APERÇU',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: Spacing.md),
          ...mealNames.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            final icon = _getMealIcon(name);
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _MealPreviewCard(
                index: index + 1,
                name: name,
                icon: icon,
              ),
            );
          }),
          const SizedBox(height: Spacing.lg),
          // Info tip
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.glassSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Spacing.md),
              border: Border.all(color: FGColors.glassBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: const Color(0xFF2ECC71),
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'Plus de repas = portions plus petites, digestion facilitée',
                    style: FGTypography.bodySmall.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String name) {
    if (name.contains('Petit-déjeuner')) return Icons.wb_sunny_rounded;
    if (name.contains('Déjeuner')) return Icons.restaurant_rounded;
    if (name.contains('Dîner')) return Icons.nights_stay_rounded;
    return Icons.apple; // Collation
  }
}

class _MealPreviewCard extends StatelessWidget {
  final int index;
  final String name;
  final IconData icon;

  const _MealPreviewCard({
    required this.index,
    required this.name,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Spacing.sm),
            ),
            child: Center(
              child: Text(
                '$index',
                style: FGTypography.body.copyWith(
                  color: const Color(0xFF2ECC71),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Icon(
            icon,
            color: FGColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            name,
            style: FGTypography.body.copyWith(
              color: FGColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
