import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Stats bar displaying volume, sets, and calories during workout
class StatsBar extends StatelessWidget {
  final double totalVolume;
  final int completedSets;
  final int totalSets;
  final int estimatedKcal;

  const StatsBar({
    super.key,
    required this.totalVolume,
    required this.completedSets,
    required this.totalSets,
    required this.estimatedKcal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.fitness_center_rounded,
            label: 'Volume',
            value: '${(totalVolume / 1000).toStringAsFixed(1)}t',
          ),
          Container(
            width: 1,
            height: 32,
            color: FGColors.glassBorder,
          ),
          _buildStatItem(
            icon: Icons.repeat_rounded,
            label: 'Séries',
            value: '$completedSets',
          ),
          Container(
            width: 1,
            height: 32,
            color: FGColors.glassBorder,
          ),
          _buildStatItem(
            icon: Icons.local_fire_department_rounded,
            label: 'Kcal',
            value: '$estimatedKcal',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: FGColors.textSecondary,
          size: 18,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          value,
          style: FGTypography.body.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
