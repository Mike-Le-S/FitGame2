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
  final Map<String, dynamic>? lastSessionSet;
  final double? suggestedWeight;

  const SetCard({
    super.key,
    required this.currentSet,
    required this.previousBest,
    required this.isWarmup,
    required this.currentSetIndex,
    this.weightType = 'kg',
    this.isMaxReps = false,
    this.lastSessionSet,
    this.suggestedWeight,
  });

  String _formatWeight(double v) {
    if (v == v.toInt().toDouble()) return v.toInt().toString();
    if (v == double.parse(v.toStringAsFixed(1))) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

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
                            ? '+${_formatWeight(currentSet.targetWeight)}'
                            : _formatWeight(currentSet.targetWeight),
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

          // Last session info + suggestion
          if (!isWarmup) ...[
            const SizedBox(height: Spacing.md),
            if (lastSessionSet != null)
              _buildLastSessionInfo()
            else if (previousBest > 0)
              _buildPreviousBest(),
            if (suggestedWeight != null) ...[
              const SizedBox(height: Spacing.sm),
              _buildSuggestion(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLastSessionInfo() {
    final lastWeight = (lastSessionSet!['actualWeight'] as num?)?.toDouble() ?? 0;
    final lastReps = (lastSessionSet!['actualReps'] as num?)?.toInt() ?? 0;

    return Container(
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
            Icons.history_rounded,
            color: FGColors.textSecondary,
            size: 14,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'Dernière fois : ${lastWeight.toInt()} kg × $lastReps',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousBest() {
    return Container(
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
            size: 14,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'Record : ${previousBest.toInt()} kg',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: FGColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(color: FGColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: FGColors.success,
            size: 14,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'Essaye ${suggestedWeight!.toStringAsFixed(suggestedWeight! == suggestedWeight!.toInt().toDouble() ? 0 : 1)} kg',
            style: FGTypography.caption.copyWith(
              color: FGColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
