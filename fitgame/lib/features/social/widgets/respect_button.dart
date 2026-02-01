import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';

/// Animated respect button with scale and glow effects
class RespectButton extends StatefulWidget {
  const RespectButton({
    super.key,
    required this.count,
    required this.hasGivenRespect,
    required this.onTap,
  });

  final int count;
  final bool hasGivenRespect;
  final VoidCallback onTap;

  @override
  State<RespectButton> createState() => _RespectButtonState();
}

class _RespectButtonState extends State<RespectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.hasGivenRespect) {
      HapticFeedback.mediumImpact();
      _controller.forward(from: 0);
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: widget.hasGivenRespect
                  ? FGColors.accent.withValues(alpha: 0.2)
                  : FGColors.glassSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.hasGivenRespect
                    ? FGColors.accent
                    : FGColors.glassBorder,
                width: 1,
              ),
              boxShadow: widget.hasGivenRespect || _glowAnimation.value > 0
                  ? [
                      BoxShadow(
                        color: FGColors.accent.withValues(
                          alpha: widget.hasGivenRespect
                              ? 0.3
                              : _glowAnimation.value * 0.5,
                        ),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Icon(
                    Icons.fitness_center,
                    size: 18,
                    color: widget.hasGivenRespect
                        ? FGColors.accent
                        : FGColors.textSecondary,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  widget.hasGivenRespect ? 'RESPECT' : 'RESPECT',
                  style: FGTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: widget.hasGivenRespect
                        ? FGColors.accent
                        : FGColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
