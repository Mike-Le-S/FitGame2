import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/health_service.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/fg_glass_card.dart';
import '../../shared/widgets/fg_mesh_gradient.dart';
import 'sheets/energy_detail_sheet.dart';
import 'sheets/sleep_detail_sheet.dart';
import 'sheets/heart_detail_sheet.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  // Health service
  final HealthService _healthService = HealthService();
  HealthSnapshot? _healthData;

  // === REAL DATA (with zero fallback when no HealthKit data) ===

  // Sleep data (in minutes)
  int get totalSleepMinutes => _healthData?.sleep?.totalMinutes ?? 0;
  int get deepSleepMinutes => _healthData?.sleep?.deepMinutes ?? 0;
  int get coreSleepMinutes => _healthData?.sleep?.lightMinutes ?? 0;
  int get remSleepMinutes => _healthData?.sleep?.remMinutes ?? 0;
  int get awakeMinutes => _healthData?.sleep?.awakeMinutes ?? 0;
  int get timeInBedMinutes => _healthData?.sleep?.inBedMinutes ?? 1; // Avoid division by zero
  final int sleepLatencyMinutes = 0;

  // Calorie data
  int get caloriesBurned =>
      _healthData?.activity?.totalCaloriesBurned ?? 0;
  final int caloriesConsumed = 0;
  final int calorieGoal = 2200;
  int get bmr => _healthData?.activity?.basalCaloriesBurned ?? 0;

  // Activity
  int get walkingCalories => _healthData?.activity?.activeCaloriesBurned ?? 0;
  final int runningCalories = 0;
  final int workoutCalories = 0;
  int get steps => _healthData?.activity?.steps ?? 0;
  final int stepsGoal = 10000;
  double get distanceKm => _healthData?.activity?.distanceKm ?? 0.0;

  // Heart data
  int get restingHeartRate =>
      _healthData?.heart?.restingHeartRate ?? 0;
  int get avgHeartRate =>
      _healthData?.heart?.averageHeartRate ?? 0;
  int get maxHeartRate =>
      _healthData?.heart?.maxHeartRate ?? 0;
  int get minHeartRate =>
      _healthData?.heart?.minHeartRate ?? 0;
  int get hrvMs => _healthData?.heart?.hrvMs ?? 0;
  final double vo2Max = 0.0; // VO2_MAX not available in health package v11.1

  // Trends (compared to 7-day average) - fetched from backend
  final int sleepTrend = 0;
  final int heartTrend = 0;
  final int energyTrend = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.05, end: 0.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _scoreAnimation = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );

    // Load health data from Apple Health / Google Fit
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    if (!_healthService.isAvailable) {
      return;
    }

    // Check if already authorized
    final authorized = await _healthService.checkAuthorization();
    if (!authorized) {
      // Request authorization
      final granted = await _healthService.requestAuthorization();
      if (!granted) {
        return;
      }
    }

    // Fetch today's health data
    final today = DateTime.now();
    final snapshot = await _healthService.getHealthSnapshot(today);

    setState(() {
      _healthData = snapshot;
    });

    // Persist to Supabase (after setState so _globalHealthScore can compute)
    if (snapshot != null) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      try {
        await SupabaseService.saveHealthMetrics(
          date: todayStr,
          sleepDurationMinutes: snapshot.sleep?.totalMinutes,
          sleepScore: snapshot.sleep?.score,
          deepSleepMinutes: snapshot.sleep?.deepMinutes,
          lightSleepMinutes: snapshot.sleep?.lightMinutes,
          remSleepMinutes: snapshot.sleep?.remMinutes,
          awakeMinutes: snapshot.sleep?.awakeMinutes,
          restingHr: snapshot.heart?.restingHeartRate,
          avgHr: snapshot.heart?.averageHeartRate,
          maxHr: snapshot.heart?.maxHeartRate,
          minHr: snapshot.heart?.minHeartRate,
          hrvMs: snapshot.heart?.hrvMs?.toDouble(),
          steps: snapshot.activity?.steps,
          activeCalories: snapshot.activity?.activeCaloriesBurned,
          totalCalories: snapshot.activity?.totalCaloriesBurned,
          distanceKm: snapshot.activity?.distanceKm,
          energyScore: _globalHealthScore,
        );
      } catch (e) {
        debugPrint('Error saving health metrics: $e');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  // Check if we have valid data for each category
  bool get _hasSleepData => totalSleepMinutes > 0;
  bool get _hasHeartData => restingHeartRate > 0 || hrvMs > 0;
  bool get _hasActivityData => steps > 0 || caloriesBurned > 0;

  int get _globalHealthScore {
    final scores = <int>[];

    // Only include scores for data we actually have
    if (_hasSleepData) {
      scores.add(_calculateSleepScore());
    }
    if (_hasHeartData) {
      scores.add(_calculateHeartScore());
    }
    if (_hasActivityData) {
      scores.add(_calculateActivityScore());
    }

    if (scores.isEmpty) return 0;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  int _calculateHeartScore() {
    // Return 0 if no heart data
    if (restingHeartRate == 0) return 0;

    int score = 50;
    // Resting HR (only count if we have data)
    if (restingHeartRate > 0 && restingHeartRate < 60) {
      score += 25;
    } else if (restingHeartRate <= 70) {
      score += 15;
    } else if (restingHeartRate <= 80) {
      score += 5;
    }
    // HRV (only count if we have data)
    if (hrvMs > 0 && hrvMs >= 50) {
      score += 25;
    } else if (hrvMs >= 40) {
      score += 15;
    } else if (hrvMs > 0) {
      score += 5;
    }
    return score.clamp(0, 100);
  }

  int _calculateActivityScore() {
    // Avoid division by zero
    final stepsPercent = stepsGoal > 0
        ? (steps / stepsGoal * 100).clamp(0.0, 100.0)
        : 0.0;
    final calorieDenom = calorieGoal - bmr;
    final caloriePercent = calorieDenom > 0
        ? ((caloriesBurned - bmr) / calorieDenom * 100).clamp(0.0, 100.0)
        : 0.0;
    return ((stepsPercent + caloriePercent) / 2).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          FGMeshGradient.health(animation: _pulseAnimation),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadHealthData,
              color: FGColors.accent,
              backgroundColor: FGColors.glassSurface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Spacing.md),
                      _buildHeader(),
                      const SizedBox(height: Spacing.lg),

                      // === HERO SCORE ===
                      _buildHeroScore(),
                      const SizedBox(height: Spacing.lg),

                      // === QUICK STATS ===
                      _buildQuickStats(),
                      const SizedBox(height: Spacing.xl),

                      // === SECTION LABEL ===
                      Text(
                        'MÉTRIQUES DÉTAILLÉES',
                        style: FGTypography.caption.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: FGColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Spacing.md),

                      // === THREE MAIN CARDS ===
                      _buildSleepCard(),
                      const SizedBox(height: Spacing.md),
                      _buildHeartCard(),
                      const SizedBox(height: Spacing.md),
                      _buildEnergyCard(),
                      const SizedBox(height: Spacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SANTÉ',
              style: FGTypography.caption.copyWith(
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: FGColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Ton corps parle',
              style: FGTypography.h2.copyWith(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Apple Health sync indicator
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
          decoration: BoxDecoration(
            color: FGColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Spacing.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: FGColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: FGColors.success.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                'Sync',
                style: FGTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: FGColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroScore() {
    final score = _globalHealthScore;
    final scoreColor = score >= 80
        ? FGColors.success
        : score >= 60
            ? const Color(0xFF6B5BFF)
            : score >= 40
                ? FGColors.warning
                : FGColors.error;

    final scoreLabel = score >= 80
        ? 'Excellent'
        : score >= 60
            ? 'Bon'
            : score >= 40
                ? 'Moyen'
                : 'À améliorer';

    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final animatedScore = (score * _scoreAnimation.value).round();

        return Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scoreColor.withValues(alpha: 0.15),
                scoreColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scoreColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: scoreColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scoreColor.withValues(alpha: 0.3),
                      scoreColor.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$animatedScore',
                    style: FGTypography.display.copyWith(
                      fontSize: 32,
                      color: scoreColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.lg),
              // Score info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCORE SANTÉ',
                      style: FGTypography.caption.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: FGColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        scoreLabel,
                        style: FGTypography.h2.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Basé sur sommeil, cœur et activité',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              // Trend indicator
              _buildTrendBadge(_getTodayTrend()),
            ],
          ),
        );
      },
    );
  }

  int _getTodayTrend() {
    return ((sleepTrend + heartTrend + energyTrend) / 3).round();
  }

  Widget _buildTrendBadge(int trend) {
    final icon = trend > 0
        ? Icons.trending_up
        : trend < 0
            ? Icons.trending_down
            : Icons.trending_flat;
    final color = trend > 0
        ? FGColors.success
        : trend < 0
            ? FGColors.error
            : FGColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Spacing.sm),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildQuickStats() {
    // Avoid division by zero
    final stepsProgress = stepsGoal > 0 ? steps / stepsGoal : 0.0;
    final calorieDenom = calorieGoal - bmr;
    final calorieProgress = calorieDenom > 0
        ? (caloriesBurned - bmr) / calorieDenom
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatPill(
            icon: Icons.directions_walk,
            value: steps > 0 ? _formatSteps(steps) : '—',
            label: 'pas',
            progress: stepsProgress,
            color: const Color(0xFF00D9FF),
            isAvailable: steps > 0,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _buildQuickStatPill(
            icon: Icons.local_fire_department,
            value: caloriesBurned > 0 ? '$caloriesBurned' : '—',
            label: 'kcal',
            progress: calorieProgress,
            color: FGColors.accent,
            isAvailable: caloriesBurned > 0,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _buildQuickStatPill(
            icon: Icons.bedtime,
            value: totalSleepMinutes > 0
                ? '${totalSleepMinutes ~/ 60}h${(totalSleepMinutes % 60).toString().padLeft(2, '0')}'
                : '—',
            label: 'sommeil',
            progress: totalSleepMinutes / (8 * 60), // Goal: 8h
            color: const Color(0xFF6B5BFF),
            isAvailable: totalSleepMinutes > 0,
          ),
        ),
      ],
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return '$steps';
  }

  Widget _buildQuickStatPill({
    required IconData icon,
    required String value,
    required String label,
    required double progress,
    required Color color,
    bool isAvailable = true,
  }) {
    final displayColor = isAvailable ? color : FGColors.textSecondary.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: displayColor, size: 18),
          const SizedBox(height: Spacing.xs),
          Text(
            value,
            style: FGTypography.body.copyWith(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: displayColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: FGTypography.caption.copyWith(
              fontSize: 9,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: isAvailable ? progress.clamp(0.0, 1.0) : 0.0,
                backgroundColor: FGColors.glassBorder,
                valueColor: AlwaysStoppedAnimation(displayColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SLEEP CARD
  // ============================================
  Widget _buildSleepCard() {
    final totalHours = totalSleepMinutes / 60;
    final sleepScore = _calculateSleepScore();
    final efficiency =
        ((totalSleepMinutes / timeInBedMinutes) * 100).round();

    return FGGlassCard(
      onTap: () => _showSleepDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6B5BFF).withValues(alpha: 0.3),
                      const Color(0xFF6B5BFF).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bedtime_rounded,
                  color: Color(0xFF6B5BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SOMMEIL',
                          style: FGTypography.caption.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: FGColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        _buildMiniTrendIcon(sleepTrend),
                      ],
                    ),
                    Text(
                      'Dernière nuit',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _buildScoreBadge(sleepScore, const Color(0xFF6B5BFF)),
              const SizedBox(width: Spacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: FGColors.textSecondary.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Big sleep duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${totalHours.floor()}h${(totalSleepMinutes % 60).toString().padLeft(2, '0')}',
                    style: FGTypography.display.copyWith(
                      fontSize: 36,
                      color: const Color(0xFF6B5BFF),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: FGColors.glassBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$efficiency% efficacité',
                      style: FGTypography.caption.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: Spacing.lg),
              // Sleep phases bars
              Expanded(
                child: _buildSleepPhasesBar(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepPhasesBar() {
    final total = deepSleepMinutes + coreSleepMinutes + remSleepMinutes;
    // Avoid division by zero when no sleep data
    final deepPct = total > 0 ? deepSleepMinutes / total : 0.33;
    final corePct = total > 0 ? coreSleepMinutes / total : 0.34;
    final remPct = total > 0 ? remSleepMinutes / total : 0.33;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 20,
            child: Row(
              children: [
                Expanded(
                  flex: (deepPct * 100).round(),
                  child: Container(color: const Color(0xFF1E3A5F)),
                ),
                Expanded(
                  flex: (corePct * 100).round(),
                  child: Container(color: const Color(0xFF4A90D9)),
                ),
                Expanded(
                  flex: (remPct * 100).round(),
                  child: Container(color: const Color(0xFF9B6BFF)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildPhaseLegend('Profond', const Color(0xFF1E3A5F)),
            const SizedBox(width: Spacing.sm),
            _buildPhaseLegend('Core', const Color(0xFF4A90D9)),
            const SizedBox(width: Spacing.sm),
            _buildPhaseLegend('REM', const Color(0xFF9B6BFF)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            fontSize: 9,
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ============================================
  // HEART CARD
  // ============================================
  Widget _buildHeartCard() {
    final restingStatus = _getHeartRateStatus(restingHeartRate);
    final hrvStatus = _getHrvStatus(hrvMs);
    final heartScore = _calculateHeartScore();

    return FGGlassCard(
      onTap: () => _showHeartDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF5B7F).withValues(alpha: 0.3),
                      const Color(0xFFFF5B7F).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF5B7F),
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CŒUR',
                          style: FGTypography.caption.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: FGColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        _buildMiniTrendIcon(heartTrend),
                      ],
                    ),
                    Text(
                      'Dernière nuit',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _buildScoreBadge(heartScore, const Color(0xFFFF5B7F)),
              const SizedBox(width: Spacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: FGColors.textSecondary.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildHeartMetric(
                  label: 'FC Repos',
                  value: '$restingHeartRate',
                  unit: 'BPM',
                  status: restingStatus.text,
                  statusColor: restingStatus.color,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: FGColors.glassBorder,
              ),
              Expanded(
                child: _buildHeartMetric(
                  label: 'VFC',
                  value: '$hrvMs',
                  unit: 'ms',
                  status: hrvStatus.text,
                  statusColor: hrvStatus.color,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: FGColors.glassBorder,
              ),
              Expanded(
                child: _buildHeartMetric(
                  label: 'VO₂ Max',
                  value: vo2Max.toStringAsFixed(1),
                  unit: '',
                  status: _getVo2Status(vo2Max).text,
                  statusColor: _getVo2Status(vo2Max).color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeartMetric({
    required String label,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: FGTypography.h3.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFF5B7F),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: FGTypography.caption.copyWith(
                    fontSize: 10,
                    color: const Color(0xFFFF5B7F).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: FGTypography.caption.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            fontSize: 10,
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ============================================
  // ENERGY CARD
  // ============================================
  Widget _buildEnergyCard() {
    // Check if user has logged calories consumed (otherwise don't show deficit)
    final hasCaloriesConsumed = caloriesConsumed > 0;
    final hasCaloriesBurned = caloriesBurned > 0;

    // Only calculate balance if user is tracking food intake
    final netCalories = hasCaloriesConsumed ? caloriesConsumed - caloriesBurned : 0;
    final isDeficit = netCalories < 0;

    return FGGlassCard(
      onTap: () => _showEnergyDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FGColors.accent.withValues(alpha: 0.3),
                      FGColors.accent.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: FGColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ÉNERGIE',
                          style: FGTypography.caption.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: FGColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        _buildMiniTrendIcon(energyTrend),
                      ],
                    ),
                    Text(
                      hasCaloriesConsumed ? 'Balance calorique' : 'Calories dépensées',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // Net calories badge - only show if tracking food
              if (hasCaloriesConsumed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (isDeficit ? FGColors.success : FGColors.warning)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(
                      color: (isDeficit ? FGColors.success : FGColors.warning)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${isDeficit ? '' : '+'}$netCalories',
                    style: FGTypography.caption.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDeficit ? FGColors.success : FGColors.warning,
                    ),
                  ),
                )
              else if (hasCaloriesBurned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: FGColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(
                      color: FGColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '$caloriesBurned',
                    style: FGTypography.caption.copyWith(
                      fontWeight: FontWeight.w900,
                      color: FGColors.accent,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: FGColors.glassBorder,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Text(
                    '—',
                    style: FGTypography.caption.copyWith(
                      fontWeight: FontWeight.w900,
                      color: FGColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: Spacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: FGColors.textSecondary.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          // Progress visualization
          Row(
            children: [
              Expanded(
                child: _buildEnergyBar(
                  label: 'Consommé',
                  value: caloriesConsumed,
                  max: hasCaloriesConsumed
                      ? (caloriesBurned > caloriesConsumed ? caloriesBurned : caloriesConsumed)
                      : caloriesBurned > 0 ? caloriesBurned : 1,
                  color: hasCaloriesConsumed
                      ? const Color(0xFF00D9FF)
                      : FGColors.textSecondary.withValues(alpha: 0.3),
                  isAvailable: hasCaloriesConsumed,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _buildEnergyBar(
                  label: 'Dépensé',
                  value: caloriesBurned,
                  max: hasCaloriesConsumed
                      ? (caloriesBurned > caloriesConsumed ? caloriesBurned : caloriesConsumed)
                      : caloriesBurned > 0 ? caloriesBurned : 1,
                  color: hasCaloriesBurned
                      ? FGColors.accent
                      : FGColors.textSecondary.withValues(alpha: 0.3),
                  isAvailable: hasCaloriesBurned,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyBar({
    required String label,
    required int value,
    required int max,
    required Color color,
    bool isAvailable = true,
  }) {
    // Avoid division by zero
    final progress = max > 0 ? value / max : 0.0;
    final displayColor = isAvailable ? color : FGColors.textSecondary.withValues(alpha: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: FGTypography.caption.copyWith(
                fontSize: 10,
                color: FGColors.textSecondary,
              ),
            ),
            Text(
              isAvailable ? '$value kcal' : '— kcal',
              style: FGTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: displayColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: isAvailable ? progress : 0.0,
              backgroundColor: FGColors.glassBorder,
              valueColor: AlwaysStoppedAnimation(displayColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTrendIcon(int trend) {
    final icon = trend > 0
        ? Icons.arrow_upward
        : trend < 0
            ? Icons.arrow_downward
            : Icons.remove;
    final color = trend > 0
        ? FGColors.success
        : trend < 0
            ? FGColors.error
            : FGColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color, size: 10),
    );
  }

  Widget _buildScoreBadge(int score, Color themeColor) {
    Color badgeColor;
    String label;

    if (score >= 85) {
      badgeColor = FGColors.success;
      label = 'A+';
    } else if (score >= 70) {
      badgeColor = themeColor;
      label = 'A';
    } else if (score >= 55) {
      badgeColor = FGColors.warning;
      label = 'B';
    } else {
      badgeColor = FGColors.error;
      label = 'C';
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            color: badgeColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ============================================
  // DETAIL BOTTOM SHEETS
  // ============================================

  void _showEnergyDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnergyDetailSheet(
        caloriesConsumed: caloriesConsumed,
        caloriesBurned: caloriesBurned,
        calorieGoal: calorieGoal,
        bmr: bmr,
        walkingCalories: walkingCalories,
        runningCalories: runningCalories,
        workoutCalories: workoutCalories,
        steps: steps,
        distanceKm: distanceKm,
      ),
    );
  }

  void _showSleepDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SleepDetailSheet(
        totalSleepMinutes: totalSleepMinutes,
        deepSleepMinutes: deepSleepMinutes,
        coreSleepMinutes: coreSleepMinutes,
        remSleepMinutes: remSleepMinutes,
        awakeMinutes: awakeMinutes,
        timeInBedMinutes: timeInBedMinutes,
        sleepLatencyMinutes: sleepLatencyMinutes,
      ),
    );
  }

  void _showHeartDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HeartDetailSheet(
        restingHeartRate: restingHeartRate,
        avgHeartRate: avgHeartRate,
        maxHeartRate: maxHeartRate,
        minHeartRate: minHeartRate,
        hrvMs: hrvMs,
        vo2Max: vo2Max,
      ),
    );
  }

  // ============================================
  // HELPER CALCULATIONS
  // ============================================

  int _calculateSleepScore() {
    // Return 0 if no sleep data
    if (totalSleepMinutes == 0) return 0;

    int score = 0;
    final totalHours = totalSleepMinutes / 60;

    // Duration score (40 points max)
    if (totalHours >= 7 && totalHours <= 9) {
      score += 40;
    } else if (totalHours >= 6 && totalHours < 7) {
      score += 25;
    } else if (totalHours > 9 && totalHours <= 10) {
      score += 30;
    } else {
      score += 10;
    }

    // Deep sleep (25 points max)
    final deepPercent = deepSleepMinutes / totalSleepMinutes;
    if (deepPercent >= 0.13 && deepPercent <= 0.23) {
      score += 25;
    } else if (deepPercent >= 0.10) {
      score += 15;
    } else {
      score += 5;
    }

    // REM (25 points max)
    final remPercent = remSleepMinutes / totalSleepMinutes;
    if (remPercent >= 0.20 && remPercent <= 0.25) {
      score += 25;
    } else if (remPercent >= 0.15) {
      score += 15;
    } else {
      score += 5;
    }

    // Awake time (10 points max)
    final awakePercent = awakeMinutes / totalSleepMinutes;
    if (awakePercent <= 0.05) {
      score += 10;
    } else if (awakePercent <= 0.10) {
      score += 5;
    }

    return score;
  }

  ({Color color, String text}) _getHeartRateStatus(int bpm) {
    if (bpm == 0) return (color: FGColors.glassBorder, text: '—');
    if (bpm < 50) return (color: const Color(0xFF00D9FF), text: 'ATHLÈTE');
    if (bpm <= 60) return (color: FGColors.success, text: 'EXCELLENT');
    if (bpm <= 70) return (color: FGColors.success, text: 'BON');
    if (bpm <= 80) return (color: FGColors.warning, text: 'NORMAL');
    return (color: FGColors.error, text: 'ÉLEVÉ');
  }

  ({Color color, String text}) _getHrvStatus(int ms) {
    if (ms == 0) return (color: FGColors.glassBorder, text: '—');
    if (ms >= 60) return (color: FGColors.success, text: 'EXCELLENT');
    if (ms >= 50) return (color: FGColors.success, text: 'BON');
    if (ms >= 40) return (color: FGColors.warning, text: 'MOYEN');
    if (ms >= 30) return (color: FGColors.warning, text: 'FAIBLE');
    return (color: FGColors.error, text: 'TRÈS FAIBLE');
  }

  ({Color color, String text}) _getVo2Status(double vo2) {
    if (vo2 >= 50) return (color: FGColors.success, text: 'SUPÉRIEUR');
    if (vo2 >= 45) return (color: FGColors.success, text: 'EXCELLENT');
    if (vo2 >= 40) return (color: const Color(0xFF6B5BFF), text: 'BON');
    if (vo2 >= 35) return (color: FGColors.warning, text: 'MOYEN');
    return (color: FGColors.error, text: 'FAIBLE');
  }
}
