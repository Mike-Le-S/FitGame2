import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Rest timer circular progress painter
class RestTimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  RestTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 12.0;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect at progress end
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.5)
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final endAngle = -math.pi / 2 + sweepAngle;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);

      canvas.drawCircle(Offset(endX, endY), 6, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RestTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
