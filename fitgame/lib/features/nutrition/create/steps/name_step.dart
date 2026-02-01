import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Diet name suggestions
const List<String> dietNameSuggestions = [
  'Plan Prise',
  'Diète Sèche',
  'Nutrition Équilibre',
  'Plan Perso',
];

/// Step 1: Diet name input
class DietNameStep extends StatelessWidget {
  final TextEditingController controller;
  final String dietName;
  final ValueChanged<String> onNameChanged;

  const DietNameStep({
    super.key,
    required this.controller,
    required this.dietName,
    required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Nomme ton\nplan',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Un nom qui reflète ton objectif nutritionnel',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xxl),
          Container(
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(Spacing.md),
              border: Border.all(color: FGColors.glassBorder),
            ),
            child: TextField(
              controller: controller,
              style: FGTypography.h3.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Ex: Plan Prise',
                hintStyle: FGTypography.h3.copyWith(
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(Spacing.lg),
              ),
              onChanged: onNameChanged,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Suggestions',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: dietNameSuggestions
                .map((name) => _SuggestionChip(
                      name: name,
                      isSelected: dietName == name,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.text = name;
                        onNameChanged(name);
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.2)
              : FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(
            color: isSelected ? const Color(0xFF2ECC71) : FGColors.glassBorder,
          ),
        ),
        child: Text(
          name,
          style: FGTypography.body.copyWith(
            color: isSelected ? const Color(0xFF2ECC71) : FGColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
