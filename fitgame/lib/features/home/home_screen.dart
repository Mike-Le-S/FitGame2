import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/fg_neon_button.dart';
import '../../shared/widgets/fg_mesh_gradient.dart';
import '../workout/tracking/active_workout_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/sleep_summary_widget.dart';
import 'widgets/macro_summary_widget.dart';
import 'widgets/friend_activity_peek.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int)? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // User data from Supabase
  String _userName = '';
  int _currentStreak = 0;

  // Today's workout data from Supabase
  String? _sessionName;
  String? _sessionMuscles;
  int? _exerciseCount;
  int? _estimatedMinutes;

  // Raw sessions for historical duration lookup
  List<Map<String, dynamic>> _rawSessions = [];

  // Widget data from Supabase
  Map<String, dynamic>? _todayHealth;
  Map<String, dynamic>? _todayNutrition;
  Map<String, dynamic>? _yesterdayNutrition;
  List<Map<String, dynamic>> _recentActivities = [];
  int _targetCalories = 2000;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadUserData();
  }

  /// Look up actual duration from the most recent completed session with the same day name.
  /// Ignores sessions under 5 min (aborted/save-and-quit sessions).
  int? _getHistoricalDuration(String dayName) {
    final normalizedDay = dayName.toLowerCase();
    for (final session in _rawSessions) {
      final sessionDay = (session['day_name'] ?? '').toString().toLowerCase();
      final completedAt = session['completed_at'];
      final duration = (session['duration_minutes'] as num?)?.toInt();
      if (sessionDay == normalizedDay && completedAt != null && duration != null && duration >= 5) {
        return duration;
      }
    }
    return null;
  }

  /// Estimate workout duration from program exercise data
  int _estimateWorkoutMinutes(List<dynamic> exercises) {
    int totalSeconds = 0;

    for (final ex in exercises) {
      final customSets = ex['customSets'] as List?;
      final hasWarmup = ex['warmup'] == true || ex['warmupEnabled'] == true;
      final restSeconds = (ex['restSeconds'] as num?)?.toInt() ??
          (ex['rest_seconds'] as num?)?.toInt() ?? 90;

      // Count work sets
      int workSetCount;
      int avgReps;
      if (customSets != null && customSets.isNotEmpty) {
        final workSets = customSets.where((s) => s['isWarmup'] != true).toList();
        workSetCount = workSets.length;
        avgReps = workSets.isNotEmpty
            ? (workSets.map((s) => (s['reps'] as num?)?.toInt() ?? 10)
                .reduce((a, b) => a + b) / workSets.length).round()
            : 10;
      } else {
        workSetCount = (ex['sets'] as num?)?.toInt() ?? 3;
        avgReps = (ex['reps'] as num?)?.toInt() ?? 10;
      }

      // Warmup sets estimate (2-3 warmup sets if enabled)
      final warmupSetCount = hasWarmup ? (workSetCount >= 4 ? 3 : 2) : 0;

      // Set execution time: reps × 4s + 20s (setup, unrack, rerack, breathing)
      final workSetDuration = avgReps * 4 + 20;
      // Warmups avg ~6 reps (10, 5, 3 or 8, 3)
      const warmupSetDuration = 6 * 4 + 20; // 44s

      // Work sets: execution + rest (no rest after last set of exercise)
      for (int i = 0; i < workSetCount; i++) {
        totalSeconds += workSetDuration;
        if (i < workSetCount - 1) {
          totalSeconds += restSeconds;
        }
      }

      // Warmup sets: execution + 60s rest
      for (int i = 0; i < warmupSetCount; i++) {
        totalSeconds += warmupSetDuration;
        totalSeconds += 60;
      }

      // Transition to next exercise: 90s (walk, load plates, adjust)
      totalSeconds += 90;
    }

    // Remove last transition (no transition after last exercise)
    if (exercises.isNotEmpty) {
      totalSeconds -= 90;
    }

    return (totalSeconds / 60).round().clamp(5, 180);
  }

  Future<void> _loadUserData() async {
    try {
      // Load profile, programs, and sessions in parallel
      final results = await Future.wait([
        SupabaseService.getCurrentProfile(),
        SupabaseService.getPrograms(),
        SupabaseService.getAssignedPrograms(),
        SupabaseService.getWorkoutSessions(limit: 10),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final myPrograms = results[1] as List<Map<String, dynamic>>;
      final assignedPrograms = results[2] as List<Map<String, dynamic>>;
      final sessions = results[3] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          // User info
          _userName = profile?['full_name'] ?? '';
          _currentStreak = profile?['current_streak'] ?? 0;
          _rawSessions = sessions;

          // Get first available program (prioritize assigned from coach)
          final allPrograms = [...assignedPrograms, ...myPrograms];
          if (allPrograms.isNotEmpty) {
            final program = allPrograms.first;
            final days = program['days'] as List? ?? [];

            if (days.isNotEmpty) {
              // Match today's weekday to a program day
              final weekdayNames = {
                1: 'lundi', 2: 'mardi', 3: 'mercredi',
                4: 'jeudi', 5: 'vendredi', 6: 'samedi', 7: 'dimanche',
              };
              final todayName = weekdayNames[DateTime.now().weekday]!;

              // Find matching day or fall back to first day
              var matchedDay = days[0] as Map<String, dynamic>;
              for (final day in days) {
                final dayMap = day as Map<String, dynamic>;
                final dayName = (dayMap['name'] ?? '').toString().toLowerCase();
                if (dayName.contains(todayName)) {
                  matchedDay = dayMap;
                  break;
                }
              }

              _sessionName = matchedDay['name'] ?? 'Jour 1';

              // Extract muscles from exercises
              final exercises = matchedDay['exercises'] as List? ?? [];
              final muscles = <String>{};
              for (final ex in exercises) {
                final muscle = ex['muscle'] ?? ex['muscleGroup'] ?? ex['muscle_group'];
                if (muscle != null) muscles.add(muscle.toString());
              }
              _sessionMuscles = muscles.take(2).join(' • ');
              _exerciseCount = exercises.length;
              _estimatedMinutes = _getHistoricalDuration(_sessionName!) ??
                  _estimateWorkoutMinutes(exercises);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impossible de charger les données'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: FGColors.textPrimary,
              onPressed: _loadUserData,
            ),
          ),
        );
      }
    }

    // Load widget data (nutrition, health, activity) in parallel
    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().substring(0, 10);
      final yesterday = today.subtract(const Duration(days: 1));

      final widgetResults = await Future.wait([
        SupabaseService.getNutritionLog(today),
        SupabaseService.getNutritionLog(yesterday),
        SupabaseService.getActivityFeed(limit: 3),
        SupabaseService.getHealthMetrics(startDate: todayStr, endDate: todayStr),
        SupabaseService.getActiveDietPlan(),
      ]);

      if (mounted) {
        final healthList = widgetResults[3] as List<Map<String, dynamic>>;
        setState(() {
          _todayNutrition = widgetResults[0] as Map<String, dynamic>?;
          _yesterdayNutrition = widgetResults[1] as Map<String, dynamic>?;
          _recentActivities = widgetResults[2] as List<Map<String, dynamic>>;
          _todayHealth = healthList.isNotEmpty ? healthList.first : null;

          final dietPlan = widgetResults[4] as Map<String, dynamic>?;
          if (dietPlan != null) {
            _targetCalories = (dietPlan['training_calories'] as num?)?.toInt() ?? 2000;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading widget data: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startWorkout() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
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
    );
  }

  void _navigateToTab(int index) {
    widget.onNavigateToTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          // === MESH GRADIENT BACKGROUND ===
          FGMeshGradient.home(animation: _pulseAnimation),

          // === MAIN CONTENT ===
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Spacing.md),

                          // === [1] HEADER avec streak badge ===
                          HomeHeader(
                            currentStreak: _currentStreak,
                            userName: _userName,
                          ),
                          const SizedBox(height: Spacing.md),

                          // === [2] TODAY'S WORKOUT ===
                          TodayWorkoutCard(
                            sessionName: _sessionName,
                            sessionMuscles: _sessionMuscles,
                            exerciseCount: _exerciseCount,
                            estimatedMinutes: _estimatedMinutes,
                          ),
                          const SizedBox(height: Spacing.md),

                          // === [3] SLEEP SUMMARY → Santé (index 4) ===
                          SleepSummaryWidget(
                            onTap: () => _navigateToTab(4),
                            totalSleep: _todayHealth?['sleep_duration_minutes'] != null
                                ? '${((_todayHealth!['sleep_duration_minutes'] as num) / 60).toStringAsFixed(1)}h'
                                : '--',
                            sleepScore: (_todayHealth?['sleep_score'] as num?)?.toInt() ?? 0,
                            deepPercent: _calculateSleepPercent(_todayHealth, 'deep_sleep_minutes'),
                            corePercent: _calculateSleepPercent(_todayHealth, 'light_sleep_minutes'),
                            remPercent: _calculateSleepPercent(_todayHealth, 'rem_sleep_minutes'),
                          ),
                          const SizedBox(height: Spacing.md),

                          // === [5] MACRO SUMMARY → Nutrition (index 3) ===
                          MacroSummaryWidget(
                            onTap: () => _navigateToTab(3),
                            currentCalories: (_todayNutrition?['calories_consumed'] as num?)?.toInt() ?? 0,
                            targetCalories: _targetCalories,
                            proteinPercent: _calculateMacroPercent(_todayNutrition, 'protein'),
                            carbsPercent: _calculateMacroPercent(_todayNutrition, 'carbs'),
                            fatPercent: _calculateMacroPercent(_todayNutrition, 'fat'),
                            yesterdayConsumed: (_yesterdayNutrition?['calories_consumed'] as num?)?.toInt() ?? 0,
                            yesterdayBurned: (_yesterdayNutrition?['calories_burned'] as num?)?.toInt() ?? 0,
                          ),
                          const SizedBox(height: Spacing.md),

                          // === [6] FRIEND ACTIVITY → Social (index 2) ===
                          FriendActivityPeek(
                            onTap: () => _navigateToTab(2),
                            activities: _recentActivities,
                          ),
                          const SizedBox(height: Spacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),

                // === [8] BOTTOM CTA ===
                _buildBottomCTA(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMacroPercent(Map<String, dynamic>? nutritionLog, String macro) {
    if (nutritionLog == null) return 0.0;
    final meals = nutritionLog['meals'] as List?;
    if (meals == null || meals.isEmpty) return 0.0;

    double totalMacro = 0;
    double totalCalories = 0;
    for (final meal in meals) {
      final mealMap = meal as Map<String, dynamic>? ?? {};
      final foods = mealMap['foods'] as List? ?? [];
      for (final food in foods) {
        final foodMap = food as Map<String, dynamic>? ?? {};
        final macros = foodMap['macros'] as Map<String, dynamic>? ?? {};
        totalMacro += (macros[macro] as num?)?.toDouble() ?? 0.0;
        totalCalories += (foodMap['calories'] as num?)?.toDouble() ?? 0.0;
      }
    }
    if (totalCalories == 0) return 0.0;

    // Convert macro grams to calories: P=4cal/g, C=4cal/g, F=9cal/g
    final calPerGram = macro == 'fat' ? 9.0 : 4.0;
    return ((totalMacro * calPerGram) / totalCalories).clamp(0.0, 1.0);
  }

  double _calculateSleepPercent(Map<String, dynamic>? health, String minutesKey) {
    if (health == null) return 0.0;
    final totalMinutes = (health['sleep_duration_minutes'] as num?)?.toDouble() ?? 0.0;
    if (totalMinutes == 0) return 0.0;
    final phaseMinutes = (health[minutesKey] as num?)?.toDouble() ?? 0.0;
    return (phaseMinutes / totalMinutes).clamp(0.0, 1.0);
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FGColors.background.withValues(alpha: 0.0),
            FGColors.background,
          ],
        ),
      ),
      child: FGNeonButton(
        label: 'Commencer la séance',
        isExpanded: true,
        onPressed: _startWorkout,
      ),
    );
  }
}
