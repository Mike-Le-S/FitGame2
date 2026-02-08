import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/theme/fg_effects.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';
import '../painters/rest_timer_painter.dart';

/// Rest timer view with circular progress and next set preview
class RestTimerView extends StatelessWidget {
  final int restSecondsRemaining;
  final int totalRestSeconds;
  final double? nextSetWeight;
  final int? nextSetReps;
  final String? nextExerciseName;
  final String? nextExerciseMuscle;
  final VoidCallback onSkipRest;
  final VoidCallback onAddRestTime;

  const RestTimerView({
    super.key,
    required this.restSecondsRemaining,
    required this.totalRestSeconds,
    this.nextSetWeight,
    this.nextSetReps,
    this.nextExerciseName,
    this.nextExerciseMuscle,
    required this.onSkipRest,
    required this.onAddRestTime,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalRestSeconds > 0
        ? 1 - (restSecondsRemaining / totalRestSeconds)
        : 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rest timer ring
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Track
                  SizedBox.expand(
                    child: CustomPaint(
                      painter: RestTimerPainter(
                        progress: progress,
                        trackColor: FGColors.glassBorder,
                        progressColor: FGColors.success,
                      ),
                    ),
                  ),

                  // Time display
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'REPOS',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.success,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        _formatRestTime(restSecondsRemaining),
                        style: FGTypography.display.copyWith(
                          color: FGColors.textPrimary,
                          fontSize: 64,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // Next set preview
            FGGlassCard(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                children: [
                  Text(
                    'PROCHAINE SÉRIE',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  if (nextSetWeight != null && nextSetReps != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${nextSetWeight!.toInt()} kg',
                            style: FGTypography.h2.copyWith(
                              color: FGColors.accent,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Text(
                            ' × ',
                            style: FGTypography.h3.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$nextSetReps reps',
                            style: FGTypography.h2.copyWith(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (nextExerciseName != null && nextExerciseMuscle != null)
                    Column(
                      children: [
                        Text(
                          nextExerciseName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: FGTypography.h3,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          nextExerciseMuscle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // Rest controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add time
                GestureDetector(
                  onTap: onAddRestTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.md),
                      border: Border.all(color: FGColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: FGColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          '+30s',
                          style: FGTypography.body.copyWith(
                            color: FGColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: Spacing.md),

                // Skip rest
                GestureDetector(
                  onTap: onSkipRest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: FGColors.accent,
                      borderRadius: BorderRadius.circular(Spacing.md),
                      boxShadow: FGEffects.neonGlow,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.skip_next_rounded,
                          color: FGColors.textOnAccent,
                          size: 18,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          'PASSER',
                          style: FGTypography.button.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRestTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
