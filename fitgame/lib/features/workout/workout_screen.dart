import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/fg_glass_card.dart';
import '../../shared/widgets/fg_mesh_gradient.dart';
import 'create/create_choice_screen.dart';
import 'create/session_creation_screen.dart';
import 'tracking/active_workout_screen.dart';
import 'history/workout_history_screen.dart';
import 'edit/program_edit_screen.dart';
import 'progress/exercise_progress_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _heroController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _heroGlow;

  // State
  bool _isLoading = true;
  bool hasActiveProgram = false;
  String programName = '';
  String? programId;
  int currentWeek = 1;
  int totalWeeks = 8;
  int activeProgramIndex = 0;
  String nextSessionName = '';
  String nextSessionMuscles = '';
  int nextSessionExercises = 0;
  int nextSessionSets = 0;
  int nextSessionDuration = 45;

  // Programs from Supabase
  List<Map<String, dynamic>> _myPrograms = [];
  List<Map<String, dynamic>> _assignedPrograms = [];
  Map<String, dynamic>? _coachInfo;

  // Track calculated current week per program (programId -> week number)
  Map<String, int> _programWeeks = {};

  // Realtime listener reference
  void Function(Map<String, dynamic>)? _assignmentListener;

  List<Map<String, dynamic>> recentSessions = [];
  // Raw sessions for historical duration lookup
  List<Map<String, dynamic>> _rawSessions = [];

  List<Map<String, dynamic>> get savedPrograms {
    // Combine my programs and assigned programs
    final List<Map<String, dynamic>> all = [];

    for (final p in _myPrograms) {
      final pId = p['id']?.toString() ?? '';
      all.add({
        'id': p['id'],
        'name': p['name'] ?? 'Sans nom',
        'weeks': p['duration_weeks'] ?? 8,
        'currentWeek': _programWeeks[pId] ?? 1,
        'isActive': false,
        'isFromCoach': false,
        'days': p['days'] ?? [],
      });
    }

    for (final p in _assignedPrograms) {
      final pId = p['id']?.toString() ?? '';
      all.add({
        'id': p['id'],
        'name': p['name'] ?? 'Sans nom',
        'weeks': p['duration_weeks'] ?? 8,
        'currentWeek': _programWeeks[pId] ?? 1,
        'isActive': false,
        'isFromCoach': true,
        'coachName': _coachInfo?['full_name'] ?? 'Coach',
        'days': p['days'] ?? [],
      });
    }

    // Mark active program
    if (all.isNotEmpty && activeProgramIndex < all.length) {
      all[activeProgramIndex]['isActive'] = true;
    }

    return all;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _heroController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.08, end: 0.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _heroGlow = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeInOut),
    );

    _loadData();
    _subscribeToAssignments();
  }

  void _subscribeToAssignments() {
    _assignmentListener = (assignment) {
      // Only react to program assignments
      if (assignment['program_id'] != null) {
        // Reload data when a new program is assigned
        _loadData();

        // Show snackbar notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nouveau programme assigné par votre coach !'),
              backgroundColor: FGColors.accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    };
    SupabaseService.addAssignmentListener(_assignmentListener!);
  }

  Future<void> _loadData() async {
    if (!SupabaseService.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load in parallel
      final results = await Future.wait([
        SupabaseService.getPrograms(),
        SupabaseService.getAssignedPrograms(),
        SupabaseService.getCoachInfo(),
        SupabaseService.getWorkoutSessions(limit: 10),
      ]);

      final myPrograms = results[0] as List<Map<String, dynamic>>;
      final assignedPrograms = results[1] as List<Map<String, dynamic>>;
      final coachInfo = results[2] as Map<String, dynamic>?;
      final sessions = results[3] as List<Map<String, dynamic>>;

      if (!mounted) return;

      // Calculate current week for each program based on first session date
      final programWeeks = <String, int>{};
      for (final session in sessions) {
        final pId = session['program_id']?.toString();
        if (pId == null) continue;
        final startedAt = session['started_at'] != null
            ? DateTime.tryParse(session['started_at'].toString())
            : null;
        if (startedAt == null) continue;

        // Track the oldest session per program
        if (!programWeeks.containsKey(pId)) {
          final weeksPassed = DateTime.now().difference(startedAt).inDays ~/ 7;
          programWeeks[pId] = (weeksPassed + 1).clamp(1, 52);
        }
      }

      setState(() {
        _myPrograms = myPrograms;
        _assignedPrograms = assignedPrograms;
        _coachInfo = coachInfo;
        _programWeeks = programWeeks;
        _rawSessions = sessions;
        _isLoading = false;

        // Set active program
        if (savedPrograms.isNotEmpty) {
          hasActiveProgram = true;
          _setActiveProgram(0);
        }

        // Process recent sessions
        _processRecentSessions(sessions);
      });
    } catch (e) {
      debugPrint('Error loading workout data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setActiveProgram(int index) {
    if (index >= savedPrograms.length) return;

    final program = savedPrograms[index];
    activeProgramIndex = index;
    programId = program['id']?.toString();
    programName = program['name'] as String;
    currentWeek = program['currentWeek'] as int;
    totalWeeks = program['weeks'] as int;

    // Set next session from program days — match today's weekday
    final days = program['days'] as List? ?? [];
    if (days.isNotEmpty) {
      final firstDay = _matchTodayDay(days);
      nextSessionName = firstDay['name'] ?? 'Jour 1';

      // Extract muscles from exercises
      final exercises = firstDay['exercises'] as List? ?? [];
      final muscles = <String>{};
      for (final ex in exercises) {
        final muscle = ex['muscle'] ?? ex['muscleGroup'] ?? ex['muscle_group'];
        if (muscle != null) muscles.add(muscle.toString());
      }
      nextSessionMuscles = muscles.take(2).join(' • ');
      nextSessionExercises = exercises.length;

      // Calculate total sets
      int totalSets = 0;
      for (final ex in exercises) {
        final customSets = ex['customSets'] as List?;
        if (customSets != null) {
          totalSets += customSets.length;
        } else {
          totalSets += (ex['sets'] as num?)?.toInt() ?? 3;
        }
      }
      nextSessionSets = totalSets;

      // Use historical duration if available, otherwise estimate from program data
      nextSessionDuration = _getHistoricalDuration(nextSessionName) ??
          _estimateWorkoutMinutes(exercises);
    } else {
      nextSessionName = 'Séance';
      nextSessionMuscles = '';
      nextSessionExercises = 0;
      nextSessionSets = 0;
      nextSessionDuration = 45;
    }
  }

  /// Match program day to today's weekday, fallback to first day
  Map<String, dynamic> _matchTodayDay(List<dynamic> days) {
    const weekdayNames = {
      1: 'lundi', 2: 'mardi', 3: 'mercredi',
      4: 'jeudi', 5: 'vendredi', 6: 'samedi', 7: 'dimanche',
    };
    final todayName = weekdayNames[DateTime.now().weekday]!;
    for (final day in days) {
      final dayMap = day as Map<String, dynamic>;
      final dayName = (dayMap['name'] ?? '').toString().toLowerCase();
      if (dayName.contains(todayName)) {
        return dayMap;
      }
    }
    return days[0] as Map<String, dynamic>;
  }

  /// Look up actual duration from the most recent completed session with the same day name
  int? _getHistoricalDuration(String dayName) {
    final normalizedDay = dayName.toLowerCase();
    for (final session in _rawSessions) {
      final sessionDay = (session['day_name'] ?? '').toString().toLowerCase();
      final completedAt = session['completed_at'];
      final duration = (session['duration_minutes'] as num?)?.toInt();
      if (sessionDay == normalizedDay && completedAt != null && duration != null && duration > 0) {
        return duration;
      }
    }
    return null;
  }

  int _estimateWorkoutMinutes(List<dynamic> exercises) {
    int totalSeconds = 0;
    for (final ex in exercises) {
      final customSets = ex['customSets'] as List?;
      final hasWarmup = ex['warmup'] == true || ex['warmupEnabled'] == true;
      final restSeconds = (ex['restSeconds'] as num?)?.toInt() ??
          (ex['rest_seconds'] as num?)?.toInt() ?? 90;

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

      final warmupSetCount = hasWarmup ? (workSetCount >= 4 ? 3 : 2) : 0;
      final workSetDuration = avgReps * 4 + 20;
      // Warmups avg ~6 reps (10, 5, 3 or 8, 3)
      const warmupSetDuration = 6 * 4 + 20; // 44s

      for (int i = 0; i < workSetCount; i++) {
        totalSeconds += workSetDuration;
        if (i < workSetCount - 1) {
          totalSeconds += restSeconds;
        }
      }
      for (int i = 0; i < warmupSetCount; i++) {
        totalSeconds += warmupSetDuration;
        totalSeconds += 60;
      }
      totalSeconds += 90; // transition
    }
    if (exercises.isNotEmpty) {
      totalSeconds -= 90;
    }
    return (totalSeconds / 60).round().clamp(5, 180);
  }

  void _processRecentSessions(List<Map<String, dynamic>> sessions) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final List<Map<String, dynamic>> processed = [];

    for (final session in sessions) {
      final completedAt = session['completed_at'] != null
          ? DateTime.tryParse(session['completed_at'].toString())
          : null;

      if (completedAt == null) continue;

      final isThisWeek = completedAt.isAfter(weekStart);
      final isToday = completedAt.day == now.day &&
          completedAt.month == now.month &&
          completedAt.year == now.year;

      final volume = (session['total_volume_kg'] as num?)?.toDouble() ?? 0;
      final duration = (session['duration_minutes'] as num?)?.toInt() ?? 0;

      if (!isThisWeek) continue;

      // Format date
      String dateStr;
      if (isToday) {
        dateStr = "Aujourd'hui";
      } else if (completedAt.day == now.day - 1) {
        dateStr = 'Hier';
      } else {
        final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        dateStr = weekdays[completedAt.weekday - 1];
      }

      // Check for PRs
      final prs = session['personal_records'] as List? ?? [];
      final hasPR = prs.isNotEmpty;
      String? prExercise;
      if (hasPR && prs.first is Map) {
        prExercise = prs.first['exerciseName']?.toString();
      }

      processed.add({
        'name': session['day_name'] ?? 'Séance',
        'date': dateStr,
        'volume': (volume * 1000).round(), // Convert to kg
        'maxVolume': 7000,
        'duration': duration,
        'isToday': isToday,
        'pr': hasPR,
        'prExercise': prExercise,
      });

      if (processed.length >= 3) break;
    }

    recentSessions = processed;
  }

  @override
  void dispose() {
    if (_assignmentListener != null) {
      SupabaseService.removeAssignmentListener(_assignmentListener!);
    }
    _pulseController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          FGMeshGradient.workout(animation: _pulseAnimation),
          SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : hasActiveProgram
                    ? _buildMainContent()
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: FGColors.accent,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRAINING',
                style: FGTypography.caption.copyWith(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: FGColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      programName,
                      style: FGTypography.h3.copyWith(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FGColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'S$currentWeek',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.success,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _openCreateFlow(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.accent.withValues(alpha: 0.2),
                    FGColors.accent.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(Spacing.md),
                border: Border.all(color: FGColors.accent.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: FGColors.accent,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateFlow() async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CreateChoiceScreen(),
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

    // Reload data if program was created successfully
    if (result == true && mounted) {
      _loadData();
    }
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spacing.lg),

                // === HERO: NEXT SESSION ===
                _buildHeroCard(),
                const SizedBox(height: Spacing.lg),

                // === RECENT SESSIONS ===
                Expanded(child: _buildRecentSessions()),
                const SizedBox(height: Spacing.md),

                // === QUICK ACTIONS ===
                _buildQuickActions(),
                const SizedBox(height: Spacing.md),
              ],
            ),
          ),
        ),
      ],
    );
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

  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: _heroGlow,
      builder: (context, child) {
        return GestureDetector(
          onTap: _startWorkout,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: FGColors.accent.withValues(alpha: _heroGlow.value * 0.3),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: FGGlassCard(
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.fitness_center,
                      size: 120,
                      color: FGColors.accent.withValues(alpha: 0.05),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lg,
                          vertical: Spacing.md,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              FGColors.accent.withValues(alpha: 0.15),
                              FGColors.accent.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: FGColors.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PROCHAINE SÉANCE',
                                style: FGTypography.caption.copyWith(
                                  color: FGColors.textOnAccent,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: FGColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '~$nextSessionDuration min',
                              style: FGTypography.caption.copyWith(
                                color: FGColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(Spacing.lg),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      nextSessionName,
                                      style: FGTypography.h1.copyWith(
                                        fontSize: 36,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: Spacing.xs),
                                  Text(
                                    nextSessionMuscles,
                                    style: FGTypography.body.copyWith(
                                      color: FGColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: Spacing.md),
                                  Row(
                                    children: [
                                      _buildExerciseChip(
                                        Icons.fitness_center,
                                        '$nextSessionExercises exos',
                                      ),
                                      const SizedBox(width: Spacing.sm),
                                      _buildExerciseChip(
                                        Icons.layers,
                                        '$nextSessionSets séries',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Play button
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    FGColors.accent,
                                    FGColors.accent.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: FGColors.accent.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: FGColors.textOnAccent,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: FGColors.glassBorder,
        borderRadius: BorderRadius.circular(Spacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: FGColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CETTE SEMAINE',
              style: FGTypography.caption.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: FGColors.textSecondary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _openHistory(null),
              child: Row(
                children: [
                  Text(
                    'Tout voir',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: FGColors.accent,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        if (recentSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              color: FGColors.glassSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Spacing.md),
              border: Border.all(color: FGColors.glassBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                  size: 24,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    'Aucune séance cette semaine',
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: recentSessions.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + index * 100),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildRecentSessionCard(recentSessions[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentSessionCard(Map<String, dynamic> session) {
    final isToday = session['isToday'] as bool;
    final hasPR = session['pr'] as bool;
    final volume = session['volume'] as int;
    final maxVolume = session['maxVolume'] as int;
    final volumePercent = volume / maxVolume;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: GestureDetector(
        onTap: () => _openHistory(session['name'] as String),
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: isToday
                ? FGColors.success.withValues(alpha: 0.08)
                : FGColors.glassSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(Spacing.md),
            border: Border.all(
              color: isToday
                  ? FGColors.success.withValues(alpha: 0.3)
                  : FGColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              // Check icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isToday
                      ? FGColors.success.withValues(alpha: 0.2)
                      : FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: isToday ? FGColors.success : FGColors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: Spacing.md),

              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            session['name'] as String,
                            style: FGTypography.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasPR) ...[
                          const SizedBox(width: Spacing.sm),
                          GestureDetector(
                            onTap: () {
                              final prExercise = session['prExercise'] as String?;
                              if (prExercise != null) {
                                _openPRProgress(prExercise);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: FGColors.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    size: 10,
                                    color: FGColors.warning,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'PR',
                                    style: FGTypography.caption.copyWith(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: FGColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Volume bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              height: 4,
                              child: LinearProgressIndicator(
                                value: volumePercent,
                                backgroundColor: FGColors.glassBorder,
                                valueColor: AlwaysStoppedAnimation(
                                  isToday ? FGColors.success : FGColors.accent.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          '${(volume / 1000).toStringAsFixed(1)}t',
                          style: FGTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: FGColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: Spacing.md),

              // Date & duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    session['date'] as String,
                    style: FGTypography.caption.copyWith(
                      color: isToday ? FGColors.success : FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${session['duration']} min',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.tune,
            label: 'Modifier',
            sublabel: 'Programme',
            onTap: () => _openProgramEdit(),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _buildActionCard(
            icon: Icons.history,
            label: 'Historique',
            sublabel: 'Séances',
            onTap: () => _openHistory(null),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _buildActionCard(
            icon: Icons.bolt,
            label: 'Séance',
            sublabel: 'Libre',
            isAccent: true,
            onTap: () => _openFreeSession(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md, horizontal: Spacing.sm),
        decoration: BoxDecoration(
          color: isAccent
            ? FGColors.accent.withValues(alpha: 0.1)
            : FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isAccent
              ? FGColors.accent.withValues(alpha: 0.3)
              : FGColors.glassBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isAccent
                  ? FGColors.accent.withValues(alpha: 0.2)
                  : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isAccent ? FGColors.accent : FGColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              label,
              style: FGTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isAccent ? FGColors.accent : FGColors.textPrimary,
                fontSize: 11,
              ),
            ),
            Text(
              sublabel,
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHistory(String? filter) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            WorkoutHistoryScreen(initialFilter: filter),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openProgramEdit() {
    if (programId == null) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProgramEditScreen(programId: programId!),
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

  void _openFreeSession() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SessionCreationScreen(),
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

  void _switchProgram(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _setActiveProgram(index);
      hasActiveProgram = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Programme "$programName" activé'),
        backgroundColor: FGColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _openPRProgress(String exerciseName) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ExerciseProgressScreen(exerciseName: exerciseName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // === EMPTY STATE ===
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: FGColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.fitness_center,
              color: FGColors.accent,
              size: 40,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            'Prêt à\ncommencer ?',
            textAlign: TextAlign.center,
            style: FGTypography.h1.copyWith(fontSize: 42, height: 1.1),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Choisis ton programme ou crée une séance',
            textAlign: TextAlign.center,
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const Spacer(),
          _buildEmptyOption(
            icon: Icons.auto_awesome_rounded,
            title: 'Programme guidé',
            subtitle: 'Un plan sur plusieurs semaines',
            isPrimary: true,
            onTap: () => _showProgramSheet(),
          ),
          const SizedBox(height: Spacing.md),
          _buildEmptyOption(
            icon: Icons.bolt_rounded,
            title: 'Séance libre',
            subtitle: 'Crée ton entraînement',
            isPrimary: false,
            onTap: () => _openFreeSession(),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildEmptyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.accent.withValues(alpha: 0.15),
                    FGColors.accent.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isPrimary ? null : FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.lg),
          border: Border.all(
            color: isPrimary
                ? FGColors.accent.withValues(alpha: 0.3)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPrimary
                    ? FGColors.accent.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.md),
              ),
              child: Icon(
                icon,
                color: isPrimary ? FGColors.accent : FGColors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isPrimary ? FGColors.accent : FGColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: isPrimary ? FGColors.accent : FGColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // === BOTTOM SHEET ===
  void _showProgramSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: FGColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
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
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Row(
                  children: [
                    Text('Programmes', style: FGTypography.h2),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: FGColors.glassBorder,
                          borderRadius: BorderRadius.circular(Spacing.sm),
                        ),
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
              const SizedBox(height: Spacing.lg),

              // List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  children: [
                    // Section: Coach programs
                    if (_assignedPrograms.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Du coach',
                        Icons.person_outline,
                        FGColors.accent,
                      ),
                      const SizedBox(height: Spacing.sm),
                      ...savedPrograms
                          .where((p) => p['isFromCoach'] == true)
                          .map(
                            (program) => Padding(
                              padding: const EdgeInsets.only(bottom: Spacing.md),
                              child: _buildProgramListItem(program),
                            ),
                          ),
                      const SizedBox(height: Spacing.lg),
                    ],

                    // Section: My programs
                    if (_myPrograms.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Mes programmes',
                        Icons.calendar_month_outlined,
                        FGColors.textSecondary,
                      ),
                      const SizedBox(height: Spacing.sm),
                      ...savedPrograms
                          .where((p) => p['isFromCoach'] != true)
                          .map(
                            (program) => Padding(
                              padding: const EdgeInsets.only(bottom: Spacing.md),
                              child: _buildProgramListItem(program),
                            ),
                          ),
                    ],

                    // Empty state
                    if (savedPrograms.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(Spacing.xl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 48,
                              color: FGColors.textSecondary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: Spacing.md),
                            Text(
                              'Aucun programme',
                              style: FGTypography.body.copyWith(
                                color: FGColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: Spacing.md),
                    _buildNewProgramButton(),
                    const SizedBox(height: Spacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Spacing.sm),
        Text(
          title.toUpperCase(),
          style: FGTypography.caption.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgramListItem(Map<String, dynamic> program) {
    final index = savedPrograms.indexOf(program);
    final isActive = index == activeProgramIndex;
    final currentW = program['currentWeek'] as int;
    final totalW = program['weeks'] as int;
    final hasProgress = currentW > 0;
    final isFromCoach = program['isFromCoach'] == true;
    final coachName = program['coachName'] as String?;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          _switchProgram(index);
        }
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: isActive
              ? FGColors.success.withValues(alpha: 0.08)
              : isFromCoach
                  ? FGColors.accent.withValues(alpha: 0.05)
                  : FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.lg),
          border: Border.all(
            color: isActive
                ? FGColors.success.withValues(alpha: 0.3)
                : isFromCoach
                    ? FGColors.accent.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? FGColors.success.withValues(alpha: 0.2)
                    : isFromCoach
                        ? FGColors.accent.withValues(alpha: 0.15)
                        : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Icon(
                isActive
                    ? Icons.play_arrow_rounded
                    : isFromCoach
                        ? Icons.person_outline
                        : Icons.calendar_month_outlined,
                color: isActive
                    ? FGColors.success
                    : isFromCoach
                        ? FGColors.accent
                        : FGColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          program['name'] as String,
                          style: FGTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: Spacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FGColors.success,
                            borderRadius: BorderRadius.circular(Spacing.xs),
                          ),
                          child: Text(
                            'ACTIF',
                            style: FGTypography.caption.copyWith(
                              fontSize: 9,
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      if (isFromCoach) ...[
                        const SizedBox(width: Spacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FGColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(Spacing.xs),
                          ),
                          child: Text(
                            'COACH',
                            style: FGTypography.caption.copyWith(
                              fontSize: 9,
                              color: FGColors.accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    isFromCoach
                        ? 'Par ${coachName ?? 'Coach'} • $totalW semaines'
                        : hasProgress
                            ? 'Semaine $currentW/$totalW'
                            : '$totalW semaines',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isActive)
              const Icon(
                Icons.chevron_right_rounded,
                color: FGColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewProgramButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _openCreateFlow();
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: FGColors.accent.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(Spacing.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: FGColors.accent,
              size: 20,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Nouveau programme',
              style: FGTypography.body.copyWith(
                color: FGColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
