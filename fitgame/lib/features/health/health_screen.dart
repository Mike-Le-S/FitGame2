import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../shared/widgets/fg_glass_card.dart';
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
  late AnimationController _gaugeController;

  // === MOCK DATA - TODO: Replace with HealthKit data ===

  // Sleep data (in minutes) - varied for testing gauges
  final int totalSleepMinutes = 7 * 60 + 23; // 7h23
  final int deepSleepMinutes = 30; // ~7% → RED (too low, ideal 13-23%)
  final int coreSleepMinutes = 4 * 60 + 30; // ~61% → YELLOW (high, ideal 45-55%)
  final int remSleepMinutes = 1 * 60 + 35; // ~21% → GREEN (ideal 20-25%)
  final int awakeMinutes = 48; // ~11% → RED (too high, ideal <5%)
  final int timeInBedMinutes = 8 * 60 + 15; // 8h15
  final int sleepLatencyMinutes = 15; // → GREEN (ideal 10-20min)

  // Calorie data
  final int caloriesBurned = 2450;
  final int caloriesConsumed = 1980;
  final int calorieGoal = 2200;
  final int bmr = 1800;

  // Activity breakdown
  final int walkingCalories = 280;
  final int runningCalories = 420;
  final int workoutCalories = 350;
  final int steps = 8742;
  final double distanceKm = 6.2;

  // Heart data
  final int restingHeartRate = 58;
  final int avgHeartRate = 72;
  final int maxHeartRate = 165;
  final int minHeartRate = 48;
  final int hrvMs = 48;
  final double vo2Max = 42.5;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.05, end: 0.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gaugeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          _buildMeshGradient(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Spacing.xl),
                    _buildHeader(),
                    const SizedBox(height: Spacing.xl),

                    // === THREE MAIN CARDS ===
                    _buildEnergyCard(),
                    const SizedBox(height: Spacing.lg),
                    _buildSleepCard(),
                    const SizedBox(height: Spacing.lg),
                    _buildHeartCard(),
                    const SizedBox(height: Spacing.xxl),
                  ],
                ),
              ),
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
            Container(color: FGColors.background),
            Positioned(
              top: -50,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6B5BFF)
                          .withValues(alpha: _pulseAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00D9FF)
                          .withValues(alpha: _pulseAnimation.value * 0.5),
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

  Widget _buildHeader() {
    return Column(
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
        const SizedBox(height: Spacing.xs),
        Text(
          'Ton corps parle',
          style: FGTypography.h1.copyWith(fontSize: 36),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Données Apple Santé • Aujourd\'hui',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ============================================
  // ENERGY CARD (Expandable)
  // ============================================
  Widget _buildEnergyCard() {
    final netCalories = caloriesConsumed - caloriesBurned;
    final isDeficit = netCalories < 0;

    return FGGlassCard(
      onTap: () => _showEnergyDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FGColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: FGColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ÉNERGIE',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Balance calorique',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
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
                child: _buildCompactStat(
                  label: 'Consommé',
                  value: '$caloriesConsumed',
                  unit: 'kcal',
                  color: const Color(0xFF00D9FF),
                ),
              ),
              Expanded(
                child: _buildCompactStat(
                  label: 'Dépensé',
                  value: '$caloriesBurned',
                  unit: 'kcal',
                  color: FGColors.accent,
                ),
              ),
              Expanded(
                child: _buildCompactStat(
                  label: isDeficit ? 'Déficit' : 'Surplus',
                  value: '${netCalories.abs()}',
                  unit: 'kcal',
                  color: isDeficit ? FGColors.success : FGColors.warning,
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // SLEEP CARD (Expandable with Gauges)
  // ============================================
  Widget _buildSleepCard() {
    final totalHours = totalSleepMinutes / 60;
    final sleepScore = _calculateSleepScore();

    return FGGlassCard(
      onTap: () => _showSleepDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5BFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: const Icon(
                  Icons.bedtime_rounded,
                  color: Color(0xFF6B5BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOMMEIL',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Analyse des phases',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildScoreBadge(sleepScore),
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
              Text(
                '${totalHours.floor()}h${(totalSleepMinutes % 60).toString().padLeft(2, '0')}',
                style: FGTypography.display.copyWith(
                  fontSize: 42,
                  color: const Color(0xFF6B5BFF),
                  height: 1,
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSleepMiniStat(
                        'Profond', deepSleepMinutes, const Color(0xFF1E3A5F)),
                    _buildSleepMiniStat(
                        'Core', coreSleepMinutes, const Color(0xFF4A90D9)),
                    _buildSleepMiniStat(
                        'REM', remSleepMinutes, const Color(0xFF9B6BFF)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // HEART CARD (Expandable)
  // ============================================
  Widget _buildHeartCard() {
    final restingStatus = _getHeartRateStatus(restingHeartRate);
    final hrvStatus = _getHrvStatusRecord(hrvMs);

    return FGGlassCard(
      onTap: () => _showHeartDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5B7F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF5B7F),
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CŒUR',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
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
              const Spacer(),
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
                child: _buildHeartMetricWithStatus(
                  label: 'Repos',
                  value: restingHeartRate,
                  unit: 'BPM',
                  status: restingStatus.text,
                  statusColor: restingStatus.color,
                  highlight: true,
                ),
              ),
              Expanded(
                child: _buildHeartMetricWithStatus(
                  label: 'VFC',
                  value: hrvMs,
                  unit: 'ms',
                  status: hrvStatus.text,
                  statusColor: hrvStatus.color,
                  highlight: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeartMetricWithStatus({
    required String label,
    required int value,
    required String unit,
    required String status,
    required Color statusColor,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$value',
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: highlight ? 28 : 24,
                color: const Color(0xFFFF5B7F),
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                unit,
                style: FGTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF5B7F).withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: FGTypography.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
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
    );
  }

  ({Color color, String text}) _getHrvStatusRecord(int ms) {
    if (ms >= 60) return (color: FGColors.success, text: 'EXCELLENT');
    if (ms >= 50) return (color: FGColors.success, text: 'BON');
    if (ms >= 40) return (color: FGColors.warning, text: 'MOYEN');
    if (ms >= 30) return (color: FGColors.warning, text: 'FAIBLE');
    return (color: FGColors.error, text: 'TRÈS FAIBLE');
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
  // HELPER WIDGETS
  // ============================================

  Widget _buildCompactStat({
    required String label,
    required String value,
    required Color color,
    String? unit,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: highlight ? 20 : 18,
                color: color,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  unit,
                  style: FGTypography.caption.copyWith(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
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
    );
  }

  Widget _buildSleepMiniStat(String label, int minutes, Color color) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final timeStr =
        hours > 0 ? '${hours}h${mins.toString().padLeft(2, '0')}' : '${mins}m';

    return Column(
      children: [
        Text(
          timeStr,
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
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

  Widget _buildScoreBadge(int score) {
    Color badgeColor;
    String label;

    if (score >= 85) {
      badgeColor = FGColors.success;
      label = 'EXCELLENT';
    } else if (score >= 70) {
      badgeColor = const Color(0xFF6B5BFF);
      label = 'BON';
    } else if (score >= 50) {
      badgeColor = FGColors.warning;
      label = 'MOYEN';
    } else {
      badgeColor = FGColors.error;
      label = 'FAIBLE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: FGTypography.caption.copyWith(
              fontWeight: FontWeight.w900,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: FGTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateSleepScore() {
    int score = 0;
    final totalHours = totalSleepMinutes / 60;

    if (totalHours >= 7 && totalHours <= 9) {
      score += 40;
    } else if (totalHours >= 6 && totalHours < 7) {
      score += 25;
    } else if (totalHours > 9 && totalHours <= 10) {
      score += 30;
    } else {
      score += 10;
    }

    final deepPercent = deepSleepMinutes / totalSleepMinutes;
    if (deepPercent >= 0.13 && deepPercent <= 0.23) {
      score += 25;
    } else if (deepPercent >= 0.10) {
      score += 15;
    } else {
      score += 5;
    }

    final remPercent = remSleepMinutes / totalSleepMinutes;
    if (remPercent >= 0.20 && remPercent <= 0.25) {
      score += 25;
    } else if (remPercent >= 0.15) {
      score += 15;
    } else {
      score += 5;
    }

    final awakePercent = awakeMinutes / totalSleepMinutes;
    if (awakePercent <= 0.05) {
      score += 10;
    } else if (awakePercent <= 0.10) {
      score += 5;
    }

    return score;
  }

  ({Color color, String text}) _getHeartRateStatus(int bpm) {
    if (bpm < 50) return (color: const Color(0xFF00D9FF), text: 'ATHLÈTE');
    if (bpm <= 60) return (color: FGColors.success, text: 'EXCELLENT');
    if (bpm <= 70) return (color: FGColors.success, text: 'BON');
    if (bpm <= 80) return (color: FGColors.warning, text: 'NORMAL');
    return (color: FGColors.error, text: 'ÉLEVÉ');
  }
}
