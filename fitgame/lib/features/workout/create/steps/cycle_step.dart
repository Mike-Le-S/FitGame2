import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';
import '../widgets/number_picker.dart';

/// Step 2: Cycle configuration
class CycleStep extends StatelessWidget {
  final bool hasCycle;
  final int trainingWeeksBeforeDeload;
  final int deloadPercentage;
  final ValueChanged<bool> onCycleChanged;
  final ValueChanged<int> onWeeksChanged;
  final ValueChanged<int> onDeloadPercentageChanged;

  const CycleStep({
    super.key,
    required this.hasCycle,
    required this.trainingWeeksBeforeDeload,
    required this.deloadPercentage,
    required this.onCycleChanged,
    required this.onWeeksChanged,
    required this.onDeloadPercentageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Durée &\nCycle',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Configure la structure de ton programme',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xxl),

          // Cycle toggle
          _CycleToggle(
            hasCycle: hasCycle,
            onChanged: onCycleChanged,
          ),

          // Cycle config (only if cycle is enabled)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: hasCycle
                ? _CycleConfig(
                    trainingWeeksBeforeDeload: trainingWeeksBeforeDeload,
                    deloadPercentage: deloadPercentage,
                    onWeeksChanged: onWeeksChanged,
                    onDeloadPercentageChanged: onDeloadPercentageChanged,
                  )
                : const SizedBox.shrink(),
          ),

          // Info card
          const SizedBox(height: Spacing.lg),
          _InfoCard(
            hasCycle: hasCycle,
            trainingWeeksBeforeDeload: trainingWeeksBeforeDeload,
            deloadPercentage: deloadPercentage,
          ),
        ],
      ),
    );
  }
}

class _CycleToggle extends StatelessWidget {
  final bool hasCycle;
  final ValueChanged<bool> onChanged;

  const _CycleToggle({
    required this.hasCycle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!hasCycle);
      },
      child: FGGlassCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasCycle
                    ? FGColors.accent.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.md),
              ),
              child: Icon(
                hasCycle ? Icons.replay_rounded : Icons.all_inclusive_rounded,
                color: hasCycle ? FGColors.accent : FGColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activer un cycle',
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    hasCycle
                        ? 'Programme avec durée définie'
                        : 'Programme continu (∞)',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: hasCycle ? FGColors.accent : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    hasCycle ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color:
                        hasCycle ? FGColors.textOnAccent : FGColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleConfig extends StatelessWidget {
  final int trainingWeeksBeforeDeload;
  final int deloadPercentage;
  final ValueChanged<int> onWeeksChanged;
  final ValueChanged<int> onDeloadPercentageChanged;

  const _CycleConfig({
    required this.trainingWeeksBeforeDeload,
    required this.deloadPercentage,
    required this.onWeeksChanged,
    required this.onDeloadPercentageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalCycleWeeks = trainingWeeksBeforeDeload + 1;

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.lg),
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: FGColors.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Spacing.lg),
          border: Border.all(color: FGColors.accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual cycle representation
            Row(
              children: [
                // Training weeks
                Expanded(
                  flex: trainingWeeksBeforeDeload,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: FGColors.accent,
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Deload week
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: FGColors.success,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$trainingWeeksBeforeDeload sem. entraînement',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '1 sem. deload',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            // Cycle length selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Semaines d\'entraînement',
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                NumberPicker(
                  value: trainingWeeksBeforeDeload,
                  min: 2,
                  max: 8,
                  onChanged: onWeeksChanged,
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Weight reduction
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Réduction des poids',
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: FGColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Text(
                    '-${100 - deloadPercentage}%',
                    style: FGTypography.body.copyWith(
                      color: FGColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: FGColors.success,
                inactiveTrackColor: FGColors.glassBorder,
                thumbColor: FGColors.success,
                overlayColor: FGColors.success.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: deloadPercentage.toDouble(),
                min: 40,
                max: 80,
                divisions: 8,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onDeloadPercentageChanged(v.round());
                },
              ),
            ),

            const SizedBox(height: Spacing.md),
            // Summary
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: FGColors.glassSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.replay_rounded,
                    color: FGColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      'Cycle de $totalCycleWeeks semaines qui se répète',
                      style: FGTypography.bodySmall.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool hasCycle;
  final int trainingWeeksBeforeDeload;
  final int deloadPercentage;

  const _InfoCard({
    required this.hasCycle,
    required this.trainingWeeksBeforeDeload,
    required this.deloadPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final String message;
    final IconData icon;
    final Color color;

    if (!hasCycle) {
      message = 'Programme continu : tu t\'entraînes sans limite de temps, parfait pour un mode de vie fitness.';
      icon = Icons.all_inclusive_rounded;
      color = FGColors.accent;
    } else {
      final totalCycleWeeks = trainingWeeksBeforeDeload + 1;
      message = 'Cycle de $totalCycleWeeks semaines : $trainingWeeksBeforeDeload sem. intensives puis 1 sem. à $deloadPercentage% des charges. Se répète automatiquement.';
      icon = Icons.auto_awesome_rounded;
      color = FGColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              message,
              style: FGTypography.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
