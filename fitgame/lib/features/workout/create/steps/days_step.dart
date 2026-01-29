import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';

/// Day short names
const List<String> _dayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Day full names
const List<String> _fullDayNames = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

/// Step 3: Training days selection
class DaysStep extends StatelessWidget {
  final List<int> trainingDays;
  final ValueChanged<List<int>> onDaysChanged;

  const DaysStep({
    super.key,
    required this.trainingDays,
    required this.onDaysChanged,
  });

  void _toggleDay(int dayIndex) {
    final newDays = List<int>.from(trainingDays);
    if (newDays.contains(dayIndex)) {
      newDays.remove(dayIndex);
    } else {
      newDays.add(dayIndex);
      newDays.sort();
    }
    onDaysChanged(newDays);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Jours\nd\'entraînement',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Sélectionne tes jours de séance',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xxl),
          // Day selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayIndex = index + 1;
              final isSelected = trainingDays.contains(dayIndex);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _toggleDay(dayIndex);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              FGColors.accent,
                              FGColors.accent.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: isSelected ? null : FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.md),
                    border: Border.all(
                      color: isSelected ? FGColors.accent : FGColors.glassBorder,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: FGColors.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _dayLetters[index],
                      style: FGTypography.body.copyWith(
                        color: isSelected
                            ? FGColors.textOnAccent
                            : FGColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: Spacing.xl),
          // Summary
          FGGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${trainingDays.length}',
                      style: FGTypography.h2.copyWith(
                        color: FGColors.accent,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'séances par semaine',
                      style: FGTypography.body.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (trainingDays.isNotEmpty) ...[
                  const SizedBox(height: Spacing.md),
                  Wrap(
                    spacing: Spacing.sm,
                    children: trainingDays
                        .map((day) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.sm,
                                vertical: Spacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: FGColors.glassBorder,
                                borderRadius: BorderRadius.circular(Spacing.xs),
                              ),
                              child: Text(
                                _fullDayNames[day - 1],
                                style: FGTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
