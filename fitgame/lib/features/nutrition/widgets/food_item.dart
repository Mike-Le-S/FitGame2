import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import 'macro_pill.dart';

/// Food item widget displaying name, quantity, macros, and calories
class FoodItem extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onTap;

  const FoodItem({
    super.key,
    required this.food,
    required this.onTap,
  });

  /// Builds the quantity text, showing plan vs actual if different
  Widget _buildQuantityText() {
    final quantity = food['quantity'] as String;
    final planQuantity = food['plan_quantity'] as String?;

    // If no plan quantity or they're the same, just show quantity
    if (planQuantity == null || planQuantity == quantity) {
      return Text(
        quantity,
        style: FGTypography.caption.copyWith(
          color: FGColors.textSecondary,
          fontSize: 11,
        ),
      );
    }

    // Show actual / plan prévu format
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: FGTypography.caption.copyWith(
          color: FGColors.textSecondary,
          fontSize: 11,
        ),
        children: [
          TextSpan(
            text: quantity,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: ' / $planQuantity prévu',
            style: TextStyle(
              color: FGColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'] as String,
                    style: FGTypography.body.copyWith(fontSize: 14),
                  ),
                  _buildQuantityText(),
                ],
              ),
            ),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MacroPill(
                    value: '${food['p']}p',
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 4),
                  MacroPill(
                    value: '${food['c']}c',
                    color: const Color(0xFF3498DB).withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 4),
                  MacroPill(
                    value: '${food['f']}f',
                    color: const Color(0xFFF39C12).withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    '${food['cal']}',
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
