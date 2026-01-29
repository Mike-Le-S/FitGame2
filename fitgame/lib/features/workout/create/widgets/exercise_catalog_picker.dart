import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../utils/exercise_catalog.dart';

/// Widget for picking exercises from the catalog to add to a day
class ExerciseCatalogPicker extends StatelessWidget {
  final int currentDay;
  final List<Map<String, dynamic>> currentExercises;
  final void Function(Map<String, dynamic> exercise, bool isAdded) onToggleExercise;

  const ExerciseCatalogPicker({
    super.key,
    required this.currentDay,
    required this.currentExercises,
    required this.onToggleExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AJOUTER DES EXERCICES',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: Spacing.md),
        ...ExerciseCatalog.muscleGroups.map((muscle) {
          final muscleExercises = ExerciseCatalog.getByMuscle(muscle);
          if (muscleExercises.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm, top: Spacing.sm),
                child: Text(
                  muscle.toUpperCase(),
                  style: FGTypography.caption.copyWith(
                    color: FGColors.accent.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: muscleExercises.map((exercise) {
                  final isAdded = currentExercises
                      .any((e) => e['name'] == exercise['name']);

                  return _ExerciseChip(
                    name: exercise['name'] as String,
                    isAdded: isAdded,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onToggleExercise(exercise, isAdded);
                    },
                  );
                }).toList(),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final String name;
  final bool isAdded;
  final VoidCallback onTap;

  const _ExerciseChip({
    required this.name,
    required this.isAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isAdded
              ? LinearGradient(
                  colors: [
                    FGColors.success.withValues(alpha: 0.15),
                    FGColors.success.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: isAdded ? null : FGColors.glassSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(
            color: isAdded
                ? FGColors.success.withValues(alpha: 0.4)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdded ? Icons.check_rounded : Icons.add_rounded,
              color: isAdded ? FGColors.success : FGColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: Spacing.xs),
            Text(
              name,
              style: FGTypography.bodySmall.copyWith(
                color: isAdded ? FGColors.success : FGColors.textPrimary,
                fontWeight: isAdded ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
