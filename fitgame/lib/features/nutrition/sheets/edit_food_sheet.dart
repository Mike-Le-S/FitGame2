import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_neon_button.dart';

class EditFoodSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onDelete;

  const EditFoodSheet({
    required this.food,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditFoodSheet> createState() => EditFoodSheetState();
}

class EditFoodSheetState extends State<EditFoodSheet> {
  late double _quantity;
  late int _baseCal, _baseP, _baseC, _baseF;

  @override
  void initState() {
    super.initState();
    _quantity = 1.0;
    _baseCal = widget.food['cal'] as int;
    _baseP = widget.food['p'] as int;
    _baseC = widget.food['c'] as int;
    _baseF = widget.food['f'] as int;
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.food['name'] as String, style: FGTypography.h3),
                    Text(
                      widget.food['quantity'] as String,
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FGColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: FGColors.error,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),

          // Quantity slider
          Text(
            'Quantité: ${_quantity.toStringAsFixed(1)}x',
            style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _quantity,
            min: 0.25,
            max: 3.0,
            divisions: 11,
            activeColor: FGColors.accent,
            inactiveColor: FGColors.glassBorder,
            onChanged: (v) => setState(() => _quantity = v),
          ),
          const SizedBox(height: Spacing.lg),

          // Calculated macros
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(Spacing.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroColumn(
                  label: 'Calories',
                  value: '${(_baseCal * _quantity).round()}',
                  color: FGColors.accent,
                ),
                _MacroColumn(
                  label: 'Protéines',
                  value: '${(_baseP * _quantity).round()}g',
                  color: const Color(0xFFE74C3C),
                ),
                _MacroColumn(
                  label: 'Glucides',
                  value: '${(_baseC * _quantity).round()}g',
                  color: const Color(0xFF3498DB),
                ),
                _MacroColumn(
                  label: 'Lipides',
                  value: '${(_baseF * _quantity).round()}g',
                  color: const Color(0xFFF39C12),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          FGNeonButton(
            label: 'Enregistrer',
            isExpanded: true,
            onPressed: () {
              widget.onSave({
                ...widget.food,
                'cal': (_baseCal * _quantity).round(),
                'p': (_baseP * _quantity).round(),
                'c': (_baseC * _quantity).round(),
                'f': (_baseF * _quantity).round(),
              });
            },
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: FGTypography.h3.copyWith(
            color: color,
            fontSize: 20,
          ),
        ),
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
