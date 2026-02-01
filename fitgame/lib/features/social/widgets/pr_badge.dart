import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../models/activity.dart';

/// Badge displaying a personal record achievement
class PRBadge extends StatelessWidget {
  const PRBadge({
    super.key,
    required this.pr,
  });

  final PersonalRecord pr;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FGColors.success.withValues(alpha: 0.2),
            FGColors.success.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FGColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: FGColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: FGColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOUVEAU PR !',
                  style: FGTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: FGColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pr.exerciseName}: ${pr.value.toStringAsFixed(pr.value.truncateToDouble() == pr.value ? 0 : 1)}${pr.unit}',
                  style: FGTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: FGColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: FGColors.success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${pr.gain.toStringAsFixed(pr.gain.truncateToDouble() == pr.gain ? 0 : 1)}${pr.unit}',
              style: FGTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: FGColors.background,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
