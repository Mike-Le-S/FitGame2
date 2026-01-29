import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/models/exercise.dart';

/// Exercise navigation dots showing progress across exercises
class ExerciseNavigation extends StatelessWidget {
  final List<Exercise> exercises;
  final int currentIndex;
  final Function(int) onExerciseTap;

  const ExerciseNavigation({
    super.key,
    required this.exercises,
    required this.currentIndex,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(exercises.length, (index) {
        final isActive = index == currentIndex;
        final isCompleted = index < currentIndex ||
            (index == currentIndex &&
                exercises[index].sets.every((s) => s.isCompleted));

        return GestureDetector(
          onTap: () {
            if (index != currentIndex) {
              onExerciseTap(index);
              HapticFeedback.selectionClick();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isCompleted
                  ? FGColors.success
                  : isActive
                      ? FGColors.accent
                      : FGColors.glassBorder,
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: FGColors.accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
