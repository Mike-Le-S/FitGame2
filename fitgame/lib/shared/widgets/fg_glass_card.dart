import 'package:flutter/material.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_effects.dart';
import '../../core/constants/spacing.dart';

/// A glass-morphism card with backdrop blur effect
class FGGlassCard extends StatelessWidget {
  const FGGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.onTap,
  });

  /// Compact preset: 8px padding (logs, history, small info)
  const FGGlassCard.compact({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.onTap,
  }) : padding = const EdgeInsets.all(Spacing.sm);

  /// Standard preset: 16px padding (notes, secondary content)
  const FGGlassCard.standard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.onTap,
  }) : padding = const EdgeInsets.all(Spacing.md);

  /// Spacious preset: vertical 16px, horizontal 0 (main content cards in parent-padded layouts)
  const FGGlassCard.spacious({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.onTap,
  }) : padding = const EdgeInsets.symmetric(vertical: Spacing.md);

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: FGEffects.glassBlur,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: FGColors.glassBorder,
                width: 1,
              ),
            ),
            padding: padding ?? const EdgeInsets.all(Spacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
