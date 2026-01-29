import 'package:flutter/material.dart';

/// Compact gauge painter for sleep metrics with gradient coloring
class SleepGaugePainter extends CustomPainter {
  final double progress;
  final double actualPercent;
  final double idealMinPercent;
  final double idealMaxPercent;
  final bool invertGauge;
  final Color accentColor;

  SleepGaugePainter({
    required this.progress,
    required this.actualPercent,
    required this.idealMinPercent,
    required this.idealMaxPercent,
    required this.invertGauge,
    required this.accentColor,
  });

  // Get color at a specific position in the gradient
  Color _getColorAtPosition(double position) {
    if (invertGauge) {
      // Green → Yellow → Red
      if (position < 0.15) return Color.lerp(const Color(0xFF00C853), const Color(0xFF69F0AE), position / 0.15)!;
      if (position < 0.35) return Color.lerp(const Color(0xFF69F0AE), const Color(0xFFFFEE58), (position - 0.15) / 0.2)!;
      if (position < 0.55) return Color.lerp(const Color(0xFFFFEE58), const Color(0xFFFFA726), (position - 0.35) / 0.2)!;
      if (position < 0.75) return Color.lerp(const Color(0xFFFFA726), const Color(0xFFFF5252), (position - 0.55) / 0.2)!;
      return Color.lerp(const Color(0xFFFF5252), const Color(0xFFD32F2F), (position - 0.75) / 0.25)!;
    } else {
      // Red → Green (ideal) → Red
      final idealCenter = (idealMinPercent + idealMaxPercent) / 2;
      if (position < idealMinPercent * 0.5) {
        return Color.lerp(const Color(0xFFD32F2F), const Color(0xFFFF5252), position / (idealMinPercent * 0.5))!;
      }
      if (position < idealMinPercent) {
        final t = (position - idealMinPercent * 0.5) / (idealMinPercent * 0.5);
        return Color.lerp(const Color(0xFFFF5252), const Color(0xFFFFCA28), t)!;
      }
      if (position < idealCenter) {
        final t = (position - idealMinPercent) / (idealCenter - idealMinPercent);
        return Color.lerp(const Color(0xFFFFCA28), const Color(0xFF00C853), t)!;
      }
      if (position < idealMaxPercent) {
        final t = (position - idealCenter) / (idealMaxPercent - idealCenter);
        return Color.lerp(const Color(0xFF00C853), const Color(0xFFFFCA28), t)!;
      }
      final postIdeal = idealMaxPercent + (1 - idealMaxPercent) * 0.5;
      if (position < postIdeal) {
        final t = (position - idealMaxPercent) / (postIdeal - idealMaxPercent);
        return Color.lerp(const Color(0xFFFFCA28), const Color(0xFFFF5252), t)!;
      }
      final t = (position - postIdeal) / (1 - postIdeal);
      return Color.lerp(const Color(0xFFFF5252), const Color(0xFFD32F2F), t)!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = size.height - 6;
    final barRect = Rect.fromLTWH(0, 0, size.width, barHeight);
    const barRadius = Radius.circular(6);
    final barRRect = RRect.fromRectAndRadius(barRect, barRadius);

    // === LAYER 1: Dark muted base ===
    canvas.drawRRect(
      barRRect,
      Paint()..color = const Color(0xFF0D0D0D),
    );

    // === LAYER 2: Visible color gradient ===
    final gradientPaint = Paint();
    if (invertGauge) {
      // Green → Yellow → Orange → Red (for "Éveillé" - less is better)
      gradientPaint.shader = LinearGradient(
        colors: [
          const Color(0xFF00C853).withValues(alpha: 0.45), // Green
          const Color(0xFF69F0AE).withValues(alpha: 0.38), // Light green
          const Color(0xFFFFEE58).withValues(alpha: 0.38), // Yellow
          const Color(0xFFFFA726).withValues(alpha: 0.38), // Orange
          const Color(0xFFFF5252).withValues(alpha: 0.45), // Red
        ],
        stops: const [0.0, 0.15, 0.40, 0.65, 1.0],
      ).createShader(barRect);
    } else {
      // Red → Orange → Yellow → Green (ideal) → Yellow → Orange → Red
      final idealCenter = (idealMinPercent + idealMaxPercent) / 2;
      gradientPaint.shader = LinearGradient(
        colors: [
          const Color(0xFFD32F2F).withValues(alpha: 0.45), // Deep red
          const Color(0xFFFF5252).withValues(alpha: 0.38), // Red
          const Color(0xFFFFA726).withValues(alpha: 0.38), // Orange
          const Color(0xFFFFEE58).withValues(alpha: 0.35), // Yellow
          const Color(0xFF00C853).withValues(alpha: 0.50), // Green (ideal)
          const Color(0xFFFFEE58).withValues(alpha: 0.35), // Yellow
          const Color(0xFFFFA726).withValues(alpha: 0.38), // Orange
          const Color(0xFFFF5252).withValues(alpha: 0.38), // Red
          const Color(0xFFD32F2F).withValues(alpha: 0.45), // Deep red
        ],
        stops: [
          0.0,
          idealMinPercent * 0.3,
          idealMinPercent * 0.6,
          idealMinPercent * 0.85,
          idealCenter,
          idealMaxPercent + (1 - idealMaxPercent) * 0.15,
          idealMaxPercent + (1 - idealMaxPercent) * 0.4,
          idealMaxPercent + (1 - idealMaxPercent) * 0.7,
          1.0,
        ],
      ).createShader(barRect);
    }
    canvas.drawRRect(barRRect, gradientPaint);

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
    final cursorX = (size.width * actualPercent * progress).clamp(6.0, size.width - 6);
    final cursorColor = _getColorAtPosition(actualPercent);

    // === LAYER 4: Luminous halo around cursor - reveals the color ===
    // Large soft outer glow
    canvas.save();
    canvas.clipRRect(barRRect);

    // Outer color glow (large, soft)
    canvas.drawCircle(
      Offset(cursorX, barHeight / 2),
      28,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Middle color glow
    canvas.drawCircle(
      Offset(cursorX, barHeight / 2),
      18,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Inner bright glow
    canvas.drawCircle(
      Offset(cursorX, barHeight / 2),
      10,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Core bright spot
    canvas.drawCircle(
      Offset(cursorX, barHeight / 2),
      5,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.restore();

    // === CURSOR - Colored pill ===
    // Cursor glow (colored)
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

    // Main cursor body (colored with white core)
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

    // Cursor highlight (white for brightness)
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

    // Small triangle indicator
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
  bool shouldRepaint(covariant SleepGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.actualPercent != actualPercent;
  }
}
