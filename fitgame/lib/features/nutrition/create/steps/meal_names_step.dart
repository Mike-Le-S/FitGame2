import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';

/// Available meal icons
const List<Map<String, dynamic>> mealIcons = [
  {'icon': Icons.wb_sunny_rounded, 'label': 'Matin'},
  {'icon': Icons.restaurant_rounded, 'label': 'Restaurant'},
  {'icon': Icons.apple, 'label': 'Snack'},
  {'icon': Icons.nights_stay_rounded, 'label': 'Soir'},
  {'icon': Icons.local_cafe_rounded, 'label': 'Café'},
  {'icon': Icons.egg_rounded, 'label': 'Oeuf'},
  {'icon': Icons.fitness_center_rounded, 'label': 'Sport'},
  {'icon': Icons.bedtime_rounded, 'label': 'Nuit'},
];

/// Step 6: Customize meal names
class MealNamesStep extends StatefulWidget {
  final List<String> mealNames;
  final List<IconData> mealIcons;
  final ValueChanged<List<String>> onMealNamesChanged;
  final ValueChanged<List<IconData>> onMealIconsChanged;

  const MealNamesStep({
    super.key,
    required this.mealNames,
    required this.mealIcons,
    required this.onMealNamesChanged,
    required this.onMealIconsChanged,
  });

  @override
  State<MealNamesStep> createState() => _MealNamesStepState();
}

class _MealNamesStepState extends State<MealNamesStep> {
  late List<TextEditingController> _controllers;

  static const _nutritionGreen = Color(0xFF2ECC71);

  @override
  void initState() {
    super.initState();
    _controllers = widget.mealNames
        .map((name) => TextEditingController(text: name))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateName(int index, String value) {
    final newNames = List<String>.from(widget.mealNames);
    newNames[index] = value;
    widget.onMealNamesChanged(newNames);
  }

  void _updateIcon(int mealIndex, IconData newIcon) {
    HapticFeedback.selectionClick();
    final newIcons = List<IconData>.from(widget.mealIcons);
    newIcons[mealIndex] = newIcon;
    widget.onMealIconsChanged(newIcons);
    Navigator.pop(context);
  }

  void _showIconPicker(int mealIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: FGColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text('Choisir une icône', style: FGTypography.h3),
            const SizedBox(height: Spacing.lg),
            Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.md,
              children: mealIcons.map((iconData) {
                final icon = iconData['icon'] as IconData;
                final isSelected = widget.mealIcons[mealIndex] == icon;
                return GestureDetector(
                  onTap: () => _updateIcon(mealIndex, icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _nutritionGreen.withValues(alpha: 0.2)
                          : FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.md),
                      border: Border.all(
                        color: isSelected
                            ? _nutritionGreen
                            : FGColors.glassBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? _nutritionGreen
                          : FGColors.textSecondary,
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + Spacing.lg),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    HapticFeedback.mediumImpact();
    if (newIndex > oldIndex) newIndex--;

    final names = List<String>.from(widget.mealNames);
    final icons = List<IconData>.from(widget.mealIcons);
    final controllers = List<TextEditingController>.from(_controllers);

    final name = names.removeAt(oldIndex);
    final icon = icons.removeAt(oldIndex);
    final controller = controllers.removeAt(oldIndex);

    names.insert(newIndex, name);
    icons.insert(newIndex, icon);
    controllers.insert(newIndex, controller);

    setState(() {
      _controllers = controllers;
    });
    widget.onMealNamesChanged(names);
    widget.onMealIconsChanged(icons);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Nomme tes\nrepas',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Personnalise chaque repas selon ton planning',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xl),
          // Reorderable list
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: widget.mealNames.length,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Material(
                  color: Colors.transparent,
                  elevation: animation.value * 8,
                  shadowColor: _nutritionGreen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(Spacing.md),
                  child: child,
                ),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              return _MealNameCard(
                key: ValueKey('meal_$index'),
                index: index,
                icon: widget.mealIcons[index],
                controller: _controllers[index],
                onNameChanged: (value) => _updateName(index, value),
                onIconTap: () => _showIconPicker(index),
              );
            },
          ),
          const SizedBox(height: Spacing.lg),
          // Tip
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
                  Icons.drag_indicator_rounded,
                  color: _nutritionGreen,
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'Maintiens et glisse pour réorganiser l\'ordre des repas',
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

class _MealNameCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final TextEditingController controller;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onIconTap;

  static const _nutritionGreen = Color(0xFF2ECC71);

  const _MealNameCard({
    super.key,
    required this.index,
    required this.icon,
    required this.controller,
    required this.onNameChanged,
    required this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: FGColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            // Number badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _nutritionGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(Spacing.xs),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: FGTypography.body.copyWith(
                    color: _nutritionGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            // Icon button
            GestureDetector(
              onTap: onIconTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  border: Border.all(color: FGColors.glassBorder),
                ),
                child: Icon(
                  icon,
                  color: FGColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            // Name input
            Expanded(
              child: TextField(
                controller: controller,
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Nom du repas',
                  hintStyle: FGTypography.body.copyWith(
                    color: FGColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: onNameChanged,
              ),
            ),
            const SizedBox(width: Spacing.md),
          ],
        ),
      ),
    );
  }
}
