import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// PR celebration overlay with animated trophy icon
class PRCelebration extends StatelessWidget {
  final bool show;
  final AnimationController animationController;

  const PRCelebration({
    super.key,
    required this.show,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final opacity = Curves.easeOut.transform(
          1 - animationController.value,
        );
        final scale = 0.8 + (animationController.value * 0.4);

        return Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Container(
                color: FGColors.success.withValues(alpha: 0.1),
                child: Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(Spacing.xl),
                          decoration: BoxDecoration(
                            color: FGColors.success.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: FGColors.success.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: FGColors.success,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        Text(
                          'NOUVEAU RECORD !',
                          style: FGTypography.h1.copyWith(
                            color: FGColors.success,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
