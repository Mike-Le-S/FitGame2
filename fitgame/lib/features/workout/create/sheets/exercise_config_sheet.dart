import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_glass_card.dart';
import '../../../../shared/widgets/fg_neon_button.dart';
import '../utils/exercise_calculator.dart';
import '../widgets/custom_sets_editor.dart';

/// Bottom sheet for configuring an exercise (mode, sets, reps, warmup, notes, progression)
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
  late String _weightType;
  late int _restSeconds;
  late List<Map<String, dynamic>> _customSets;
  late TextEditingController _notesController;
  late TextEditingController _progressionController;
  bool _showNotes = false;
  bool _showProgression = false;

  // Progression structured config
  String _progressionType = 'none';
  int _repThreshold = 8;
  double _weightIncrement = 2.5;

  static int _toInt(dynamic val, int fallback) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.exercise['mode'] ?? 'classic';
    _warmupEnabled = widget.exercise['warmup'] ?? widget.exercise['warmupEnabled'] ?? false;
    _sets = _toInt(widget.exercise['sets'], 3);
    _reps = _toInt(widget.exercise['reps'], 10);
    _weightType = widget.exercise['weightType'] ?? 'kg';
    _restSeconds = _toInt(widget.exercise['restSeconds'], 90);

    _notesController = TextEditingController(text: widget.exercise['notes'] ?? '');
    _progressionController = TextEditingController(text: widget.exercise['progressionRule'] ?? '');

    _showNotes = _notesController.text.isNotEmpty;
    _showProgression = _progressionController.text.isNotEmpty;

    // Load progression config
    final prog = widget.exercise['progression'] as Map<String, dynamic>?;
    if (prog != null) {
      _progressionType = prog['type'] ?? 'none';
      _repThreshold = prog['repThreshold'] ?? 8;
      _weightIncrement = (prog['weightIncrement'] as num?)?.toDouble() ?? 2.5;
      _showProgression = true;
    }

    // Load custom sets
    final existing = widget.exercise['customSets'] as List?;
    if (existing != null) {
      _customSets = existing.map((s) => Map<String, dynamic>.from(s as Map)).toList();
    } else {
      _customSets = ExerciseCalculator.generateCustomSets(
        mode: _selectedMode,
        sets: _sets,
        reps: _reps,
        baseWeight: 0,
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _progressionController.dispose();
    super.dispose();
  }

  void _onModeChanged(String mode) async {
    if (_selectedMode == 'custom') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FGColors.glassSurface,
          title: Text('Changer de mode ?', style: FGTypography.h3),
          content: Text(
            'Tes séries personnalisées seront remplacées par le template "$mode".',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler', style: TextStyle(color: FGColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Remplacer', style: TextStyle(color: FGColors.accent)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMode = mode;
      if (mode != 'custom') {
        _customSets = ExerciseCalculator.generateCustomSets(
          mode: mode,
          sets: _sets,
          reps: _reps,
          baseWeight: _customSets.isNotEmpty
              ? (_customSets.first['weight'] as num?)?.toDouble() ?? 0
              : 0,
        );
      }
    });
  }

  List<Map<String, dynamic>> _calculateWarmupPreview() {
    if (_customSets.isEmpty) return [];

    // Find max weight among work sets
    final maxWeight = _customSets
        .where((s) => s['isWarmup'] != true)
        .map((s) => (s['weight'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (max, w) => w > max ? w : max);

    if (maxWeight <= 0) return [];

    double roundTo2_5(double v) => (v / 2.5).round() * 2.5;

    if (maxWeight >= 60) {
      return [
        {'reps': 10, 'weight': roundTo2_5(maxWeight * 0.4)},
        {'reps': 5, 'weight': roundTo2_5(maxWeight * 0.6)},
        {'reps': 3, 'weight': roundTo2_5(maxWeight * 0.8)},
      ];
    } else {
      return [
        {'reps': 8, 'weight': roundTo2_5(maxWeight * 0.5)},
        {'reps': 3, 'weight': roundTo2_5(maxWeight * 0.75)},
      ];
    }
  }

  void _onCustomSetsChanged(List<Map<String, dynamic>> newSets) {
    setState(() {
      _customSets = newSets;
      _selectedMode = 'custom';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                  // === WEIGHT TYPE ===
                  _SectionLabel('TYPE DE POIDS'),
                  const SizedBox(height: Spacing.sm),
                  _buildWeightTypeSelector(),
                  const SizedBox(height: Spacing.xl),

                  // === MODE ===
                  _SectionLabel('MODE D\'ENTRAÎNEMENT'),
                  const SizedBox(height: Spacing.md),
                  _buildModeSelector(),
                  const SizedBox(height: Spacing.xl),

                  // === CUSTOM SETS TABLE ===
                  _SectionLabel('SÉRIES'),
                  const SizedBox(height: Spacing.md),
                  CustomSetsEditor(
                    sets: _customSets,
                    weightType: _weightType,
                    onChanged: _onCustomSetsChanged,
                    warmupPreview: _warmupEnabled ? _calculateWarmupPreview() : [],
                  ),
                  const SizedBox(height: Spacing.xl),

                  // === REST ===
                  _SectionLabel('REPOS ENTRE SÉRIES'),
                  const SizedBox(height: Spacing.sm),
                  _buildRestPicker(),
                  const SizedBox(height: Spacing.xl),

                  // === WARMUP ===
                  GestureDetector(
                    onTap: () => setState(() => _warmupEnabled = !_warmupEnabled),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: _warmupEnabled
                            ? FGColors.warning.withValues(alpha: 0.1)
                            : FGColors.glassSurface,
                        borderRadius: BorderRadius.circular(Spacing.md),
                        border: Border.all(
                          color: _warmupEnabled
                              ? FGColors.warning.withValues(alpha: 0.4)
                              : FGColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.whatshot_rounded,
                            color: _warmupEnabled ? FGColors.warning : FGColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Échauffement auto',
                                  style: FGTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _warmupEnabled ? FGColors.textPrimary : FGColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Séries progressives avant les séries de travail',
                                  style: FGTypography.caption.copyWith(
                                    color: FGColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _warmupEnabled,
                            onChanged: (v) => setState(() => _warmupEnabled = v),
                            activeThumbColor: FGColors.warning,
                            activeTrackColor: FGColors.warning.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),

                  // === NOTES (collapsible) ===
                  _buildCollapsibleSection(
                    title: 'NOTES / CONSIGNES',
                    icon: Icons.edit_note_rounded,
                    isExpanded: _showNotes,
                    onToggle: () => setState(() => _showNotes = !_showNotes),
                    child: Container(
                      decoration: BoxDecoration(
                        color: FGColors.glassSurface,
                        borderRadius: BorderRadius.circular(Spacing.sm),
                        border: Border.all(color: FGColors.glassBorder),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: FGTypography.bodySmall,
                        decoration: InputDecoration(
                          hintText: 'Ex: Buste penché, 2-3 min repos sur les lourdes...',
                          hintStyle: FGTypography.bodySmall.copyWith(
                            color: FGColors.textSecondary.withValues(alpha: 0.4),
                          ),
                          contentPadding: const EdgeInsets.all(Spacing.md),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // === PROGRESSION (collapsible) ===
                  _buildCollapsibleSection(
                    title: 'RÈGLE DE PROGRESSION',
                    icon: Icons.trending_up_rounded,
                    isExpanded: _showProgression,
                    onToggle: () => setState(() => _showProgression = !_showProgression),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: FGColors.glassSurface,
                            borderRadius: BorderRadius.circular(Spacing.sm),
                            border: Border.all(color: FGColors.glassBorder),
                          ),
                          child: TextField(
                            controller: _progressionController,
                            maxLines: 2,
                            style: FGTypography.bodySmall,
                            decoration: InputDecoration(
                              hintText: 'Ex: Quand 7 reps @97kg → passe à 100kg',
                              hintStyle: FGTypography.bodySmall.copyWith(
                                color: FGColors.textSecondary.withValues(alpha: 0.4),
                              ),
                              contentPadding: const EdgeInsets.all(Spacing.md),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                        // Structured progression
                        _buildProgressionConfig(),
                      ],
                    ),
                  ),
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
                final config = <String, dynamic>{
                  'mode': _selectedMode,
                  'warmup': _warmupEnabled,
                  'sets': _customSets.length,
                  'reps': _reps,
                  'weightType': _weightType,
                  'restSeconds': _restSeconds,
                  'customSets': _customSets,
                  'notes': _notesController.text.trim(),
                  'progressionRule': _progressionController.text.trim(),
                };

                if (_progressionType != 'none') {
                  config['progression'] = {
                    'type': _progressionType,
                    'repThreshold': _repThreshold,
                    'weightIncrement': _weightIncrement,
                  };
                }

                widget.onSave(config);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTypeSelector() {
    return Row(
      children: [
        _WeightTypeChip(
          label: 'Kg',
          icon: Icons.fitness_center,
          isSelected: _weightType == 'kg',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _weightType = 'kg');
          },
        ),
        const SizedBox(width: Spacing.sm),
        _WeightTypeChip(
          label: 'PDC',
          icon: Icons.accessibility_new_rounded,
          isSelected: _weightType == 'bodyweight',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _weightType = 'bodyweight');
          },
        ),
        const SizedBox(width: Spacing.sm),
        _WeightTypeChip(
          label: 'PDC + Lest',
          icon: Icons.add_circle_outline,
          isSelected: _weightType == 'bodyweight_plus',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _weightType = 'bodyweight_plus');
          },
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        _ModeChip(label: 'Classique', isSelected: _selectedMode == 'classic', onTap: () => _onModeChanged('classic')),
        _ModeChip(label: 'RPT', isSelected: _selectedMode == 'rpt', onTap: () => _onModeChanged('rpt')),
        _ModeChip(label: 'Pyramidal', isSelected: _selectedMode == 'pyramid', onTap: () => _onModeChanged('pyramid')),
        _ModeChip(label: 'Dropset', isSelected: _selectedMode == 'dropset', onTap: () => _onModeChanged('dropset')),
        if (_selectedMode == 'custom')
          _ModeChip(label: 'Personnalisé', isSelected: true, onTap: () {}),
      ],
    );
  }

  Widget _buildRestPicker() {
    return FGGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: FGColors.textSecondary),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              _restSeconds >= 60
                  ? '${_restSeconds ~/ 60} min ${_restSeconds % 60 > 0 ? '${_restSeconds % 60}s' : ''}'
                  : '${_restSeconds}s',
              style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _restSeconds = (_restSeconds - 15).clamp(15, 300));
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: const Icon(Icons.remove, size: 16, color: FGColors.textSecondary),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _restSeconds = (_restSeconds + 15).clamp(15, 300));
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: const Icon(Icons.add, size: 16, color: FGColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Icon(icon, size: 16, color: FGColors.textSecondary),
              const SizedBox(width: Spacing.sm),
              Text(
                title,
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: FGColors.textSecondary,
              ),
            ],
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: Spacing.sm),
          child,
        ],
      ],
    );
  }

  Widget _buildProgressionConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESSION AUTO',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            _ModeChip(
              label: 'Aucune',
              isSelected: _progressionType == 'none',
              onTap: () => setState(() => _progressionType = 'none'),
            ),
            _ModeChip(
              label: 'Seuil reps',
              isSelected: _progressionType == 'threshold',
              onTap: () => setState(() => _progressionType = 'threshold'),
            ),
          ],
        ),
        if (_progressionType == 'threshold') ...[
          const SizedBox(height: Spacing.md),
          FGGlassCard(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Si reps ≥',
                        style: FGTypography.bodySmall.copyWith(
                          color: FGColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: _InlineNumberPicker(
                        value: _repThreshold,
                        min: 1,
                        max: 30,
                        onChanged: (v) => setState(() => _repThreshold = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Augmenter de',
                        style: FGTypography.bodySmall.copyWith(
                          color: FGColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: _InlineWeightPicker(
                        value: _weightIncrement,
                        onChanged: (v) => setState(() => _weightIncrement = v),
                      ),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      'kg',
                      style: FGTypography.bodySmall.copyWith(
                        color: FGColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: FGTypography.caption.copyWith(
        color: FGColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _WeightTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeightTypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? FGColors.accent.withValues(alpha: 0.15)
                : FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.sm),
            border: Border.all(
              color: isSelected ? FGColors.accent : FGColors.glassBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? FGColors.accent : FGColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: FGTypography.caption.copyWith(
                  color: isSelected ? FGColors.accent : FGColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? FGColors.accent.withValues(alpha: 0.15)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(
            color: isSelected ? FGColors.accent : FGColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: FGTypography.bodySmall.copyWith(
            color: isSelected ? FGColors.accent : FGColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _InlineNumberPicker extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _InlineNumberPicker({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (value > min) onChanged(value - 1);
          },
          child: Icon(Icons.remove, size: 16, color: FGColors.textSecondary),
        ),
        Expanded(
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: FGTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (value < max) onChanged(value + 1);
          },
          child: Icon(Icons.add, size: 16, color: FGColors.textSecondary),
        ),
      ],
    );
  }
}

class _InlineWeightPicker extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _InlineWeightPicker({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (value > 0.5) onChanged(value - 0.5);
          },
          child: Icon(Icons.remove, size: 16, color: FGColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value == value.toInt().toDouble()
                ? '${value.toInt()}'
                : value.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: FGTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: FGColors.accent,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (value < 20) onChanged(value + 0.5);
          },
          child: Icon(Icons.add, size: 16, color: FGColors.textSecondary),
        ),
      ],
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
