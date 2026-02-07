import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';
import '../utils/exercise_calculator.dart';

/// Reorderable list of exercises for a single day
class DayExerciseList extends StatelessWidget {
  final int day;
  final List<Map<String, dynamic>> exercises;
  final Set<int> selectedForSuperset;
  final List<List<int>> supersets;
  final VoidCallback? onCreateSuperset;
  final VoidCallback onAddCustomExercise;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onRemove;
  final void Function(int index, Map<String, dynamic> exercise) onConfigure;
  final void Function(int index) onToggleSupersetSelection;

  const DayExerciseList({
    super.key,
    required this.day,
    required this.exercises,
    required this.selectedForSuperset,
    required this.supersets,
    this.onCreateSuperset,
    required this.onAddCustomExercise,
    required this.onReorder,
    required this.onRemove,
    required this.onConfigure,
    required this.onToggleSupersetSelection,
  });

  int _getSupersetIndex(int exerciseIndex) {
    for (int i = 0; i < supersets.length; i++) {
      if (supersets[i].contains(exerciseIndex)) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SÉANCE DU JOUR',
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            // Superset button
            if (selectedForSuperset.length >= 2 && onCreateSuperset != null)
              GestureDetector(
                onTap: onCreateSuperset,
                child: Container(
                  margin: const EdgeInsets.only(right: Spacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        FGColors.success,
                        FGColors.success.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(Spacing.xs),
                    boxShadow: [
                      BoxShadow(
                        color: FGColors.success.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        color: FGColors.textOnAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Créer superset',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textOnAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            GestureDetector(
              onTap: onAddCustomExercise,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: FGColors.accent.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(Spacing.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: FGColors.accent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Personnalisé',
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
        ),
        const SizedBox(height: Spacing.md),
        FGGlassCard(
          padding: EdgeInsets.zero,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercises.length,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.mediumImpact();
              if (newIndex > oldIndex) newIndex--;
              onReorder(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                elevation: 8,
                shadowColor: FGColors.accent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(Spacing.sm),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _DayExerciseItem(
                key: ValueKey('${day}_${exercise['name']}_$index'),
                exercise: exercise,
                index: index,
                total: exercises.length,
                isSelected: selectedForSuperset.contains(index),
                supersetIndex: _getSupersetIndex(index),
                onLongPress: () => onToggleSupersetSelection(index),
                onConfigure: () => onConfigure(index, exercise),
                onRemove: () => onRemove(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayExerciseItem extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final int index;
  final int total;
  final bool isSelected;
  final int supersetIndex;
  final VoidCallback onLongPress;
  final VoidCallback onConfigure;
  final VoidCallback onRemove;

  const _DayExerciseItem({
    super.key,
    required this.exercise,
    required this.index,
    required this.total,
    required this.isSelected,
    required this.supersetIndex,
    required this.onLongPress,
    required this.onConfigure,
    required this.onRemove,
  });

  String _buildCustomSetsSummary(List customSets) {
    if (customSets.isEmpty) return '';
    final count = customSets.length;
    final weights = customSets
        .where((s) => s['isWarmup'] != true)
        .map((s) => (s['weight'] as num?)?.toDouble() ?? 0.0)
        .where((w) => w > 0)
        .toList();
    if (weights.isEmpty) return '$count×';
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final minStr = minW == minW.roundToDouble() ? minW.toInt().toString() : minW.toString();
    final maxStr = maxW == maxW.roundToDouble() ? maxW.toInt().toString() : maxW.toString();
    if (minW == maxW) return '$count× ${minStr}kg';
    return '$count× $minStr→${maxStr}kg';
  }

  @override
  Widget build(BuildContext context) {
    final mode = exercise['mode'] ?? 'classic';
    final hasWarmup = exercise['warmup'] ?? false;
    final customSets = exercise['customSets'] as List?;
    final hasCustomSets = customSets != null && customSets.isNotEmpty;
    final notes = exercise['notes'] as String? ?? '';
    final hasNotes = notes.isNotEmpty;
    final weightType = exercise['weightType'] as String? ?? 'kg';
    final isBodyweight = weightType == 'bodyweight' || weightType == 'bodyweight_plus';

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? FGColors.success.withValues(alpha: 0.08) : null,
          border: Border(
            left: supersetIndex >= 0
                ? BorderSide(
                    color: FGColors.success,
                    width: 3,
                  )
                : BorderSide.none,
            bottom: index < total - 1
                ? BorderSide(color: FGColors.glassBorder)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Superset indicator or drag handle
            if (supersetIndex >= 0)
              Container(
                margin: const EdgeInsets.only(right: Spacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: FGColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'S${supersetIndex + 1}',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              )
            else
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(Spacing.xs),
                  child: const Icon(
                    Icons.drag_indicator_rounded,
                    color: FGColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            const SizedBox(width: Spacing.sm),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.accent.withValues(alpha: 0.2),
                    FGColors.accent.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name'] as String,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          exercise['muscle'] as String,
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasCustomSets) ...[
                        Text(
                          ' • ',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _buildCustomSetsSummary(customSets),
                          style: FGTypography.caption.copyWith(
                            color: FGColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else if (mode != 'classic') ...[
                        Text(
                          ' • ',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          ExerciseCalculator.getModeLabel(mode),
                          style: FGTypography.caption.copyWith(
                            color: FGColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (hasWarmup) ...[
                        Text(
                          ' • ',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Warmup',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (isBodyweight) ...[
                        const SizedBox(width: Spacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: FGColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'PDC',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      if (hasNotes) ...[
                        const SizedBox(width: Spacing.xs),
                        Icon(
                          Icons.note_alt_outlined,
                          color: FGColors.textSecondary,
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            GestureDetector(
              onTap: onConfigure,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.tune_rounded,
                  color: FGColors.accent,
                  size: 18,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onRemove();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.close_rounded,
                  color: FGColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
