import 'package:flutter/material.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../shared/widgets/fg_glass_card.dart';
import '../../shared/widgets/fg_neon_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Mock data - TODO: Replace with real data
  final int currentStreak = 12;
  final int weekSessions = 3;
  final int weekTarget = 5;
  final String totalTime = '1h45';
  final int calories = 850;

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
                          const SizedBox(height: Spacing.lg),

                          // === HEADER ===
                          _buildHeader(),
                          const SizedBox(height: Spacing.xl),

                          // === TODAY'S WORKOUT - MAIN CTA ===
                          _buildTodayWorkout(),
                          const SizedBox(height: Spacing.xl),

                          // === HERO STREAK ===
                          _buildHeroStreak(),
                          const SizedBox(height: Spacing.xl),

                          // === INLINE STATS ===
                          _buildInlineStats(),
                          const SizedBox(height: Spacing.lg),

                          // === LAST WORKOUT - SUBTLE ===
                          _buildLastWorkout(),
                          const SizedBox(height: Spacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),

                // === BOTTOM CTA ===
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salut Mike',
              style: FGTypography.h2.copyWith(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Prêt à dominer ?',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
              ),
            ),
          ],
        ),
        // Profile avatar placeholder
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: FGColors.glassBorder,
              width: 2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FGColors.accent.withValues(alpha: 0.3),
                FGColors.accent.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: const Center(
            child: Text(
              'M',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: FGColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStreak() {
    final streakInfo = _getStreakInfo(currentStreak);
    final nextMilestone = _getNextMilestone(currentStreak);
    final prevMilestone = _getPreviousMilestone(currentStreak);
    final progress = (currentStreak - prevMilestone) / (nextMilestone - prevMilestone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small label
        Text(
          'SÉRIE EN COURS',
          style: FGTypography.caption.copyWith(
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.sm),

        // MASSIVE streak number
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$currentStreak',
              style: FGTypography.display.copyWith(
                fontSize: 96,
                color: FGColors.accent,
                height: 0.9,
                shadows: [
                  Shadow(
                    color: FGColors.accent.withValues(alpha: 0.5),
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md, left: Spacing.sm),
              child: Text(
                'JOURS',
                style: FGTypography.h3.copyWith(
                  color: FGColors.textSecondary,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: Spacing.md),

        // Progress towards next milestone
        Row(
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: FGColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Spacing.sm),
                border: Border.all(
                  color: FGColors.accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    streakInfo.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    streakInfo.title,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.md),

            // Progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$nextMilestone jours',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: FGColors.glassBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: FGColors.accent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: FGColors.accent.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineStats() {
    return Row(
      children: [
        _buildStatPill('$weekSessions/$weekTarget', 'séances'),
        const SizedBox(width: Spacing.sm),
        _buildStatPill(totalTime, 'cette sem.'),
        const SizedBox(width: Spacing.sm),
        _buildStatPill('$calories', 'kcal'),
      ],
    );
  }

  Widget _buildStatPill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.md,
          horizontal: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: FGColors.glassSurface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: FGColors.glassBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: FGTypography.h3.copyWith(
                color: FGColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: FGTypography.caption.copyWith(
                fontSize: 10,
                color: FGColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayWorkout() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to workout detail
      },
      child: FGGlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient accent
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.accent.withValues(alpha: 0.15),
                    FGColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: FGColors.accent,
                      borderRadius: BorderRadius.circular(Spacing.xs),
                    ),
                    child: Text(
                      'AUJOURD\'HUI',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textOnAccent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '45 min',
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: Spacing.xs),
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: FGColors.textSecondary,
                  ),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upper Body',
                    style: FGTypography.h1.copyWith(
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Push • 6 exercices',
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Muscle tags
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      _buildMuscleTag('Pectoraux', isPrimary: true),
                      _buildMuscleTag('Épaules'),
                      _buildMuscleTag('Triceps'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleTag(String label, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: isPrimary
            ? FGColors.accent.withValues(alpha: 0.2)
            : FGColors.glassBorder,
        borderRadius: BorderRadius.circular(Spacing.xl),
        border: isPrimary
            ? Border.all(color: FGColors.accent.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Text(
        label,
        style: FGTypography.caption.copyWith(
          color: isPrimary ? FGColors.accent : FGColors.textPrimary,
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLastWorkout() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to history
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FGColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: FGColors.success,
                size: 18,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                'Lower Body • 38 min',
                style: FGTypography.bodySmall.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
            ),
            Text(
              'Hier',
              style: FGTypography.caption,
            ),
            const SizedBox(width: Spacing.xs),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: FGColors.textSecondary,
            ),
          ],
        ),
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
        onPressed: () {
          // TODO: Start workout
        },
      ),
    );
  }

  // === HELPERS ===

  ({String title, String emoji}) _getStreakInfo(int days) {
    if (days >= 365) return (title: 'IMMORTEL', emoji: '👑');
    if (days >= 200) return (title: 'LÉGENDE', emoji: '⚡');
    if (days >= 100) return (title: 'CHAMPION', emoji: '🏆');
    if (days >= 50) return (title: 'ATHLÈTE', emoji: '🦁');
    if (days >= 30) return (title: 'GUERRIER', emoji: '⚔️');
    if (days >= 14) return (title: 'MOTIVÉ', emoji: '💪');
    if (days >= 7) return (title: 'RÉGULIER', emoji: '✨');
    return (title: 'DÉBUTANT', emoji: '🌱');
  }

  int _getPreviousMilestone(int days) {
    if (days >= 365) return 365;
    if (days >= 200) return 200;
    if (days >= 100) return 100;
    if (days >= 50) return 50;
    if (days >= 30) return 30;
    if (days >= 14) return 14;
    if (days >= 7) return 7;
    return 0;
  }

  int _getNextMilestone(int days) {
    if (days < 7) return 7;
    if (days < 14) return 14;
    if (days < 30) return 30;
    if (days < 50) return 50;
    if (days < 100) return 100;
    if (days < 200) return 200;
    if (days < 365) return 365;
    return 365;
  }
}
