import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/constants/spacing.dart';

class ProgressDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Set<int> visitedSteps;
  final ValueChanged<int>? onStepTapped;

  static const _nutritionGreen = Color(0xFF2ECC71);

  const ProgressDots({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.visitedSteps,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            final isActive = visitedSteps.contains(stepBefore + 1);
            return Expanded(
              child: Container(
                height: 2,
                color: isActive ? _nutritionGreen : FGColors.glassBorder,
              ),
            );
          }
          final step = index ~/ 2;
          final isCurrent = step == currentStep;
          final isVisited = visitedSteps.contains(step);
          return GestureDetector(
            onTap: isVisited && !isCurrent
                ? () {
                    HapticFeedback.selectionClick();
                    onStepTapped?.call(step);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 14 : 10,
              height: isCurrent ? 14 : 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent || isVisited ? _nutritionGreen : Colors.transparent,
                border: Border.all(
                  color: isCurrent || isVisited ? _nutritionGreen : FGColors.glassBorder,
                  width: 2,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: _nutritionGreen.withValues(alpha: 0.6), blurRadius: 8)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
