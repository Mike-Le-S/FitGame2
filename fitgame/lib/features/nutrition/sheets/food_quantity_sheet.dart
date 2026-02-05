import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';

/// Sheet to adjust food quantity before adding to a meal.
/// Automatically recalculates all nutritional values.
class FoodQuantitySheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final Function(Map<String, dynamic>) onConfirm;

  const FoodQuantitySheet({
    super.key,
    required this.food,
    required this.onConfirm,
  });

  @override
  State<FoodQuantitySheet> createState() => _FoodQuantitySheetState();
}

class _FoodQuantitySheetState extends State<FoodQuantitySheet> {
  late TextEditingController _quantityController;
  double _quantity = 100; // Default 100g

  // Base values per 100g
  late int _baseCal;
  late int _baseProtein;
  late int _baseCarbs;
  late int _baseFat;
  late int _baseFiber;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '100');

    // Extract base values (per 100g)
    _baseCal = (widget.food['cal'] as num?)?.toInt() ?? 0;
    _baseProtein = (widget.food['protein'] as num?)?.toInt() ?? 0;
    _baseCarbs = (widget.food['carbs'] as num?)?.toInt() ?? 0;
    _baseFat = (widget.food['fat'] as num?)?.toInt() ?? 0;
    _baseFiber = (widget.food['fiber'] as num?)?.toInt() ?? 0;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // Calculate scaled value
  int _scaled(int base) => ((base * _quantity) / 100).round();

  void _onQuantityChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() => _quantity = parsed);
    }
  }

  void _adjustQuantity(double delta) {
    HapticFeedback.selectionClick();
    final newValue = (_quantity + delta).clamp(1.0, 2000.0);
    setState(() {
      _quantity = newValue;
      _quantityController.text = newValue.round().toString();
    });
  }

  void _setPreset(double value) {
    HapticFeedback.lightImpact();
    setState(() {
      _quantity = value;
      _quantityController.text = value.round().toString();
    });
  }

  void _confirm() {
    HapticFeedback.mediumImpact();

    // Create food with adjusted values
    final adjustedFood = Map<String, dynamic>.from(widget.food);
    adjustedFood['quantity'] = '${_quantity.round()}g';
    adjustedFood['cal'] = _scaled(_baseCal);
    adjustedFood['protein'] = _scaled(_baseProtein);
    adjustedFood['carbs'] = _scaled(_baseCarbs);
    adjustedFood['fat'] = _scaled(_baseFat);
    adjustedFood['fiber'] = _scaled(_baseFiber);

    // Also scale extended nutrients if present
    final extendedKeys = [
      'sat_fat', 'mono_fat', 'poly_fat', 'trans_fat', 'cholesterol',
      'sodium', 'potassium', 'calcium', 'iron', 'magnesium', 'zinc',
      'phosphorus', 'selenium', 'vit_a', 'vit_c', 'vit_d', 'vit_e',
      'vit_k', 'vit_b1', 'vit_b2', 'vit_b3', 'vit_b6', 'vit_b12', 'folate'
    ];

    for (final key in extendedKeys) {
      if (widget.food[key] != null) {
        final base = (widget.food[key] as num).toDouble();
        adjustedFood[key] = (base * _quantity / 100);
      }
    }

    widget.onConfirm(adjustedFood);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.food['name'] as String? ?? 'Aliment';
    final category = widget.food['category'] as String? ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  Text(name, style: FGTypography.h3),
                  if (category.isNotEmpty)
                    Text(
                      category,
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: Spacing.xl),

                  // Quantity section
                  Text(
                    'QUANTITÉ',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Quantity input with +/- buttons
                  Row(
                    children: [
                      // Minus button
                      GestureDetector(
                        onTap: () => _adjustQuantity(-10),
                        onLongPress: () => _adjustQuantity(-50),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: FGColors.glassSurface,
                            borderRadius: BorderRadius.circular(Spacing.md),
                            border: Border.all(color: FGColors.glassBorder),
                          ),
                          child: const Icon(Icons.remove, color: FGColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),

                      // Quantity input
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: FGColors.glassSurface,
                            borderRadius: BorderRadius.circular(Spacing.md),
                            border: Border.all(color: FGColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: FGTypography.h3.copyWith(fontSize: 20),
                                  onChanged: _onQuantityChanged,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: Spacing.md),
                                child: Text(
                                  'g',
                                  style: FGTypography.body.copyWith(
                                    color: FGColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),

                      // Plus button
                      GestureDetector(
                        onTap: () => _adjustQuantity(10),
                        onLongPress: () => _adjustQuantity(50),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: FGColors.glassSurface,
                            borderRadius: BorderRadius.circular(Spacing.md),
                            border: Border.all(color: FGColors.glassBorder),
                          ),
                          child: const Icon(Icons.add, color: FGColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),

                  // Quick presets
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      _buildPresetChip(50),
                      _buildPresetChip(100),
                      _buildPresetChip(150),
                      _buildPresetChip(200),
                      _buildPresetChip(250),
                      _buildPresetChip(300),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Calculated macros
                  Text(
                    'VALEURS NUTRITIONNELLES',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Calories (prominent)
                  Container(
                    padding: const EdgeInsets.all(Spacing.lg),
                    decoration: BoxDecoration(
                      color: FGColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Spacing.md),
                      border: Border.all(color: FGColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_scaled(_baseCal)}',
                          style: FGTypography.h1.copyWith(
                            fontSize: 36,
                            color: FGColors.accent,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'kcal',
                          style: FGTypography.body.copyWith(
                            color: FGColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Macros row
                  Row(
                    children: [
                      _buildMacroTile('Protéines', _scaled(_baseProtein), 'g', const Color(0xFF3498DB)),
                      const SizedBox(width: Spacing.sm),
                      _buildMacroTile('Glucides', _scaled(_baseCarbs), 'g', const Color(0xFF9B59B6)),
                      const SizedBox(width: Spacing.sm),
                      _buildMacroTile('Lipides', _scaled(_baseFat), 'g', const Color(0xFFE67E22)),
                    ],
                  ),
                  if (_baseFiber > 0) ...[
                    const SizedBox(height: Spacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: FGColors.glassSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(Spacing.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Fibres: ${_scaled(_baseFiber)}g',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: GestureDetector(
              onTap: _confirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  borderRadius: BorderRadius.circular(Spacing.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'Ajouter ${_quantity.round()}g',
                      style: FGTypography.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(int grams) {
    final isSelected = _quantity.round() == grams;
    return GestureDetector(
      onTap: () => _setPreset(grams.toDouble()),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.2)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(
            color: isSelected ? const Color(0xFF2ECC71) : FGColors.glassBorder,
          ),
        ),
        child: Text(
          '${grams}g',
          style: FGTypography.caption.copyWith(
            color: isSelected ? const Color(0xFF2ECC71) : FGColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMacroTile(String label, int value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$value$unit',
              style: FGTypography.h3.copyWith(
                color: color,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: FGTypography.caption.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
