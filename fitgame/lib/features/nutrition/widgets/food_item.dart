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
                  Text(
                    food['quantity'] as String,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Row(
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
          ],
        ),
      ),
    );
  }
}
