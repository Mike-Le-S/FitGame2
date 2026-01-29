import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../painters/mini_progress_ring_painter.dart';

/// Day selector widget with mini progress rings for weekly meal planning
class DaySelector extends StatelessWidget {
  final int selectedDayIndex;
  final List<int> trainingDays;
  final List<String> dayNames;
  final PageController pageController;
  final Function(int) onDaySelected;
  final Map<String, int> Function(int) getDayTotals;
  final int Function(int) getCalorieTarget;

  const DaySelector({
    super.key,
    required this.selectedDayIndex,
    required this.trainingDays,
    required this.dayNames,
    required this.pageController,
    required this.onDaySelected,
    required this.getDayTotals,
    required this.getCalorieTarget,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (context, index) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, index) {
          final isSelected = selectedDayIndex == index;
          final isTraining = trainingDays.contains(index);
          final dayTotals = getDayTotals(index);
          final target = getCalorieTarget(index);
          final progress = (dayTotals['cal']! / target).clamp(0.0, 1.0);

          return GestureDetector(
            onTap: () {
              onDaySelected(index);
              pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? FGColors.glassSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(Spacing.md),
                border: Border.all(
                  color: isSelected
                      ? FGColors.accent
                      : isTraining
                          ? FGColors.accent.withValues(alpha: 0.3)
                          : FGColors.glassBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isTraining && isSelected
                    ? [
                        BoxShadow(
                          color: FGColors.accentGlow,
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isTraining)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: FGColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: FGColors.accentGlow,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 6),
                  const SizedBox(height: 2),
                  Text(
                    dayNames[index],
                    style: FGTypography.caption.copyWith(
                      color: isSelected
                          ? FGColors.textPrimary
                          : FGColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Mini progress ring
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomPaint(
                      painter: MiniProgressRingPainter(
                        progress: progress,
                        color: progress >= 0.9 && progress <= 1.1
                            ? FGColors.success
                            : progress > 1.1
                                ? FGColors.warning
                                : FGColors.accent,
                      ),
                      child: Center(
                        child: Text(
                          '${(progress * 100).round()}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? FGColors.textPrimary
                                : FGColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
