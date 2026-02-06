import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/fg_neon_button.dart';

// Steps
import 'steps/name_step.dart';
import 'steps/cycle_step.dart';
import 'steps/days_step.dart';
import 'steps/exercises_step.dart';

// Sheets
import 'sheets/success_modal.dart';
import 'sheets/custom_exercise_sheet.dart';
import 'sheets/exercise_config_sheet.dart';

/// Multi-step program creation flow
class ProgramCreationFlow extends StatefulWidget {
  const ProgramCreationFlow({super.key});

  @override
  State<ProgramCreationFlow> createState() => _ProgramCreationFlowState();
}

class _ProgramCreationFlowState extends State<ProgramCreationFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Program data
  String _programName = '';
  bool _hasCycle = false;
  final List<int> _trainingDays = [1, 3, 5]; // Mon, Wed, Fri
  int _trainingWeeksBeforeDeload = 5;
  int _deloadPercentage = 60;

  // Exercises by day (key = day number 1-7)
  final Map<int, List<Map<String, dynamic>>> _exercisesByDay = {};
  int _selectedDayTab = 0;

  // Superset tracking
  final Map<int, List<List<int>>> _supersetsByDay = {};
  final Map<int, Set<int>> _selectedForSuperset = {};

  // Controllers
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // === Navigation ===

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
      // Initialize exercise maps when entering the exercises step (step 3)
      if (_currentStep == 3) {
        _initializeExercisesForDays();
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishCreation();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _isSaving = false;

  Future<void> _finishCreation() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      // Build days array for database
      final days = <Map<String, dynamic>>[];
      final sortedDays = List<int>.from(_trainingDays)..sort();

      for (int i = 0; i < sortedDays.length; i++) {
        final dayNumber = sortedDays[i];
        final exercises = _exercisesByDay[dayNumber] ?? [];
        final supersets = _supersetsByDay[dayNumber] ?? [];

        days.add({
          'id': 'day-$i',
          'name': _getDayName(dayNumber),
          'dayOfWeek': dayNumber,
          'isRestDay': false,
          'exercises': exercises.map((ex) => {
            'id': 'ex-${DateTime.now().millisecondsSinceEpoch}-${exercises.indexOf(ex)}',
            'name': ex['name'],
            'muscle': ex['muscle'] ?? 'other',
            'mode': ex['mode'] ?? 'classic',
            'sets': ex['sets'] ?? 3,
            'reps': ex['reps'] ?? 10,
            'warmupEnabled': ex['warmup'] ?? false,
          }).toList(),
          'supersets': supersets,
        });
      }

      // Save to Supabase
      await SupabaseService.createProgram(
        name: _programName,
        goal: 'bulk', // Default goal, could be added to the flow
        durationWeeks: _hasCycle ? _trainingWeeksBeforeDeload : 8,
        deloadFrequency: _hasCycle ? _trainingWeeksBeforeDeload : null,
        days: days,
      );

      if (mounted) {
        _showSuccessModal();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: FGColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getDayName(int dayNumber) {
    const names = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return names[dayNumber];
  }

  void _showSuccessModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (modalContext) => SuccessModal(
        programName: _programName,
        daysCount: _trainingDays.length,
        exercisesCount: _trainingDays.fold<int>(
          0,
          (sum, day) => sum + (_exercisesByDay[day]?.length ?? 0),
        ),
        onDismiss: () {
          Navigator.pop(modalContext); // Close modal
          Navigator.pop(context, true); // Close flow, return true to CreateChoiceScreen
          // CreateChoiceScreen._navigateTo will handle closing itself when it receives true
        },
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _programName.trim().isNotEmpty;
      case 1:
        return true;
      case 2:
        return _trainingDays.isNotEmpty;
      case 3:
        for (final day in _trainingDays) {
          final exercises = _exercisesByDay[day] ?? [];
          if (exercises.isEmpty) return false;
        }
        return true;
      default:
        return false;
    }
  }

  // === Exercise management ===

  void _initializeExercisesForDays() {
    final sortedDays = List<int>.from(_trainingDays)..sort();
    for (final day in sortedDays) {
      _exercisesByDay.putIfAbsent(day, () => []);
      _supersetsByDay.putIfAbsent(day, () => []);
      _selectedForSuperset.putIfAbsent(day, () => {});
    }
  }

  void _toggleExercise(int day, Map<String, dynamic> exercise, bool isAdded) {
    setState(() {
      if (isAdded) {
        _exercisesByDay[day]?.removeWhere((e) => e['name'] == exercise['name']);
      } else {
        _exercisesByDay[day]?.add(Map.from(exercise));
      }
    });
  }

  void _showAddCustomExercise(int day) {
    showCustomExerciseSheet(
      context,
      onAdd: (exercise) {
        setState(() {
          _exercisesByDay[day]?.add(exercise);
        });
      },
    );
  }

  void _showExerciseConfig(int day, int index, Map<String, dynamic> exercise) {
    showExerciseConfigSheet(
      context,
      exercise: exercise,
      onSave: (config) {
        setState(() {
          _exercisesByDay[day]?[index]['mode'] = config['mode'];
          _exercisesByDay[day]?[index]['warmup'] = config['warmup'];
          _exercisesByDay[day]?[index]['sets'] = config['sets'];
          _exercisesByDay[day]?[index]['reps'] = config['reps'];
        });
      },
    );
  }

  void _reorderExercise(int day, int oldIndex, int newIndex) {
    setState(() {
      final exercises = _exercisesByDay[day]!;
      final item = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, item);
    });
  }

  void _removeExercise(int day, int index) {
    setState(() {
      _exercisesByDay[day]?.removeAt(index);
      _selectedForSuperset[day]?.remove(index);
      _removeFromSupersets(day, index);
    });
  }

  void _toggleSupersetSelection(int day, int index) {
    setState(() {
      final selection = _selectedForSuperset[day] ?? {};
      if (selection.contains(index)) {
        selection.remove(index);
      } else {
        selection.add(index);
      }
      _selectedForSuperset[day] = selection;
    });
  }

  void _createSuperset(int day) {
    HapticFeedback.mediumImpact();
    final selected = List<int>.from(_selectedForSuperset[day] ?? {});
    if (selected.length >= 2) {
      selected.sort();
      setState(() {
        _supersetsByDay[day]?.add(selected);
        _selectedForSuperset[day]?.clear();
      });
    }
  }

  void _removeFromSupersets(int day, int removedIndex) {
    final supersets = _supersetsByDay[day] ?? [];
    for (int i = supersets.length - 1; i >= 0; i--) {
      supersets[i].remove(removedIndex);
      for (int j = 0; j < supersets[i].length; j++) {
        if (supersets[i][j] > removedIndex) {
          supersets[i][j]--;
        }
      }
      if (supersets[i].length < 2) {
        supersets.removeAt(i);
      }
    }
    final selected = _selectedForSuperset[day] ?? {};
    final newSelected = <int>{};
    for (final idx in selected) {
      if (idx > removedIndex) {
        newSelected.add(idx - 1);
      } else if (idx != removedIndex) {
        newSelected.add(idx);
      }
    }
    _selectedForSuperset[day] = newSelected;
  }

  // === Build ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          _buildMeshGradient(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      NameStep(
                        controller: _nameController,
                        programName: _programName,
                        onNameChanged: (value) =>
                            setState(() => _programName = value),
                      ),
                      CycleStep(
                        hasCycle: _hasCycle,
                        trainingWeeksBeforeDeload: _trainingWeeksBeforeDeload,
                        deloadPercentage: _deloadPercentage,
                        onCycleChanged: (value) =>
                            setState(() => _hasCycle = value),
                        onWeeksChanged: (value) =>
                            setState(() => _trainingWeeksBeforeDeload = value),
                        onDeloadPercentageChanged: (value) =>
                            setState(() => _deloadPercentage = value),
                      ),
                      DaysStep(
                        trainingDays: _trainingDays,
                        onDaysChanged: (days) =>
                            setState(() {
                              _trainingDays.clear();
                              _trainingDays.addAll(days);
                            }),
                      ),
                      ExercisesStep(
                        trainingDays: _trainingDays,
                        selectedDayTab: _selectedDayTab,
                        exercisesByDay: _exercisesByDay,
                        selectedForSuperset: _selectedForSuperset,
                        supersetsByDay: _supersetsByDay,
                        onDayTabSelected: (index) =>
                            setState(() => _selectedDayTab = index),
                        onToggleExercise: _toggleExercise,
                        onAddCustomExercise: _showAddCustomExercise,
                        onReorder: _reorderExercise,
                        onRemove: _removeExercise,
                        onConfigure: _showExerciseConfig,
                        onToggleSupersetSelection: _toggleSupersetSelection,
                        onCreateSuperset: _createSuperset,
                      ),
                    ],
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshGradient() {
    return Positioned(
      bottom: -100,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              FGColors.accent.withValues(alpha: 0.08),
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
            onTap: _previousStep,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(Spacing.sm),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: Icon(
                _currentStep == 0
                    ? Icons.close_rounded
                    : Icons.arrow_back_rounded,
                color: FGColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Étape ${_currentStep + 1}/$_totalSteps',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, 0),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: index < _totalSteps - 1 ? Spacing.xs : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isCurrent ? 4 : 3,
                decoration: BoxDecoration(
                  color: isActive ? FGColors.accent : FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: FGColors.accent.withValues(alpha: 0.5),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomActions() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canProceed = _canProceed();

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
        label: isLastStep ? 'Créer le programme' : 'Continuer',
        isExpanded: true,
        onPressed: canProceed ? _nextStep : null,
      ),
    );
  }
}
