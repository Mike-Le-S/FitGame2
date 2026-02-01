import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../models/diet_models.dart';
import '../../widgets/day_type_toggle.dart';
import '../../sheets/food_library_sheet.dart';
import '../sheets/food_quantity_sheet.dart';

/// Step 7: Meal planning for Training and Rest days
class MealPlanningStep extends StatefulWidget {
  final List<MealPlan> trainingDayMeals;
  final List<MealPlan> restDayMeals;
  final int trainingCalories;
  final int restCalories;
  final int proteinPercent;
  final int carbsPercent;
  final int fatPercent;
  final ValueChanged<List<MealPlan>> onTrainingMealsChanged;
  final ValueChanged<List<MealPlan>> onRestMealsChanged;

  const MealPlanningStep({
    super.key,
    required this.trainingDayMeals,
    required this.restDayMeals,
    required this.trainingCalories,
    required this.restCalories,
    required this.proteinPercent,
    required this.carbsPercent,
    required this.fatPercent,
    required this.onTrainingMealsChanged,
    required this.onRestMealsChanged,
  });

  @override
  State<MealPlanningStep> createState() => _MealPlanningStepState();
}

class _MealPlanningStepState extends State<MealPlanningStep> {
  bool _isTrainingDay = true;
  int? _expandedMealIndex;

  static const _nutritionGreen = Color(0xFF2ECC71);
  static const _trainingColor = Color(0xFFFF6B35);

  List<MealPlan> get _currentMeals =>
      _isTrainingDay ? widget.trainingDayMeals : widget.restDayMeals;

  int get _targetCalories =>
      _isTrainingDay ? widget.trainingCalories : widget.restCalories;

  int get _targetProtein =>
      (_targetCalories * widget.proteinPercent / 100 / 4).round();

  int get _targetCarbs =>
      (_targetCalories * widget.carbsPercent / 100 / 4).round();

  int get _targetFat =>
      (_targetCalories * widget.fatPercent / 100 / 9).round();

  int get _currentCalories =>
      _currentMeals.fold(0, (sum, meal) => sum + meal.totalCalories);

  int get _currentProtein =>
      _currentMeals.fold(0, (sum, meal) => sum + meal.totalProtein);

  int get _currentCarbs =>
      _currentMeals.fold(0, (sum, meal) => sum + meal.totalCarbs);

  int get _currentFat =>
      _currentMeals.fold(0, (sum, meal) => sum + meal.totalFat);

  void _addFoodToMeal(int mealIndex, FoodEntry food) {
    final meals = List<MealPlan>.from(_currentMeals);
    meals[mealIndex] = meals[mealIndex].addFood(food);

    if (_isTrainingDay) {
      widget.onTrainingMealsChanged(meals);
    } else {
      widget.onRestMealsChanged(meals);
    }
  }

  void _showQuantitySheet(int mealIndex, Map<String, dynamic> foodData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FoodQuantitySheet(
        foodData: foodData,
        onConfirm: (food) => _addFoodToMeal(mealIndex, food),
      ),
    );
  }

  void _removeFoodFromMeal(int mealIndex, String foodId) {
    HapticFeedback.lightImpact();
    final meals = List<MealPlan>.from(_currentMeals);
    meals[mealIndex] = meals[mealIndex].removeFood(foodId);

    if (_isTrainingDay) {
      widget.onTrainingMealsChanged(meals);
    } else {
      widget.onRestMealsChanged(meals);
    }
  }

  void _openFoodLibrary(int mealIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FoodLibrarySheet(
        onSelectFood: (food) {
          Navigator.pop(context);
          // Open quantity sheet after selecting food
          _showQuantitySheet(mealIndex, food);
        },
      ),
    );
  }

  void _copyTrainingToRest() {
    HapticFeedback.mediumImpact();
    final copiedMeals = widget.trainingDayMeals
        .map((meal) => MealPlan(
              name: meal.name,
              icon: meal.icon,
              foods: List<FoodEntry>.from(meal.foods),
            ))
        .toList();
    widget.onRestMealsChanged(copiedMeals);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Repas copiés vers jour Repos',
          style: FGTypography.body.copyWith(color: Colors.white),
        ),
        backgroundColor: _nutritionGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Planifie tes\nrepas',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Ajoute des aliments à chaque repas (optionnel)',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.lg),
          // Day type toggle
          DayTypeToggle(
            isTrainingDay: _isTrainingDay,
            onChanged: (value) {
              setState(() {
                _isTrainingDay = value;
                _expandedMealIndex = null;
              });
            },
          ),
          const SizedBox(height: Spacing.md),
          // Macro dashboard
          _MacroDashboard(
            targetCalories: _targetCalories,
            currentCalories: _currentCalories,
            targetProtein: _targetProtein,
            currentProtein: _currentProtein,
            targetCarbs: _targetCarbs,
            currentCarbs: _currentCarbs,
            targetFat: _targetFat,
            currentFat: _currentFat,
            accentColor: _isTrainingDay ? _trainingColor : _nutritionGreen,
          ),
          const SizedBox(height: Spacing.lg),
          // Copy button (only on Rest day if Training has foods)
          if (!_isTrainingDay &&
              widget.trainingDayMeals.any((m) => m.foods.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: GestureDetector(
                onTap: _copyTrainingToRest,
                child: Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: _nutritionGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Spacing.md),
                    border: Border.all(
                      color: _nutritionGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.content_copy_rounded,
                        color: _nutritionGreen,
                        size: 18,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Copier depuis Training',
                        style: FGTypography.body.copyWith(
                          color: _nutritionGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Meal cards
          ..._currentMeals.asMap().entries.map((entry) {
            final index = entry.key;
            final meal = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _PlanningMealCard(
                meal: meal,
                isExpanded: _expandedMealIndex == index,
                accentColor: _isTrainingDay ? _trainingColor : _nutritionGreen,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _expandedMealIndex =
                        _expandedMealIndex == index ? null : index;
                  });
                },
                onAddFood: () => _openFoodLibrary(index),
                onRemoveFood: (foodId) => _removeFoodFromMeal(index, foodId),
              ),
            );
          }),
          const SizedBox(height: Spacing.lg),
          // Optional note
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
                  Icons.info_outline_rounded,
                  color: FGColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'Tu peux passer cette étape et ajouter les aliments plus tard.',
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
}

class _MacroDashboard extends StatelessWidget {
  final int targetCalories;
  final int currentCalories;
  final int targetProtein;
  final int currentProtein;
  final int targetCarbs;
  final int currentCarbs;
  final int targetFat;
  final int currentFat;
  final Color accentColor;

  const _MacroDashboard({
    required this.targetCalories,
    required this.currentCalories,
    required this.targetProtein,
    required this.currentProtein,
    required this.targetCarbs,
    required this.currentCarbs,
    required this.targetFat,
    required this.currentFat,
    required this.accentColor,
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
      child: Column(
        children: [
          // Calories row
          Row(
            children: [
              Text(
                'Objectif:',
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '$currentCalories',
                style: FGTypography.h3.copyWith(
                  color: accentColor,
                ),
              ),
              Text(
                ' / $targetCalories kcal',
                style: FGTypography.body.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: targetCalories > 0
                  ? (currentCalories / targetCalories).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: FGColors.glassBorder,
              valueColor: AlwaysStoppedAnimation(accentColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: Spacing.md),
          // Macros row
          Row(
            children: [
              Expanded(
                child: _MacroMini(
                  label: 'P',
                  current: currentProtein,
                  target: targetProtein,
                  color: const Color(0xFFE74C3C),
                ),
              ),
              Expanded(
                child: _MacroMini(
                  label: 'C',
                  current: currentCarbs,
                  target: targetCarbs,
                  color: const Color(0xFF3498DB),
                ),
              ),
              Expanded(
                child: _MacroMini(
                  label: 'F',
                  current: currentFat,
                  target: targetFat,
                  color: const Color(0xFFF39C12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroMini extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const _MacroMini({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          '$label: ${current}g/${target}g',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _PlanningMealCard extends StatelessWidget {
  final MealPlan meal;
  final bool isExpanded;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onAddFood;
  final ValueChanged<String> onRemoveFood;

  const _PlanningMealCard({
    required this.meal,
    required this.isExpanded,
    required this.accentColor,
    required this.onTap,
    required this.onAddFood,
    required this.onRemoveFood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: Icon(
                      meal.icon,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: FGTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          meal.foods.isEmpty
                              ? 'Aucun aliment'
                              : '${meal.foods.length} aliment${meal.foods.length > 1 ? 's' : ''}',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (meal.foods.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${meal.totalCalories} kcal',
                          style: FGTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        Text(
                          '${meal.totalProtein}g prot',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: Spacing.sm),
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                0,
                Spacing.md,
                Spacing.md,
              ),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: FGColors.glassBorder,
                  ),
                  const SizedBox(height: Spacing.sm),
                  // Food items
                  ...meal.foods.map((food) => _FoodRow(
                        food: food,
                        onRemove: () => onRemoveFood(food.id),
                      )),
                  const SizedBox(height: Spacing.sm),
                  // Add food button
                  GestureDetector(
                    onTap: onAddFood,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(Spacing.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            'Ajouter un aliment',
                            style: FGTypography.caption.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  final FoodEntry food;
  final VoidCallback onRemove;

  const _FoodRow({
    required this.food,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Build quantity display string
    final quantityDisplay = food.quantity != '1'
        ? '${food.quantity}× ${food.unit}'
        : food.unit;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: FGTypography.body.copyWith(fontSize: 14),
                ),
                Text(
                  quantityDisplay,
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${food.calories} kcal',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Row(
            children: [
              Text(
                'P${food.protein}',
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFFE74C3C),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'C${food.carbs}',
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF3498DB),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'F${food.fat}',
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFFF39C12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: Spacing.sm),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: FGColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.close_rounded,
                color: FGColors.error,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
