import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Workout header showing exercise name, muscle group, progress, and timer
class WorkoutHeader extends StatelessWidget {
  final String exerciseName;
  final String muscleGroup;
  final int currentExercise;
  final int totalExercises;
  final int workoutSeconds;
  final VoidCallback onExitTap;
  final String notes;
  final String progressionRule;
  final VoidCallback? onNotesTap;

  const WorkoutHeader({
    super.key,
    required this.exerciseName,
    required this.muscleGroup,
    required this.currentExercise,
    required this.totalExercises,
    required this.workoutSeconds,
    required this.onExitTap,
    this.notes = '',
    this.progressionRule = '',
    this.onNotesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Close button
              GestureDetector(
                onTap: onExitTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(color: FGColors.glassBorder),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: FGColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: Spacing.md),

              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      style: FGTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FGColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(Spacing.xs),
                          ),
                          child: Text(
                            muscleGroup,
                            style: FGTypography.caption.copyWith(
                              color: FGColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          '$currentExercise/$totalExercises',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Workout timer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  border: Border.all(color: FGColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: FGColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      _formatDuration(workoutSeconds),
                      style: FGTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              // Notes info button
              if (notes.isNotEmpty || progressionRule.isNotEmpty) ...[
                const SizedBox(width: Spacing.sm),
                GestureDetector(
                  onTap: onNotesTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: FGColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      border: Border.all(
                        color: FGColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'i',
                        style: FGTypography.body.copyWith(
                          color: FGColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
