import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Macro presets
const List<Map<String, dynamic>> macroPresets = [
  {'name': 'Équilibré', 'p': 30, 'c': 45, 'f': 25},
  {'name': 'High Protein', 'p': 40, 'c': 35, 'f': 25},
  {'name': 'Low Carb', 'p': 35, 'c': 25, 'f': 40},
];

/// Step 4: Macro distribution (P/C/F)
class MacrosStep extends StatelessWidget {
  final int proteinPercent;
  final int carbsPercent;
  final int fatPercent;
  final int trainingCalories;
  final ValueChanged<int> onProteinChanged;
  final ValueChanged<int> onCarbsChanged;
  final ValueChanged<int> onFatChanged;
  final void Function(int p, int c, int f) onPresetSelected;

  const MacrosStep({
    super.key,
    required this.proteinPercent,
    required this.carbsPercent,
    required this.fatPercent,
    required this.trainingCalories,
    required this.onProteinChanged,
    required this.onCarbsChanged,
    required this.onFatChanged,
    required this.onPresetSelected,
  });

  int get _total => proteinPercent + carbsPercent + fatPercent;

  // Calculate grams from percentage and calories
  int _gramsFromPercent(int percent, double calPerGram) {
    return ((trainingCalories * percent / 100) / calPerGram).round();
  }

  @override
  Widget build(BuildContext context) {
    final proteinGrams = _gramsFromPercent(proteinPercent, 4.0);
    final carbsGrams = _gramsFromPercent(carbsPercent, 4.0);
    final fatGrams = _gramsFromPercent(fatPercent, 9.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Répartition\nmacros',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Protéines, glucides et lipides',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.lg),
          // Presets
          Text(
            'PRESETS',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: macroPresets.map((preset) {
              final isSelected = preset['p'] == proteinPercent &&
                  preset['c'] == carbsPercent &&
                  preset['f'] == fatPercent;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: preset != macroPresets.last ? Spacing.sm : 0,
                  ),
                  child: _PresetChip(
                    name: preset['name'] as String,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPresetSelected(
                        preset['p'] as int,
                        preset['c'] as int,
                        preset['f'] as int,
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.xl),
          // Total indicator
          if (_total != 100)
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              margin: const EdgeInsets.only(bottom: Spacing.md),
              decoration: BoxDecoration(
                color: FGColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Spacing.sm),
                border: Border.all(color: FGColors.warning),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: FGColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Total: $_total% (doit faire 100%)',
                    style: FGTypography.bodySmall.copyWith(
                      color: FGColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Macro sliders
          _MacroSlider(
            label: 'Protéines',
            percent: proteinPercent,
            grams: proteinGrams,
            color: const Color(0xFFE74C3C),
            onChanged: onProteinChanged,
          ),
          const SizedBox(height: Spacing.lg),
          _MacroSlider(
            label: 'Glucides',
            percent: carbsPercent,
            grams: carbsGrams,
            color: const Color(0xFF3498DB),
            onChanged: onCarbsChanged,
          ),
          const SizedBox(height: Spacing.lg),
          _MacroSlider(
            label: 'Lipides',
            percent: fatPercent,
            grams: fatGrams,
            color: const Color(0xFFF39C12),
            onChanged: onFatChanged,
          ),
          const SizedBox(height: Spacing.xl),
          // Summary card
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
                _MacroSummary(
                  label: 'P',
                  grams: proteinGrams,
                  color: const Color(0xFFE74C3C),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: FGColors.glassBorder,
                ),
                _MacroSummary(
                  label: 'C',
                  grams: carbsGrams,
                  color: const Color(0xFF3498DB),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: FGColors.glassBorder,
                ),
                _MacroSummary(
                  label: 'F',
                  grams: fatGrams,
                  color: const Color(0xFFF39C12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
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
        child: Center(
          child: Text(
            name,
            style: FGTypography.caption.copyWith(
              color:
                  isSelected ? const Color(0xFF2ECC71) : FGColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroSlider extends StatelessWidget {
  final String label;
  final int percent;
  final int grams;
  final Color color;
  final ValueChanged<int> onChanged;

  const _MacroSlider({
    required this.label,
    required this.percent,
    required this.grams,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: FGColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  '$percent%',
                  style: FGTypography.h3.copyWith(color: color),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  '($grams g)',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: percent.toDouble(),
            min: 10,
            max: 60,
            divisions: 50,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              onChanged(value.round());
            },
          ),
        ),
      ],
    );
  }
}

class _MacroSummary extends StatelessWidget {
  final String label;
  final int grams;
  final Color color;

  const _MacroSummary({
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              label,
              style: FGTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          '${grams}g',
          style: FGTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: FGColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
