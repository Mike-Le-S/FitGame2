import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import 'models/exercise_history.dart';
import 'widgets/progress_chart.dart';
import 'widgets/pr_history_list.dart';

/// Écran affichant la progression d'un exercice avec graphique et historique des PR
class ExerciseProgressScreen extends StatefulWidget {
  final String exerciseName;

  const ExerciseProgressScreen({
    super.key,
    required this.exerciseName,
  });

  @override
  State<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late ExerciseHistory _history;

  @override
  void initState() {
    super.initState();
    _history = MockExerciseData.getHistory(widget.exerciseName) ??
        MockExerciseData.benchPressHistory;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          // Background gradient
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    FGColors.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: _buildAppBar(),
                  ),
                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(Spacing.md),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildChartCard(),
                        const SizedBox(height: Spacing.md),
                        _buildProgressStats(),
                        const SizedBox(height: Spacing.lg),
                        PRHistoryList(prEntries: _history.prEntries),
                        const SizedBox(height: Spacing.xxl),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          // Back button
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: FGColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _history.exerciseName.toUpperCase(),
                  style: FGTypography.h3.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  _history.muscleGroup,
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Current PR badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_history.currentPR.toInt()}kg',
                  style: FGTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return FGGlassCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart,
                color: FGColors.accent,
                size: 20,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'PROGRESSION',
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ProgressChart(
            history: _history,
            height: 220,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStats() {
    final progressPct = _history.progressPercentage;
    final totalGain = _history.totalGain;
    final weeks = _history.weeksOfProgress;

    return FGGlassCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          // Progress icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: FGColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up,
              color: FGColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: Spacing.md),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '+${progressPct.toStringAsFixed(1)}%',
                      style: FGTypography.h2.copyWith(
                        color: FGColors.success,
                      ),
                    ),
                    Text(
                      ' depuis le début',
                      style: FGTypography.body.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '+${totalGain.toStringAsFixed(totalGain % 1 == 0 ? 0 : 1)}kg en $weeks semaines',
                  style: FGTypography.bodySmall.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Chevron
          const Icon(
            Icons.chevron_right,
            color: FGColors.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }
}
