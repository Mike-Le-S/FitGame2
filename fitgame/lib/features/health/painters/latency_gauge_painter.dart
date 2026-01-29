import 'package:flutter/material.dart';

/// Compact gauge painter for sleep latency metric with gradient coloring
class LatencyGaugePainter extends CustomPainter {
  final double progress;
  final int actualMinutes;
  final int idealMinMinutes;
  final int idealMaxMinutes;
  final int maxMinutes;
  final Color accentColor;

  LatencyGaugePainter({
    required this.progress,
    required this.actualMinutes,
    required this.idealMinMinutes,
    required this.idealMaxMinutes,
    required this.maxMinutes,
    required this.accentColor,
  });

  Color _getColorAtPosition(double position) {
    final idealMinFraction = idealMinMinutes / maxMinutes;
    final idealMaxFraction = idealMaxMinutes / maxMinutes;
    final idealCenter = (idealMinFraction + idealMaxFraction) / 2;

    // Yellow (fast) → Green (ideal) → Red (slow)
    if (position < idealMinFraction * 0.5) {
      return Color.lerp(const Color(0xFFFFCA28), const Color(0xFFFFEE58), position / (idealMinFraction * 0.5))!;
    }
    if (position < idealMinFraction) {
      final t = (position - idealMinFraction * 0.5) / (idealMinFraction * 0.5);
      return Color.lerp(const Color(0xFFFFEE58), const Color(0xFF69F0AE), t)!;
    }
    if (position < idealCenter) {
      final t = (position - idealMinFraction) / (idealCenter - idealMinFraction);
      return Color.lerp(const Color(0xFF69F0AE), const Color(0xFF00C853), t)!;
    }
    if (position < idealMaxFraction) {
      final t = (position - idealCenter) / (idealMaxFraction - idealCenter);
      return Color.lerp(const Color(0xFF00C853), const Color(0xFF69F0AE), t)!;
    }
    final postIdeal = idealMaxFraction + (1 - idealMaxFraction) * 0.4;
    if (position < postIdeal) {
      final t = (position - idealMaxFraction) / (postIdeal - idealMaxFraction);
      return Color.lerp(const Color(0xFF69F0AE), const Color(0xFFFFA726), t)!;
    }
    final t = (position - postIdeal) / (1 - postIdeal);
    return Color.lerp(const Color(0xFFFFA726), const Color(0xFFD32F2F), t)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = size.height - 6;
    final barRect = Rect.fromLTWH(0, 0, size.width, barHeight);
    const barRadius = Radius.circular(6);
    final barRRect = RRect.fromRectAndRadius(barRect, barRadius);

    final idealMinFraction = idealMinMinutes / maxMinutes;
    final idealMaxFraction = idealMaxMinutes / maxMinutes;

    // === LAYER 1: Dark muted base ===
    canvas.drawRRect(
      barRRect,
      Paint()..color = const Color(0xFF0D0D0D),
    );

    // === LAYER 2: Visible color gradient ===
    // Yellow (too fast) → Green (ideal) → Orange → Red (too slow)
    final idealCenter = (idealMinFraction + idealMaxFraction) / 2;
    canvas.drawRRect(
      barRRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFCA28).withValues(alpha: 0.42), // Yellow (too fast)
            const Color(0xFFFFEE58).withValues(alpha: 0.35), // Light yellow
            const Color(0xFF00C853).withValues(alpha: 0.50), // Green (ideal)
            const Color(0xFFFFEE58).withValues(alpha: 0.35), // Light yellow
            const Color(0xFFFFA726).withValues(alpha: 0.38), // Orange
            const Color(0xFFFF5252).withValues(alpha: 0.42), // Red
            const Color(0xFFD32F2F).withValues(alpha: 0.45), // Deep red
          ],
          stops: [
            0.0,
            idealMinFraction * 0.5,
            idealCenter,
            idealMaxFraction + (1 - idealMaxFraction) * 0.15,
            idealMaxFraction + (1 - idealMaxFraction) * 0.4,
            idealMaxFraction + (1 - idealMaxFraction) * 0.7,
            1.0,
          ],
        ).createShader(barRect),
    );

    // === LAYER 3: Subtle inner edge ===
    canvas.drawRRect(
      barRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(barRect),
    );

    // === CURSOR POSITION ===
    final actualFraction = (actualMinutes / maxMinutes).clamp(0.0, 1.0);
    final cursorX = (size.width * actualFraction * progress).clamp(6.0, size.width - 6);
    final cursorColor = _getColorAtPosition(actualFraction);

    // === LAYER 4: Luminous halo around cursor ===
    canvas.save();
    canvas.clipRRect(barRRect);

    canvas.drawCircle(
      Offset(cursorX, barHeight / 2),
      28,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    canvas.drawCircle(
      Offset(cursorX, barHeight / 2),
      18,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawCircle(
      Offset(cursorX, barHeight / 2),
      10,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawCircle(
      Offset(cursorX, barHeight / 2),
      5,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.restore();

    // === CURSOR - Colored pill ===
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cursorX, barHeight / 2),
          width: 6,
          height: barHeight,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..color = cursorColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cursorX, barHeight / 2),
          width: 4,
          height: barHeight - 2,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Color.lerp(cursorColor, Colors.white, 0.3)!,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cursorX - 0.5, barHeight / 2),
          width: 1,
          height: barHeight - 4,
        ),
        const Radius.circular(0.5),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    // Triangle (stays white)
    final trianglePath = Path();
    trianglePath.moveTo(cursorX, barHeight + 1);
    trianglePath.lineTo(cursorX - 3, barHeight + 5);
    trianglePath.lineTo(cursorX + 3, barHeight + 5);
    trianglePath.close();

    canvas.drawPath(
      trianglePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    canvas.drawPath(
      trianglePath,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant LatencyGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.actualMinutes != actualMinutes;
  }
}
