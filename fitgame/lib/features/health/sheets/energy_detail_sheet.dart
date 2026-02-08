import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';

/// Detailed energy/calorie breakdown bottom sheet
class EnergyDetailSheet extends StatelessWidget {
  final int caloriesConsumed;
  final int caloriesBurned;
  final int calorieGoal;
  final int bmr;
  final int walkingCalories;
  final int runningCalories;
  final int workoutCalories;
  final int steps;
  final double distanceKm;

  const EnergyDetailSheet({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.calorieGoal,
    required this.bmr,
    required this.walkingCalories,
    required this.runningCalories,
    required this.workoutCalories,
    required this.steps,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final netCalories = caloriesConsumed - caloriesBurned;
    final isDeficit = netCalories < 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: FGColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: Spacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FGColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: FGColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(Spacing.md),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: FGColors.accent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Text(
                        'Énergie',
                        style: FGTypography.h2,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Main stats
                  FGGlassCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildDetailStat(
                                'Consommé',
                                '$caloriesConsumed',
                                'kcal',
                                const Color(0xFF00D9FF),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: FGColors.glassBorder,
                            ),
                            Expanded(
                              child: _buildDetailStat(
                                'Dépensé',
                                '$caloriesBurned',
                                'kcal',
                                FGColors.accent,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: FGColors.glassBorder,
                            ),
                            Expanded(
                              child: _buildDetailStat(
                                isDeficit ? 'Déficit' : 'Surplus',
                                '${netCalories.abs()}',
                                'kcal',
                                isDeficit ? FGColors.success : FGColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Activity breakdown
                  Text(
                    'DÉPENSES PAR ACTIVITÉ',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  FGGlassCard(
                    child: Column(
                      children: [
                        _buildActivityRow(
                          Icons.favorite_rounded,
                          'Métabolisme de base',
                          bmr,
                          caloriesBurned,
                          FGColors.textSecondary,
                        ),
                        const SizedBox(height: Spacing.md),
                        _buildActivityRow(
                          Icons.directions_walk_rounded,
                          'Marche',
                          walkingCalories,
                          caloriesBurned,
                          const Color(0xFF00D9FF),
                        ),
                        const SizedBox(height: Spacing.md),
                        _buildActivityRow(
                          Icons.directions_run_rounded,
                          'Course',
                          runningCalories,
                          caloriesBurned,
                          const Color(0xFF6B5BFF),
                        ),
                        const SizedBox(height: Spacing.md),
                        _buildActivityRow(
                          Icons.fitness_center_rounded,
                          'Musculation',
                          workoutCalories,
                          caloriesBurned,
                          FGColors.accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Movement stats
                  Text(
                    'MOUVEMENT',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FGGlassCard(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.directions_walk_rounded,
                                color: Color(0xFF00D9FF),
                                size: 28,
                              ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                _formatNumber(steps),
                                style: FGTypography.h3.copyWith(
                                  color: const Color(0xFF00D9FF),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'pas',
                                style: FGTypography.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: FGGlassCard(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.straighten_rounded,
                                color: Color(0xFF00D9FF),
                                size: 28,
                              ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                distanceKm.toStringAsFixed(1),
                                style: FGTypography.h3.copyWith(
                                  color: const Color(0xFF00D9FF),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'km',
                                style: FGTypography.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(
      String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: FGTypography.h2.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          unit,
          style: FGTypography.caption.copyWith(
            color: color.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(
    IconData icon,
    String label,
    int calories,
    int maxCalories,
    Color color,
  ) {
    final percent = (calories / maxCalories).clamp(0.0, 1.0);

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: Spacing.md),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: FGTypography.caption.copyWith(
              color: FGColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
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
                widthFactor: percent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.md),
        SizedBox(
          width: 60,
          child: Text(
            '$calories',
            textAlign: TextAlign.right,
            style: FGTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return '$number';
  }
}
