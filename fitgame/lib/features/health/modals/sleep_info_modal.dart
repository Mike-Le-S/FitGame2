import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../models/sleep_metric_info.dart';

/// Educational modal displaying detailed information about a sleep metric
class SleepInfoModal extends StatelessWidget {
  final SleepMetricInfo info;

  const SleepInfoModal({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: FGColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
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
                  // Title
                  Text(
                    info.title,
                    style: FGTypography.h2,
                  ),
                  const SizedBox(height: Spacing.md),

                  // Description
                  Text(
                    info.description,
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Benefits
                  Text(
                    'BÉNÉFICES',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  FGGlassCard(
                    child: Column(
                      children: info.benefits.map((benefit) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: FGColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: Spacing.sm),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: FGTypography.caption.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Fitness Impact
                  Text(
                    'IMPACT FITNESS',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  FGGlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.fitness_center_rounded,
                          color: FGColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Text(
                            info.fitnessImpact,
                            style: FGTypography.caption.copyWith(
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Ideal Range
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B5BFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      border: Border.all(
                        color: const Color(0xFF6B5BFF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed_rounded,
                          color: Color(0xFF6B5BFF),
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zone idéale',
                                style: FGTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: FGColors.textSecondary,
                                ),
                              ),
                              Text(
                                info.idealRange,
                                style: FGTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B5BFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
}
