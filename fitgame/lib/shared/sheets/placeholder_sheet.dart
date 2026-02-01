import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/spacing.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';

/// Sheet "Coming soon" réutilisable pour les fonctionnalités pas encore implémentées
class PlaceholderSheet extends StatelessWidget {
  const PlaceholderSheet({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.construction_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.construction_rounded,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlaceholderSheet(
        title: title,
        message: message,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: FGColors.glassBorder,
              width: 1,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FGColors.textSecondary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: FGColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: FGColors.accent,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Title
                  Text(
                    title,
                    style: FGTypography.h3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.sm),

                  // Message
                  Text(
                    message,
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: FGColors.glassBorder,
                          ),
                        ),
                      ),
                      child: Text(
                        'Compris',
                        style: FGTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
