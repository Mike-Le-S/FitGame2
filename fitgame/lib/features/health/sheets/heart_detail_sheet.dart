import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../painters/heart_gauge_painter.dart';
import '../models/heart_metric_info.dart';
import '../models/heart_history_data.dart';
import '../../../core/services/supabase_service.dart';
import '../modals/heart_info_modal.dart';

class HeartDetailSheet extends StatefulWidget {
  final int restingHeartRate;
  final int avgHeartRate;
  final int maxHeartRate;
  final int minHeartRate;
  final int hrvMs;
  final double vo2Max;

  const HeartDetailSheet({
    super.key,
    required this.restingHeartRate,
    required this.avgHeartRate,
    required this.maxHeartRate,
    required this.minHeartRate,
    required this.hrvMs,
    required this.vo2Max,
  });

  @override
  State<HeartDetailSheet> createState() => HeartDetailSheetState();
}

class HeartDetailSheetState extends State<HeartDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedPeriod = 0; // 0: Aujourd'hui, 1: 7 jours, 2: 14 jours

  // Heart metric educational content
  static const _heartInfo = {
    'resting': HeartMetricInfo(
      title: 'Fréquence Cardiaque au Repos',
      description:
          'La fréquence cardiaque au repos (FCR) est le nombre de battements par minute '
          'lorsque vous êtes complètement détendu. C\'est un indicateur clé de votre '
          'santé cardiovasculaire et de votre niveau de forme physique.',
      benefits: [
        'Indicateur de forme cardiovasculaire',
        'Suivi de la récupération',
        'Détection précoce du surentraînement',
        'Marqueur de santé générale',
      ],
      fitnessImpact:
          'Une FCR basse indique un cœur efficace. Les athlètes d\'endurance ont souvent '
          'une FCR entre 40-60 BPM. Une augmentation soudaine peut signaler une fatigue '
          'ou une maladie imminente.',
      idealRange: '50-70 BPM (athlètes: 40-60)',
    ),
    'hrv': HeartMetricInfo(
      title: 'Variabilité de la Fréquence Cardiaque (VFC)',
      description:
          'La VFC mesure les variations de temps entre chaque battement cardiaque. '
          'Contrairement à la fréquence cardiaque, une VFC élevée est généralement '
          'signe d\'un bon état de santé et d\'une bonne capacité d\'adaptation.',
      benefits: [
        'Indicateur du système nerveux autonome',
        'Mesure de la capacité de récupération',
        'Évaluation du stress et de la fatigue',
        'Prédicteur de performance sportive',
      ],
      fitnessImpact:
          'Une VFC élevée indique une bonne récupération et une capacité à gérer le stress. '
          'Planifiez vos entraînements intenses les jours de VFC haute et privilégiez '
          'la récupération active les jours de VFC basse.',
      idealRange: '50-100 ms (variable selon l\'âge)',
    ),
    'vo2max': HeartMetricInfo(
      title: 'VO₂ Max',
      description:
          'Le VO₂ Max représente la quantité maximale d\'oxygène que votre corps peut '
          'utiliser pendant un effort intense. C\'est l\'indicateur de référence de '
          'votre capacité aérobie.',
      benefits: [
        'Mesure de l\'endurance cardiorespiratoire',
        'Prédicteur de performance en endurance',
        'Indicateur de longévité',
        'Suivi des progrès d\'entraînement',
      ],
      fitnessImpact:
          'Un VO₂ Max élevé permet de maintenir des efforts intenses plus longtemps. '
          'Il s\'améliore avec l\'entraînement en intervalles (HIIT) et l\'entraînement '
          'en endurance régulier.',
      idealRange: '40-50+ mL/kg/min (excellent)',
    ),
  };

  // Historical data - empty until loaded from HealthKit
  List<HeartHistoryData> _historyData = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData(int days) async {
    if (_isLoadingHistory) return;
    setState(() => _isLoadingHistory = true);

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final metrics = await SupabaseService.getHealthMetrics(
        startDate: startDate.toIso8601String().substring(0, 10),
        endDate: endDate.toIso8601String().substring(0, 10),
      );

      final history = <HeartHistoryData>[];
      for (int i = 0; i < metrics.length; i++) {
        final m = metrics[i];
        final restingHr = m['resting_hr'] as int? ?? 0;
        final hrv = (m['hrv_ms'] as num?)?.round() ?? 0;
        if (restingHr == 0 && hrv == 0) continue;

        int trend = 0;
        if (i > 0) {
          final prevHrv = (metrics[i - 1]['hrv_ms'] as num?)?.round() ?? 0;
          if (hrv > prevHrv) {
            trend = 1;
          } else if (hrv < prevHrv) {
            trend = -1;
          }
        }

        final date = DateTime.parse(m['date'] as String);
        final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        final dayLabel = '${dayNames[date.weekday - 1]} ${date.day}';

        history.add(HeartHistoryData(
          day: dayLabel,
          restingHR: restingHr,
          hrv: hrv,
          trend: trend,
        ));
      }

      if (mounted) {
        setState(() {
          _historyData = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading heart history: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _showInfoModal(String key) {
    final info = _heartInfo[key];
    if (info == null) return;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HeartInfoModal(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: FGColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: Spacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FGColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5B7F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(Spacing.sm),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFFF5B7F),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analyse Cardiaque',
                              style: FGTypography.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Données de la dernière nuit',
                              style: FGTypography.caption.copyWith(
                                fontSize: 11,
                                color: FGColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Period selector tabs
                  _buildPeriodSelector(),
                  const SizedBox(height: Spacing.lg),

                  // Show different content based on selected period
                  if (_selectedPeriod == 0) ...[
                    // Today's detailed view with gauges
                    _buildTodayView(),
                  ] else ...[
                    // Historical view
                    _buildHistoryView(),
                  ],

                  const SizedBox(height: Spacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Aujourd\'hui', '7 jours', '14 jours'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = _selectedPeriod == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPeriod = index);
                if (index > 0) {
                  _loadHistoryData(index == 1 ? 7 : 14);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF5B7F).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFFFF5B7F).withValues(alpha: 0.3))
                      : null,
                ),
                child: Text(
                  periods[index],
                  textAlign: TextAlign.center,
                  style: FGTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFFFF5B7F)
                        : FGColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTodayView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resting HR Gauge
        _buildCompactHeartGauge(
          infoKey: 'resting',
          label: 'FC Repos',
          value: widget.restingHeartRate,
          unit: 'BPM',
          color: const Color(0xFFFF5B7F),
          minValue: 40,
          maxValue: 100,
          idealMin: 50,
          idealMax: 70,
          invertGauge: false,
        ),
        const SizedBox(height: Spacing.md),

        // HRV Gauge
        _buildCompactHeartGauge(
          infoKey: 'hrv',
          label: 'Variabilité (VFC)',
          value: widget.hrvMs,
          unit: 'ms',
          color: const Color(0xFF6B5BFF),
          minValue: 10,
          maxValue: 120,
          idealMin: 50,
          idealMax: 100,
          invertGauge: false,
          higherIsBetter: true,
        ),
        const SizedBox(height: Spacing.lg),

        // Stats row
        Text(
          'STATISTIQUES DE LA NUIT',
          style: FGTypography.caption.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'Min',
                '${widget.minHeartRate}',
                'BPM',
                const Color(0xFF00D9FF),
                Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _buildMiniStatCard(
                'Moy',
                '${widget.avgHeartRate}',
                'BPM',
                const Color(0xFFFF5B7F),
                Icons.show_chart_rounded,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _buildMiniStatCard(
                'Max',
                '${widget.maxHeartRate}',
                'BPM',
                FGColors.accent,
                Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),

        // VO2 Max Card
        Text(
          'CAPACITÉ AÉROBIE',
          style: FGTypography.caption.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        _buildVo2Card(),
      ],
    );
  }

  Widget _buildHistoryView() {
    if (_isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
        ),
      );
    }

    final isWeekly = _selectedPeriod == 1;
    final requestedDays = isWeekly ? 7 : 14;

    // Use actual available data count
    final data = _historyData.take(requestedDays).toList();
    final actualDays = data.length;

    if (actualDays == 0) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    // Calculate averages using actual data count
    final avgRestingHR =
        data.map((d) => d.restingHR).reduce((a, b) => a + b) ~/ actualDays;
    final avgHrv =
        data.map((d) => d.hrv).reduce((a, b) => a + b) ~/ actualDays;

    // Calculate trend (compare first half vs second half)
    final halfPoint = actualDays ~/ 2;
    int hrvTrend = 0;
    if (halfPoint > 0) {
      final firstHalf = data.take(halfPoint).toList();
      final secondHalf = data.skip(halfPoint).toList();
      if (firstHalf.isNotEmpty && secondHalf.isNotEmpty) {
        final firstHrvAvg = firstHalf.map((d) => d.hrv).reduce((a, b) => a + b) ~/ firstHalf.length;
        final secondHrvAvg = secondHalf.map((d) => d.hrv).reduce((a, b) => a + b) ~/ secondHalf.length;
        hrvTrend = secondHrvAvg > firstHrvAvg ? 1 : (secondHrvAvg < firstHrvAvg ? -1 : 0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'FC Repos Moy.',
                '$avgRestingHR',
                'BPM',
                const Color(0xFFFF5B7F),
                _getTrendIcon(0), // HR trend typically stable
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _buildSummaryCard(
                'VFC Moyenne',
                '$avgHrv',
                'ms',
                const Color(0xFF6B5BFF),
                _getTrendIcon(hrvTrend),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),

        // History chart
        Text(
          'ÉVOLUTION',
          style: FGTypography.caption.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        _buildHistoryChart(actualDays),
        const SizedBox(height: Spacing.lg),

        // Daily breakdown
        Text(
          'DÉTAIL PAR JOUR',
          style: FGTypography.caption.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        ...List.generate(
          actualDays,
          (index) => _buildDayRow(data[index]),
        ),
      ],
    );
  }

  Widget _buildCompactHeartGauge({
    required String infoKey,
    required String label,
    required int value,
    required String unit,
    required Color color,
    required int minValue,
    required int maxValue,
    required int idealMin,
    required int idealMax,
    required bool invertGauge,
    bool higherIsBetter = false,
  }) {
    final normalizedValue = (value - minValue) / (maxValue - minValue);
    final normalizedIdealMin = (idealMin - minValue) / (maxValue - minValue);
    final normalizedIdealMax = (idealMax - minValue) / (maxValue - minValue);

    final status = _getHeartGaugeStatus(
      value,
      idealMin,
      idealMax,
      higherIsBetter,
    );

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.sm),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showInfoModal(infoKey),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: FGTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline_rounded,
                          size: 12,
                          color: FGColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$value',
                    style: FGTypography.caption.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: FGTypography.caption.copyWith(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.text,
                      style: FGTypography.caption.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 20,
                child: CustomPaint(
                  painter: HeartGaugePainter(
                    progress: _animController.value,
                    actualPercent: normalizedValue.clamp(0.0, 1.0),
                    idealMinPercent: normalizedIdealMin,
                    idealMaxPercent: normalizedIdealMax,
                    accentColor: color,
                    higherIsBetter: higherIsBetter,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStatCard(
    String label,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: FGTypography.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                unit,
                style: FGTypography.caption.copyWith(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 8,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: FGTypography.caption.copyWith(
              fontSize: 9,
              color: FGColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVo2Card() {
    final status = _getVo2Status(widget.vo2Max);

    return GestureDetector(
      onTap: () => _showInfoModal('vo2max'),
      child: FGGlassCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: const Icon(
                Icons.air_rounded,
                color: Color(0xFF00D9FF),
                size: 24,
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
                        'VO₂ Max',
                        style: FGTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: FGColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  Text(
                    'Capacité aérobie',
                    style: FGTypography.caption.copyWith(
                      fontSize: 10,
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.vo2Max.toStringAsFixed(1),
                      style: FGTypography.h3.copyWith(
                        color: const Color(0xFF00D9FF),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      ' mL/kg/min',
                      style: FGTypography.caption.copyWith(
                        color: const Color(0xFF00D9FF).withValues(alpha: 0.7),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.text,
                    style: FGTypography.caption.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: status.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    String unit,
    Color color,
    Widget trendIcon,
  ) {
    return FGGlassCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: FGTypography.caption.copyWith(
                  fontSize: 10,
                  color: FGColors.textSecondary,
                ),
              ),
              const Spacer(),
              trendIcon,
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: FGTypography.h2.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: FGTypography.caption.copyWith(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getTrendIcon(int trend) {
    if (trend > 0) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: FGColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.trending_up_rounded,
          size: 14,
          color: FGColors.success,
        ),
      );
    } else if (trend < 0) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: FGColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.trending_down_rounded,
          size: 14,
          color: FGColors.error,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: FGColors.textSecondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.trending_flat_rounded,
        size: 14,
        color: FGColors.textSecondary,
      ),
    );
  }

  Widget _buildHistoryChart(int days) {
    final data = _historyData.take(days).toList();
    final maxHrv = data.map((d) => d.hrv).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.sm),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length.clamp(0, 7), (index) {
          final item = data[index];
          final hrvHeight = (item.hrv / maxHrv) * 90;
          final hrvColor = _getHrvColor(item.hrv);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + index * 50),
                      height: hrvHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            hrvColor.withValues(alpha: 0.3),
                            hrvColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: hrvColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.day,
                    style: FGTypography.caption.copyWith(
                      fontSize: 9,
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayRow(HeartHistoryData data) {
    final hrvStatus = _getHrvColor(data.hrv);
    final hrStatus = _getRestingHRColor(data.restingHR);

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              data.day,
              style: FGTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hrStatus,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${data.restingHR}',
                  style: FGTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF5B7F),
                  ),
                ),
                Text(
                  ' BPM',
                  style: FGTypography.caption.copyWith(
                    fontSize: 9,
                    color: FGColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hrvStatus,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${data.hrv}',
                  style: FGTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B5BFF),
                  ),
                ),
                Text(
                  ' ms',
                  style: FGTypography.caption.copyWith(
                    fontSize: 9,
                    color: FGColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _getTrendIcon(data.trend),
        ],
      ),
    );
  }

  Color _getHrvColor(int hrv) {
    if (hrv >= 60) return FGColors.success;
    if (hrv >= 45) return const Color(0xFFFFCA28);
    if (hrv >= 30) return FGColors.warning;
    return FGColors.error;
  }

  Color _getRestingHRColor(int hr) {
    if (hr < 50) return const Color(0xFF00D9FF);
    if (hr <= 60) return FGColors.success;
    if (hr <= 70) return FGColors.success;
    if (hr <= 80) return FGColors.warning;
    return FGColors.error;
  }

  ({String text, Color color}) _getHeartGaugeStatus(
    int value,
    int idealMin,
    int idealMax,
    bool higherIsBetter,
  ) {
    if (higherIsBetter) {
      if (value >= idealMin) return (text: 'Optimal', color: FGColors.success);
      if (value >= idealMin * 0.7) {
        return (text: 'Moyen', color: FGColors.warning);
      }
      return (text: 'Faible', color: FGColors.error);
    } else {
      if (value >= idealMin && value <= idealMax) {
        return (text: 'Optimal', color: FGColors.success);
      }
      if (value < idealMin) {
        return (text: 'Athlète', color: const Color(0xFF00D9FF));
      }
      if (value <= idealMax * 1.15) {
        return (text: 'Normal', color: FGColors.warning);
      }
      return (text: 'Élevé', color: FGColors.error);
    }
  }

  ({String text, Color color}) _getVo2Status(double vo2) {
    if (vo2 >= 50) return (text: 'Supérieur', color: const Color(0xFF00D9FF));
    if (vo2 >= 42) return (text: 'Excellent', color: FGColors.success);
    if (vo2 >= 35) return (text: 'Bon', color: FGColors.success);
    if (vo2 >= 30) return (text: 'Moyen', color: FGColors.warning);
    return (text: 'Faible', color: FGColors.error);
  }
}
