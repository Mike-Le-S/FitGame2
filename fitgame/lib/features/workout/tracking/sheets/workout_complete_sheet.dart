import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/theme/fg_effects.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/models/time_stats.dart';

class WorkoutCompleteSheet extends StatelessWidget {
  final int duration;
  final double totalVolume;
  final int exerciseCount;
  final TimeStats? timeStats;
  final VoidCallback onClose;

  const WorkoutCompleteSheet({
    super.key,
    required this.duration,
    required this.totalVolume,
    required this.exerciseCount,
    this.timeStats,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon
              Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: FGColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: FGColors.success,
                  size: 48,
                ),
              ),

              const SizedBox(height: Spacing.md),

              Text(
                'SÉANCE TERMINÉE !',
                style: FGTypography.h1.copyWith(
                  color: FGColors.success,
                ),
              ),

              const SizedBox(height: Spacing.lg),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompleteStat(
                    icon: Icons.timer_outlined,
                    value: _formatDuration(duration),
                    label: 'Durée',
                  ),
                  _buildCompleteStat(
                    icon: Icons.fitness_center_rounded,
                    value: '${(totalVolume / 1000).toStringAsFixed(1)}t',
                    label: 'Volume',
                  ),
                  _buildCompleteStat(
                    icon: Icons.local_fire_department_rounded,
                    value: '${(totalVolume * 0.05).toInt()}',
                    label: 'Kcal',
                  ),
                ],
              ),

              // Time breakdown section
              if (timeStats != null && timeStats!.tensionTime > 0) ...[
                const SizedBox(height: Spacing.lg),
                _buildTimeBreakdown(timeStats!),
              ],

              const SizedBox(height: Spacing.xl),

              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  decoration: BoxDecoration(
                    color: FGColors.accent,
                    borderRadius: BorderRadius.circular(Spacing.lg),
                    boxShadow: FGEffects.neonGlow,
                  ),
                  child: Center(
                    child: Text(
                      'TERMINER',
                      style: FGTypography.button.copyWith(
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
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

  Widget _buildTimeBreakdown(TimeStats stats) {
    // Calculate proportions for stacked bar
    final total = stats.tensionTime + stats.totalRestTime + stats.totalTransitionTime;
    final exercisePct = total > 0 ? stats.tensionTime / total : 0.33;
    final restPct = total > 0 ? stats.totalRestTime / total : 0.33;
    final transitionPct = total > 0 ? stats.totalTransitionTime / total : 0.33;

    // Efficiency score color
    Color effColor;
    if (stats.efficiencyScore > 35) {
      effColor = FGColors.success;
    } else if (stats.efficiencyScore > 20) {
      effColor = FGColors.warning;
    } else {
      effColor = FGColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉPARTITION DU TEMPS',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: Spacing.md),

          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (exercisePct * 100).round().clamp(1, 100),
                    child: Container(color: FGColors.accent),
                  ),
                  Expanded(
                    flex: (restPct * 100).round().clamp(1, 100),
                    child: Container(color: FGColors.glassBorder),
                  ),
                  if (transitionPct > 0)
                    Expanded(
                      flex: (transitionPct * 100).round().clamp(1, 100),
                      child: Container(color: FGColors.warning),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spacing.sm),

          // Legend
          Row(
            children: [
              _buildLegendDot(FGColors.accent),
              const SizedBox(width: 4),
              Text('Exercice', style: _legendStyle),
              const SizedBox(width: Spacing.md),
              _buildLegendDot(FGColors.glassBorder),
              const SizedBox(width: 4),
              Text('Repos', style: _legendStyle),
              if (stats.totalTransitionTime > 0) ...[
                const SizedBox(width: Spacing.md),
                _buildLegendDot(FGColors.warning),
                const SizedBox(width: 4),
                Text('Transit', style: _legendStyle),
              ],
            ],
          ),

          const SizedBox(height: Spacing.md),

          // Detail rows
          _buildTimeRow('Sous tension', _formatDuration(stats.tensionTime)),
          const SizedBox(height: 6),
          _buildTimeRow('Repos total', _formatDuration(stats.totalRestTime)),
          if (stats.totalTransitionTime > 0) ...[
            const SizedBox(height: 6),
            _buildTimeRow(
              'Transitions',
              '${_formatDuration(stats.totalTransitionTime)} (moy ${stats.avgTransition.round()}s)',
            ),
          ],

          const SizedBox(height: Spacing.md),

          // Efficiency score
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: effColor),
              const SizedBox(width: 4),
              Text(
                'Efficacité : ${stats.efficiencyScore.round()}%',
                style: FGTypography.caption.copyWith(
                  color: effColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  'temps sous tension / total',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  TextStyle get _legendStyle => FGTypography.caption.copyWith(
        color: FGColors.textSecondary,
        fontSize: 10,
      );

  Widget _buildTimeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: FGColors.textSecondary,
          size: 24,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          value,
          style: FGTypography.h2.copyWith(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}';
    }
    if (minutes > 0) {
      return '${minutes}min ${secs.toString().padLeft(2, '0')}s';
    }
    return '${secs}s';
  }
}
