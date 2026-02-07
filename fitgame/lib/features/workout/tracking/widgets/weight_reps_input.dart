import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';
import '../../../../core/models/workout_set.dart';

/// Weight and reps input widget with increment/decrement buttons
class WeightRepsInput extends StatelessWidget {
  final WorkoutSet currentSet;
  final Function(double) onWeightChange;
  final Function(int) onRepsChange;
  final Function(double, bool) onNumberPickerTap;
  final String weightType;
  final bool isMaxReps;

  const WeightRepsInput({
    super.key,
    required this.currentSet,
    required this.onWeightChange,
    required this.onRepsChange,
    required this.onNumberPickerTap,
    this.weightType = 'kg',
    this.isMaxReps = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBodyweight = weightType == 'bodyweight';
    final bool isBodyweightPlus = weightType == 'bodyweight_plus';
    final String weightLabel = isBodyweightPlus ? 'LEST' : 'POIDS';
    final String weightUnit = isBodyweightPlus ? '+kg' : 'kg';
    final String repsLabel = isMaxReps ? 'REPS (MAX)' : 'REPS';

    return Row(
      children: [
        // Weight input - hidden for bodyweight exercises
        if (!isBodyweight) ...[
          Expanded(
            child: _InputCard(
              label: weightLabel,
              unit: weightUnit,
              value: currentSet.actualWeight,
              isInteger: false,
              onDecrease: () {
                final newValue = (currentSet.actualWeight - 2.5).clamp(0.0, 500.0);
                onWeightChange(newValue);
                HapticFeedback.lightImpact();
              },
              onIncrease: () {
                final newValue = (currentSet.actualWeight + 2.5).clamp(0.0, 500.0);
                onWeightChange(newValue);
                HapticFeedback.lightImpact();
              },
              onValueTap: () => onNumberPickerTap(currentSet.actualWeight, false),
            ),
          ),
          const SizedBox(width: Spacing.md),
        ],

        // Reps input
        Expanded(
          child: _InputCard(
            label: repsLabel,
            unit: null,
            value: currentSet.actualReps.toDouble(),
            isInteger: true,
            onDecrease: () {
              final newValue = (currentSet.actualReps - 1).clamp(0, 100);
              onRepsChange(newValue);
              HapticFeedback.lightImpact();
            },
            onIncrease: () {
              final newValue = (currentSet.actualReps + 1).clamp(0, 100);
              onRepsChange(newValue);
              HapticFeedback.lightImpact();
            },
            onValueTap: () =>
                onNumberPickerTap(currentSet.actualReps.toDouble(), true),
          ),
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final String? unit;
  final double value;
  final bool isInteger;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onValueTap;

  const _InputCard({
    required this.label,
    required this.unit,
    required this.value,
    required this.isInteger,
    required this.onDecrease,
    required this.onIncrease,
    required this.onValueTap,
  });

  String get _formattedValue {
    if (isInteger) return value.toInt().toString();
    return value == value.toInt()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return FGGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label with optional unit
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: FGColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    unit!,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: Spacing.md),

          // Value display - tappable
          GestureDetector(
            onTap: onValueTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Text(
                _formattedValue,
                textAlign: TextAlign.center,
                style: FGTypography.h1.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: FGColors.textPrimary,
                  height: 1,
                ),
              ),
            ),
          ),

          const SizedBox(height: Spacing.md),

          // Increment/decrement buttons
          Row(
            children: [
              Expanded(
                child: _StepperButton(
                  icon: Icons.remove_rounded,
                  onTap: onDecrease,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: _StepperButton(
                  icon: Icons.add_rounded,
                  onTap: onIncrease,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: FGColors.glassSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(
            color: FGColors.glassBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          icon,
          color: FGColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
