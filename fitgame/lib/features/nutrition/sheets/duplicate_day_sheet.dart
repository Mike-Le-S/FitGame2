import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_neon_button.dart';

class DuplicateDaySheet extends StatefulWidget {
  final int sourceDay;
  final List<String> dayNames;
  final Function(List<int>) onDuplicate;

  const DuplicateDaySheet({
    required this.sourceDay,
    required this.dayNames,
    required this.onDuplicate,
  });

  @override
  State<DuplicateDaySheet> createState() => DuplicateDaySheetState();
}

class DuplicateDaySheetState extends State<DuplicateDaySheet> {
  final Set<int> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Dupliquer ${widget.dayNames[widget.sourceDay]}', style: FGTypography.h3),
          const SizedBox(height: Spacing.sm),
          Text(
            'Sélectionne les jours où copier ce plan',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.lg),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: List.generate(7, (index) {
              if (index == widget.sourceDay) return const SizedBox.shrink();
              final isSelected = _selectedDays.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(index);
                    } else {
                      _selectedDays.add(index);
                    }
                  });
                  HapticFeedback.selectionClick();
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
                      color: isSelected ? FGColors.accent : FGColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    widget.dayNames[index],
                    style: FGTypography.body.copyWith(
                      color: isSelected ? FGColors.accent : FGColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: Spacing.xl),
          FGNeonButton(
            label: 'Dupliquer vers ${_selectedDays.length} jour(s)',
            isExpanded: true,
            onPressed: _selectedDays.isEmpty
                ? null
                : () => widget.onDuplicate(_selectedDays.toList()),
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }
}
