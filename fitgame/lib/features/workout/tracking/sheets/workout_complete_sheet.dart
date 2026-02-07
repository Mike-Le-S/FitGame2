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
  final int totalSets;
  final TimeStats? timeStats;
  final VoidCallback onClose;

  const WorkoutCompleteSheet({
    super.key,
    required this.duration,
    required this.totalVolume,
    required this.exerciseCount,
    this.totalSets = 0,
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
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: trophy + title in a row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: FGColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: FGColors.success,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Text(
                    'SÉANCE\nTERMINÉE !',
                    style: FGTypography.h2.copyWith(
                      color: FGColors.success,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      height: 1.1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacing.lg),

              // Main stats: 2×2 grid
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    Icons.timer_outlined,
                    _formatDuration(duration),
                    'Durée',
                  )),
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: _buildStatCard(
                    Icons.fitness_center_rounded,
                    _formatVolume(totalVolume),
                    'Volume',
                  )),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    Icons.repeat_rounded,
                    '$totalSets',
                    totalSets == 1 ? 'Série' : 'Séries',
                  )),
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: _buildStatCard(
                    Icons.local_fire_department_rounded,
                    '${(totalVolume * 0.05).toInt()}',
                    'Kcal',
                  )),
                ],
              ),

              // Time breakdown section
              if (timeStats != null && timeStats!.tensionTime > 0) ...[
                const SizedBox(height: Spacing.md),
                _buildTimeBreakdown(timeStats!),
              ],

              const SizedBox(height: Spacing.lg),

              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  decoration: BoxDecoration(
                    color: FGColors.accent,
                    borderRadius: BorderRadius.circular(Spacing.md),
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

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.md,
        horizontal: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: FGColors.glassSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: FGColors.textSecondary, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: FGTypography.h3.copyWith(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
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
          // Header row: title + efficiency badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: effColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: effColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 12, color: effColor),
                    const SizedBox(width: 2),
                    Text(
                      '${stats.efficiencyScore.round()}%',
                      style: FGTypography.caption.copyWith(
                        color: effColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  if (restPct > 0)
                    Expanded(
                      flex: (restPct * 100).round().clamp(1, 100),
                      child: Container(
                        color: FGColors.textSecondary.withValues(alpha: 0.4),
                      ),
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

          // Legend + detail rows combined
          _buildTimeDetailRow(
            FGColors.accent,
            'Sous tension',
            _formatDuration(stats.tensionTime),
          ),
          const SizedBox(height: 4),
          _buildTimeDetailRow(
            FGColors.textSecondary.withValues(alpha: 0.4),
            'Repos',
            _formatDuration(stats.totalRestTime),
          ),
          if (stats.totalTransitionTime > 0) ...[
            const SizedBox(height: 4),
            _buildTimeDetailRow(
              FGColors.warning,
              'Transitions',
              '${_formatDuration(stats.totalTransitionTime)} (moy ${stats.avgTransition.round()}s)',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeDetailRow(Color dotColor, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const Spacer(),
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

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toInt()}kg';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
    }
    if (minutes > 0) {
      return '${minutes}min ${secs.toString().padLeft(2, '0')}s';
    }
    return '${secs}s';
  }
}
