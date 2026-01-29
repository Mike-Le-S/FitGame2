import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../painters/sleep_gauge_painter.dart';
import '../painters/latency_gauge_painter.dart';
import '../models/sleep_metric_info.dart';
import '../modals/sleep_info_modal.dart';

class SleepDetailSheet extends StatefulWidget {
  final int totalSleepMinutes;
  final int deepSleepMinutes;
  final int coreSleepMinutes;
  final int remSleepMinutes;
  final int awakeMinutes;
  final int timeInBedMinutes;
  final int sleepLatencyMinutes;

  const SleepDetailSheet({
    required this.totalSleepMinutes,
    required this.deepSleepMinutes,
    required this.coreSleepMinutes,
    required this.remSleepMinutes,
    required this.awakeMinutes,
    required this.timeInBedMinutes,
    required this.sleepLatencyMinutes,
  });

  @override
  State<SleepDetailSheet> createState() => SleepDetailSheetState();
}

class SleepDetailSheetState extends State<SleepDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Sleep metric educational content
  static const _sleepInfo = {
    'deep': SleepMetricInfo(
      title: 'Sommeil Profond',
      description:
          'Le sommeil profond (stades N3) est la phase la plus réparatrice. '
          'C\'est pendant cette phase que votre corps libère l\'hormone de croissance, '
          'répare les tissus musculaires et renforce le système immunitaire.',
      benefits: [
        'Récupération musculaire et tissulaire',
        'Consolidation de la mémoire à long terme',
        'Régulation hormonale (GH, cortisol)',
        'Renforcement du système immunitaire',
      ],
      fitnessImpact:
          'Essentiel pour la synthèse protéique et la récupération après l\'entraînement. '
          'Un manque de sommeil profond ralentit la progression musculaire et augmente le risque de blessure.',
      idealRange: '13-23% du temps de sommeil total',
    ),
    'core': SleepMetricInfo(
      title: 'Sommeil Core (Léger)',
      description:
          'Le sommeil core comprend les stades N1 et N2. C\'est une phase de transition '
          'qui représente environ la moitié de votre nuit. Bien que "léger", il joue un rôle '
          'crucial dans le traitement de l\'information et la consolidation motrice.',
      benefits: [
        'Traitement des informations de la journée',
        'Consolidation des apprentissages moteurs',
        'Maintien des fonctions cognitives',
        'Régulation de la température corporelle',
      ],
      fitnessImpact:
          'Important pour mémoriser les mouvements et techniques appris à l\'entraînement. '
          'Aide à automatiser les gestes sportifs et améliore la coordination.',
      idealRange: '45-55% du temps de sommeil total',
    ),
    'rem': SleepMetricInfo(
      title: 'Sommeil Paradoxal (REM)',
      description:
          'Le sommeil REM (Rapid Eye Movement) est la phase des rêves. Votre cerveau '
          'est très actif tandis que vos muscles sont paralysés. Cette phase augmente '
          'en durée au fil de la nuit.',
      benefits: [
        'Consolidation de la mémoire émotionnelle',
        'Créativité et résolution de problèmes',
        'Régulation de l\'humeur',
        'Traitement du stress et des émotions',
      ],
      fitnessImpact:
          'Crucial pour la motivation et la santé mentale. Un bon sommeil REM améliore '
          'la concentration pendant l\'entraînement et aide à gérer le stress de la compétition.',
      idealRange: '20-25% du temps de sommeil total',
    ),
    'awake': SleepMetricInfo(
      title: 'Temps Éveillé',
      description:
          'Le temps passé éveillé pendant la nuit inclut les micro-réveils et les réveils '
          'conscients. Un certain nombre de réveils est normal, mais trop de temps éveillé '
          'fragmente le sommeil et réduit sa qualité.',
      benefits: [
        'Permet les changements de position',
        'Les micro-réveils sont normaux entre les cycles',
        'Réveil matinal naturel',
      ],
      fitnessImpact:
          'Un temps éveillé excessif indique un sommeil fragmenté qui compromet la récupération. '
          'Peut être causé par le stress, la caféine tardive, ou un environnement de sommeil inadéquat.',
      idealRange: 'Moins de 5% du temps au lit',
    ),
    'latency': SleepMetricInfo(
      title: 'Latence d\'Endormissement',
      description:
          'Le temps nécessaire pour s\'endormir après s\'être couché. Une latence trop courte '
          'peut indiquer une dette de sommeil, tandis qu\'une latence trop longue peut signaler '
          'de l\'insomnie ou une mauvaise hygiène de sommeil.',
      benefits: [
        'Indicateur de la pression de sommeil',
        'Révèle la qualité de l\'hygiène de sommeil',
        'Permet d\'ajuster l\'heure du coucher',
      ],
      fitnessImpact:
          'S\'endormir trop vite (<10min) suggère une dette de sommeil qui affecte la performance. '
          'S\'endormir lentement (>20min) peut indiquer un surentraînement ou du stress.',
      idealRange: '10-20 minutes',
    ),
  };

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

  void _showInfoModal(String key) {
    final info = _sleepInfo[key];
    if (info == null) return;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SleepInfoModal(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = widget.totalSleepMinutes / 60;
    final efficiency =
        (widget.totalSleepMinutes / widget.timeInBedMinutes * 100).round();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: FGColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
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
                  // Compact header with stats
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B5BFF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(Spacing.sm),
                        ),
                        child: const Icon(
                          Icons.bedtime_rounded,
                          color: Color(0xFF6B5BFF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analyse du Sommeil',
                              style: FGTypography.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Dernière nuit',
                              style: FGTypography.caption.copyWith(
                                fontSize: 10,
                                color: FGColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Total sleep
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${totalHours.floor()}h${(widget.totalSleepMinutes % 60).toString().padLeft(2, '0')}',
                            style: FGTypography.h3.copyWith(
                              color: const Color(0xFF6B5BFF),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (efficiency >= 85
                                      ? FGColors.success
                                      : efficiency >= 75
                                          ? FGColors.warning
                                          : FGColors.error)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$efficiency% eff.',
                              style: FGTypography.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: efficiency >= 85
                                    ? FGColors.success
                                    : efficiency >= 75
                                        ? FGColors.warning
                                        : FGColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),

                  // ALL 5 GAUGES - Compact grid
                  Text(
                    'PHASES DE SOMMEIL',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),

                  // Deep Sleep - compact
                  _buildCompactGauge(
                    infoKey: 'deep',
                    label: 'Profond',
                    minutes: widget.deepSleepMinutes,
                    totalMinutes: widget.totalSleepMinutes,
                    idealMinPercent: 0.13,
                    idealMaxPercent: 0.23,
                    color: const Color(0xFF1E3A5F),
                  ),
                  const SizedBox(height: Spacing.sm),

                  // Core Sleep - compact
                  _buildCompactGauge(
                    infoKey: 'core',
                    label: 'Core',
                    minutes: widget.coreSleepMinutes,
                    totalMinutes: widget.totalSleepMinutes,
                    idealMinPercent: 0.45,
                    idealMaxPercent: 0.55,
                    color: const Color(0xFF4A90D9),
                  ),
                  const SizedBox(height: Spacing.sm),

                  // REM Sleep - compact
                  _buildCompactGauge(
                    infoKey: 'rem',
                    label: 'REM',
                    minutes: widget.remSleepMinutes,
                    totalMinutes: widget.totalSleepMinutes,
                    idealMinPercent: 0.20,
                    idealMaxPercent: 0.25,
                    color: const Color(0xFF9B6BFF),
                  ),
                  const SizedBox(height: Spacing.sm),

                  // Awake Time - compact (inverted)
                  _buildCompactGauge(
                    infoKey: 'awake',
                    label: 'Éveillé',
                    minutes: widget.awakeMinutes,
                    totalMinutes: widget.totalSleepMinutes,
                    idealMinPercent: 0.0,
                    idealMaxPercent: 0.05,
                    color: const Color(0xFFFF6B6B),
                    invertGauge: true,
                  ),
                  const SizedBox(height: Spacing.sm),

                  // Sleep Latency - compact
                  _buildCompactLatencyGauge(
                    infoKey: 'latency',
                    label: 'Endormissement',
                    minutes: widget.sleepLatencyMinutes,
                    color: const Color(0xFF00D9FF),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Time in bed - minimal
                  Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.king_bed_rounded,
                              color: FGColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              'Temps au lit',
                              style: FGTypography.caption.copyWith(
                                color: FGColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.timeInBedMinutes ~/ 60}h${(widget.timeInBedMinutes % 60).toString().padLeft(2, '0')}',
                          style: FGTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactGauge({
    required String infoKey,
    required String label,
    required int minutes,
    required int totalMinutes,
    required double idealMinPercent,
    required double idealMaxPercent,
    required Color color,
    bool invertGauge = false,
  }) {
    final actualPercent = minutes / totalMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final timeStr =
        hours > 0 ? '${hours}h${mins.toString().padLeft(2, '0')}' : '${mins}m';
    final percentStr = '${(actualPercent * 100).round()}%';

    final status = _getGaugeStatus(actualPercent, idealMinPercent, idealMaxPercent, invertGauge);

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
              // Header row: label + info + value + status
              Row(
                children: [
                  // Label with info button
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
                  // Value
                  Text(
                    timeStr,
                    style: FGTypography.caption.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    percentStr,
                    style: FGTypography.caption.copyWith(
                      fontSize: 9,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  // Status badge
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
              // Premium gauge
              SizedBox(
                height: 20,
                child: CustomPaint(
                  painter: SleepGaugePainter(
                    progress: _animController.value,
                    actualPercent: actualPercent,
                    idealMinPercent: idealMinPercent,
                    idealMaxPercent: idealMaxPercent,
                    invertGauge: invertGauge,
                    accentColor: color,
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

  Widget _buildCompactLatencyGauge({
    required String infoKey,
    required String label,
    required int minutes,
    required Color color,
  }) {
    const idealMin = 10;
    const idealMax = 20;
    final status = _getLatencyStatus(minutes, idealMin, idealMax);

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
                    '${minutes}min',
                    style: FGTypography.caption.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 12,
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
                  painter: LatencyGaugePainter(
                    progress: _animController.value,
                    actualMinutes: minutes,
                    idealMinMinutes: idealMin,
                    idealMaxMinutes: idealMax,
                    maxMinutes: 40,
                    accentColor: color,
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

  ({String text, Color color}) _getGaugeStatus(
      double actual, double idealMin, double idealMax, bool invertGauge) {
    if (invertGauge) {
      if (actual <= idealMax) {
        return (text: 'Optimal', color: FGColors.success);
      } else if (actual <= idealMax * 2) {
        return (text: 'Acceptable', color: FGColors.warning);
      } else {
        return (text: 'Élevé', color: FGColors.error);
      }
    } else {
      if (actual >= idealMin && actual <= idealMax) {
        return (text: 'Optimal', color: FGColors.success);
      } else if (actual < idealMin) {
        return (text: 'Insuffisant', color: FGColors.warning);
      } else {
        return (text: 'Élevé', color: FGColors.warning);
      }
    }
  }

  ({String text, Color color}) _getLatencyStatus(int minutes, int idealMin, int idealMax) {
    if (minutes >= idealMin && minutes <= idealMax) {
      return (text: 'Optimal', color: FGColors.success);
    } else if (minutes < idealMin) {
      return (text: 'Rapide', color: FGColors.warning);
    } else if (minutes <= 30) {
      return (text: 'Acceptable', color: FGColors.warning);
    } else {
      return (text: 'Long', color: FGColors.error);
    }
  }
}
