import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../models/heart_metric_info.dart';

/// Educational modal displaying detailed information about a heart metric
class HeartInfoModal extends StatelessWidget {
  final HeartMetricInfo info;

  const HeartInfoModal({super.key, required this.info});

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
                  Text(
                    info.title,
                    style: FGTypography.h3.copyWith(
                      color: const Color(0xFFFF5B7F),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    info.description,
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Ideal range
                  FGGlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: FGColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(Spacing.sm),
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: FGColors.success,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plage idéale',
                                style: FGTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: FGColors.success,
                                ),
                              ),
                              Text(
                                info.idealRange,
                                style: FGTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Benefits
                  Text(
                    'POURQUOI C\'EST IMPORTANT',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  ...info.benefits.map((benefit) => Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5B7F),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                benefit,
                                style: FGTypography.body.copyWith(
                                  color: FGColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: Spacing.lg),

                  // Fitness impact
                  Text(
                    'IMPACT SUR L\'ENTRAÎNEMENT',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: FGColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      border: Border.all(
                        color: FGColors.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          color: FGColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            info.fitnessImpact,
                            style: FGTypography.body.copyWith(
                              color: FGColors.textPrimary,
                              height: 1.5,
                            ),
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
