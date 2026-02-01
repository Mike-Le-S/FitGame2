import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';

class QuickStatsRow extends StatelessWidget {
  final int weekSessions;
  final int weekTarget;
  final String totalTime;
  final int calories;

  const QuickStatsRow({
    super.key,
    required this.weekSessions,
    required this.weekTarget,
    required this.totalTime,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatPill('$weekSessions/$weekTarget', 'séances'),
        const SizedBox(width: Spacing.sm),
        _buildStatPill(totalTime, 'cette sem.'),
        const SizedBox(width: Spacing.sm),
        _buildStatPill('$calories', 'kcal'),
      ],
    );
  }

  Widget _buildStatPill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.md,
          horizontal: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: FGColors.glassSurface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: FGColors.glassBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: FGTypography.h3.copyWith(
                color: FGColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: FGTypography.caption.copyWith(
                fontSize: 10,
                color: FGColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
