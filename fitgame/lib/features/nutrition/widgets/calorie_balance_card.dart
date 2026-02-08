import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';

class CalorieBalanceCard extends StatelessWidget {
  final int caloriesConsumed;
  final int caloriesBurned;
  final int? caloriesPredicted;
  final int calorieTarget;
  final String goalType; // 'bulk', 'cut', 'maintain'
  final bool isLoading;

  const CalorieBalanceCard({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    this.caloriesPredicted,
    required this.calorieTarget,
    required this.goalType,
    this.isLoading = false,
  });

  int get balance => caloriesConsumed - caloriesBurned;

  bool get isDeficit => balance < 0;

  Color get balanceColor {
    if (goalType == 'cut') {
      return isDeficit ? FGColors.success : FGColors.warning;
    } else if (goalType == 'bulk') {
      return isDeficit ? FGColors.warning : FGColors.success;
    }
    // maintain
    return balance.abs() < 200 ? FGColors.success : FGColors.warning;
  }

  String get balanceLabel {
    if (goalType == 'cut') {
      return isDeficit ? 'Déficit' : 'Surplus';
    } else if (goalType == 'bulk') {
      return isDeficit ? 'Déficit' : 'Surplus';
    }
    return balance.abs() < 200 ? 'Équilibré' : (isDeficit ? 'Déficit' : 'Surplus');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.glassSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacing.lg),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: FGColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                'BILAN DU JOUR',
                style: FGTypography.caption.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: FGColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Main stats row
          if (isLoading)
            const Center(
              child: SizedBox(
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FGColors.accent,
                ),
              ),
            )
          else
            Row(
              children: [
                // Consumed
                Expanded(
                  child: _buildStatColumn(
                    label: 'Consommé',
                    value: caloriesConsumed,
                    color: FGColors.textPrimary,
                  ),
                ),
                // Burned
                Expanded(
                  child: _buildStatColumn(
                    label: 'Brûlé',
                    value: caloriesBurned,
                    color: FGColors.accent,
                    subtitle: 'Apple Santé',
                  ),
                ),
                // Balance
                Expanded(
                  child: _buildStatColumn(
                    label: 'Balance',
                    value: balance,
                    color: balanceColor,
                    showSign: true,
                    badge: balanceLabel,
                  ),
                ),
              ],
            ),

          // Prediction
          if (caloriesPredicted != null && !isLoading) ...[
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: FGColors.glassBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_graph_rounded,
                    color: FGColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      'Prédiction fin de journée: ~$caloriesPredicted kcal',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Progress bar
          const SizedBox(height: Spacing.md),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required int value,
    required Color color,
    String? subtitle,
    bool showSign = false,
    String? badge,
  }) {
    final displayValue = showSign && value > 0 ? '+$value' : value.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                displayValue,
                style: FGTypography.h2.copyWith(
                  fontSize: 22,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                'kcal',
                style: FGTypography.caption.copyWith(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: FGTypography.caption.copyWith(
              fontSize: 9,
              color: FGColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
        if (badge != null) ...[
          const SizedBox(height: Spacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: balanceColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Spacing.xs),
            ),
            child: Text(
              badge,
              style: FGTypography.caption.copyWith(
                fontSize: 9,
                color: balanceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = calorieTarget > 0
        ? (caloriesConsumed / calorieTarget).clamp(0.0, 1.5)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Objectif: $calorieTarget kcal',
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: FGTypography.caption.copyWith(
                color: progress > 1.0 ? FGColors.warning : FGColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: FGColors.glassBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 1.0 ? FGColors.warning : const Color(0xFF2ECC71),
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
