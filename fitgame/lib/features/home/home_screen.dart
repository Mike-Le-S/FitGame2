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

  Future<void> _loadUserData() async {
    try {
      // Load profile and programs in parallel
      final results = await Future.wait([
        SupabaseService.getCurrentProfile(),
        SupabaseService.getPrograms(),
        SupabaseService.getAssignedPrograms(),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final myPrograms = results[1] as List<Map<String, dynamic>>;
      final assignedPrograms = results[2] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          // User info
          _userName = profile?['full_name'] ?? '';
          _currentStreak = profile?['current_streak'] ?? 0;

          // Get first available program (prioritize assigned from coach)
          final allPrograms = [...assignedPrograms, ...myPrograms];
          if (allPrograms.isNotEmpty) {
            final program = allPrograms.first;
            final days = program['days'] as List? ?? [];

            if (days.isNotEmpty) {
              final firstDay = days[0] as Map<String, dynamic>;
              _sessionName = firstDay['name'] ?? 'Jour 1';

              // Extract muscles from exercises
              final exercises = firstDay['exercises'] as List? ?? [];
              final muscles = <String>{};
              for (final ex in exercises) {
                final muscle = ex['muscleGroup'] ?? ex['muscle_group'];
                if (muscle != null) muscles.add(muscle.toString());
              }
              _sessionMuscles = muscles.take(2).join(' • ');
              _exerciseCount = exercises.length;
              _estimatedMinutes = exercises.length * 8 + 10;
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
                          ),
                          const SizedBox(height: Spacing.md),

                          // === [5] MACRO SUMMARY → Nutrition (index 3) ===
                          MacroSummaryWidget(
                            onTap: () => _navigateToTab(3),
                          ),
                          const SizedBox(height: Spacing.md),

                          // === [6] FRIEND ACTIVITY → Social (index 2) ===
                          FriendActivityPeek(
                            onTap: () => _navigateToTab(2),
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
