import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../../../shared/widgets/fg_neon_button.dart';
import '../tracking/active_workout_screen.dart';

/// Quick single session creation screen
class SessionCreationScreen extends StatefulWidget {
  const SessionCreationScreen({super.key});

  @override
  State<SessionCreationScreen> createState() => _SessionCreationScreenState();
}

class _SessionCreationScreenState extends State<SessionCreationScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late AnimationController _fadeController;

  String _sessionName = '';
  final List<Map<String, dynamic>> _exercises = [];
  final List<String> _selectedMuscles = [];

  final List<Map<String, dynamic>> _muscleGroups = [
    {'name': 'Pectoraux', 'icon': Icons.fitness_center},
    {'name': 'Dos', 'icon': Icons.fitness_center},
    {'name': 'Épaules', 'icon': Icons.fitness_center},
    {'name': 'Biceps', 'icon': Icons.fitness_center},
    {'name': 'Triceps', 'icon': Icons.fitness_center},
    {'name': 'Jambes', 'icon': Icons.fitness_center},
    {'name': 'Abdos', 'icon': Icons.fitness_center},
  ];

  final List<Map<String, dynamic>> _suggestedExercises = [
    {'name': 'Développé couché', 'muscle': 'Pectoraux', 'sets': 4, 'reps': 10},
    {'name': 'Squat barre', 'muscle': 'Jambes', 'sets': 4, 'reps': 8},
    {'name': 'Rowing barre', 'muscle': 'Dos', 'sets': 4, 'reps': 10},
    {'name': 'Développé militaire', 'muscle': 'Épaules', 'sets': 3, 'reps': 12},
    {'name': 'Curl biceps', 'muscle': 'Biceps', 'sets': 3, 'reps': 12},
    {'name': 'Extension triceps', 'muscle': 'Triceps', 'sets': 3, 'reps': 12},
    {'name': 'Soulevé de terre', 'muscle': 'Dos', 'sets': 4, 'reps': 6},
    {'name': 'Presse jambes', 'muscle': 'Jambes', 'sets': 4, 'reps': 12},
    {'name': 'Tractions', 'muscle': 'Dos', 'sets': 4, 'reps': 8},
    {'name': 'Dips', 'muscle': 'Triceps', 'sets': 3, 'reps': 10},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredExercises {
    if (_selectedMuscles.isEmpty) return _suggestedExercises;
    return _suggestedExercises
        .where((e) => _selectedMuscles.contains(e['muscle']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          _buildMeshGradient(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Spacing.md),
                          Text(
                            'Nouvelle\nséance',
                            style: FGTypography.h1.copyWith(
                              fontSize: 32,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: Spacing.xxl),
                          _buildNameInput(),
                          const SizedBox(height: Spacing.xxl),
                          _buildMuscleSelector(),
                          const SizedBox(height: Spacing.xxl),
                          _buildExercisesList(),
                          const SizedBox(height: Spacing.xxl),
                          if (_exercises.isNotEmpty) _buildSelectedExercises(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomAction(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshGradient() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 350,
        height: 350,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              FGColors.accent.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.lg, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(Spacing.sm),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: FGColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          if (_exercises.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: FGColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Text(
                '${_exercises.length} exercice${_exercises.length > 1 ? 's' : ''}',
                style: FGTypography.caption.copyWith(
                  color: FGColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOM DE LA SÉANCE',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Container(
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.md),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: TextField(
            controller: _nameController,
            style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Ex: Push Day, Jambes...',
              hintStyle: FGTypography.body.copyWith(
                color: FGColors.textSecondary.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(Spacing.md),
            ),
            onChanged: (value) => setState(() => _sessionName = value),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GROUPES MUSCULAIRES',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: _muscleGroups.map((muscle) {
            final isSelected = _selectedMuscles.contains(muscle['name']);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedMuscles.remove(muscle['name']);
                  } else {
                    _selectedMuscles.add(muscle['name'] as String);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            FGColors.accent,
                            FGColors.accent.withValues(alpha: 0.8),
                          ],
                        )
                      : null,
                  color: isSelected ? null : FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  border: Border.all(
                    color: isSelected ? FGColors.accent : FGColors.glassBorder,
                  ),
                ),
                child: Text(
                  muscle['name'] as String,
                  style: FGTypography.body.copyWith(
                    color:
                        isSelected ? FGColors.textOnAccent : FGColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExercisesList() {
    final exercises = _filteredExercises;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'EXERCICES SUGGÉRÉS',
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showAddCustomExercise(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: FGColors.glassBorder),
                  borderRadius: BorderRadius.circular(Spacing.xs),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: FGColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      'Personnalisé',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        ...exercises.map((exercise) {
          final isAdded =
              _exercises.any((e) => e['name'] == exercise['name']);
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: _buildExerciseItem(exercise, isAdded),
          );
        }),
        if (exercises.isEmpty)
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              color: FGColors.glassSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Spacing.md),
              border: Border.all(color: FGColors.glassBorder),
            ),
            child: Center(
              child: Text(
                'Aucun exercice pour ce groupe musculaire',
                style: FGTypography.body.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseItem(Map<String, dynamic> exercise, bool isAdded) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          if (isAdded) {
            _exercises.removeWhere((e) => e['name'] == exercise['name']);
          } else {
            _exercises.add(Map.from(exercise));
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isAdded
              ? FGColors.success.withValues(alpha: 0.08)
              : FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isAdded
                ? FGColors.success.withValues(alpha: 0.3)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isAdded
                    ? FGColors.success.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Icon(
                isAdded ? Icons.check_rounded : Icons.add_rounded,
                color: isAdded ? FGColors.success : FGColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name'] as String,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isAdded ? FGColors.textPrimary : FGColors.textPrimary,
                    ),
                  ),
                  Text(
                    exercise['muscle'] as String,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${exercise['sets']}x${exercise['reps']}',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedExercises() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TA SÉANCE',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: Spacing.md),
        FGGlassCard(
          padding: EdgeInsets.zero,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exercises.length,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.mediumImpact();
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _exercises.removeAt(oldIndex);
                _exercises.insert(newIndex, item);
              });
            },
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final exercise = _exercises[index];
              return Container(
                key: ValueKey(exercise['name']),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  border: index < _exercises.length - 1
                      ? Border(
                          bottom: BorderSide(color: FGColors.glassBorder),
                        )
                      : null,
                ),
                child: Row(
                  children: [
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
                        color: FGColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(Spacing.xs),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(
                        exercise['name'] as String,
                        style: FGTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${exercise['sets']}x${exercise['reps']}',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _exercises.removeAt(index);
                        });
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: FGColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final canCreate = _sessionName.trim().isNotEmpty && _exercises.isNotEmpty;

    return Container(
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
        label: 'Créer la séance',
        isExpanded: true,
        onPressed: canCreate ? _createAndStartSession : null,
      ),
    );
  }

  Future<void> _createAndStartSession() async {
    HapticFeedback.heavyImpact();

    // Format exercises for Supabase
    final exercisesData = _exercises.map((e) => {
      'name': e['name'],
      'muscleGroup': e['muscle'],
      'sets': e['sets'],
      'reps': e['reps'],
    }).toList();

    try {
      // Create session in Supabase
      await SupabaseService.startWorkoutSession(
        dayName: _sessionName.trim(),
        exercises: exercisesData,
      );

      if (mounted) {
        // Navigate to active workout (single atomic operation)
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ActiveWorkoutScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la création de la séance'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showAddCustomExercise() {
    final nameController = TextEditingController();
    int sets = 3;
    int reps = 10;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
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
                Container(
                  decoration: BoxDecoration(
                    color: FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.md),
                    border: Border.all(color: FGColors.glassBorder),
                  ),
                  child: TextField(
                    controller: nameController,
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
                const SizedBox(height: Spacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Séries',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          _buildSheetNumberPicker(
                            value: sets,
                            min: 1,
                            max: 10,
                            onChanged: (v) => setSheetState(() => sets = v),
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
                            'Répétitions',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          _buildSheetNumberPicker(
                            value: reps,
                            min: 1,
                            max: 30,
                            onChanged: (v) => setSheetState(() => reps = v),
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
                    if (nameController.text.trim().isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _exercises.add({
                          'name': nameController.text.trim(),
                          'muscle': 'Personnalisé',
                          'sets': sets,
                          'reps': reps,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: Spacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetNumberPicker({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (value > min) {
                  HapticFeedback.selectionClick();
                  onChanged(value - 1);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                child: const Icon(
                  Icons.remove_rounded,
                  color: FGColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
          Text(
            '$value',
            style: FGTypography.h3.copyWith(
              color: FGColors.accent,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (value < max) {
                  HapticFeedback.selectionClick();
                  onChanged(value + 1);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                child: const Icon(
                  Icons.add_rounded,
                  color: FGColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
