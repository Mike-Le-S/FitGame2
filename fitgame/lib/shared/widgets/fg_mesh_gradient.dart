import 'package:flutter/material.dart';
import '../../core/theme/fg_colors.dart';

/// A configurable mesh gradient background widget used across screens.
///
/// Renders animated radial gradient orbs to create a soft glowing
/// background effect on top of the dark base color. Each screen uses
/// a named factory constructor to get its specific gradient configuration.
class FGMeshGradient extends StatelessWidget {
  /// Animation that drives the gradient pulse effect.
  final Animation<double> animation;

  /// List of orb configurations to render.
  final List<MeshGradientOrb> orbs;

  const FGMeshGradient({
    super.key,
    required this.animation,
    required this.orbs,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final alpha = animation.value;
        return Stack(
          children: [
            Container(color: FGColors.background),
            ...orbs.map((orb) => _buildOrb(orb, alpha)),
          ],
        );
      },
    );
  }

  Widget _buildOrb(MeshGradientOrb orb, double alpha) {
    final gradientColors = orb.colors.map((c) {
      if (c.alphaMultiplier != null) {
        return c.color.withValues(alpha: alpha * c.alphaMultiplier!);
      }
      return c.color;
    }).toList();

    return Positioned(
      top: orb.top,
      bottom: orb.bottom,
      left: orb.left,
      right: orb.right,
      child: Container(
        width: orb.size,
        height: orb.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: gradientColors,
            stops: orb.stops,
          ),
        ),
      ),
    );
  }

  // ============================================
  // Factory constructors for each screen
  // ============================================

  /// Home screen: top-right accent orb + bottom-left accent orb.
  /// Original also had a noise overlay gradient but it was purely cosmetic
  /// and applied over the full area; omitted here for simplicity since
  /// the visual impact is negligible.
  factory FGMeshGradient.home({required Animation<double> animation}) {
    return FGMeshGradient(
      animation: animation,
      orbs: [
        MeshGradientOrb(
          top: -100,
          right: -80,
          size: 350,
          colors: [
            OrbColor(FGColors.accent, alphaMultiplier: 0.6),
            OrbColor(FGColors.accent, alphaMultiplier: 0.2),
            OrbColor.transparent(),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        MeshGradientOrb(
          bottom: 100,
          left: -120,
          size: 300,
          colors: [
            OrbColor(FGColors.accent, alphaMultiplier: 0.15),
            OrbColor.transparent(),
          ],
          stops: const [0.0, 1.0],
        ),
      ],
    );
  }

  /// Workout screen: top-right accent orb + bottom-left accent orb.
  factory FGMeshGradient.workout({required Animation<double> animation}) {
    return FGMeshGradient(
      animation: animation,
      orbs: [
        MeshGradientOrb(
          top: -50,
          right: -100,
          size: 400,
          colors: [
            OrbColor(FGColors.accent, alphaMultiplier: 0.5),
            OrbColor(FGColors.accent, alphaMultiplier: 0.2),
            OrbColor.transparent(),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        MeshGradientOrb(
          bottom: 100,
          left: -150,
          size: 350,
          colors: [
            OrbColor(FGColors.accent, alphaMultiplier: 0.15),
            OrbColor.transparent(),
          ],
        ),
      ],
    );
  }

  /// Nutrition screen: green top-right orb + accent bottom-left orb.
  factory FGMeshGradient.nutrition({required Animation<double> animation}) {
    return FGMeshGradient(
      animation: animation,
      orbs: [
        MeshGradientOrb(
          top: -80,
          right: -60,
          size: 300,
          colors: [
            OrbColor(const Color(0xFF2ECC71), alphaMultiplier: 1.0),
            OrbColor.transparent(),
          ],
        ),
        MeshGradientOrb(
          bottom: 200,
          left: -100,
          size: 350,
          colors: [
            OrbColor(FGColors.accent, alphaMultiplier: 0.5),
            OrbColor.transparent(),
          ],
        ),
      ],
    );
  }

  /// Health screen: purple top-left orb + pink bottom-right orb.
  factory FGMeshGradient.health({required Animation<double> animation}) {
    return FGMeshGradient(
      animation: animation,
      orbs: [
        MeshGradientOrb(
          top: -80,
          left: -120,
          size: 400,
          colors: [
            OrbColor(const Color(0xFF6B5BFF), alphaMultiplier: 0.8),
            OrbColor(const Color(0xFF6B5BFF), alphaMultiplier: 0.3),
            OrbColor.transparent(),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        MeshGradientOrb(
          bottom: 50,
          right: -100,
          size: 350,
          colors: [
            OrbColor(const Color(0xFFFF5B7F), alphaMultiplier: 0.4),
            OrbColor.transparent(),
          ],
        ),
      ],
    );
  }

  /// Social screen: accent top-right orb + purple bottom-left orb.
  factory FGMeshGradient.social({required Animation<double> animation}) {
    return FGMeshGradient(
      animation: animation,
      orbs: [
        MeshGradientOrb(
          top: -50,
          right: -100,
          size: 350,
          colors: [
            OrbColor(FGColors.accent, alphaMultiplier: 1.0),
            OrbColor.transparent(),
          ],
        ),
        MeshGradientOrb(
          bottom: 150,
          left: -80,
          size: 300,
          colors: [
            OrbColor(const Color(0xFF6B5BFF), alphaMultiplier: 0.5),
            OrbColor.transparent(),
          ],
        ),
      ],
    );
  }

  /// Profile screen: accent top-left orb + accent bottom-right orb.
  factory FGMeshGradient.profile({required Animation<double> animation}) {
    return FGMeshGradient(
      animation: animation,
      orbs: [
        MeshGradientOrb(
          top: -80,
          left: -100,
          size: 350,
          colors: [
            OrbColor(FGColors.accent, alphaMultiplier: 0.5),
            OrbColor(FGColors.accent, alphaMultiplier: 0.2),
            OrbColor.transparent(),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        MeshGradientOrb(
          bottom: 150,
          right: -100,
          size: 300,
          colors: [
            OrbColor(FGColors.accent, alphaMultiplier: 0.25),
            OrbColor.transparent(),
          ],
          stops: const [0.0, 1.0],
        ),
      ],
    );
  }
}

/// Configuration for a single gradient orb.
class MeshGradientOrb {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final List<OrbColor> colors;
  final List<double>? stops;

  const MeshGradientOrb({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.colors,
    this.stops,
  });
}

/// Color configuration for a gradient orb.
class OrbColor {
  final Color color;

  /// If non-null, the alpha is computed as [animation.value * alphaMultiplier].
  /// If null, the color is used as-is (e.g. Colors.transparent).
  final double? alphaMultiplier;

  const OrbColor(this.color, {this.alphaMultiplier});

  /// Transparent color stop (used as-is, no alpha computation).
  const OrbColor.transparent()
      : color = Colors.transparent,
        alphaMultiplier = null;
}
