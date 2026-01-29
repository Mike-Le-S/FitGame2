import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../widgets/day_tabs.dart';
import '../widgets/day_exercise_list.dart';
import '../widgets/exercise_catalog_picker.dart';

/// Step 4: Exercises configuration per day
class ExercisesStep extends StatelessWidget {
  final List<int> trainingDays;
  final int selectedDayTab;
  final Map<int, List<Map<String, dynamic>>> exercisesByDay;
  final Map<int, Set<int>> selectedForSuperset;
  final Map<int, List<List<int>>> supersetsByDay;
  final ValueChanged<int> onDayTabSelected;
  final void Function(int day, Map<String, dynamic> exercise, bool isAdded) onToggleExercise;
  final void Function(int day) onAddCustomExercise;
  final void Function(int day, int oldIndex, int newIndex) onReorder;
  final void Function(int day, int index) onRemove;
  final void Function(int day, int index, Map<String, dynamic> exercise) onConfigure;
  final void Function(int day, int index) onToggleSupersetSelection;
  final void Function(int day) onCreateSuperset;

  const ExercisesStep({
    super.key,
    required this.trainingDays,
    required this.selectedDayTab,
    required this.exercisesByDay,
    required this.selectedForSuperset,
    required this.supersetsByDay,
    required this.onDayTabSelected,
    required this.onToggleExercise,
    required this.onAddCustomExercise,
    required this.onReorder,
    required this.onRemove,
    required this.onConfigure,
    required this.onToggleSupersetSelection,
    required this.onCreateSuperset,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDays = List<int>.from(trainingDays)..sort();

    // Ensure selectedDayTab is valid
    final currentTabIndex = selectedDayTab >= sortedDays.length ? 0 : selectedDayTab;
    final currentDay = sortedDays.isNotEmpty ? sortedDays[currentTabIndex] : 1;
    final currentExercises = exercisesByDay[currentDay] ?? [];

    return Column(
      children: [
        // Header section with title
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.xl, Spacing.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tes\nexercices',
                style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Configure chaque jour d\'entraînement',
                style: FGTypography.body.copyWith(color: FGColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Day tabs
        DayTabs(
          sortedDays: sortedDays,
          selectedIndex: currentTabIndex,
          exercisesByDay: exercisesByDay,
          onDaySelected: onDayTabSelected,
        ),

        const SizedBox(height: Spacing.md),

        // Exercise content for selected day
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day summary badge
                _DaySummary(
                  dayName: dayNames[currentDay - 1],
                  exerciseCount: currentExercises.length,
                ),
                const SizedBox(height: Spacing.lg),

                // Selected exercises for this day
                if (currentExercises.isNotEmpty) ...[
                  DayExerciseList(
                    day: currentDay,
                    exercises: currentExercises,
                    selectedForSuperset: selectedForSuperset[currentDay] ?? {},
                    supersets: supersetsByDay[currentDay] ?? [],
                    onCreateSuperset: (selectedForSuperset[currentDay]?.length ?? 0) >= 2
                        ? () => onCreateSuperset(currentDay)
                        : null,
                    onAddCustomExercise: () => onAddCustomExercise(currentDay),
                    onReorder: (oldIndex, newIndex) =>
                        onReorder(currentDay, oldIndex, newIndex),
                    onRemove: (index) => onRemove(currentDay, index),
                    onConfigure: (index, exercise) =>
                        onConfigure(currentDay, index, exercise),
                    onToggleSupersetSelection: (index) =>
                        onToggleSupersetSelection(currentDay, index),
                  ),
                  const SizedBox(height: Spacing.xl),
                ],

                // Add exercises section
                ExerciseCatalogPicker(
                  currentDay: currentDay,
                  currentExercises: currentExercises,
                  onToggleExercise: (exercise, isAdded) =>
                      onToggleExercise(currentDay, exercise, isAdded),
                ),
                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DaySummary extends StatelessWidget {
  final String dayName;
  final int exerciseCount;

  const _DaySummary({
    required this.dayName,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FGColors.accent.withValues(alpha: 0.08),
            FGColors.accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FGColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Spacing.sm),
            ),
            child: Center(
              child: Text(
                dayName.substring(0, 1),
                style: FGTypography.h3.copyWith(
                  color: FGColors.accent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: FGTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  exerciseCount == 0
                      ? 'Aucun exercice'
                      : '$exerciseCount exercice${exerciseCount > 1 ? 's' : ''}',
                  style: FGTypography.caption.copyWith(
                    color: exerciseCount == 0
                        ? FGColors.textSecondary
                        : FGColors.success,
                    fontWeight: exerciseCount > 0 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (exerciseCount > 0)
            Container(
              padding: const EdgeInsets.all(Spacing.xs),
              decoration: BoxDecoration(
                color: FGColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: FGColors.success,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
