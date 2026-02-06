import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import 'food_item.dart';

/// Expandable meal card widget showing foods, calories, and add/edit functionality
class MealCard extends StatefulWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onAddFood;
  final Function(Map<String, dynamic>) onEditFood;
  final VoidCallback? onDelete;
  final bool canDelete;

  const MealCard({
    super.key,
    required this.meal,
    required this.onAddFood,
    required this.onEditFood,
    this.onDelete,
    this.canDelete = true,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool _isExpanded = false;

  int get _mealCalories {
    int total = 0;
    for (final food in widget.meal['foods'] as List) {
      total += food['cal'] as int;
    }
    return total;
  }

  int get _mealProtein {
    int total = 0;
    for (final food in widget.meal['foods'] as List) {
      total += food['p'] as int;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final foods = widget.meal['foods'] as List;

    return FGGlassCard(
      padding: const EdgeInsets.all(Spacing.md),
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
        HapticFeedback.selectionClick();
      },
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FGColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(
                  widget.meal['icon'] as IconData,
                  color: FGColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.meal['name'] as String,
                      style: FGTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${foods.length} aliments',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_mealCalories kcal',
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: FGColors.accent,
                    ),
                  ),
                  Text(
                    '${_mealProtein}g prot',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: Spacing.sm),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: FGColors.textSecondary,
                ),
              ),
            ],
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: Spacing.md),
                Container(
                  height: 1,
                  color: FGColors.glassBorder,
                ),
                const SizedBox(height: Spacing.sm),
                ...foods.map<Widget>((food) {
                  return FoodItem(
                    food: food as Map<String, dynamic>,
                    onTap: () => widget.onEditFood(food),
                  );
                }),
                const SizedBox(height: Spacing.sm),
                // Add food button
                GestureDetector(
                  onTap: widget.onAddFood,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: Spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: FGColors.accent.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: FGColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          'Ajouter un aliment',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Delete meal button
                if (widget.canDelete && widget.onDelete != null) ...[
                  const SizedBox(height: Spacing.sm),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onDelete!();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: Spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: FGColors.error.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(Spacing.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: FGColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            'Supprimer ce repas',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
