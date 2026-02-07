import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/theme/fg_effects.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/workout_set.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/health_service.dart';
import '../../../core/services/progression_service.dart';
import 'sheets/number_picker_sheet.dart';
import 'sheets/workout_complete_sheet.dart';
import 'sheets/exit_confirmation_sheet.dart';
import 'widgets/workout_header.dart';
import 'widgets/stats_bar.dart';
import 'widgets/set_card.dart';
import 'widgets/exercise_navigation.dart';
import 'widgets/set_indicators.dart';
import 'widgets/weight_reps_input.dart';
import 'widgets/rest_timer_view.dart';
import 'widgets/pr_celebration.dart';

/// Active Workout Tracking Screen
/// The core experience for tracking exercises during a workout session
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _meshController;
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _prCelebrationController;

  late Animation<double> _meshAnimation;
  late Animation<double> _pulseAnimation;

  // Page Controller for exercise navigation
  late PageController _exercisePageController;

  // Workout state
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  bool _isResting = false;
  int _restSecondsRemaining = 0;
  Timer? _restTimer;
  Timer? _workoutTimer;
  int _workoutSeconds = 0;
  final DateTime _workoutStartTime = DateTime.now();
  double _totalVolume = 0;
  bool _showPRCelebration = false;

  // Workout data
  late List<Exercise> _exercises;
  String? _sessionId; // Supabase session ID
  String _dayName = 'Séance libre'; // Day name from program or default
  String? _programId;
  bool _isLoading = true; // Loading state for exercises

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
          final firstDay = days[0] as Map<String, dynamic>;
          final exercisesData = firstDay['exercises'] as List? ?? [];
          final dayName = firstDay['name']?.toString() ?? 'Jour 1';

          setState(() {
            _dayName = dayName;
            _exercises = exercisesData.map((ex) {
              final customSets = ex['customSets'] as List?;
              final sets = <WorkoutSet>[];

              if (customSets != null && customSets.isNotEmpty) {
                // Use custom sets with individual reps/weight per set
                for (final cs in customSets) {
                  sets.add(WorkoutSet(
                    targetReps: (cs['reps'] as num?)?.toInt() ?? 10,
                    targetWeight: (cs['weight'] as num?)?.toDouble() ?? 0,
                    isWarmup: cs['isWarmup'] == true,
                    isMaxReps: cs['isMaxReps'] == true,
                  ));
                }
              } else {
                // Fallback: uniform sets
                final numSets = (ex['sets'] as num?)?.toInt() ?? 3;
                final numReps = (ex['reps'] as num?)?.toInt() ?? 10;
                final warmupEnabled = ex['warmupEnabled'] == true;

                if (warmupEnabled) {
                  sets.add(WorkoutSet(targetWeight: 0, targetReps: numReps, isWarmup: true));
                }
                for (int i = 0; i < numSets; i++) {
                  sets.add(WorkoutSet(targetWeight: 0, targetReps: numReps));
                }
              }

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

    _prCelebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _workoutSeconds++;
      });
    });
  }

  void _startRestTimer() {
    final exercise = _exercises[_currentExerciseIndex];
    setState(() {
      _isResting = true;
      _restSecondsRemaining = exercise.restSeconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining <= 0) {
        timer.cancel();
        setState(() {
          _isResting = false;
        });
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

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _addRestTime(int seconds) {
    setState(() {
      _restSecondsRemaining += seconds;
    });
    HapticFeedback.lightImpact();
  }

  void _validateSet() {
    final exercise = _exercises[_currentExerciseIndex];
    final currentSet = exercise.sets[_currentSetIndex];

    // Calculate volume
    final setVolume = currentSet.actualWeight * currentSet.actualReps;
    _totalVolume += setVolume;

    // Mark set as completed
    currentSet.isCompleted = true;

    // Check for PR
    if (currentSet.actualWeight > exercise.previousBest) {
      _triggerPRCelebration();
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

    // Move to next set or exercise
    if (_currentSetIndex < exercise.sets.length - 1) {
      setState(() {
        _currentSetIndex++;
      });
      _startRestTimer();
    } else if (_currentExerciseIndex < _exercises.length - 1) {
      // Move to next exercise
      setState(() {
        _currentExerciseIndex++;
        _currentSetIndex = 0;
      });
      _exercisePageController.animateToPage(
        _currentExerciseIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      _startRestTimer();
    } else {
      // Workout complete
      _showWorkoutCompleteSheet();
    }
  }

  void _triggerPRCelebration() {
    setState(() {
      _showPRCelebration = true;
    });
    _prCelebrationController.forward(from: 0);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 1), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showPRCelebration = false;
      });
    });
  }

  Future<void> _showWorkoutCompleteSheet() async {
    // Save workout session to Supabase
    await _saveWorkoutSession();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      isScrollControlled: true,
      builder: (context) => WorkoutCompleteSheet(
        duration: _workoutSeconds,
        totalVolume: _totalVolume,
        exerciseCount: _exercises.length,
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
        final setsData = ex.sets.map((set) => {
          'setNumber': ex.sets.indexOf(set) + 1,
          'isWarmup': set.isWarmup,
          'targetWeight': set.targetWeight,
          'targetReps': set.targetReps,
          'actualWeight': set.actualWeight,
          'actualReps': set.actualReps,
          'completed': set.isCompleted,
        }).toList();

        return {
          'exerciseName': ex.name,
          'muscle': ex.muscle,
          'weightType': ex.weightType,
          'sets': setsData,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ExitConfirmationSheet(
        onConfirm: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  void dispose() {
    _meshController.dispose();
    _timerController.dispose();
    _pulseController.dispose();
    _prCelebrationController.dispose();
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
                ),
                Expanded(
                  child: _isResting
                      ? RestTimerView(
                          restSecondsRemaining: _restSecondsRemaining,
                          totalRestSeconds:
                              _exercises[_currentExerciseIndex].restSeconds,
                          nextSetWeight: _exercises[_currentExerciseIndex]
                              .sets[_currentSetIndex]
                              .targetWeight,
                          nextSetReps: _exercises[_currentExerciseIndex]
                              .sets[_currentSetIndex]
                              .targetReps,
                          nextExerciseName: _currentExerciseIndex <
                                      _exercises.length - 1 &&
                                  _currentSetIndex >=
                                      _exercises[_currentExerciseIndex]
                                              .sets
                                              .length -
                                          1
                              ? _exercises[_currentExerciseIndex + 1].name
                              : null,
                          nextExerciseMuscle: _currentExerciseIndex <
                                      _exercises.length - 1 &&
                                  _currentSetIndex >=
                                      _exercises[_currentExerciseIndex]
                                              .sets
                                              .length -
                                          1
                              ? _exercises[_currentExerciseIndex + 1].muscle
                              : null,
                          onSkipRest: _skipRest,
                          onAddRestTime: () => _addRestTime(30),
                        )
                      : _buildActiveView(),
                ),
              ],
            ),
          ),
          if (_showPRCelebration)
            PRCelebration(
              show: _showPRCelebration,
              animationController: _prCelebrationController,
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: [
          const SizedBox(height: Spacing.md),

          // Exercise navigation dots
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
          const SizedBox(height: Spacing.xl),

          // Main set card
          SetCard(
            currentSet: currentSet,
            previousBest: exercise.previousBest,
            isWarmup: currentSet.isWarmup,
            currentSetIndex: _currentSetIndex,
            weightType: exercise.weightType,
            isMaxReps: currentSet.isMaxReps,
          ),
          const SizedBox(height: Spacing.lg),

          // Weight and reps input
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
          const SizedBox(height: Spacing.xl),

          // Validate button
          _buildValidateButton(),
          const SizedBox(height: Spacing.xl),

          // Sets progress
          SetIndicators(
            exercise: exercise,
            currentSetIndex: _currentSetIndex,
            onSetTap: (index) {
              setState(() {
                _currentSetIndex = index;
              });
            },
          ),
          const SizedBox(height: Spacing.lg),

          // Stats bar
          StatsBar(
            totalVolume: _totalVolume,
            completedSets: _exercises.fold<int>(
                0, (sum, e) => sum + e.sets.where((s) => s.isCompleted).length),
            totalSets: _exercises.fold<int>(0, (sum, e) => sum + e.sets.length),
            estimatedKcal: (_totalVolume * 0.05).toInt(),
          ),
          const SizedBox(height: Spacing.xxl),
        ],
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
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
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
