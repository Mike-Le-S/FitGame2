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
    required this.initialValue,
    required this.isInteger,
    required this.onValueChange,
  });

  @override
  State<NumberPickerSheet> createState() => NumberPickerSheetState();
}

class NumberPickerSheetState extends State<NumberPickerSheet> {
  late double _value;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(
      text: widget.isInteger
          ? _value.toInt().toString()
          : _value.toStringAsFixed(_value == _value.toInt() ? 0 : 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
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
              const SizedBox(height: Spacing.lg),

              // Input field
              TextField(
                controller: _controller,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: !widget.isInteger,
                ),
                textAlign: TextAlign.center,
                autofocus: true,
                style: FGTypography.display.copyWith(
                  fontSize: 48,
                  color: FGColors.accent,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: FGTypography.display.copyWith(
                    fontSize: 48,
                    color: FGColors.textSecondary,
                  ),
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) {
                    _value = parsed;
                  }
                },
              ),

              const SizedBox(height: Spacing.lg),

              // Quick values
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                alignment: WrapAlignment.center,
                children: (widget.isInteger
                        ? [5, 8, 10, 12, 15, 20]
                        : [60.0, 80.0, 100.0, 120.0, 140.0])
                    .map((v) {
                  return GestureDetector(
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
                        color: FGColors.glassSurface,
                        borderRadius: BorderRadius.circular(Spacing.sm),
                        border: Border.all(color: FGColors.glassBorder),
                      ),
                      child: Text(
                        widget.isInteger ? v.toString() : '${v}kg',
                        style: FGTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: Spacing.lg),

              // Confirm button
              GestureDetector(
                onTap: () => widget.onValueChange(_value),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  decoration: BoxDecoration(
                    color: FGColors.accent,
                    borderRadius: BorderRadius.circular(Spacing.md),
                    boxShadow: FGEffects.neonGlow,
                  ),
                  child: Center(
                    child: Text(
                      'CONFIRMER',
                      style: FGTypography.button,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
