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

  const WeightRepsInput({
    super.key,
    required this.currentSet,
    required this.onWeightChange,
    required this.onRepsChange,
    required this.onNumberPickerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Weight input
        Expanded(
          child: _buildInputCard(
            label: 'POIDS',
            value: currentSet.actualWeight,
            unit: 'kg',
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

        // Reps input
        Expanded(
          child: _buildInputCard(
            label: 'REPS',
            value: currentSet.actualReps.toDouble(),
            unit: '',
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

  Widget _buildInputCard({
    required String label,
    required double value,
    required String unit,
    bool isInteger = false,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    required VoidCallback onValueTap,
  }) {
    return FGGlassCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        children: [
          Text(
            label,
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease button
              GestureDetector(
                onTap: onDecrease,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(color: FGColors.glassBorder),
                  ),
                  child: const Icon(
                    Icons.remove_rounded,
                    color: FGColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),

              // Value display
              Expanded(
                child: GestureDetector(
                  onTap: onValueTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          isInteger
                              ? value.toInt().toString()
                              : value.toStringAsFixed(
                                  value == value.toInt() ? 0 : 1),
                          style: FGTypography.h2.copyWith(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: Spacing.xs),
                          Text(
                            unit,
                            style: FGTypography.body.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Increase button
              GestureDetector(
                onTap: onIncrease,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(color: FGColors.glassBorder),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: FGColors.textPrimary,
                    size: 20,
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
