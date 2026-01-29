import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/models/exercise.dart';

/// Set progress indicators showing completed and active sets
class SetIndicators extends StatelessWidget {
  final Exercise exercise;
  final int currentSetIndex;
  final Function(int) onSetTap;

  const SetIndicators({
    super.key,
    required this.exercise,
    required this.currentSetIndex,
    required this.onSetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESSION',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: List.generate(exercise.sets.length, (index) {
            final set = exercise.sets[index];
            final isActive = index == currentSetIndex;
            final isCompleted = set.isCompleted;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < exercise.sets.length - 1 ? Spacing.sm : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    if (!isCompleted && index != currentSetIndex) {
                      onSetTap(index);
                      HapticFeedback.selectionClick();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? FGColors.success.withValues(alpha: 0.2)
                          : isActive
                              ? FGColors.accent.withValues(alpha: 0.2)
                              : FGColors.glassSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      border: Border.all(
                        color: isCompleted
                            ? FGColors.success.withValues(alpha: 0.4)
                            : isActive
                                ? FGColors.accent.withValues(alpha: 0.4)
                                : FGColors.glassBorder,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              color: FGColors.success,
                              size: 20,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (set.isWarmup)
                                  Icon(
                                    Icons.whatshot_rounded,
                                    color: isActive
                                        ? FGColors.warning
                                        : FGColors.textSecondary,
                                    size: 14,
                                  )
                                else
                                  Text(
                                    '${index + 1}',
                                    style: FGTypography.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isActive
                                          ? FGColors.accent
                                          : FGColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
