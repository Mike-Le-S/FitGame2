import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../../workout/tracking/active_workout_screen.dart';

class TodayWorkoutCard extends StatelessWidget {
  final String? sessionName;
  final String? sessionMuscles;
  final int? exerciseCount;
  final int? estimatedMinutes;

  const TodayWorkoutCard({
    super.key,
    this.sessionName,
    this.sessionMuscles,
    this.exerciseCount,
    this.estimatedMinutes,
  });

  bool get hasSession => sessionName != null && sessionName!.isNotEmpty;

  void _startWorkout(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ActiveWorkoutScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasSession) {
      return _buildEmptyState(context);
    }

    return GestureDetector(
      onTap: () => _startWorkout(context),
      child: FGGlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient accent
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.accent.withValues(alpha: 0.15),
                    FGColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: FGColors.accent,
                      borderRadius: BorderRadius.circular(Spacing.xs),
                    ),
                    child: Text(
                      'AUJOURD\'HUI',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textOnAccent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (estimatedMinutes != null) ...[
                    Text(
                      '~$estimatedMinutes min',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: Spacing.xs),
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: FGColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.md, Spacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionName!,
                          style: FGTypography.h3.copyWith(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (sessionMuscles != null && sessionMuscles!.isNotEmpty)
                          Text(
                            exerciseCount != null
                                ? '$sessionMuscles • $exerciseCount exercices'
                                : sessionMuscles!,
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_circle_filled,
                    color: FGColors.accent,
                    size: 32,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return FGGlassCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FGColors.glassBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: FGColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pas de séance prévue',
                  style: FGTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: FGColors.textSecondary,
                  ),
                ),
                Text(
                  'Crée un programme pour commencer',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
