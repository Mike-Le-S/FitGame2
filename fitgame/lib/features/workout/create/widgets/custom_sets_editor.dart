import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';

/// Editable table of custom sets (reps, weight, warmup per set)
class CustomSetsEditor extends StatelessWidget {
  final List<Map<String, dynamic>> sets;
  final String weightType;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const CustomSetsEditor({
    super.key,
    required this.sets,
    required this.weightType,
    required this.onChanged,
  });

  void _updateSet(int index, Map<String, dynamic> updated) {
    final newSets = List<Map<String, dynamic>>.from(
      sets.map((s) => Map<String, dynamic>.from(s)),
    );
    newSets[index] = updated;
    onChanged(newSets);
  }

  void _removeSet(int index) {
    final newSets = List<Map<String, dynamic>>.from(
      sets.map((s) => Map<String, dynamic>.from(s)),
    );
    newSets.removeAt(index);
    onChanged(newSets);
  }

  void _addSet() {
    final newSets = List<Map<String, dynamic>>.from(
      sets.map((s) => Map<String, dynamic>.from(s)),
    );
    final lastSet = sets.isNotEmpty ? sets.last : {'reps': 10, 'weight': 0.0, 'isWarmup': false};
    newSets.add({
      'reps': lastSet['reps'] ?? 10,
      'weight': lastSet['weight'] ?? 0.0,
      'isWarmup': false,
    });
    onChanged(newSets);
  }

  @override
  Widget build(BuildContext context) {
    final isBodyweight = weightType == 'bodyweight';
    final weightLabel = weightType == 'bodyweight_plus' ? 'LEST' : 'POIDS';
    final weightUnit = weightType == 'bodyweight_plus' ? '+kg' : 'kg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FGGlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: FGColors.accent.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '#',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 70,
                      child: _HeaderLabel('REPS'),
                    ),
                    if (!isBodyweight)
                      SizedBox(
                        width: 90,
                        child: _HeaderLabel(weightLabel),
                      ),
                    const SizedBox(width: Spacing.sm),
                    const _HeaderLabel('W'),
                    const Spacer(),
                  ],
                ),
              ),
              // Set rows
              ...sets.asMap().entries.map((entry) {
                final i = entry.key;
                final set = entry.value;
                final isLast = i == sets.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    border: !isLast
                        ? Border(
                            bottom: BorderSide(color: FGColors.glassBorder),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Set number
                      SizedBox(
                        width: 36,
                        child: set['isWarmup'] == true
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: FGColors.warning.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'W',
                                  textAlign: TextAlign.center,
                                  style: FGTypography.caption.copyWith(
                                    color: FGColors.warning,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              )
                            : Text(
                                '${i + 1}',
                                style: FGTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                      // Reps input
                      SizedBox(
                        width: 70,
                        child: _CompactInput(
                          value: set['reps'] as int? ?? 10,
                          suffix: set['isMaxReps'] == true ? 'MAX' : null,
                          onChanged: (v) {
                            final updated = Map<String, dynamic>.from(set);
                            updated['reps'] = v;
                            _updateSet(i, updated);
                          },
                        ),
                      ),
                      // Weight input
                      if (!isBodyweight)
                        SizedBox(
                          width: 90,
                          child: _CompactWeightInput(
                            value: (set['weight'] as num?)?.toDouble() ?? 0,
                            unit: weightUnit,
                            onChanged: (v) {
                              final updated = Map<String, dynamic>.from(set);
                              updated['weight'] = v;
                              _updateSet(i, updated);
                            },
                          ),
                        ),
                      const SizedBox(width: Spacing.sm),
                      // Warmup toggle
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final updated = Map<String, dynamic>.from(set);
                          updated['isWarmup'] = !(set['isWarmup'] == true);
                          _updateSet(i, updated);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: set['isWarmup'] == true
                                ? FGColors.warning.withValues(alpha: 0.2)
                                : FGColors.glassSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: set['isWarmup'] == true
                                  ? FGColors.warning
                                  : FGColors.glassBorder,
                            ),
                          ),
                          child: Icon(
                            Icons.whatshot_rounded,
                            size: 14,
                            color: set['isWarmup'] == true
                                ? FGColors.warning
                                : FGColors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Delete button
                      if (sets.length > 1)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _removeSet(i);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: FGColors.textSecondary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        // Add set button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _addSet();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            decoration: BoxDecoration(
              border: Border.all(
                color: FGColors.accent.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(Spacing.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: FGColors.accent,
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  'Ajouter une série',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  const _HeaderLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: FGTypography.caption.copyWith(
        color: FGColors.accent,
        fontWeight: FontWeight.w700,
        fontSize: 10,
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  final int value;
  final String? suffix;
  final ValueChanged<int> onChanged;

  const _CompactInput({
    required this.value,
    this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (suffix != null) {
      return Container(
        height: 32,
        alignment: Alignment.center,
        child: Text(
          suffix!,
          style: FGTypography.caption.copyWith(
            color: FGColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (value > 1) {
              HapticFeedback.selectionClick();
              onChanged(value - 1);
            }
          },
          child: Icon(Icons.remove, size: 14, color: FGColors.textSecondary),
        ),
        Expanded(
          child: Container(
            height: 32,
            alignment: Alignment.center,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(value + 1);
          },
          child: Icon(Icons.add, size: 14, color: FGColors.textSecondary),
        ),
      ],
    );
  }
}

class _CompactWeightInput extends StatelessWidget {
  final double value;
  final String unit;
  final ValueChanged<double> onChanged;

  const _CompactWeightInput({
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged((value - 2.5).clamp(0, 500));
          },
          child: Icon(Icons.remove, size: 14, color: FGColors.textSecondary),
        ),
        Expanded(
          child: Container(
            height: 32,
            alignment: Alignment.center,
            child: Text(
              value == value.toInt().toDouble()
                  ? '${value.toInt()}'
                  : value.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: FGColors.accent,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged((value + 2.5).clamp(0, 500));
          },
          child: Icon(Icons.add, size: 14, color: FGColors.textSecondary),
        ),
      ],
    );
  }
}
