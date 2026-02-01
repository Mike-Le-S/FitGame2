import 'package:flutter/material.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Success modal shown after diet creation
class DietSuccessModal extends StatefulWidget {
  final String dietName;
  final String goalType;
  final int trainingCalories;
  final int mealsPerDay;
  final int supplementsCount;
  final VoidCallback onDismiss;

  const DietSuccessModal({
    super.key,
    required this.dietName,
    required this.goalType,
    required this.trainingCalories,
    required this.mealsPerDay,
    this.supplementsCount = 0,
    required this.onDismiss,
  });

  @override
  State<DietSuccessModal> createState() => _DietSuccessModalState();
}

class _DietSuccessModalState extends State<DietSuccessModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  static const _nutritionGreen = Color(0xFF2ECC71);

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

  String get _goalLabel {
    switch (widget.goalType) {
      case 'bulk':
        return 'Prise de masse';
      case 'cut':
        return 'Sèche';
      default:
        return 'Maintien';
    }
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
                        _nutritionGreen.withValues(alpha: 0.3),
                        _nutritionGreen.withValues(alpha: 0.1),
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
                        color: _nutritionGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _nutritionGreen,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: _nutritionGreen,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            // Title
            Text(
              'Plan créé !',
              style: FGTypography.h2.copyWith(
                color: FGColors.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            // Diet name
            Text(
              widget.dietName,
              style: FGTypography.body.copyWith(
                color: _nutritionGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat(_goalLabel, 'objectif'),
                _buildDivider(),
                _buildStat('${widget.trainingCalories}', 'kcal'),
                _buildDivider(),
                _buildStat('${widget.mealsPerDay}', 'repas'),
                if (widget.supplementsCount > 0) ...[
                  _buildDivider(),
                  _buildStat('${widget.supplementsCount}', 'suppléments'),
                ],
              ],
            ),
            const SizedBox(height: Spacing.xl),
            // Button with green theme
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _nutritionGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Parfait',
                  style: FGTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      color: FGColors.glassBorder,
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: FGTypography.body.copyWith(
            color: FGColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
