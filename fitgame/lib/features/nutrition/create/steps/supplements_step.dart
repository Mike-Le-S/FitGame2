import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../models/diet_models.dart';

/// Step 8: Supplements configuration
class SupplementsStep extends StatelessWidget {
  final List<SupplementEntry> supplements;
  final ValueChanged<List<SupplementEntry>> onSupplementsChanged;

  const SupplementsStep({
    super.key,
    required this.supplements,
    required this.onSupplementsChanged,
  });

  Set<String> get _selectedIds => supplements.map((s) => s.id).toSet();

  void _toggleSupplement(String id) {
    if (_selectedIds.contains(id)) {
      onSupplementsChanged(
        supplements.where((s) => s.id != id).toList(),
      );
    } else {
      final newSupplement = SupplementCatalog.fromCatalogId(id);
      onSupplementsChanged([...supplements, newSupplement]);
    }
  }

  void _updateSupplement(SupplementEntry updated) {
    final index = supplements.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      final newList = List<SupplementEntry>.from(supplements);
      newList[index] = updated;
      onSupplementsChanged(newList);
    }
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
            'Compléments',
            style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Configure tes suppléments et rappels',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xl),
          // Catalog section
          Text(
            'CATALOGUE',
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
            children: SupplementCatalog.supplements.map((data) {
              final id = data['id'] as String;
              final isSelected = _selectedIds.contains(id);
              return _SupplementChip(
                name: data['name'] as String,
                icon: data['icon'] as IconData,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _toggleSupplement(id);
                },
              );
            }).toList(),
          ),
          if (supplements.isNotEmpty) ...[
            const SizedBox(height: Spacing.xl),
            Text(
              'MES COMPLÉMENTS',
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: Spacing.md),
            ...supplements.map((supplement) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: _SupplementCard(
                    supplement: supplement,
                    onUpdate: _updateSupplement,
                    onRemove: () => _toggleSupplement(supplement.id),
                  ),
                )),
          ],
          const SizedBox(height: Spacing.lg),
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

class _SupplementChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  static const _nutritionGreen = Color(0xFF2ECC71);

  const _SupplementChip({
    required this.name,
    required this.icon,
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
              ? _nutritionGreen.withValues(alpha: 0.15)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(
            color: isSelected ? _nutritionGreen : FGColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? _nutritionGreen : FGColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              name,
              style: FGTypography.body.copyWith(
                color: isSelected ? _nutritionGreen : FGColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplementCard extends StatelessWidget {
  final SupplementEntry supplement;
  final ValueChanged<SupplementEntry> onUpdate;
  final VoidCallback onRemove;

  static const _nutritionGreen = Color(0xFF2ECC71);

  const _SupplementCard({
    required this.supplement,
    required this.onUpdate,
    required this.onRemove,
  });

  void _showDosageEditor(BuildContext context) {
    final controller = TextEditingController(text: supplement.dosage);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
              Text('Modifier le dosage', style: FGTypography.h3),
              const SizedBox(height: Spacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                decoration: BoxDecoration(
                  color: FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(Spacing.md),
                  border: Border.all(color: FGColors.glassBorder),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: FGTypography.body,
                  decoration: InputDecoration(
                    hintText: 'Ex: 5g, 2 capsules...',
                    hintStyle: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      onUpdate(supplement.copyWith(dosage: controller.text));
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _nutritionGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                  ),
                  child: const Text('Confirmer'),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimingPicker(BuildContext context) {
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
            Text('Moment de prise', style: FGTypography.h3),
            const SizedBox(height: Spacing.lg),
            ...SupplementTiming.values.map((timing) {
              final isSelected = supplement.timing == timing;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onUpdate(supplement.copyWith(timing: timing));
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.md),
                  margin: const EdgeInsets.only(bottom: Spacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _nutritionGreen.withValues(alpha: 0.15)
                        : FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.md),
                    border: Border.all(
                      color: isSelected ? _nutritionGreen : FGColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getTimingIcon(timing),
                        color:
                            isSelected ? _nutritionGreen : FGColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.md),
                      Text(
                        timing.label,
                        style: FGTypography.body.copyWith(
                          color: isSelected
                              ? _nutritionGreen
                              : FGColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: _nutritionGreen,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  IconData _getTimingIcon(SupplementTiming timing) {
    switch (timing) {
      case SupplementTiming.morning:
        return Icons.wb_sunny_rounded;
      case SupplementTiming.preWorkout:
        return Icons.directions_run_rounded;
      case SupplementTiming.postWorkout:
        return Icons.fitness_center_rounded;
      case SupplementTiming.evening:
        return Icons.nights_stay_rounded;
      case SupplementTiming.withMeal:
        return Icons.restaurant_rounded;
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: supplement.reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _nutritionGreen,
              surface: FGColors.glassSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      onUpdate(supplement.copyWith(
        notificationsEnabled: true,
        reminderTime: time,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _nutritionGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(
                  supplement.icon,
                  color: _nutritionGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplement.name,
                      style: FGTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showTimingPicker(context),
                      child: Row(
                        children: [
                          Icon(
                            _getTimingIcon(supplement.timing),
                            color: FGColors.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            supplement.timing.label,
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: Spacing.xs),
                          Icon(
                            Icons.edit_rounded,
                            color: FGColors.textSecondary,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Dosage
              GestureDetector(
                onTap: () => _showDosageEditor(context),
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
                    supplement.dosage,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _nutritionGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // Remove button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onRemove();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: FGColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: FGColors.error,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // Notification toggle
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: FGColors.glassSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Spacing.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_rounded,
                  color: supplement.notificationsEnabled
                      ? _nutritionGreen
                      : FGColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Rappel: ',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
                if (supplement.notificationsEnabled &&
                    supplement.reminderTime != null)
                  GestureDetector(
                    onTap: () => _showTimePicker(context),
                    child: Text(
                      '${supplement.reminderTime!.hour.toString().padLeft(2, '0')}:${supplement.reminderTime!.minute.toString().padLeft(2, '0')}',
                      style: FGTypography.body.copyWith(
                        color: _nutritionGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Text(
                    'OFF',
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                Switch(
                  value: supplement.notificationsEnabled,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    if (value && supplement.reminderTime == null) {
                      _showTimePicker(context);
                    } else {
                      onUpdate(supplement.copyWith(
                        notificationsEnabled: value,
                      ));
                    }
                  },
                  activeThumbColor: _nutritionGreen,
                  activeTrackColor: _nutritionGreen.withValues(alpha: 0.3),
                  inactiveTrackColor: FGColors.glassBorder,
                  inactiveThumbColor: FGColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
