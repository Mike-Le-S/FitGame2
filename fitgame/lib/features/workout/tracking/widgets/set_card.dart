import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';
import '../../../../core/models/workout_set.dart';

/// Main set card displaying target weight, reps, and previous best
class SetCard extends StatelessWidget {
  final WorkoutSet currentSet;
  final double previousBest;
  final bool isWarmup;
  final int currentSetIndex;
  final String weightType;
  final bool isMaxReps;

  const SetCard({
    super.key,
    required this.currentSet,
    required this.previousBest,
    required this.isWarmup,
    required this.currentSetIndex,
    this.weightType = 'kg',
    this.isMaxReps = false,
  });

  @override
  Widget build(BuildContext context) {
    return FGGlassCard(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        children: [
          // Set indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWarmup)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: FGColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Spacing.xs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.whatshot_rounded,
                        color: FGColors.warning,
                        size: 14,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        'ÉCHAUFFEMENT',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.warning,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'SÉRIE ${currentSetIndex + 1}',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
            ],
          ),

          const SizedBox(height: Spacing.lg),

          // Target display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Weight
              Column(
                children: [
                  Text(
                    weightType == 'bodyweight'
                        ? 'PDC'
                        : weightType == 'bodyweight_plus'
                            ? '+${currentSet.targetWeight.toInt()}'
                            : '${currentSet.targetWeight.toInt()}',
                    style: FGTypography.display.copyWith(
                      color: FGColors.accent,
                      fontSize: weightType == 'bodyweight' ? 40 : 56,
                    ),
                  ),
                  Text(
                    weightType == 'bodyweight'
                        ? 'poids du corps'
                        : weightType == 'bodyweight_plus'
                            ? '+kg'
                            : 'kg',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Text(
                  '\u00d7',
                  style: FGTypography.h2.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
              ),

              // Reps
              Column(
                children: [
                  Text(
                    isMaxReps ? 'MAX' : '${currentSet.targetReps}',
                    style: FGTypography.display.copyWith(
                      fontSize: isMaxReps ? 40 : 56,
                    ),
                  ),
                  Text(
                    isMaxReps ? 'reps max' : 'reps',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Previous best indicator
          if (!isWarmup && previousBest > 0) ...[
            const SizedBox(height: Spacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: FGColors.glassSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: FGColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Record: ${previousBest.toInt()} kg',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
