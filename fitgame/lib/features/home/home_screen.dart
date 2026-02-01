import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/constants/spacing.dart';
import '../../shared/widgets/fg_neon_button.dart';
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

  // Real data - fetched from backend
  final int currentStreak = 0;

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
          _buildMeshGradient(),

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
                          HomeHeader(currentStreak: currentStreak),
                          const SizedBox(height: Spacing.md),

                          // === [2] TODAY'S WORKOUT ===
                          const TodayWorkoutCard(),
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

  Widget _buildMeshGradient() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Base background
            Container(color: FGColors.background),

            // Top-right glow orb
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FGColors.accent.withValues(alpha: _pulseAnimation.value * 0.6),
                      FGColors.accent.withValues(alpha: _pulseAnimation.value * 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Bottom-left subtle glow
            Positioned(
              bottom: 100,
              left: -120,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FGColors.accent.withValues(alpha: _pulseAnimation.value * 0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // Noise overlay for texture
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      FGColors.background.withValues(alpha: 0.3),
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
