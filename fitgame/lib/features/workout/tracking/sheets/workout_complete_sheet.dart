import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/theme/fg_effects.dart';
import '../../../../core/constants/spacing.dart';

class WorkoutCompleteSheet extends StatelessWidget {
  final int duration;
  final double totalVolume;
  final int exerciseCount;
  final VoidCallback onClose;

  const WorkoutCompleteSheet({
    required this.duration,
    required this.totalVolume,
    required this.exerciseCount,
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
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon
              Container(
                padding: const EdgeInsets.all(Spacing.xl),
                decoration: BoxDecoration(
                  color: FGColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: FGColors.success,
                  size: 64,
                ),
              ),

              const SizedBox(height: Spacing.lg),

              Text(
                'SÉANCE TERMINÉE !',
                style: FGTypography.h1.copyWith(
                  color: FGColors.success,
                ),
              ),

              const SizedBox(height: Spacing.xl),

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

              const SizedBox(height: Spacing.xxl),

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

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}min';
  }
}
