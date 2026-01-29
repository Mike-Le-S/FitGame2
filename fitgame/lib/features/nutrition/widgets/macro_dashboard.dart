import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../painters/macro_ring_painter.dart';

/// Macro dashboard widget displaying calorie hero with ring and macro breakdown
class MacroDashboard extends StatelessWidget {
  final Map<String, int> totals;
  final int calorieTarget;
  final Map<String, int> targets;
  final Animation<double> animation;

  const MacroDashboard({
    super.key,
    required this.totals,
    required this.calorieTarget,
    required this.targets,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final calProgress = (totals['cal']! / calorieTarget).clamp(0.0, 1.5);
    final pProgress = (totals['p']! / targets['protein']!).clamp(0.0, 1.5);
    final cProgress = (totals['c']! / targets['carbs']!).clamp(0.0, 1.5);
    final fProgress = (totals['f']! / targets['fat']!).clamp(0.0, 1.5);

    return FGGlassCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        children: [
          // Calories hero
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CALORIES',
                      style: FGTypography.caption.copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: FGColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final value =
                                (totals['cal']! * animation.value).round();
                            return Text(
                              '$value',
                              style: FGTypography.numbers.copyWith(
                                color: FGColors.accent,
                                fontSize: 42,
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            '/ $calorieTarget',
                            style: FGTypography.body.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Big calorie ring
              SizedBox(
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: MacroRingPainter(
                        progress: calProgress * animation.value,
                        color: calProgress >= 0.9 && calProgress <= 1.1
                            ? FGColors.success
                            : calProgress > 1.1
                                ? FGColors.warning
                                : FGColors.accent,
                        strokeWidth: 8,
                      ),
                      child: Center(
                        child: Text(
                          '${(calProgress * 100 * animation.value).round()}%',
                          style: FGTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          // Macro breakdown
          Row(
            children: [
              Expanded(
                child: _buildMacroItem(
                  'Protéines',
                  totals['p']!,
                  targets['protein']!,
                  pProgress,
                  const Color(0xFFE74C3C), // Red for protein
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _buildMacroItem(
                  'Glucides',
                  totals['c']!,
                  targets['carbs']!,
                  cProgress,
                  const Color(0xFF3498DB), // Blue for carbs
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _buildMacroItem(
                  'Lipides',
                  totals['f']!,
                  targets['fat']!,
                  fProgress,
                  const Color(0xFFF39C12), // Yellow for fat
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(
      String label, int current, int target, double progress, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedProgress = progress * animation.value;
        final animatedCurrent = (current * animation.value).round();

        return Column(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CustomPaint(
                painter: MacroRingPainter(
                  progress: animatedProgress,
                  color: color,
                  strokeWidth: 5,
                ),
                child: Center(
                  child: Text(
                    '${animatedCurrent}g',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textPrimary,
                    ),
                  ),
                ),
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
            Text(
              '/ ${target}g',
              style: FGTypography.caption.copyWith(
                fontSize: 9,
                color: FGColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      },
    );
  }
}
