import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';

/// Custom painter for challenge progress arc
class ChallengeProgressPainter extends CustomPainter {
  ChallengeProgressPainter({
    required this.progress,
    required this.strokeWidth,
    this.backgroundColor,
    this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // Start from top
    const sweepAngle = 2 * math.pi;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor ?? FGColors.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor ?? FGColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress.clamp(0.0, 1.0),
        false,
        progressPaint,
      );

      // Glow effect at the end
      if (progress < 1.0) {
        final glowPaint = Paint()
          ..color = (progressColor ?? FGColors.accent).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        final endAngle = startAngle + sweepAngle * progress.clamp(0.0, 1.0);
        final endPoint = Offset(
          center.dx + radius * math.cos(endAngle),
          center.dy + radius * math.sin(endAngle),
        );

        canvas.drawCircle(endPoint, strokeWidth / 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(ChallengeProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
