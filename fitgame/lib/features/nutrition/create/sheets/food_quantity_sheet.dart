import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../models/diet_models.dart';

/// Sheet for selecting food quantity before adding to meal
class FoodQuantitySheet extends StatefulWidget {
  final Map<String, dynamic> foodData;
  final Function(FoodEntry) onConfirm;

  const FoodQuantitySheet({
    super.key,
    required this.foodData,
    required this.onConfirm,
  });

  @override
  State<FoodQuantitySheet> createState() => _FoodQuantitySheetState();
}

class _FoodQuantitySheetState extends State<FoodQuantitySheet> {
  double _quantity = 1.0;

  static const _nutritionGreen = Color(0xFF2ECC71);

  // Quick presets for quantity
  static const List<double> _presets = [0.5, 1.0, 1.5, 2.0, 3.0];

  // Base values from food data
  int get _baseCal => widget.foodData['cal'] as int;
  int get _baseP => widget.foodData['p'] as int;
  int get _baseC => widget.foodData['c'] as int;
  int get _baseF => widget.foodData['f'] as int;

  // Calculated values based on quantity
  int get _calories => (_baseCal * _quantity).round();
  int get _protein => (_baseP * _quantity).round();
  int get _carbs => (_baseC * _quantity).round();
  int get _fat => (_baseF * _quantity).round();

  String get _quantityLabel {
    if (_quantity == _quantity.roundToDouble()) {
      return _quantity.toInt().toString();
    }
    return _quantity.toStringAsFixed(1);
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    final food = FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.foodData['name'] as String,
      quantity: _quantityLabel,
      calories: _calories,
      protein: _protein,
      carbs: _carbs,
      fat: _fat,
      unit: widget.foodData['unit'] as String,
    );
    widget.onConfirm(food);
    Navigator.pop(context);
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
          // Title
          Text('Quantité', style: FGTypography.h3),
          const SizedBox(height: Spacing.sm),
          // Food name
          Text(
            widget.foodData['name'] as String,
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xl),
          // Quantity display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _quantityLabel,
                style: FGTypography.display.copyWith(
                  fontSize: 56,
                  color: _nutritionGreen,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '× ${widget.foodData['unit']}',
                style: FGTypography.body.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _nutritionGreen,
              inactiveTrackColor: FGColors.glassBorder,
              thumbColor: _nutritionGreen,
              overlayColor: _nutritionGreen.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _quantity,
              min: 0.25,
              max: 5.0,
              divisions: 19, // 0.25 steps
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _quantity = value);
              },
            ),
          ),
          const SizedBox(height: Spacing.md),
          // Quick presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _presets.map((preset) {
              final isSelected = (_quantity - preset).abs() < 0.01;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _quantity = preset);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _nutritionGreen.withValues(alpha: 0.2)
                        : FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(
                      color: isSelected ? _nutritionGreen : FGColors.glassBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      preset == preset.roundToDouble()
                          ? preset.toInt().toString()
                          : preset.toString(),
                      style: FGTypography.body.copyWith(
                        color: isSelected ? _nutritionGreen : FGColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.xl),
          // Macros preview
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(Spacing.md),
              border: Border.all(color: FGColors.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroPreview(
                  label: 'Calories',
                  value: '$_calories',
                  unit: 'kcal',
                  color: _nutritionGreen,
                ),
                _MacroPreview(
                  label: 'Protéines',
                  value: '$_protein',
                  unit: 'g',
                  color: const Color(0xFFE74C3C),
                ),
                _MacroPreview(
                  label: 'Glucides',
                  value: '$_carbs',
                  unit: 'g',
                  color: const Color(0xFF3498DB),
                ),
                _MacroPreview(
                  label: 'Lipides',
                  value: '$_fat',
                  unit: 'g',
                  color: const Color(0xFFF39C12),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _nutritionGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                elevation: 0,
              ),
              child: Text(
                'Ajouter',
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

class _MacroPreview extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MacroPreview({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: FGTypography.body.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              unit,
              style: FGTypography.caption.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
