import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Dietary restrictions
const List<Map<String, dynamic>> dietaryRestrictions = [
  {'id': 'vegetarian', 'label': 'Végétarien', 'icon': Icons.eco_rounded},
  {'id': 'vegan', 'label': 'Vegan', 'icon': Icons.spa_rounded},
  {'id': 'gluten_free', 'label': 'Sans gluten', 'icon': Icons.grain_rounded},
  {
    'id': 'lactose_free',
    'label': 'Sans lactose',
    'icon': Icons.no_drinks_rounded
  },
];

/// Food preferences (what they like)
const List<Map<String, dynamic>> foodPreferences = [
  {'id': 'chicken', 'label': 'Poulet', 'icon': Icons.restaurant_rounded},
  {'id': 'fish', 'label': 'Poisson', 'icon': Icons.set_meal_rounded},
  {'id': 'beef', 'label': 'Boeuf', 'icon': Icons.lunch_dining_rounded},
  {'id': 'eggs', 'label': 'Oeufs', 'icon': Icons.egg_rounded},
  {'id': 'rice', 'label': 'Riz', 'icon': Icons.rice_bowl_rounded},
  {'id': 'pasta', 'label': 'Pâtes', 'icon': Icons.ramen_dining_rounded},
  {'id': 'vegetables', 'label': 'Légumes', 'icon': Icons.grass_rounded},
  {'id': 'fruits', 'label': 'Fruits', 'icon': Icons.apple},
];

/// Step 6: Dietary preferences and restrictions
class PreferencesStep extends StatelessWidget {
  final Set<String> restrictions;
  final Set<String> preferences;
  final ValueChanged<Set<String>> onRestrictionsChanged;
  final ValueChanged<Set<String>> onPreferencesChanged;

  const PreferencesStep({
    super.key,
    required this.restrictions,
    required this.preferences,
    required this.onRestrictionsChanged,
    required this.onPreferencesChanged,
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
            'Préférences\nalimentaires',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Personnalise ton plan selon tes goûts',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xl),
          // Restrictions section
          Text(
            'RESTRICTIONS',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: dietaryRestrictions.map((restriction) {
              final isSelected =
                  restrictions.contains(restriction['id'] as String);
              return _PreferenceChip(
                label: restriction['label'] as String,
                icon: restriction['icon'] as IconData,
                isSelected: isSelected,
                isRestriction: true,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final newRestrictions = Set<String>.from(restrictions);
                  if (isSelected) {
                    newRestrictions.remove(restriction['id'] as String);
                  } else {
                    newRestrictions.add(restriction['id'] as String);
                  }
                  onRestrictionsChanged(newRestrictions);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.xl),
          // Preferences section
          Text(
            'ALIMENTS PRÉFÉRÉS',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: foodPreferences.map((preference) {
              final isSelected =
                  preferences.contains(preference['id'] as String);
              return _PreferenceChip(
                label: preference['label'] as String,
                icon: preference['icon'] as IconData,
                isSelected: isSelected,
                isRestriction: false,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final newPreferences = Set<String>.from(preferences);
                  if (isSelected) {
                    newPreferences.remove(preference['id'] as String);
                  } else {
                    newPreferences.add(preference['id'] as String);
                  }
                  onPreferencesChanged(newPreferences);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.xl),
          // Optional note
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.glassSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Spacing.md),
              border: Border.all(color: FGColors.glassBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: FGColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'Cette étape est optionnelle. Tu peux la passer si tu veux.',
                    style: FGTypography.bodySmall.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isRestriction;
  final VoidCallback onTap;

  const _PreferenceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isRestriction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isRestriction ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71);

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
              ? color.withValues(alpha: 0.15)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(
            color: isSelected ? color : FGColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : FGColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: FGTypography.body.copyWith(
                color: isSelected ? color : FGColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
