import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import 'models/exercise_history.dart';
import 'widgets/progress_chart.dart';
import 'widgets/pr_history_list.dart';

/// Écran affichant la progression d'un exercice avec graphique et historique des PR
class ExerciseProgressScreen extends StatefulWidget {
  final String exerciseName;
  final String? muscleGroup;

  const ExerciseProgressScreen({
    super.key,
    required this.exerciseName,
    this.muscleGroup,
  });

  @override
  State<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  ExerciseHistory? _history;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final sessionData = await SupabaseService.getExerciseHistory(
        widget.exerciseName,
        limit: 30,
      );

      if (mounted) {
        final entries = <ExerciseProgressEntry>[];
        double currentPR = 0;
        String muscleGroup = widget.muscleGroup ?? '';

        for (final session in sessionData) {
          final date = DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
          final sets = session['sets'] as List? ?? [];

          // Find best set in this session
          double maxWeight = 0;
          int repsAtMax = 0;

          for (final set in sets) {
            final s = set as Map<String, dynamic>;
            if (s['completed'] == true) {
              final weight = (s['weightKg'] as num?)?.toDouble() ?? 0;
              if (weight > maxWeight) {
                maxWeight = weight;
                repsAtMax = (s['reps'] as num?)?.toInt() ?? 0;
              }
            }
          }

          if (maxWeight > 0) {
            final isPR = maxWeight > currentPR;
            if (isPR) currentPR = maxWeight;

            entries.add(ExerciseProgressEntry(
              date: date,
              weight: maxWeight,
              reps: repsAtMax,
              isPR: isPR,
            ));
          }
        }

        // Sort entries by date (oldest first for chart)
        entries.sort((a, b) => a.date.compareTo(b.date));

        // Recalculate PRs after sorting
        double runningMax = 0;
        final correctedEntries = entries.map((e) {
          final isPR = e.weight > runningMax;
          if (isPR) runningMax = e.weight;
          return ExerciseProgressEntry(
            date: e.date,
            weight: e.weight,
            reps: e.reps,
            isPR: isPR,
          );
        }).toList();

        setState(() {
          _history = ExerciseHistory(
            exerciseName: widget.exerciseName,
            muscleGroup: muscleGroup,
            currentPR: currentPR,
            entries: correctedEntries,
          );
          _isLoading = false;
        });

        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _history = ExerciseHistory.empty(widget.exerciseName);
          _isLoading = false;
        });
        _fadeController.forward();
      }
    }
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
            child: _isLoading
                ? _buildLoading()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _history == null || _history!.entries.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildAppBar(),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(
              color: FGColors.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: FGColors.glassBorder,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.show_chart_rounded,
                    size: 40,
                    color: FGColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Aucun historique',
                  style: FGTypography.h3.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Ta progression apparaîtra\naprès tes premières séances',
                  textAlign: TextAlign.center,
                  style: FGTypography.body.copyWith(
                    color: FGColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
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
              PRHistoryList(prEntries: _history!.prEntries),
              const SizedBox(height: Spacing.xxl),
            ]),
          ),
        ),
      ],
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
                  widget.exerciseName.toUpperCase(),
                  style: FGTypography.h3.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
                if (_history != null && _history!.muscleGroup.isNotEmpty)
                  Text(
                    _history!.muscleGroup,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Current PR badge
          if (_history != null && _history!.currentPR > 0)
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
                    '${_history!.currentPR.toInt()}kg',
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
            history: _history!,
            height: 220,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStats() {
    final progressPct = _history!.progressPercentage;
    final totalGain = _history!.totalGain;
    final weeks = _history!.weeksOfProgress;

    if (progressPct == 0 && totalGain == 0) {
      return const SizedBox.shrink();
    }

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
        ],
      ),
    );
  }
}
