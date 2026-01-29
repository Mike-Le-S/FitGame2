import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';
import '../../../../shared/widgets/fg_neon_button.dart';
import '../utils/exercise_calculator.dart';
import '../widgets/mode_card.dart';
import '../widgets/number_picker.dart';
import '../widgets/toggle_card.dart';

/// Bottom sheet for configuring an exercise (mode, sets, reps, warmup)
class ExerciseConfigSheet extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final void Function(Map<String, dynamic> config) onSave;

  const ExerciseConfigSheet({
    super.key,
    required this.exercise,
    required this.onSave,
  });

  @override
  State<ExerciseConfigSheet> createState() => _ExerciseConfigSheetState();
}

class _ExerciseConfigSheetState extends State<ExerciseConfigSheet> {
  late String _selectedMode;
  late bool _warmupEnabled;
  late int _sets;
  late int _reps;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.exercise['mode'] ?? 'classic';
    _warmupEnabled = widget.exercise['warmup'] ?? false;
    _sets = widget.exercise['sets'] ?? 3;
    _reps = widget.exercise['reps'] ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate preview sets based on mode
    final previewSets = ExerciseCalculator.calculateSets(
      mode: _selectedMode,
      sets: _sets,
      reps: _reps,
      warmup: _warmupEnabled,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: Spacing.md),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exercise['name'] as String,
                  style: FGTypography.h3,
                ),
                Text(
                  widget.exercise['muscle'] as String,
                  style: FGTypography.bodySmall.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode selector
                  Text(
                    'MODE D\'ENTRAÎNEMENT',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  ModeCard(
                    mode: 'classic',
                    label: 'Classique',
                    description: 'Séries × Reps avec même poids',
                    icon: Icons.fitness_center,
                    isSelected: _selectedMode == 'classic',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMode = 'classic');
                    },
                  ),
                  const SizedBox(height: Spacing.sm),
                  ModeCard(
                    mode: 'rpt',
                    label: 'RPT',
                    description: 'Reverse Pyramid: -10% poids, -2 reps par série',
                    icon: Icons.trending_down,
                    isSelected: _selectedMode == 'rpt',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMode = 'rpt');
                    },
                  ),
                  const SizedBox(height: Spacing.sm),
                  ModeCard(
                    mode: 'pyramid',
                    label: 'Pyramidal',
                    description: 'Montée progressive en poids, descente en reps',
                    icon: Icons.trending_up,
                    isSelected: _selectedMode == 'pyramid',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMode = 'pyramid');
                    },
                  ),
                  const SizedBox(height: Spacing.sm),
                  ModeCard(
                    mode: 'dropset',
                    label: 'Dropset',
                    description: 'Série principale + 3 drops à -20%, -40%, -60%',
                    icon: Icons.arrow_downward,
                    isSelected: _selectedMode == 'dropset',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMode = 'dropset');
                    },
                  ),

                  const SizedBox(height: Spacing.xl),

                  // Base sets/reps config (only for non-pyramid modes)
                  if (_selectedMode != 'pyramid' && _selectedMode != 'dropset') ...[
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
                  ],

                  // Warmup toggle (not for pyramid - it's built-in)
                  if (_selectedMode != 'pyramid')
                    ToggleCard(
                      icon: Icons.local_fire_department,
                      title: 'Échauffement adaptatif',
                      subtitle: ExerciseCalculator.getWarmupDescription(_selectedMode),
                      value: _warmupEnabled,
                      onChanged: (v) => setState(() => _warmupEnabled = v),
                      activeColor: FGColors.warning,
                    ),

                  const SizedBox(height: Spacing.xl),

                  // Preview section
                  Text(
                    'APERÇU DES SÉRIES',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  _SetsPreviewTable(sets: previewSets),

                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FGColors.background.withValues(alpha: 0),
                  FGColors.background,
                ],
              ),
            ),
            child: FGNeonButton(
              label: 'Enregistrer',
              isExpanded: true,
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onSave({
                  'mode': _selectedMode,
                  'warmup': _warmupEnabled,
                  'sets': _sets,
                  'reps': _reps,
                });
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SetsPreviewTable extends StatelessWidget {
  final List<Map<String, dynamic>> sets;

  const _SetsPreviewTable({required this.sets});

  @override
  Widget build(BuildContext context) {
    return FGGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.accent.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'SÉRIE',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'POIDS',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.right,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ...sets.asMap().entries.map((entry) {
            final i = entry.key;
            final set = entry.value;
            final isLast = i == sets.length - 1;
            return Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                border: !isLast
                    ? Border(
                        bottom: BorderSide(
                          color: FGColors.glassBorder,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Row(
                      children: [
                        if (set['warmup'] == true)
                          Container(
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
                              style: FGTypography.caption.copyWith(
                                color: FGColors.warning,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          )
                        else
                          Text(
                            '${set['number']}',
                            style: FGTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      set['weight'] as String,
                      style: FGTypography.body.copyWith(
                        color: FGColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${set['reps']}',
                      textAlign: TextAlign.right,
                      style: FGTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Show the exercise config sheet
Future<void> showExerciseConfigSheet(
  BuildContext context, {
  required Map<String, dynamic> exercise,
  required void Function(Map<String, dynamic> config) onSave,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ExerciseConfigSheet(
      exercise: exercise,
      onSave: onSave,
    ),
  );
}
