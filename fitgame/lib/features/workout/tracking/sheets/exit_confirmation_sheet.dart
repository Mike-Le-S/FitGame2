import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

class ExitConfirmationSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ExitConfirmationSheet({
    required this.onConfirm,
    required this.onCancel,
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
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: Spacing.xl),

              // Warning icon
              Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: FGColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: FGColors.warning,
                  size: 40,
                ),
              ),

              const SizedBox(height: Spacing.lg),

              Text(
                'Quitter la séance ?',
                style: FGTypography.h2,
              ),

              const SizedBox(height: Spacing.sm),

              Text(
                'Ta progression sera perdue.',
                style: FGTypography.body.copyWith(
                  color: FGColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.xl),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: Spacing.md),
                        decoration: BoxDecoration(
                          color: FGColors.glassSurface,
                          borderRadius: BorderRadius.circular(Spacing.md),
                          border: Border.all(color: FGColors.glassBorder),
                        ),
                        child: Center(
                          child: Text(
                            'CONTINUER',
                            style: FGTypography.button.copyWith(
                              color: FGColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: Spacing.md),
                        decoration: BoxDecoration(
                          color: FGColors.error,
                          borderRadius: BorderRadius.circular(Spacing.md),
                        ),
                        child: Center(
                          child: Text(
                            'QUITTER',
                            style: FGTypography.button,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
