import 'package:flutter/material.dart';

/// Compact gauge painter for heart rate metrics with gradient coloring
class HeartGaugePainter extends CustomPainter {
  final double progress;
  final double actualPercent;
  final double idealMinPercent;
  final double idealMaxPercent;
  final Color accentColor;
  final bool higherIsBetter;

  HeartGaugePainter({
    required this.progress,
    required this.actualPercent,
    required this.idealMinPercent,
    required this.idealMaxPercent,
    required this.accentColor,
    this.higherIsBetter = false,
  });

  Color _getColorAtPosition(double position) {
    if (higherIsBetter) {
      // Red → Yellow → Green (right is better)
      if (position < 0.3) {
        return Color.lerp(
            const Color(0xFFD32F2F), const Color(0xFFFF5252), position / 0.3)!;
      }
      if (position < 0.5) {
        return Color.lerp(const Color(0xFFFF5252), const Color(0xFFFFCA28),
            (position - 0.3) / 0.2)!;
      }
      if (position < 0.7) {
        return Color.lerp(const Color(0xFFFFCA28), const Color(0xFF69F0AE),
            (position - 0.5) / 0.2)!;
      }
      return Color.lerp(const Color(0xFF69F0AE), const Color(0xFF00C853),
          (position - 0.7) / 0.3)!;
    } else {
      // Cyan (low) → Green (ideal) → Red (high)
      final idealCenter = (idealMinPercent + idealMaxPercent) / 2;

      if (position < idealMinPercent * 0.5) {
        return Color.lerp(const Color(0xFF00D9FF), const Color(0xFF00E5FF),
            position / (idealMinPercent * 0.5))!;
      }
      if (position < idealMinPercent) {
        final t = (position - idealMinPercent * 0.5) / (idealMinPercent * 0.5);
        return Color.lerp(
            const Color(0xFF00E5FF), const Color(0xFF00C853), t)!;
      }
      if (position < idealCenter) {
        return const Color(0xFF00C853);
      }
      if (position < idealMaxPercent) {
        return const Color(0xFF00C853);
      }
      final postIdeal = idealMaxPercent + (1 - idealMaxPercent) * 0.5;
      if (position < postIdeal) {
        final t = (position - idealMaxPercent) / (postIdeal - idealMaxPercent);
        return Color.lerp(
            const Color(0xFFFFCA28), const Color(0xFFFF5252), t)!;
      }
      final t = (position - postIdeal) / (1 - postIdeal);
      return Color.lerp(
          const Color(0xFFFF5252), const Color(0xFFD32F2F), t)!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = size.height - 6;
    final barRect = Rect.fromLTWH(0, 0, size.width, barHeight);
    const barRadius = Radius.circular(6);
    final barRRect = RRect.fromRectAndRadius(barRect, barRadius);

    // Dark base
    canvas.drawRRect(
      barRRect,
      Paint()..color = const Color(0xFF0D0D0D),
    );

    // Color gradient
    final gradientPaint = Paint();
    if (higherIsBetter) {
      gradientPaint.shader = LinearGradient(
        colors: [
          const Color(0xFFD32F2F).withValues(alpha: 0.45),
          const Color(0xFFFF5252).withValues(alpha: 0.38),
          const Color(0xFFFFCA28).withValues(alpha: 0.38),
          const Color(0xFF69F0AE).withValues(alpha: 0.45),
          const Color(0xFF00C853).withValues(alpha: 0.50),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(barRect);
    } else {
      gradientPaint.shader = LinearGradient(
        colors: [
          const Color(0xFF00D9FF).withValues(alpha: 0.40),
          const Color(0xFF00E5FF).withValues(alpha: 0.35),
          const Color(0xFF00C853).withValues(alpha: 0.50),
          const Color(0xFF00C853).withValues(alpha: 0.50),
          const Color(0xFFFFCA28).withValues(alpha: 0.38),
          const Color(0xFFFF5252).withValues(alpha: 0.38),
          const Color(0xFFD32F2F).withValues(alpha: 0.45),
        ],
        stops: [
          0.0,
          idealMinPercent * 0.5,
          idealMinPercent,
          idealMaxPercent,
          idealMaxPercent + (1 - idealMaxPercent) * 0.3,
          idealMaxPercent + (1 - idealMaxPercent) * 0.6,
          1.0,
        ],
      ).createShader(barRect);
    }
    canvas.drawRRect(barRRect, gradientPaint);

    // Inner edge
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

    // Cursor position
    final cursorX =
        (size.width * actualPercent * progress).clamp(6.0, size.width - 6);
    final cursorColor = _getColorAtPosition(actualPercent);

    // Glow effect
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

    // Cursor pill
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

    // Triangle indicator
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
  bool shouldRepaint(covariant HeartGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.actualPercent != actualPercent;
  }
}
