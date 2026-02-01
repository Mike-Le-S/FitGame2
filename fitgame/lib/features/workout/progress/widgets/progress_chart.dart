import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../models/exercise_history.dart';

/// Widget affichant le graphique de progression des poids
class ProgressChart extends StatefulWidget {
  final ExerciseHistory history;
  final double height;

  const ProgressChart({
    super.key,
    required this.history,
    this.height = 200,
  });

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _ProgressChartPainter(
            entries: widget.history.entries,
            animationProgress: _animation.value,
          ),
        );
      },
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  final List<ExerciseProgressEntry> entries;
  final double animationProgress;

  _ProgressChartPainter({
    required this.entries,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const double paddingLeft = 45;
    const double paddingRight = 16;
    const double paddingTop = 20;
    const double paddingBottom = 30;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Calcul des bornes Y
    final weights = entries.map((e) => e.weight).toList();
    final minWeight = (weights.reduce((a, b) => a < b ? a : b) - 5)
        .clamp(0, double.infinity);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b) + 5;
    final weightRange = maxWeight - minWeight;

    // Paint pour la grille
    final gridPaint = Paint()
      ..color = FGColors.glassBorder.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Dessiner les lignes de grille horizontales
    const int gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = paddingTop + (chartHeight / gridLines) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      // Labels Y
      final weightValue = maxWeight - (weightRange / gridLines) * i;
      final textSpan = TextSpan(
        text: '${weightValue.toInt()}',
        style: const TextStyle(
          color: FGColors.textSecondary,
          fontSize: 10,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Calculer les points du graphique
    final points = <Offset>[];
    final prPoints = <Offset>[];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final x = paddingLeft + (chartWidth / (entries.length - 1)) * i;
      final y = paddingTop +
          chartHeight -
          ((entry.weight - minWeight) / weightRange) * chartHeight;

      points.add(Offset(x, y));
      if (entry.isPR) {
        prPoints.add(Offset(x, y));
      }

      // Labels X (semaines)
      final weekLabel = 'S${i + 1}';
      final textSpan = TextSpan(
        text: weekLabel,
        style: const TextStyle(
          color: FGColors.textSecondary,
          fontSize: 10,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - paddingBottom + 8),
      );
    }

    // Dessiner la zone sous la courbe (gradient)
    if (points.length >= 2) {
      final gradientPath = Path();
      final animatedPoints = points
          .take((points.length * animationProgress).ceil().clamp(2, points.length))
          .toList();

      gradientPath.moveTo(animatedPoints.first.dx, paddingTop + chartHeight);
      for (final point in animatedPoints) {
        gradientPath.lineTo(point.dx, point.dy);
      }
      gradientPath.lineTo(animatedPoints.last.dx, paddingTop + chartHeight);
      gradientPath.close();

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FGColors.accent.withValues(alpha: 0.3),
            FGColors.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(
          paddingLeft,
          paddingTop,
          chartWidth,
          chartHeight,
        ));

      canvas.drawPath(gradientPath, gradientPaint);
    }

    // Dessiner la ligne principale
    if (points.length >= 2) {
      final linePath = Path();
      final animatedPointCount =
          (points.length * animationProgress).ceil().clamp(1, points.length);

      linePath.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < animatedPointCount; i++) {
        // Courbe de Bézier pour un rendu plus lisse
        if (i < points.length - 1) {
          final p0 = points[i - 1];
          final p1 = points[i];
          final p2 = points[i + 1];

          final controlX1 = p0.dx + (p1.dx - p0.dx) * 0.5;
          final controlX2 = p1.dx - (p2.dx - p0.dx) * 0.1;

          linePath.cubicTo(
            controlX1,
            p0.dy,
            controlX2,
            p1.dy,
            p1.dx,
            p1.dy,
          );
        } else {
          linePath.lineTo(points[i].dx, points[i].dy);
        }
      }

      final linePaint = Paint()
        ..color = FGColors.accent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Dessiner les points normaux
    final pointPaint = Paint()
      ..color = FGColors.accent
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = FGColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final animatedPointCount =
        (points.length * animationProgress).ceil().clamp(0, points.length);

    for (int i = 0; i < animatedPointCount; i++) {
      final point = points[i];
      canvas.drawCircle(point, 6, pointBorderPaint);
      canvas.drawCircle(point, 5, pointPaint);
    }

    // Dessiner les points PR (dorés)
    final prPaint = Paint()
      ..color = const Color(0xFFFFD700) // Or
      ..style = PaintingStyle.fill;

    final prGlowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (final prPoint in prPoints) {
      // Vérifier si ce point est dans les points animés
      final pointIndex = points.indexOf(prPoint);
      if (pointIndex < animatedPointCount) {
        // Glow
        canvas.drawCircle(prPoint, 10, prGlowPaint);
        // Point principal
        canvas.drawCircle(prPoint, 7, prPaint);
        // Bordure
        canvas.drawCircle(
          prPoint,
          7,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}
