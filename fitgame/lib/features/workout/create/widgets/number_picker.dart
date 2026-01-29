import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Compact number picker with +/- buttons (inline style)
class NumberPicker extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const NumberPicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (value > min) {
                HapticFeedback.selectionClick();
                onChanged(value - 1);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: FGColors.glassBorder),
                ),
              ),
              child: Icon(
                Icons.remove_rounded,
                color: value > min ? FGColors.textSecondary : FGColors.glassBorder,
                size: 16,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                '$value',
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FGColors.accent,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (value < max) {
                HapticFeedback.selectionClick();
                onChanged(value + 1);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: FGColors.glassBorder),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                color: value < max ? FGColors.textSecondary : FGColors.glassBorder,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expanded number picker with larger touch targets (for forms)
class ExpandedNumberPicker extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const ExpandedNumberPicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (value > min) {
                  HapticFeedback.selectionClick();
                  onChanged(value - 1);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                child: Icon(
                  Icons.remove_rounded,
                  color: value > min ? FGColors.textPrimary : FGColors.glassBorder,
                  size: 20,
                ),
              ),
            ),
          ),
          Text(
            '$value',
            style: FGTypography.h3.copyWith(color: FGColors.accent),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (value < max) {
                  HapticFeedback.selectionClick();
                  onChanged(value + 1);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                child: Icon(
                  Icons.add_rounded,
                  color: value < max ? FGColors.textPrimary : FGColors.glassBorder,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
