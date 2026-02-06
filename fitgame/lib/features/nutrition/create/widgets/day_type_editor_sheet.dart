import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../sheets/food_add_sheet.dart';

class DayTypeEditorSheet extends StatefulWidget {
  final Map<String, dynamic> dayType;
  final ValueChanged<Map<String, dynamic>> onSave;

  const DayTypeEditorSheet({
    super.key,
    required this.dayType,
    required this.onSave,
  });

  @override
  State<DayTypeEditorSheet> createState() => _DayTypeEditorSheetState();
}

class _DayTypeEditorSheetState extends State<DayTypeEditorSheet> {
  static const _nutritionGreen = Color(0xFF2ECC71);
  static const _emojis = [
    '🏋️', '🧘', '💪', '🏃', '🚴', '🏊', '⚡',
    '🔥', '🍽️', '🥗', '📅', '🌙', '🎯', '⭐',
  ];

  late final TextEditingController _nameController;
  late String _selectedEmoji;
  late List<Map<String, dynamic>> _meals;
  final Set<int> _expandedMeals = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dayType['name'] as String? ?? '');
    _selectedEmoji = widget.dayType['emoji'] as String? ?? '📅';
    _meals = List<Map<String, dynamic>>.from(
      (widget.dayType['meals'] as List? ?? []).map((m) {
        final meal = Map<String, dynamic>.from(m as Map);
        if (meal['foods'] != null) {
          meal['foods'] = List<Map<String, dynamic>>.from(
            (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f as Map)),
          );
        } else {
          meal['foods'] = <Map<String, dynamic>>[];
        }
        return meal;
      }),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _totalCalories {
    int total = 0;
    for (final meal in _meals) {
      final foods = meal['foods'] as List? ?? [];
      for (final food in foods) {
        total += ((food as Map)['cal'] as int?) ?? ((food)['calories'] as int?) ?? 0;
      }
    }
    return total;
  }

  void _save() {
    widget.onSave({
      ...widget.dayType,
      'name': _nameController.text.trim(),
      'emoji': _selectedEmoji,
      'meals': _meals,
    });
  }

  void _addMeal() {
    HapticFeedback.mediumImpact();
    setState(() {
      _meals.add({
        'name': 'Repas ${_meals.length + 1}',
        'icon': 'restaurant_rounded',
        'foods': <Map<String, dynamic>>[],
      });
    });
  }

  void _removeMeal(int index) {
    if (_meals.length <= 1) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _meals.removeAt(index);
      _expandedMeals.remove(index);
    });
  }

  void _addFoodToMeal(int mealIndex) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodAddSheet(
        onSelectFood: (food) {
          Navigator.pop(context);
          setState(() {
            if (_meals[mealIndex]['foods'] == null) {
              _meals[mealIndex]['foods'] = <Map<String, dynamic>>[];
            }
            (_meals[mealIndex]['foods'] as List).add(food);
          });
        },
      ),
    );
  }

  void _removeFood(int mealIndex, int foodIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      (_meals[mealIndex]['foods'] as List).removeAt(foodIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Spacing.lg)),
      ),
      child: Column(
        children: [
          _buildSheetHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  Text(
                    'NOM',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      border: Border.all(color: FGColors.glassBorder),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Nom du type de jour',
                        hintStyle: FGTypography.body.copyWith(
                          color: FGColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(Spacing.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Emoji selector
                  Text(
                    'EMOJI',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: _emojis.map((emoji) {
                      final isSelected = _selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedEmoji = emoji);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _nutritionGreen.withValues(alpha: 0.15)
                                : FGColors.glassSurface,
                            borderRadius: BorderRadius.circular(Spacing.sm),
                            border: Border.all(
                              color: isSelected ? _nutritionGreen : FGColors.glassBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Meals section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REPAS',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '$_totalCalories kcal',
                        style: FGTypography.body.copyWith(
                          color: _nutritionGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),

                  // Meal accordions
                  ..._meals.asMap().entries.map((entry) {
                    final mealIndex = entry.key;
                    final meal = entry.value;
                    final isExpanded = _expandedMeals.contains(mealIndex);
                    final foods = meal['foods'] as List? ?? [];
                    int mealCal = 0;
                    for (final food in foods) {
                      mealCal += ((food as Map)['cal'] as int?) ?? ((food)['calories'] as int?) ?? 0;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: Container(
                        decoration: BoxDecoration(
                          color: FGColors.glassSurface,
                          borderRadius: BorderRadius.circular(Spacing.md),
                          border: Border.all(color: FGColors.glassBorder),
                        ),
                        child: Column(
                          children: [
                            // Meal header (tap to expand)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (isExpanded) {
                                    _expandedMeals.remove(mealIndex);
                                  } else {
                                    _expandedMeals.add(mealIndex);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(Spacing.md),
                                child: Row(
                                  children: [
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      color: FGColors.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    Expanded(
                                      child: Text(
                                        meal['name'] as String? ?? 'Repas',
                                        style: FGTypography.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${foods.length} aliment${foods.length != 1 ? 's' : ''} · $mealCal kcal',
                                      style: FGTypography.caption.copyWith(
                                        color: FGColors.textSecondary,
                                      ),
                                    ),
                                    if (_meals.length > 1) ...[
                                      const SizedBox(width: Spacing.sm),
                                      GestureDetector(
                                        onTap: () => _removeMeal(mealIndex),
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: FGColors.error,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Expanded content
                            if (isExpanded) ...[
                              const Divider(height: 1, color: Color(0xFF1A1A1A)),
                              // Food list
                              ...foods.asMap().entries.map((foodEntry) {
                                final foodIndex = foodEntry.key;
                                final food = foodEntry.value as Map;
                                final foodName = food['name'] as String? ?? 'Aliment';
                                final foodCal = (food['cal'] as int?) ?? (food['calories'] as int?) ?? 0;
                                final foodQty = food['quantity'] as String? ?? '';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Spacing.md,
                                    vertical: Spacing.xs,
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: Spacing.lg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              foodName,
                                              style: FGTypography.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '$foodQty · $foodCal kcal',
                                              style: FGTypography.caption.copyWith(
                                                color: FGColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _removeFood(mealIndex, foodIndex),
                                        child: Icon(
                                          Icons.remove_circle_outline_rounded,
                                          color: FGColors.error,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              // Add food button
                              Padding(
                                padding: const EdgeInsets.all(Spacing.sm),
                                child: GestureDetector(
                                  onTap: () => _addFoodToMeal(mealIndex),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                                    decoration: BoxDecoration(
                                      color: _nutritionGreen.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(Spacing.sm),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_rounded, color: _nutritionGreen, size: 18),
                                        const SizedBox(width: Spacing.xs),
                                        Text(
                                          'Ajouter un aliment',
                                          style: FGTypography.bodySmall.copyWith(
                                            color: _nutritionGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                  // Add meal button
                  const SizedBox(height: Spacing.sm),
                  GestureDetector(
                    onTap: _addMeal,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: FGColors.glassSurface,
                        borderRadius: BorderRadius.circular(Spacing.md),
                        border: Border.all(
                          color: _nutritionGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: _nutritionGreen, size: 20),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            'Ajouter un repas',
                            style: FGTypography.body.copyWith(
                              color: _nutritionGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FGColors.glassBorder, width: 0.5),
        ),
      ),
      child: Column(
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
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: FGTypography.body.copyWith(color: FGColors.textSecondary),
                ),
              ),
              const Spacer(),
              Text(
                'Type de jour',
                style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _save,
                child: Text(
                  'Enregistrer',
                  style: FGTypography.body.copyWith(
                    color: _nutritionGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
