import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/theme/fg_effects.dart';
import '../../../../core/constants/spacing.dart';

class NumberPickerSheet extends StatefulWidget {
  final double initialValue;
  final bool isInteger;
  final Function(double) onValueChange;

  const NumberPickerSheet({
    super.key,
    required this.initialValue,
    required this.isInteger,
    required this.onValueChange,
  });

  @override
  State<NumberPickerSheet> createState() => _NumberPickerSheetState();
}

class _NumberPickerSheetState extends State<NumberPickerSheet> {
  late double _value;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(
      text: widget.isInteger
          ? _value.toInt().toString()
          : _formatWeight(_value),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Format weight: no decimals if whole, up to 2 decimals otherwise
  String _formatWeight(double v) {
    if (v == v.toInt().toDouble()) return v.toInt().toString();
    if (v == double.parse(v.toStringAsFixed(1))) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  void _confirm() {
    HapticFeedback.lightImpact();
    widget.onValueChange(_value);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.md),
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
            const SizedBox(height: Spacing.sm),

            // Input field + confirm button in a row
            Row(
              children: [
                // Input field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      border: Border.all(color: FGColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: !widget.isInteger,
                      ),
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: FGTypography.display.copyWith(
                        fontSize: 36,
                        color: FGColors.accent,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        hintText: '0',
                        hintStyle: FGTypography.display.copyWith(
                          fontSize: 36,
                          color: FGColors.textSecondary,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.trim().isEmpty) {
                          _value = 0;
                          return;
                        }
                        final parsed = double.tryParse(value);
                        if (parsed != null) {
                          _value = parsed.clamp(0, 9999);
                        }
                      },
                      onSubmitted: (_) => _confirm(),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                // OK button
                GestureDetector(
                  onTap: _confirm,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: FGColors.accent,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      boxShadow: FGEffects.neonGlow,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: Spacing.sm),

            // Quick values
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (widget.isInteger
                        ? [5, 8, 10, 12, 15, 20]
                        : [40.0, 60.0, 80.0, 100.0, 120.0, 140.0])
                    .map((v) {
                  final isSelected = _value == v.toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(right: Spacing.sm),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _value = v.toDouble();
                          _controller.text = widget.isInteger
                              ? v.toString()
                              : v.toStringAsFixed(0);
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FGColors.accent.withValues(alpha: 0.2)
                              : FGColors.glassSurface,
                          borderRadius: BorderRadius.circular(Spacing.sm),
                          border: Border.all(
                            color: isSelected
                                ? FGColors.accent
                                : FGColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          widget.isInteger ? v.toString() : '${v.toStringAsFixed(0)}kg',
                          style: FGTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? FGColors.accent : FGColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
