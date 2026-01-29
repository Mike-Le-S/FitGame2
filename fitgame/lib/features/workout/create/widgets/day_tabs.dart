import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Day names in French
const List<String> dayNames = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

/// Horizontal scrollable tabs for day selection in exercises step
class DayTabs extends StatelessWidget {
  final List<int> sortedDays;
  final int selectedIndex;
  final Map<int, List<Map<String, dynamic>>> exercisesByDay;
  final ValueChanged<int> onDaySelected;

  const DayTabs({
    super.key,
    required this.sortedDays,
    required this.selectedIndex,
    required this.exercisesByDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sortedDays.length,
        separatorBuilder: (context, index) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, index) {
          final day = sortedDays[index];
          final isSelected = index == selectedIndex;
          final exerciseCount = (exercisesByDay[day] ?? []).length;
          final hasExercises = exerciseCount > 0;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onDaySelected(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          FGColors.accent,
                          FGColors.accent.withValues(alpha: 0.85),
                        ],
                      )
                    : null,
                color: isSelected ? null : FGColors.glassSurface,
                borderRadius: BorderRadius.circular(Spacing.md),
                border: Border.all(
                  color: isSelected
                      ? FGColors.accent
                      : hasExercises
                          ? FGColors.success.withValues(alpha: 0.4)
                          : FGColors.glassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: FGColors.accent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayNames[day - 1].substring(0, 3),
                    style: FGTypography.body.copyWith(
                      color: isSelected
                          ? FGColors.textOnAccent
                          : FGColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasExercises) ...[
                    const SizedBox(width: Spacing.sm),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? FGColors.textOnAccent.withValues(alpha: 0.2)
                            : FGColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$exerciseCount',
                        style: FGTypography.caption.copyWith(
                          color: isSelected
                              ? FGColors.textOnAccent
                              : FGColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
