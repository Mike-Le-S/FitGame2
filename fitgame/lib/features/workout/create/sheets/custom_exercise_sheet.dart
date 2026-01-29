import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_neon_button.dart';
import '../utils/exercise_catalog.dart';
import '../widgets/number_picker.dart';

/// Bottom sheet for adding a custom exercise
class CustomExerciseSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> exercise) onAdd;

  const CustomExerciseSheet({
    super.key,
    required this.onAdd,
  });

  @override
  State<CustomExerciseSheet> createState() => _CustomExerciseSheetState();
}

class _CustomExerciseSheetState extends State<CustomExerciseSheet> {
  final _nameController = TextEditingController();
  String _selectedMuscle = 'Pectoraux';
  int _sets = 3;
  int _reps = 10;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text('Exercice personnalisé', style: FGTypography.h3),
            const SizedBox(height: Spacing.lg),
            // Name input
            Container(
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(Spacing.md),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: TextField(
                controller: _nameController,
                style: FGTypography.body,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nom de l\'exercice',
                  hintStyle: FGTypography.body.copyWith(
                    color: FGColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(Spacing.md),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            // Muscle selector
            Text(
              'GROUPE MUSCULAIRE',
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: ExerciseCatalog.muscleGroups.map((muscle) {
                final isSelected = muscle == _selectedMuscle;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedMuscle = muscle);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FGColors.accent.withValues(alpha: 0.2)
                          : FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      border: Border.all(
                        color: isSelected ? FGColors.accent : FGColors.glassBorder,
                      ),
                    ),
                    child: Text(
                      muscle,
                      style: FGTypography.bodySmall.copyWith(
                        color: isSelected ? FGColors.accent : FGColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Spacing.lg),
            // Sets & Reps
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SÉRIES',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      ExpandedNumberPicker(
                        value: _sets,
                        min: 1,
                        max: 10,
                        onChanged: (v) => setState(() => _sets = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RÉPÉTITIONS',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      ExpandedNumberPicker(
                        value: _reps,
                        min: 1,
                        max: 30,
                        onChanged: (v) => setState(() => _reps = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            FGNeonButton(
              label: 'Ajouter',
              isExpanded: true,
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  widget.onAdd({
                    'name': _nameController.text.trim(),
                    'muscle': _selectedMuscle,
                    'sets': _sets,
                    'reps': _reps,
                    'mode': 'classic',
                    'warmup': false,
                  });
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }
}

/// Show the custom exercise sheet
Future<void> showCustomExerciseSheet(
  BuildContext context, {
  required void Function(Map<String, dynamic> exercise) onAdd,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => CustomExerciseSheet(onAdd: onAdd),
  );
}
