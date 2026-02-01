import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';

class MacroSummaryWidget extends StatelessWidget {
  final VoidCallback? onTap;

  // Real data - fetched from backend
  final int currentCalories = 0;
  final int targetCalories = 2000;
  final double proteinPercent = 0.0;
  final double carbsPercent = 0.0;
  final double fatPercent = 0.0;

  // Real data - fetched from backend
  final int yesterdayConsumed = 0;
  final int yesterdayBurned = 0;

  const MacroSummaryWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final caloriePercent = currentCalories / targetCalories;
    final yesterdayDelta = yesterdayConsumed - yesterdayBurned;
    final isDeficit = yesterdayDelta < 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: FGGlassCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with calories
            Row(
              children: [
                const Text(
                  '🍽️',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  'NUTRITION',
                  style: FGTypography.caption.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: FGColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  '$currentCalories',
                  style: FGTypography.h3.copyWith(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  ' / $targetCalories',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: FGColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),

            // Calorie progress bar + yesterday badge in row
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: FGColors.glassBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: caloriePercent.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                FGColors.accent,
                                FGColors.accent.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: FGColors.accent.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                // Yesterday badge with info button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isDeficit ? FGColors.success : FGColors.warning).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hier ${isDeficit ? "" : "+"}$yesterdayDelta',
                        style: FGTypography.caption.copyWith(
                          color: isDeficit ? FGColors.success : FGColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _showInfoDialog(context, yesterdayConsumed, yesterdayBurned, yesterdayDelta),
                        child: Icon(
                          Icons.info_outline,
                          size: 12,
                          color: isDeficit ? FGColors.success : FGColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),

            // Macro progress bars
            Row(
              children: [
                _buildMacroBar('P', proteinPercent, const Color(0xFFEF4444)), // Red
                const SizedBox(width: Spacing.sm),
                _buildMacroBar('C', carbsPercent, const Color(0xFFF59E0B)), // Amber
                const SizedBox(width: Spacing.sm),
                _buildMacroBar('F', fatPercent, const Color(0xFF10B981)), // Green
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, int consumed, int burned, int delta) {
    final isDeficit = delta < 0;
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: FGColors.glassBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: FGColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: FGColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Balance calorique',
                style: FGTypography.h3.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              // Consumed row
              _buildCalorieRow(
                'Mangé hier',
                '$consumed kcal',
                Icons.restaurant,
                FGColors.accent,
              ),
              const SizedBox(height: Spacing.sm),
              // Burned row
              _buildCalorieRow(
                'Dépensé (Apple Santé)',
                '$burned kcal',
                Icons.local_fire_department,
                const Color(0xFFF59E0B),
              ),
              const SizedBox(height: Spacing.md),
              // Divider
              Container(
                height: 1,
                color: FGColors.glassBorder,
              ),
              const SizedBox(height: Spacing.md),
              // Result row
              _buildCalorieRow(
                isDeficit ? 'Déficit' : 'Surplus',
                '${delta.abs()} kcal',
                isDeficit ? Icons.trending_down : Icons.trending_up,
                isDeficit ? FGColors.success : FGColors.warning,
                isBold: true,
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                isDeficit
                  ? 'Tu as brûlé plus que consommé hier.'
                  : 'Tu as consommé plus que brûlé hier.',
                style: FGTypography.bodySmall.copyWith(
                  color: FGColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xl,
                    vertical: Spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: FGColors.accent,
                    borderRadius: BorderRadius.circular(Spacing.md),
                  ),
                  child: Text(
                    'Compris',
                    style: FGTypography.body.copyWith(
                      color: FGColors.textOnAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieRow(String label, String value, IconData icon, Color color, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            label,
            style: FGTypography.body.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: FGTypography.body.copyWith(
            color: isBold ? color : FGColors.textPrimary,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBar(String label, double percent, Color color) {
    return Expanded(
      child: Row(
        children: [
          Text(
            label,
            style: FGTypography.caption.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            '${(percent * 100).round()}%',
            style: FGTypography.caption.copyWith(
              fontSize: 10,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: FGColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percent.clamp(0.0, 1.0),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
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
