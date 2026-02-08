import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/theme/fg_effects.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/workout_set.dart';
import '../../../core/models/time_stats.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/health_service.dart';
import '../../../core/services/progression_service.dart';
import 'sheets/number_picker_sheet.dart';
import 'sheets/workout_complete_sheet.dart';
import 'sheets/exit_confirmation_sheet.dart';
import 'widgets/workout_header.dart';
import 'widgets/set_card.dart';
import 'widgets/exercise_navigation.dart';
import 'widgets/set_indicators.dart';
import 'widgets/weight_reps_input.dart';
import 'widgets/rest_timer_view.dart';

/// Active Workout Tracking Screen
/// The core experience for tracking exercises during a workout session
class ActiveWorkoutScreen extends StatefulWidget {
  /// Initial time estimate (minutes) from the calling screen (workout/home).
  /// Ensures the displayed estimate matches what the user saw before tapping.
  final int? initialEstimatedMinutes;

  const ActiveWorkoutScreen({super.key, this.initialEstimatedMinutes});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _meshController;
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late Animation<double> _meshAnimation;
  late Animation<double> _pulseAnimation;

  // Page Controller for exercise navigation
  late PageController _exercisePageController;

  // Workout state
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  bool _isResting = false;
  int _restSecondsRemaining = 0;
  int _restTotalSeconds = 0;
  // Cached rest timer preview (captured before index advances)
  double? _restNextSetWeight;
  int? _restNextSetReps;
  String? _restNextExerciseName;
  String? _restNextExerciseMuscle;
  Timer? _restTimer;
  Timer? _workoutTimer;
  int _workoutSeconds = 0;
  final DateTime _workoutStartTime = DateTime.now();
  double _totalVolume = 0;

  // Workout data
  late List<Exercise> _exercises;
  String? _sessionId; // Supabase session ID
  String _dayName = 'Séance libre'; // Day name from program or default
  String? _programId;
  bool _isLoading = true; // Loading state for exercises

  // Last session data per exercise: { exerciseName: [ {actualWeight, actualReps, ...}, ... ] }
  final Map<String, List<Map<String, dynamic>>> _lastSessionSets = {};

  // Time tracking
  DateTime? _currentSetStartTime; // When current set became active
  DateTime? _lastExerciseEndTime; // When last exercise's final set was validated
  DateTime? _currentRestStartTime; // When rest timer started
  // Historical avg set duration per exercise from last session
  final Map<String, double> _lastSessionAvgSetDuration = {};

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
    _initializeAnimations();
    _startWorkoutTimer();
  }

  void _initializeWorkout() {
    // Initialize with empty exercises - will be loaded from Supabase
    // For free sessions, users can add exercises manually
    _exercises = [];
    _loadWorkoutFromProgram();

    _exercisePageController = PageController(initialPage: 0);
  }

  /// Match program day to today's weekday, fallback to first day
  Map<String, dynamic> _matchTodayDay(List<dynamic> days) {
    const weekdayNames = {
      1: 'lundi', 2: 'mardi', 3: 'mercredi',
      4: 'jeudi', 5: 'vendredi', 6: 'samedi', 7: 'dimanche',
    };
    final todayName = weekdayNames[DateTime.now().weekday]!;
    for (final day in days) {
      if (day is! Map<String, dynamic>) continue;
      final dayMap = day;
      final dayName = (dayMap['name'] ?? '').toString().toLowerCase();
      if (dayName.contains(todayName)) {
        return dayMap;
      }
    }
    return days[0] as Map<String, dynamic>;
  }

  Future<void> _loadWorkoutFromProgram() async {
    try {
      // Try to load from active program
      final results = await Future.wait([
        SupabaseService.getPrograms(),
        SupabaseService.getAssignedPrograms(),
      ]);

      final myPrograms = results[0];
      final assignedPrograms = results[1];
      final allPrograms = [...assignedPrograms, ...myPrograms];

      if (allPrograms.isNotEmpty && mounted) {
        final program = allPrograms.first;
        _programId = program['id']?.toString();
        final days = program['days'] as List? ?? [];

        if (days.isNotEmpty) {
          final matchedDay = _matchTodayDay(days);
          final exercisesData = matchedDay['exercises'] as List? ?? [];
          final dayName = matchedDay['name']?.toString() ?? 'Jour 1';

          // Load last session data for each exercise (non-blocking)
          _loadLastSessionData(
            exercisesData.map((ex) => (ex['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList(),
          );

          setState(() {
            _dayName = dayName;
            _currentSetStartTime = DateTime.now();
            _exercises = exercisesData.map((ex) {
              final customSets = ex['customSets'] as List?;
              final warmupEnabled = ex['warmup'] == true || ex['warmupEnabled'] == true;
              final sets = <WorkoutSet>[];

              // Build work sets
              final workSets = <WorkoutSet>[];
              if (customSets != null && customSets.isNotEmpty) {
                for (final cs in customSets) {
                  // Skip old-style manual warmup sets (auto-generated now)
                  if (cs['isWarmup'] == true) continue;
                  workSets.add(WorkoutSet(
                    targetReps: (cs['reps'] as num?)?.toInt() ?? 10,
                    targetWeight: (cs['weight'] as num?)?.toDouble() ?? 0,
                    isMaxReps: cs['isMaxReps'] == true,
                  ));
                }
              } else {
                final numSets = (ex['sets'] as num?)?.toInt() ?? 3;
                final numReps = (ex['reps'] as num?)?.toInt() ?? 10;
                for (int i = 0; i < numSets; i++) {
                  workSets.add(WorkoutSet(targetWeight: 0, targetReps: numReps));
                }
              }

              // Auto-generate warmup sets if enabled
              if (warmupEnabled && workSets.isNotEmpty) {
                final maxWeight = workSets.fold<double>(
                  0, (max, s) => s.targetWeight > max ? s.targetWeight : max);
                sets.addAll(_calculateWarmupSets(maxWeight));
              }
              sets.addAll(workSets);

              return Exercise(
                name: ex['name'] ?? 'Exercice',
                muscle: ex['muscle'] ?? ex['muscleGroup'] ?? ex['muscle_group'] ?? '',
                restSeconds: (ex['restSeconds'] as num?)?.toInt() ?? (ex['rest_seconds'] as num?)?.toInt() ?? 90,
                previousBest: (ex['previous_best'] as num?)?.toDouble() ?? 0,
                sets: sets,
                notes: ex['notes'] ?? '',
                progressionRule: ex['progressionRule'] ?? '',
                progression: ex['progression'] as Map<String, dynamic>?,
                weightType: ex['weightType'] ?? 'kg',
              );
            }).toList();
            _isLoading = false;
          });
        } else {
          // No days in program - show empty state
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // No programs - show empty state
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading workout: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impossible de charger le programme - ajoute des exercices manuellement'),
            backgroundColor: FGColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Auto-generate warmup sets based on the heaviest work set weight
  /// >= 60kg: 3 warmups (40% × 10, 60% × 5, 80% × 3)
  /// < 60kg: 2 warmups (50% × 8, 75% × 3)
  List<WorkoutSet> _calculateWarmupSets(double maxWeight) {
    if (maxWeight <= 0) return [];

    final warmups = <WorkoutSet>[];

    if (maxWeight >= 60) {
      warmups.addAll([
        WorkoutSet(targetWeight: _roundTo2_5(maxWeight * 0.4), targetReps: 10, isWarmup: true),
        WorkoutSet(targetWeight: _roundTo2_5(maxWeight * 0.6), targetReps: 5, isWarmup: true),
        WorkoutSet(targetWeight: _roundTo2_5(maxWeight * 0.8), targetReps: 3, isWarmup: true),
      ]);
    } else {
      warmups.addAll([
        WorkoutSet(targetWeight: _roundTo2_5(maxWeight * 0.5), targetReps: 8, isWarmup: true),
        WorkoutSet(targetWeight: _roundTo2_5(maxWeight * 0.75), targetReps: 3, isWarmup: true),
      ]);
    }

    return warmups;
  }

  /// Round to nearest 2.5 kg (standard plate increment)
  double _roundTo2_5(double value) {
    return (value / 2.5).round() * 2.5;
  }

  Future<void> _loadLastSessionData(List<String> exerciseNames) async {
    try {
      for (final name in exerciseNames) {
        final history = await SupabaseService.getExerciseHistory(name, limit: 1);
        if (history.isNotEmpty) {
          final sets = (history.first['sets'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
          if (sets.isNotEmpty && mounted) {
            setState(() {
              _lastSessionSets[name] = sets;
            });
            // Extract historical avg set duration for time estimation
            final durations = sets
                .where((s) => s['actualDurationSeconds'] != null && s['isWarmup'] != true)
                .map((s) => (s['actualDurationSeconds'] as num).toDouble())
                .toList();
            if (durations.isNotEmpty) {
              _lastSessionAvgSetDuration[name] =
                  durations.reduce((a, b) => a + b) / durations.length;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading last session data: $e');
    }
  }

  void _initializeAnimations() {
    _meshController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _meshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _meshController, curve: Curves.easeInOut),
    );

    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _workoutSeconds++;
      });
    });
  }

  void _startRestTimer({int? overrideSeconds}) {
    final exercise = _exercises[_currentExerciseIndex];
    _currentRestStartTime = DateTime.now();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = overrideSeconds ?? exercise.restSeconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining <= 0) {
        timer.cancel();
        _recordRestDuration();
        setState(() {
          _isResting = false;
        });
        _currentSetStartTime = DateTime.now();
        HapticFeedback.heavyImpact();
      } else {
        setState(() {
          _restSecondsRemaining--;
        });

        // Haptic at 10, 5, 3, 2, 1 seconds
        if (_restSecondsRemaining <= 5 || _restSecondsRemaining == 10) {
          HapticFeedback.lightImpact();
        }
      }
    });
  }

  /// Record actual rest duration on the previous set (the one that triggered rest)
  void _recordRestDuration() {
    if (_currentRestStartTime == null) return;
    final actualRest = DateTime.now().difference(_currentRestStartTime!).inSeconds;
    // Find the previous completed set to attach rest duration
    final exercise = _exercises[_currentExerciseIndex];
    final prevSetIdx = _currentSetIndex - 1;
    if (prevSetIdx >= 0 && exercise.sets[prevSetIdx].isCompleted) {
      exercise.sets[prevSetIdx].actualRestSeconds = actualRest;
    } else if (_currentSetIndex == 0 && _currentExerciseIndex > 0) {
      // Rest was between exercises — attach to last set of previous exercise
      final prevEx = _exercises[_currentExerciseIndex - 1];
      if (prevEx.sets.isNotEmpty) {
        prevEx.sets.last.actualRestSeconds = actualRest;
      }
    }
  }

  void _skipRest() {
    _restTimer?.cancel();
    _recordRestDuration();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
    _currentSetStartTime = DateTime.now();
    HapticFeedback.mediumImpact();
  }

  void _addRestTime(int seconds) {
    setState(() {
      _restSecondsRemaining += seconds;
    });
    HapticFeedback.lightImpact();
  }

  /// Estimate remaining workout time in seconds
  int _calculateEstimatedRemainingSeconds() {
    // Before any set is completed, use the initial estimate from the calling
    // screen so the displayed time matches what the user saw on workout/home.
    // Subtract elapsed seconds so it counts down naturally.
    if (widget.initialEstimatedMinutes != null &&
        widget.initialEstimatedMinutes! > 0) {
      final hasAnyCompleted =
          _exercises.any((ex) => ex.sets.any((s) => s.isCompleted));
      if (!hasAnyCompleted) {
        return (widget.initialEstimatedMinutes! * 60 - _workoutSeconds)
            .clamp(0, 99999);
      }
    }

    int remaining = 0;

    for (int exIdx = _currentExerciseIndex; exIdx < _exercises.length; exIdx++) {
      final ex = _exercises[exIdx];
      final startSet = exIdx == _currentExerciseIndex ? _currentSetIndex : 0;

      for (int sIdx = startSet; sIdx < ex.sets.length; sIdx++) {
        final s = ex.sets[sIdx];
        if (s.isCompleted) continue;

        // Estimate set execution time
        remaining += _estimateSetDuration(ex, s);

        // Estimate rest time (skip rest after the very last set of the workout)
        final isVeryLastSet =
            exIdx == _exercises.length - 1 && sIdx == ex.sets.length - 1;
        if (!isVeryLastSet) {
          remaining += s.isWarmup ? 60 : ex.restSeconds;
        }
      }

      // Estimate transition time to next exercise (if not last)
      if (exIdx < _exercises.length - 1 && exIdx >= _currentExerciseIndex) {
        remaining += _estimateTransitionDuration();
      }
    }

    return remaining.clamp(0, 99999);
  }

  /// Estimate a single set's execution time
  int _estimateSetDuration(Exercise exercise, WorkoutSet workoutSet) {
    // Priority 1: Current session average for this exercise
    final completedSets = exercise.sets
        .where((s) => s.isCompleted && !s.isWarmup && s.actualDurationSeconds != null);
    if (completedSets.isNotEmpty) {
      return (completedSets
              .map((s) => s.actualDurationSeconds!)
              .reduce((a, b) => a + b) /
          completedSets.length)
          .round();
    }

    // Priority 2: Historical average from last session
    final histAvg = _lastSessionAvgSetDuration[exercise.name];
    if (histAvg != null) {
      return histAvg.round();
    }

    // Priority 3: Formula fallback (4s/rep + 20s setup/rerack)
    return workoutSet.targetReps * 4 + 20;
  }

  /// Estimate transition duration between exercises
  int _estimateTransitionDuration() {
    // Use measured transitions from this session if available
    final measuredTransitions = _exercises
        .where((ex) => ex.transitionSeconds != null)
        .map((ex) => ex.transitionSeconds!)
        .toList();
    if (measuredTransitions.isNotEmpty) {
      return (measuredTransitions.reduce((a, b) => a + b) /
              measuredTransitions.length)
          .round();
    }
    // Default: 90 seconds
    return 90;
  }

  /// Build TimeStats for the workout complete screen
  TimeStats _buildTimeStats() {
    int tensionTime = 0;
    int totalRestTime = 0;
    int totalTransitionTime = 0;
    final transitions = <int>[];

    for (final ex in _exercises) {
      if (ex.transitionSeconds != null) {
        totalTransitionTime += ex.transitionSeconds!;
        transitions.add(ex.transitionSeconds!);
      }
      for (final s in ex.sets) {
        if (s.actualDurationSeconds != null) {
          tensionTime += s.actualDurationSeconds!;
        }
        if (s.actualRestSeconds != null) {
          totalRestTime += s.actualRestSeconds!;
        }
      }
    }

    final avgTransition =
        transitions.isNotEmpty ? transitions.reduce((a, b) => a + b) / transitions.length : 0.0;
    final efficiency =
        _workoutSeconds > 0 ? (tensionTime / _workoutSeconds) * 100 : 0.0;

    return TimeStats(
      totalDuration: _workoutSeconds,
      tensionTime: tensionTime,
      totalRestTime: totalRestTime,
      totalTransitionTime: totalTransitionTime,
      avgTransition: avgTransition,
      efficiencyScore: efficiency,
    );
  }

  void _validateSet() {
    final exercise = _exercises[_currentExerciseIndex];
    final currentSet = exercise.sets[_currentSetIndex];

    // Guard: don't re-validate already completed sets
    if (currentSet.isCompleted) return;

    // Record set duration
    if (_currentSetStartTime != null) {
      currentSet.actualDurationSeconds =
          DateTime.now().difference(_currentSetStartTime!).inSeconds;
    }

    // Record transition time (first set of a new exercise)
    if (_currentSetIndex == 0 &&
        _currentExerciseIndex > 0 &&
        _lastExerciseEndTime != null) {
      final transitionBrute =
          DateTime.now().difference(_lastExerciseEndTime!).inSeconds;
      // Subtract rest time that was taken between exercises
      final prevEx = _exercises[_currentExerciseIndex - 1];
      final lastSetRest = prevEx.sets.last.actualRestSeconds ?? 0;
      exercise.transitionSeconds =
          (transitionBrute - lastSetRest).clamp(0, 9999);
    }

    // Calculate volume
    final setVolume = currentSet.actualWeight * currentSet.actualReps;
    _totalVolume += setVolume;

    // Mark set as completed
    currentSet.isCompleted = true;

    // Track if this is the last set of the exercise (for transition tracking)
    final isLastSetOfExercise = _currentSetIndex >= exercise.sets.length - 1;
    if (isLastSetOfExercise) {
      _lastExerciseEndTime = DateTime.now();
    }

    // Check progression suggestion
    final progressionMessage = ProgressionService.checkProgression(exercise, currentSet);
    if (progressionMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(progressionMessage),
          backgroundColor: FGColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    HapticFeedback.mediumImpact();

    // Shorter rest after warmup sets (45s vs normal rest)
    final restSeconds = currentSet.isWarmup ? 45 : null;

    // Move to next set or exercise
    if (_currentSetIndex < exercise.sets.length - 1) {
      // Cache next set preview BEFORE advancing
      final nextSet = exercise.sets[_currentSetIndex + 1];
      _restNextSetWeight = nextSet.targetWeight;
      _restNextSetReps = nextSet.targetReps;
      _restNextExerciseName = null;
      _restNextExerciseMuscle = null;
      _restTotalSeconds = restSeconds ?? exercise.restSeconds;
      setState(() {
        _currentSetIndex++;
      });
      _startRestTimer(overrideSeconds: restSeconds);
    } else if (_currentExerciseIndex < _exercises.length - 1) {
      // Cache next exercise preview BEFORE advancing
      final nextExercise = _exercises[_currentExerciseIndex + 1];
      final nextFirstSet = nextExercise.sets.isNotEmpty ? nextExercise.sets.first : null;
      _restNextSetWeight = nextFirstSet?.targetWeight;
      _restNextSetReps = nextFirstSet?.targetReps;
      _restNextExerciseName = nextExercise.name;
      _restNextExerciseMuscle = nextExercise.muscle;
      _restTotalSeconds = restSeconds ?? exercise.restSeconds;
      // Move to next exercise
      setState(() {
        _currentExerciseIndex++;
        _currentSetIndex = 0;
      });
      if (mounted) {
        _exercisePageController.animateToPage(
          _currentExerciseIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
      _startRestTimer(overrideSeconds: restSeconds);
    } else {
      // Workout complete
      _showWorkoutCompleteSheet();
    }
  }

  Future<void> _showWorkoutCompleteSheet() async {
    // Save workout session to Supabase
    await _saveWorkoutSession();

    if (!mounted) return;

    final timeStats = _buildTimeStats();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      isScrollControlled: true,
      builder: (context) => WorkoutCompleteSheet(
        duration: _workoutSeconds,
        totalVolume: _totalVolume,
        exerciseCount: _exercises.length,
        totalSets: _exercises.fold<int>(
          0, (sum, ex) => sum + ex.sets.where((s) => s.isCompleted && !s.isWarmup).length),
        timeStats: timeStats,
        onClose: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _saveWorkoutSession() async {
    try {
      // Build exercises data for Supabase
      final exercisesData = _exercises.map((ex) {
        final setsData = List.generate(ex.sets.length, (i) {
          final set = ex.sets[i];
          return <String, dynamic>{
            'setNumber': i + 1,
            'isWarmup': set.isWarmup,
            'targetWeight': set.targetWeight,
            'targetReps': set.targetReps,
            'actualWeight': set.actualWeight,
            'actualReps': set.actualReps,
            'completed': set.isCompleted,
            if (set.actualDurationSeconds != null)
              'actualDurationSeconds': set.actualDurationSeconds,
            if (set.actualRestSeconds != null)
              'actualRestSeconds': set.actualRestSeconds,
          };
        });

        return {
          'exerciseName': ex.name,
          'muscle': ex.muscle,
          'weightType': ex.weightType,
          'sets': setsData,
          if (ex.transitionSeconds != null)
            'transitionSeconds': ex.transitionSeconds,
        };
      }).toList();

      // Calculate total sets completed
      int totalSets = 0;
      for (final ex in _exercises) {
        totalSets += ex.sets.where((s) => s.isCompleted && !s.isWarmup).length;
      }

      // Detect PRs (simplified - compare to previousBest)
      final prs = <Map<String, dynamic>>[];
      for (final ex in _exercises) {
        final maxWeight = ex.sets
            .where((s) => s.isCompleted && !s.isWarmup)
            .fold<double>(0, (max, s) => s.actualWeight > max ? s.actualWeight : max);
        if (maxWeight > ex.previousBest) {
          prs.add({
            'exerciseName': ex.name,
            'weightKg': maxWeight,
            'previousBest': ex.previousBest,
          });
        }
      }

      // Save to Supabase if user is authenticated
      if (SupabaseService.isAuthenticated) {
        // Start session if not already started
        if (_sessionId == null) {
          final session = await SupabaseService.startWorkoutSession(
            programId: _programId,
            dayName: _dayName,
            exercises: exercisesData,
            startedAt: _workoutStartTime,
          );
          _sessionId = session['id'];
        }

        // Complete the session
        await SupabaseService.completeWorkoutSession(
          sessionId: _sessionId!,
          durationMinutes: (_workoutSeconds / 60).round(),
          totalVolumeKg: _totalVolume,
          totalSets: totalSets,
          exercises: exercisesData,
          personalRecords: prs.isNotEmpty ? prs : null,
        );

        // Update streak
        try {
          await SupabaseService.updateStreak();
        } catch (e) {
          debugPrint('Error updating streak: $e');
        }

        // Check and unlock achievements
        try {
          final newAchievements = await SupabaseService.checkAchievements();
          if (newAchievements.isNotEmpty && mounted) {
            debugPrint('New achievements unlocked: $newAchievements');
          }
        } catch (e) {
          debugPrint('Error checking achievements: $e');
        }

        // Create activity feed entry
        try {
          // Build top exercises for social feed (top 3 by weight)
          final topExercisesData = _exercises
              .map((ex) {
                final maxSet = ex.sets
                    .where((s) => s.isCompleted && !s.isWarmup)
                    .fold<({double weight, int reps})>(
                      (weight: 0, reps: 0),
                      (best, s) => s.actualWeight > best.weight
                          ? (weight: s.actualWeight, reps: s.actualReps)
                          : best,
                    );
                return {
                  'name': ex.name,
                  'shortName': ex.name.length > 4 ? ex.name.substring(0, 4).toUpperCase() : ex.name.toUpperCase(),
                  'weightKg': maxSet.weight,
                  'reps': maxSet.reps,
                };
              })
              .where((e) => (e['weightKg'] as double) > 0)
              .toList()
            ..sort((a, b) => (b['weightKg'] as double).compareTo(a['weightKg'] as double));

          // Build muscles string
          final muscles = _exercises
              .map((ex) => ex.muscle)
              .where((m) => m.isNotEmpty)
              .toSet()
              .take(3)
              .join(' • ');

          // Build PR data for social feed
          Map<String, dynamic>? prData;
          if (prs.isNotEmpty) {
            final topPr = prs.first;
            prData = {
              'exerciseName': topPr['exerciseName'],
              'value': topPr['weightKg'],
              'gain': (topPr['weightKg'] as double) - (topPr['previousBest'] as double),
              'unit': 'kg',
            };
          }

          await SupabaseService.createActivity(
            activityType: 'workout_completed',
            title: '$_dayName terminée',
            description: '$totalSets séries • ${(_totalVolume / 1000).toStringAsFixed(1)}t volume',
            metadata: {
              'session_id': _sessionId,
              'duration_minutes': (_workoutSeconds / 60).round(),
              'volume_kg': _totalVolume,
              'exercise_count': _exercises.length,
              'muscles': muscles,
              'exercises': topExercisesData.take(3).toList(),
              if (prData != null) 'pr': prData,
              'personal_records': prs.length,
            },
          );
        } catch (e) {
          debugPrint('Error creating activity: $e');
        }

        // Update challenge progress
        try {
          final activeChallenges = await SupabaseService.getActiveChallenges();
          for (final challenge in activeChallenges) {
            final exerciseName = challenge['exercise_name'] as String? ?? '';
            final challengeType = challenge['type'] as String? ?? '';

            // Find matching exercise in this workout
            for (final ex in _exercises) {
              if (ex.name.toLowerCase() == exerciseName.toLowerCase()) {
                double value = 0;
                if (challengeType == 'weight') {
                  value = ex.sets
                      .where((s) => s.isCompleted && !s.isWarmup)
                      .fold<double>(0, (max, s) => s.actualWeight > max ? s.actualWeight : max);
                } else if (challengeType == 'reps') {
                  value = ex.sets
                      .where((s) => s.isCompleted && !s.isWarmup)
                      .fold<double>(0, (max, s) => s.actualReps > max ? s.actualReps.toDouble() : max);
                }
                if (value > 0) {
                  await SupabaseService.updateChallengeProgress(
                    challenge['id'],
                    value,
                  );
                }
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('Error updating challenge progress: $e');
        }

        // Write workout to Apple Health
        try {
          final healthService = HealthService();
          if (healthService.isAuthorized) {
            await healthService.writeWorkout(
              start: _workoutStartTime,
              end: DateTime.now(),
              caloriesBurned: (_totalVolume * 0.05).round(),
            );
          }
        } catch (e) {
          debugPrint('Error writing workout to HealthKit: $e');
        }
      }
    } catch (e) {
      debugPrint('Error saving workout session: $e');
      // Don't block the completion flow on save error
    }
  }

  void _showExitConfirmation() {
    final hasCompletedSets = _exercises.any((ex) => ex.sets.any((s) => s.isCompleted));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ExitConfirmationSheet(
        onConfirm: () {
          Navigator.pop(sheetContext);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(sheetContext),
        onSaveAndQuit: hasCompletedSets ? () async {
          Navigator.pop(sheetContext);
          await _saveWorkoutSession();
          if (mounted) {
            Navigator.pop(context);
          }
        } : null,
      ),
    );
  }

  @override
  void dispose() {
    _meshController.dispose();
    _timerController.dispose();
    _pulseController.dispose();
    _exercisePageController.dispose();
    _restTimer?.cancel();
    _workoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while exercises are being fetched
    if (_isLoading) {
      return Scaffold(
        backgroundColor: FGColors.background,
        body: Stack(
          children: [
            _buildMeshGradient(),
            const Center(
              child: CircularProgressIndicator(
                color: FGColors.accent,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state if no exercises loaded
    if (_exercises.isEmpty) {
      return Scaffold(
        backgroundColor: FGColors.background,
        body: Stack(
          children: [
            _buildMeshGradient(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: FGColors.glassSurface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: FGColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: FGColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text(
                      'Aucun exercice',
                      style: FGTypography.h2.copyWith(
                        color: FGColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Crée d\'abord un programme avec des exercices',
                      style: FGTypography.body.copyWith(
                        color: FGColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          _buildMeshGradient(),
          SafeArea(
            child: Column(
              children: [
                WorkoutHeader(
                  exerciseName: _exercises[_currentExerciseIndex].name,
                  muscleGroup: _exercises[_currentExerciseIndex].muscle,
                  currentExercise: _currentExerciseIndex + 1,
                  totalExercises: _exercises.length,
                  workoutSeconds: _workoutSeconds,
                  onExitTap: _showExitConfirmation,
                  notes: _exercises[_currentExerciseIndex].notes,
                  progressionRule: _exercises[_currentExerciseIndex].progressionRule,
                  onNotesTap: () => _showNotesSheet(_exercises[_currentExerciseIndex]),
                ),
                Expanded(
                  child: _isResting
                      ? RestTimerView(
                          restSecondsRemaining: _restSecondsRemaining,
                          totalRestSeconds: _restTotalSeconds,
                          nextSetWeight: _restNextSetWeight,
                          nextSetReps: _restNextSetReps,
                          nextExerciseName: _restNextExerciseName,
                          nextExerciseMuscle: _restNextExerciseMuscle,
                          onSkipRest: _skipRest,
                          onAddRestTime: () => _addRestTime(30),
                        )
                      : _buildActiveView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshGradient() {
    return AnimatedBuilder(
      animation: _meshAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: FGColors.background),
            // Dynamic gradient based on rest/active state
            Positioned(
              top: -50 + (_meshAnimation.value * 30),
              right: -100 + (_meshAnimation.value * 20),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (_isResting ? FGColors.success : FGColors.accent)
                          .withValues(alpha: 0.15 + (_meshAnimation.value * 0.1)),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100 - (_meshAnimation.value * 40),
              left: -150,
              child: Container(
                width: 350,
                height: 350,
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveView() {
    final exercise = _exercises[_currentExerciseIndex];
    final currentSet = exercise.sets[_currentSetIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: [
          const SizedBox(height: Spacing.cardGap),

          // 1. Exercise navigation dots
          ExerciseNavigation(
            exercises: _exercises,
            currentIndex: _currentExerciseIndex,
            onExerciseTap: (index) {
              setState(() {
                _currentExerciseIndex = index;
                _currentSetIndex =
                    _exercises[index].sets.indexWhere((s) => !s.isCompleted);
                if (_currentSetIndex == -1) {
                  _currentSetIndex = _exercises[index].sets.length - 1;
                }
              });
              _exercisePageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
          ),
          const SizedBox(height: Spacing.cardGap),

          // 2. Set progress timeline
          SetIndicators(
            exercise: exercise,
            currentSetIndex: _currentSetIndex,
            onSetTap: (index) {
              setState(() {
                _currentSetIndex = index;
              });
            },
          ),
          const SizedBox(height: Spacing.cardGap),

          // 3. Inline notes/progression (tappable for full view)
          if (exercise.notes.isNotEmpty || exercise.progressionRule.isNotEmpty) ...[
            _buildInlineNotes(exercise),
            const SizedBox(height: Spacing.cardGap),
          ],

          // 4. Target set card — takes available space
          Expanded(
            child: SetCard(
              currentSet: currentSet,
              previousBest: exercise.previousBest,
              isWarmup: currentSet.isWarmup,
              currentSetIndex: _currentSetIndex,
              workSetNumber: currentSet.isWarmup ? null : _workSetNumber(exercise, _currentSetIndex),
              weightType: exercise.weightType,
              isMaxReps: currentSet.isMaxReps,
              lastSessionSet: _getLastSessionSet(exercise.name, _currentSetIndex),
              suggestedWeight: _getSuggestedWeight(exercise, _currentSetIndex),
            ),
          ),
          const SizedBox(height: Spacing.cardGap),

          // 5. Last session comparison (all work sets)
          if (_lastSessionSets[exercise.name]?.isNotEmpty == true) ...[
            _buildLastSessionRow(exercise),
            const SizedBox(height: Spacing.cardGap),
          ],

          // 6. Completed sets mini-log (this session)
          if (exercise.sets.any((s) => s.isCompleted)) ...[
            _buildCompletedSetsLog(exercise),
            const SizedBox(height: Spacing.cardGap),
          ],

          // 7. Weight & reps input
          WeightRepsInput(
            currentSet: currentSet,
            weightType: exercise.weightType,
            isMaxReps: currentSet.isMaxReps,
            onWeightChange: (value) {
              setState(() {
                currentSet.actualWeight = value;
              });
            },
            onRepsChange: (value) {
              setState(() {
                currentSet.actualReps = value;
              });
            },
            onNumberPickerTap: (initialValue, isInteger) {
              _showNumberPicker(
                initialValue: initialValue,
                isInteger: isInteger,
                onValueChange: (value) {
                  setState(() {
                    if (isInteger) {
                      currentSet.actualReps = value.toInt();
                    } else {
                      currentSet.actualWeight = value;
                    }
                  });
                },
              );
            },
          ),
          const SizedBox(height: Spacing.cardGap),

          // 8. Validate button
          _buildValidateButton(),
          const SizedBox(height: Spacing.cardGap),

          // 9. Session insights
          _buildSessionInsights(),
          const SizedBox(height: Spacing.cardGap),
        ],
      ),
    );
  }

  /// Inline notes — scrollable inside the card with visible scrollbar
  Widget _buildInlineNotes(Exercise exercise) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 120),
      child: FGGlassCard.standard(
        child: ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbColor: WidgetStatePropertyAll(
              FGColors.textSecondary.withValues(alpha: 0.3),
            ),
            thickness: const WidgetStatePropertyAll(3),
            radius: const Radius.circular(2),
            minThumbLength: 20,
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exercise.notes.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, color: FGColors.accent, size: 16),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            exercise.notes,
                            style: FGTypography.body.copyWith(
                              color: FGColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (exercise.notes.isNotEmpty && exercise.progressionRule.isNotEmpty)
                    const SizedBox(height: Spacing.sm),
                  if (exercise.progressionRule.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.trending_up_rounded, color: FGColors.success, size: 16),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            exercise.progressionRule,
                            style: FGTypography.body.copyWith(
                              color: FGColors.success.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Last session performance — horizontal pills per work set
  Widget _buildLastSessionRow(Exercise exercise) {
    final lastSets = _lastSessionSets[exercise.name]!;
    final workSets = lastSets
        .where((s) => s['isWarmup'] != true && s['completed'] == true)
        .toList();

    if (workSets.isEmpty) return const SizedBox.shrink();

    return FGGlassCard.compact(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: FGColors.textSecondary, size: 12),
              const SizedBox(width: Spacing.xs),
              Text(
                'DERNIÈRE SÉANCE',
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            children: List.generate(workSets.length, (index) {
              final set = workSets[index];
              final w = (set['actualWeight'] as num?)?.toDouble() ?? 0;
              final r = (set['actualReps'] as num?)?.toInt() ?? 0;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < workSets.length - 1 ? Spacing.xs : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: FGColors.glassSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(Spacing.xs),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_fmtW(w)}×$r',
                      textAlign: TextAlign.center,
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Completed sets log for current exercise this session
  Widget _buildCompletedSetsLog(Exercise exercise) {
    final completed = <int>[];
    for (int i = 0; i < exercise.sets.length; i++) {
      if (exercise.sets[i].isCompleted) {
        completed.add(i);
      }
    }
    if (completed.isEmpty) return const SizedBox.shrink();

    return FGGlassCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: FGColors.success, size: 12),
              const SizedBox(width: Spacing.xs),
              Text(
                'CETTE SÉANCE',
                style: FGTypography.caption.copyWith(
                  color: FGColors.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          ...completed.map((i) {
            final s = exercise.sets[i];
            final label = s.isWarmup
                ? 'Ech.'
                : 'S.${_workSetNumber(exercise, i)}';
            final weightStr = exercise.weightType == 'bodyweight'
                ? 'PDC'
                : exercise.weightType == 'bodyweight_plus'
                    ? 'PDC +${_fmtW(s.actualWeight)}kg'
                    : '${_fmtW(s.actualWeight)}kg';
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      label,
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Icon(Icons.check_rounded, color: FGColors.success, size: 12),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      '$weightStr × ${s.actualReps}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
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

  /// Format weight for compact display
  String _fmtW(double v) {
    if (v == v.toInt().toDouble()) return v.toInt().toString();
    if (v == double.parse(v.toStringAsFixed(1))) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  /// Get work-set number (1-based, excluding warmups)
  int _workSetNumber(Exercise exercise, int setIndex) {
    int n = 0;
    for (int i = 0; i <= setIndex; i++) {
      if (!exercise.sets[i].isWarmup) n++;
    }
    return n;
  }

  Widget _buildSessionInsights() {
    // Completed sets / total (excluding warmups)
    int completedSets = 0;
    int totalSets = 0;
    for (final ex in _exercises) {
      for (final s in ex.sets) {
        if (!s.isWarmup) {
          totalSets++;
          if (s.isCompleted) {
            completedSets++;
          }
        }
      }
    }

    // Volume formatted
    String volumeStr;
    if (_totalVolume >= 1000) {
      volumeStr = '${(_totalVolume / 1000).toStringAsFixed(1)}T';
    } else {
      volumeStr = '${_totalVolume.toInt()}kg';
    }

    // Exercises remaining after current
    final exosRemaining = _exercises.length - _currentExerciseIndex - 1;

    // Next exercise
    final hasNext = _currentExerciseIndex < _exercises.length - 1;
    final nextExercise = hasNext ? _exercises[_currentExerciseIndex + 1] : null;

    // Progress ratio for the bar
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;

    return FGGlassCard.compact(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats row + progress bar + time estimate in one compact block
          Row(
            children: [
              // Volume
              Expanded(
                child: _buildStatColumn(
                  volumeStr,
                  'VOLUME',
                  FGColors.accent,
                ),
              ),
              Container(width: 1, height: 28, color: FGColors.glassBorder),
              // Sets
              Expanded(
                child: _buildStatColumn(
                  '$completedSets/$totalSets',
                  'SÉRIES',
                  FGColors.textPrimary,
                ),
              ),
              Container(width: 1, height: 28, color: FGColors.glassBorder),
              // Exercises remaining
              Expanded(
                child: _buildStatColumn(
                  '$exosRemaining',
                  exosRemaining <= 1 ? 'EXO RESTANT' : 'EXOS RESTANTS',
                  exosRemaining == 0 ? FGColors.success : FGColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacing.xs),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: FGColors.glassBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                FGColors.accent.withValues(alpha: 0.8),
              ),
            ),
          ),

          // Bottom row: next exercise (left) + time estimate (right)
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              // Next exercise
              if (nextExercise != null) ...[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: FGColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.skip_next_rounded,
                    size: 11,
                    color: FGColors.accent,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: nextExercise.name,
                          style: FGTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                        TextSpan(
                          text: '  ${nextExercise.sets.where((s) => !s.isWarmup).length}×${nextExercise.sets.where((s) => !s.isWarmup).isNotEmpty ? nextExercise.sets.firstWhere((s) => !s.isWarmup).targetReps : '?'}',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (nextExercise == null)
                const Spacer(),
              // Time estimate
              ..._buildTimeEstimateWidgets(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: FGTypography.body.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  /// Build time estimate widgets for inline use in a Row
  List<Widget> _buildTimeEstimateWidgets() {
    final estimatedSeconds = _calculateEstimatedRemainingSeconds();

    // Transition alert: first set of new exercise, lingering too long
    bool isTransitionAlert = false;
    if (_currentSetIndex == 0 &&
        _currentExerciseIndex > 0 &&
        _lastExerciseEndTime != null &&
        !_isResting) {
      final timeSinceEnd =
          DateTime.now().difference(_lastExerciseEndTime!).inSeconds;
      final prevEx = _exercises[_currentExerciseIndex - 1];
      final expectedRest = prevEx.restSeconds;
      if (timeSinceEnd > expectedRest + 90) {
        isTransitionAlert = true;
      }
    }

    // Format time
    String timeStr;
    if (estimatedSeconds < 60) {
      timeStr = '< 1 min';
    } else if (estimatedSeconds >= 3600) {
      final h = estimatedSeconds ~/ 3600;
      final m = (estimatedSeconds % 3600) ~/ 60;
      timeStr = '~${h}h${m.toString().padLeft(2, '0')}';
    } else {
      final m = estimatedSeconds ~/ 60;
      timeStr = '~$m min';
    }

    // Color: green when < 5 min, orange on alert, otherwise secondary
    Color timeColor;
    if (isTransitionAlert) {
      timeColor = FGColors.warning;
    } else if (estimatedSeconds < 300) {
      timeColor = FGColors.success;
    } else {
      timeColor = FGColors.textSecondary;
    }

    return [
      if (isTransitionAlert) ...[
        Icon(Icons.bolt_rounded, size: 11, color: FGColors.warning),
        const SizedBox(width: 2),
      ],
      Icon(Icons.schedule_rounded, size: 11, color: timeColor),
      const SizedBox(width: Spacing.xs),
      Text(
        timeStr,
        style: FGTypography.caption.copyWith(
          color: timeColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    ];
  }




  /// Get last session's actual performance for a specific set index
  /// Matches work sets only (skips warmups on both sides)
  Map<String, dynamic>? _getLastSessionSet(String exerciseName, int setIndex) {
    final exercise = _exercises.firstWhere((e) => e.name == exerciseName);
    final currentSet = exercise.sets[setIndex];

    // No history for warmup sets
    if (currentSet.isWarmup) return null;

    final sets = _lastSessionSets[exerciseName];
    if (sets == null) return null;

    // Calculate work-set index (position among non-warmup sets)
    int workSetIndex = 0;
    for (int i = 0; i < setIndex; i++) {
      if (!exercise.sets[i].isWarmup) workSetIndex++;
    }

    // Match against last session's non-warmup sets
    final lastWorkSets = sets.where((s) => s['isWarmup'] != true).toList();
    if (workSetIndex >= lastWorkSets.length) return null;

    final set = lastWorkSets[workSetIndex];
    if (set['completed'] != true) return null;
    return set;
  }

  /// Calculate suggested weight based on last session + progression rules
  double? _getSuggestedWeight(Exercise exercise, int setIndex) {
    if (exercise.sets[setIndex].isWarmup) return null;

    final lastSet = _getLastSessionSet(exercise.name, setIndex);
    if (lastSet == null) return null;

    final progression = exercise.progression;
    if (progression == null) return null;
    if (progression['type'] != 'threshold') return null;

    final repThreshold = (progression['repThreshold'] as num?)?.toInt();
    final weightIncrement = (progression['weightIncrement'] as num?)?.toDouble();
    if (repThreshold == null || weightIncrement == null) return null;

    final lastReps = (lastSet['actualReps'] as num?)?.toInt() ?? 0;
    final lastWeight = (lastSet['actualWeight'] as num?)?.toDouble() ?? 0;

    // If last time they hit the threshold on this set, suggest increased weight
    if (lastReps >= repThreshold && lastWeight > 0) {
      return lastWeight + weightIncrement;
    }

    return null;
  }

  void _showNotesSheet(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(Spacing.md),
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: FGColors.background,
          borderRadius: BorderRadius.circular(Spacing.lg),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center_rounded, color: FGColors.accent, size: 20),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: FGTypography.h3.copyWith(color: FGColors.textPrimary),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded, color: FGColors.textSecondary, size: 20),
                ),
              ],
            ),
            if (exercise.notes.isNotEmpty) ...[
              const SizedBox(height: Spacing.lg),
              Text(
                'Consignes',
                style: FGTypography.caption.copyWith(
                  color: FGColors.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                exercise.notes,
                style: FGTypography.body.copyWith(color: FGColors.textPrimary),
              ),
            ],
            if (exercise.progressionRule.isNotEmpty) ...[
              const SizedBox(height: Spacing.lg),
              Text(
                'Progression',
                style: FGTypography.caption.copyWith(
                  color: FGColors.success,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                exercise.progressionRule,
                style: FGTypography.body.copyWith(color: FGColors.textPrimary),
              ),
            ],
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  void _showNumberPicker({
    required double initialValue,
    required bool isInteger,
    required Function(double) onValueChange,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => NumberPickerSheet(
        initialValue: initialValue,
        isInteger: isInteger,
        onValueChange: (value) {
          onValueChange(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildValidateButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.05 + 0.95,
          child: GestureDetector(
            onTap: _validateSet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: FGColors.accent,
                borderRadius: BorderRadius.circular(Spacing.lg),
                boxShadow: FGEffects.neonGlow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: FGColors.textOnAccent,
                    size: 24,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'VALIDER LA SÉRIE',
                    style: FGTypography.button.copyWith(
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}