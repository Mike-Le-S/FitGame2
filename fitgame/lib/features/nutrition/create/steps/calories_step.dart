import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Step 3: Calorie targets for training and rest days
class CaloriesStep extends StatelessWidget {
  final int trainingCalories;
  final int restCalories;
  final ValueChanged<int> onTrainingCaloriesChanged;
  final ValueChanged<int> onRestCaloriesChanged;

  const CaloriesStep({
    super.key,
    required this.trainingCalories,
    required this.restCalories,
    required this.onTrainingCaloriesChanged,
    required this.onRestCaloriesChanged,
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
            'Objectifs\ncaloriques',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Ajuste selon tes jours d\'entraînement',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xxl),
          _CalorieCard(
            title: 'Jour Training',
            subtitle: 'Plus de carbs pour l\'énergie',
            icon: Icons.fitness_center_rounded,
            color: FGColors.accent,
            calories: trainingCalories,
            onCaloriesChanged: onTrainingCaloriesChanged,
          ),
          const SizedBox(height: Spacing.lg),
          _CalorieCard(
            title: 'Jour Repos',
            subtitle: 'Récupération et maintien',
            icon: Icons.hotel_rounded,
            color: const Color(0xFF2ECC71),
            calories: restCalories,
            onCaloriesChanged: onRestCaloriesChanged,
          ),
          const SizedBox(height: Spacing.lg),
          // Difference indicator
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
                    'Différence de ${trainingCalories - restCalories} kcal entre les jours',
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

class _CalorieCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int calories;
  final ValueChanged<int> onCaloriesChanged;

  const _CalorieCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.calories,
    required this.onCaloriesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: Spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: FGColors.textPrimary,
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
            ],
          ),
          const SizedBox(height: Spacing.lg),
          // Calorie value with controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (calories > 1000) {
                    onCaloriesChanged(calories - 50);
                  }
                },
              ),
              const SizedBox(width: Spacing.lg),
              GestureDetector(
                onTap: () => _showNumberPicker(context),
                child: Column(
                  children: [
                    Text(
                      '$calories',
                      style: FGTypography.display.copyWith(
                        fontSize: 48,
                        color: color,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.lg),
              _ControlButton(
                icon: Icons.add_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (calories < 5000) {
                    onCaloriesChanged(calories + 50);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNumberPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CaloriePickerSheet(
        initialValue: calories,
        onSelect: (value) {
          onCaloriesChanged(value);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Icon(
          icon,
          color: FGColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}

class _CaloriePickerSheet extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onSelect;

  const _CaloriePickerSheet({
    required this.initialValue,
    required this.onSelect,
  });

  @override
  State<_CaloriePickerSheet> createState() => _CaloriePickerSheetState();
}

class _CaloriePickerSheetState extends State<_CaloriePickerSheet> {
  late FixedExtentScrollController _scrollController;
  late int _selectedValue;

  // Values from 1000 to 5000 in steps of 50
  final List<int> _values = List.generate(81, (i) => 1000 + i * 50);

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    final initialIndex = _values.indexOf(_selectedValue);
    _scrollController = FixedExtentScrollController(
      initialItem: initialIndex >= 0 ? initialIndex : 36, // Default 2800
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FGColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Sélectionner les calories', style: FGTypography.h3),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            height: 200,
            child: ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: 50,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() => _selectedValue = _values[index]);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _values.length,
                builder: (context, index) {
                  final isSelected = _values[index] == _selectedValue;
                  return Center(
                    child: Text(
                      '${_values[index]} kcal',
                      style: FGTypography.h3.copyWith(
                        color: isSelected
                            ? const Color(0xFF2ECC71)
                            : FGColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSelect(_selectedValue),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
              ),
              child: Text(
                'Valider',
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
