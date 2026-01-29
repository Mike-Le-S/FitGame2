import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';

/// Mini progress ring painter for small circular indicators
class MiniProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  MiniProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Background
    final bgPaint = Paint()
      ..color = FGColors.glassBorder.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant MiniProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
