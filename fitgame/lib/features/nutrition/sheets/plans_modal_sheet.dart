import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class PlansModalSheet extends StatefulWidget {
  final Map<String, dynamic>? activePlan;
  final List<Map<String, dynamic>> allPlans;
  final VoidCallback onPlanChanged;
  final Function(Map<String, dynamic>) onEditPlan;
  final VoidCallback onCreatePlan;

  const PlansModalSheet({
    super.key,
    this.activePlan,
    required this.allPlans,
    required this.onPlanChanged,
    required this.onEditPlan,
    required this.onCreatePlan,
  });

  @override
  State<PlansModalSheet> createState() => _PlansModalSheetState();
}

class _PlansModalSheetState extends State<PlansModalSheet> {
  bool _isLoading = false;

  String _getGoalLabel(String? goal) {
    switch (goal) {
      case 'bulk':
        return 'Prise de masse';
      case 'cut':
        return 'Sèche';
      case 'maintain':
        return 'Maintien';
      default:
        return '';
    }
  }

  Future<void> _showActivateDialog(Map<String, dynamic> plan) async {
    final result = await showModalBottomSheet<DateTime?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActivatePlanDialog(planName: plan['name'] as String? ?? 'Plan'),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService.activateDietPlan(plan['id'] as String, activeFrom: result);
        if (mounted) {
          Navigator.pop(context);
          widget.onPlanChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plan "${plan['name']}" activé'),
              backgroundColor: FGColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: FGColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deactivatePlan() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.deactivateAllDietPlans();
      if (mounted) {
        Navigator.pop(context);
        widget.onPlanChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan désactivé'),
            backgroundColor: FGColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherPlans = widget.allPlans
        .where((p) => p['id'] != widget.activePlan?['id'])
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                Text('Mes plans', style: FGTypography.h3),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: FGColors.glassBorder,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: FGColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          // Content
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    children: [
                      // Active plan section
                      if (widget.activePlan != null) ...[
                        Text(
                          'ACTIF',
                          style: FGTypography.caption.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: FGColors.success,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        _buildPlanCard(widget.activePlan!, isActive: true),
                        const SizedBox(height: Spacing.lg),
                      ],
                      // Other plans section
                      if (otherPlans.isNotEmpty) ...[
                        Text(
                          'AUTRES PLANS',
                          style: FGTypography.caption.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: FGColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        ...otherPlans.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: Spacing.md),
                              child: _buildPlanCard(p, isActive: false),
                            )),
                      ],
                      // Empty state
                      if (widget.allPlans.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(Spacing.xl),
                          child: Column(
                            children: [
                              Icon(
                                Icons.restaurant_menu_rounded,
                                size: 48,
                                color: FGColors.textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: Spacing.md),
                              Text(
                                'Aucun plan créé',
                                style: FGTypography.body.copyWith(
                                  color: FGColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: Spacing.lg),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onCreatePlan();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Spacing.lg,
                                    vertical: Spacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2ECC71),
                                    borderRadius: BorderRadius.circular(Spacing.md),
                                  ),
                                  child: Text(
                                    'Créer un plan',
                                    style: FGTypography.body.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: Spacing.lg),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, {required bool isActive}) {
    final name = plan['name'] as String? ?? 'Plan';
    final goal = plan['goal'] as String?;
    final trainingCal = plan['training_calories'] as int?;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isActive
            ? FGColors.success.withValues(alpha: 0.08)
            : FGColors.glassSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Spacing.lg),
        border: Border.all(
          color: isActive
              ? FGColors.success.withValues(alpha: 0.3)
              : FGColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: FGTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${_getGoalLabel(goal)}${trainingCal != null ? ' • $trainingCal kcal' : ''}',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: FGColors.success,
                    borderRadius: BorderRadius.circular(Spacing.xs),
                  ),
                  child: Text(
                    'ACTIF',
                    style: FGTypography.caption.copyWith(
                      fontSize: 9,
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    widget.onEditPlan(plan);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    decoration: BoxDecoration(
                      color: FGColors.glassBorder,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: Center(
                      child: Text(
                        'Modifier',
                        style: FGTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (isActive) {
                      _deactivatePlan();
                    } else {
                      _showActivateDialog(plan);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    decoration: BoxDecoration(
                      color: isActive
                          ? FGColors.warning.withValues(alpha: 0.2)
                          : const Color(0xFF2ECC71).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: Center(
                      child: Text(
                        isActive ? 'Désactiver' : 'Activer',
                        style: FGTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isActive ? FGColors.warning : const Color(0xFF2ECC71),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivatePlanDialog extends StatefulWidget {
  final String planName;

  const _ActivatePlanDialog({required this.planName});

  @override
  State<_ActivatePlanDialog> createState() => _ActivatePlanDialogState();
}

class _ActivatePlanDialogState extends State<_ActivatePlanDialog> {
  int _selectedOption = 0; // 0=now, 1=tomorrow, 2=custom
  DateTime _customDate = DateTime.now().add(const Duration(days: 2));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
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
          Text(
            'Activer "${widget.planName}"',
            style: FGTypography.h3,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'À partir de :',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.lg),
          _buildOption(0, 'Maintenant'),
          const SizedBox(height: Spacing.sm),
          _buildOption(1, 'Demain'),
          const SizedBox(height: Spacing.sm),
          _buildDateOption(),
          const SizedBox(height: Spacing.xl),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    decoration: BoxDecoration(
                      color: FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.md),
                    ),
                    child: Center(
                      child: Text(
                        'Annuler',
                        style: FGTypography.body.copyWith(
                          color: FGColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    DateTime date;
                    switch (_selectedOption) {
                      case 0:
                        date = DateTime.now();
                        break;
                      case 1:
                        date = DateTime.now().add(const Duration(days: 1));
                        break;
                      default:
                        date = _customDate;
                    }
                    Navigator.pop(context, date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      borderRadius: BorderRadius.circular(Spacing.md),
                    ),
                    child: Center(
                      child: Text(
                        'Confirmer',
                        style: FGTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String label) {
    final isSelected = _selectedOption == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = index),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2ECC71)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2ECC71) : FGColors.glassBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: Spacing.md),
            Text(
              label,
              style: FGTypography.body.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOption() {
    final isSelected = _selectedOption == 2;
    return GestureDetector(
      onTap: () async {
        setState(() => _selectedOption = 2);
        final picked = await showDatePicker(
          context: context,
          initialDate: _customDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _customDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2ECC71)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2ECC71) : FGColors.glassBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: Spacing.md),
            Text(
              'Le ${_customDate.day}/${_customDate.month}/${_customDate.year}',
              style: FGTypography.body.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: FGColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
