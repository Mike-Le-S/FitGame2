import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';

class SleepSummaryWidget extends StatelessWidget {
  final VoidCallback? onTap;

  // Real data - fetched from backend
  final String totalSleep = '--';
  final int sleepScore = 0;
  final double deepPercent = 0.0;
  final double corePercent = 0.0;
  final double remPercent = 0.0;

  const SleepSummaryWidget({
    super.key,
    this.onTap,
  });

  String get _scoreLabel {
    if (sleepScore >= 85) return 'EXCELLENT';
    if (sleepScore >= 70) return 'BON';
    if (sleepScore >= 50) return 'MOYEN';
    return 'FAIBLE';
  }

  Color get _scoreColor {
    if (sleepScore >= 85) return FGColors.success;
    if (sleepScore >= 70) return FGColors.accent;
    if (sleepScore >= 50) return FGColors.warning;
    return FGColors.error;
  }

  @override
  Widget build(BuildContext context) {
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
            // Header row
            Row(
              children: [
                const Text(
                  '😴',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'SOMMEIL',
                  style: FGTypography.caption.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: FGColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$sleepScore',
                        style: FGTypography.h3.copyWith(
                          color: _scoreColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _scoreLabel,
                        style: FGTypography.caption.copyWith(
                          color: _scoreColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: FGColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Main content row
            Row(
              children: [
                // Total sleep time
                Text(
                  totalSleep,
                  style: FGTypography.h2.copyWith(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: Spacing.lg),

                // Phase bars
                Expanded(
                  child: Column(
                    children: [
                      // Combined bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              Expanded(
                                flex: (deepPercent * 100).round(),
                                child: Container(
                                  color: const Color(0xFF6366F1), // Indigo for deep
                                ),
                              ),
                              Expanded(
                                flex: (corePercent * 100).round(),
                                child: Container(
                                  color: const Color(0xFF8B5CF6), // Purple for core
                                ),
                              ),
                              Expanded(
                                flex: (remPercent * 100).round(),
                                child: Container(
                                  color: const Color(0xFFA78BFA), // Light purple for REM
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),

                      // Labels row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPhaseLabel('Profond', deepPercent, const Color(0xFF6366F1)),
                          _buildPhaseLabel('Core', corePercent, const Color(0xFF8B5CF6)),
                          _buildPhaseLabel('REM', remPercent, const Color(0xFFA78BFA)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseLabel(String label, double percent, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(percent * 100).round()}%',
          style: FGTypography.caption.copyWith(
            fontSize: 10,
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
