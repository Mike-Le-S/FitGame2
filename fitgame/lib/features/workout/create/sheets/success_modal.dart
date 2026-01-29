import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../shared/widgets/fg_neon_button.dart';

/// Success modal shown after program creation
class SuccessModal extends StatefulWidget {
  final String programName;
  final int daysCount;
  final int exercisesCount;
  final VoidCallback onDismiss;

  const SuccessModal({
    super.key,
    required this.programName,
    required this.daysCount,
    required this.exercisesCount,
    required this.onDismiss,
  });

  @override
  State<SuccessModal> createState() => _SuccessModalState();
}

class _SuccessModalState extends State<SuccessModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(Spacing.xl),
        decoration: BoxDecoration(
          color: FGColors.glassSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            // Success icon
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        FGColors.success.withValues(alpha: 0.3),
                        FGColors.success.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: FGColors.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FGColors.success,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: FGColors.success,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            // Title
            Text(
              'Programme créé !',
              style: FGTypography.h2.copyWith(
                color: FGColors.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            // Program name
            Text(
              widget.programName,
              style: FGTypography.body.copyWith(
                color: FGColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat('${widget.daysCount}', 'jours'),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  color: FGColors.glassBorder,
                ),
                _buildStat('${widget.exercisesCount}', 'exercices'),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            // Button
            FGNeonButton(
              label: 'Parfait',
              isExpanded: true,
              onPressed: widget.onDismiss,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: FGTypography.h3.copyWith(
            color: FGColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
