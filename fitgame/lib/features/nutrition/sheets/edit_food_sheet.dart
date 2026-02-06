import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_neon_button.dart';

class EditFoodSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onDelete;

  const EditFoodSheet({
    super.key,
    required this.food,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditFoodSheet> createState() => EditFoodSheetState();
}

class EditFoodSheetState extends State<EditFoodSheet> {
  late int _baseCal, _baseP, _baseC, _baseF;
  late int _baseGrams; // Base portion in grams
  late int _currentGrams; // Current grams entered
  late TextEditingController _gramsController;

  @override
  void initState() {
    super.initState();
    _baseCal = widget.food['cal'] as int;
    _baseP = widget.food['p'] as int;
    _baseC = widget.food['c'] as int;
    _baseF = widget.food['f'] as int;

    // Parse base grams from quantity string (e.g., "100g" -> 100)
    _baseGrams = _parseGrams(widget.food['quantity'] as String? ?? '100g');
    _currentGrams = _baseGrams;
    _gramsController = TextEditingController(text: _currentGrams.toString());
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  int _parseGrams(String quantityStr) {
    // Try to extract number from string like "100g", "150 g", "100"
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(quantityStr);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 100;
    }
    return 100; // Default to 100g if can't parse
  }

  double get _effectiveMultiplier {
    return _currentGrams / _baseGrams;
  }

  Widget _buildGramPreset(int grams) {
    final isSelected = _currentGrams == grams;
    return Padding(
      padding: const EdgeInsets.only(right: Spacing.sm),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _currentGrams = grams;
            _gramsController.text = grams.toString();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? FGColors.accent.withValues(alpha: 0.2)
                : FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.sm),
            border: Border.all(
              color: isSelected ? FGColors.accent : FGColors.glassBorder,
            ),
          ),
          child: Text(
            '${grams}g',
            style: FGTypography.caption.copyWith(
              color: isSelected ? FGColors.accent : FGColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
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

          // Grams input section
          Text(
            'Quantité',
            style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.sm),

          // Grams input row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(color: FGColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      // Minus button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final newValue = (_currentGrams - 10).clamp(1, 9999);
                          setState(() {
                            _currentGrams = newValue;
                            _gramsController.text = newValue.toString();
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: FGColors.glassBorder,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(Spacing.sm - 1),
                            ),
                          ),
                          child: const Icon(
                            Icons.remove_rounded,
                            color: FGColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _gramsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: FGTypography.h3.copyWith(fontSize: 18),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            final grams = int.tryParse(value) ?? _baseGrams;
                            setState(() => _currentGrams = grams.clamp(1, 9999));
                          },
                        ),
                      ),
                      // Unit label
                      Padding(
                        padding: const EdgeInsets.only(right: Spacing.sm),
                        child: Text(
                          'g',
                          style: FGTypography.body.copyWith(
                            color: FGColors.textSecondary,
                          ),
                        ),
                      ),
                      // Plus button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final newValue = (_currentGrams + 10).clamp(1, 9999);
                          setState(() {
                            _currentGrams = newValue;
                            _gramsController.text = newValue.toString();
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: FGColors.glassBorder,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(Spacing.sm - 1),
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: FGColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),

          // Quick gram presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGramPreset(25),
                _buildGramPreset(50),
                _buildGramPreset(100),
                _buildGramPreset(150),
                _buildGramPreset(200),
                _buildGramPreset(250),
                _buildGramPreset(300),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Info about base portion
          Text(
            'Portion de base: ${_baseGrams}g',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
            ),
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
                  value: '${(_baseCal * _effectiveMultiplier).round()}',
                  color: FGColors.accent,
                ),
                _MacroColumn(
                  label: 'Protéines',
                  value: '${(_baseP * _effectiveMultiplier).round()}g',
                  color: const Color(0xFFE74C3C),
                ),
                _MacroColumn(
                  label: 'Glucides',
                  value: '${(_baseC * _effectiveMultiplier).round()}g',
                  color: const Color(0xFF3498DB),
                ),
                _MacroColumn(
                  label: 'Lipides',
                  value: '${(_baseF * _effectiveMultiplier).round()}g',
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
                'quantity': '${_currentGrams}g',
                'cal': (_baseCal * _effectiveMultiplier).round(),
                'p': (_baseP * _effectiveMultiplier).round(),
                'c': (_baseC * _effectiveMultiplier).round(),
                'f': (_baseF * _effectiveMultiplier).round(),
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
