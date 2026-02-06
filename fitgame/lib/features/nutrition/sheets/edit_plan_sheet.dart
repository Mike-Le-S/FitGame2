import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class EditPlanSheet extends StatefulWidget {
  final Map<String, dynamic> plan;
  final bool isFromCoach;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const EditPlanSheet({
    super.key,
    required this.plan,
    required this.isFromCoach,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditPlanSheet> createState() => _EditPlanSheetState();
}

class _EditPlanSheetState extends State<EditPlanSheet> {
  late TextEditingController _nameController;
  late TextEditingController _trainingCalController;
  late TextEditingController _restCalController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    final trainingMacros = plan['training_macros'] as Map<String, dynamic>?;

    _nameController = TextEditingController(text: plan['name'] as String? ?? '');
    _trainingCalController = TextEditingController(
      text: (plan['training_calories'] as int?)?.toString() ?? '2800',
    );
    _restCalController = TextEditingController(
      text: (plan['rest_calories'] as int?)?.toString() ?? '2400',
    );
    _proteinController = TextEditingController(
      text: (trainingMacros?['protein'] as int?)?.toString() ?? '180',
    );
    _carbsController = TextEditingController(
      text: (trainingMacros?['carbs'] as int?)?.toString() ?? '300',
    );
    _fatController = TextEditingController(
      text: (trainingMacros?['fat'] as int?)?.toString() ?? '80',
    );

    // Track changes
    _nameController.addListener(_onChanged);
    _trainingCalController.addListener(_onChanged);
    _restCalController.addListener(_onChanged);
    _proteinController.addListener(_onChanged);
    _carbsController.addListener(_onChanged);
    _fatController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _trainingCalController.dispose();
    _restCalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Le nom du plan est requis'),
          backgroundColor: FGColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService.updateDietPlan(
        widget.plan['id'] as String,
        {
          'name': _nameController.text.trim(),
          'training_calories': int.tryParse(_trainingCalController.text) ?? 2800,
          'rest_calories': int.tryParse(_restCalController.text) ?? 2400,
          'training_macros': {
            'protein': int.tryParse(_proteinController.text) ?? 180,
            'carbs': int.tryParse(_carbsController.text) ?? 300,
            'fat': int.tryParse(_fatController.text) ?? 80,
          },
        },
      );

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Plan mis à jour'),
            backgroundColor: FGColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FGColors.glassSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: FGColors.glassBorder),
        ),
        title: Text(
          'Supprimer ce plan ?',
          style: FGTypography.h3,
        ),
        content: Text(
          'Cette action est irréversible. Toutes les données du plan "${_nameController.text}" seront perdues.',
          style: FGTypography.body.copyWith(color: FGColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: FGTypography.body.copyWith(color: FGColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePlan();
            },
            child: Text(
              'Supprimer',
              style: FGTypography.body.copyWith(
                color: FGColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlan() async {
    setState(() => _isLoading = true);

    try {
      await SupabaseService.deleteDietPlan(widget.plan['id'] as String);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Plan supprimé'),
            backgroundColor: FGColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        widget.onDelete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: FGColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: Column(
            children: [
              // Handle bar
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.isFromCoach
                            ? FGColors.accent.withValues(alpha: 0.15)
                            : const Color(0xFF2ECC71).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(Spacing.sm),
                      ),
                      child: Icon(
                        widget.isFromCoach
                            ? Icons.person_outline
                            : Icons.edit_rounded,
                        color: widget.isFromCoach
                            ? FGColors.accent
                            : const Color(0xFF2ECC71),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Modifier le plan', style: FGTypography.h3),
                          if (widget.isFromCoach)
                            Text(
                              'Plan du coach (lecture seule pour certains champs)',
                              style: FGTypography.caption.copyWith(
                                color: FGColors.accent,
                              ),
                            ),
                        ],
                      ),
                    ),
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  children: [
                    // Plan name
                    _buildSectionTitle('Nom du plan'),
                    const SizedBox(height: Spacing.sm),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Ex: Plan prise de masse',
                      icon: Icons.label_outline,
                      enabled: !widget.isFromCoach,
                    ),
                    const SizedBox(height: Spacing.xl),

                    // Calories section
                    _buildSectionTitle('Objectifs caloriques'),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCalorieInput(
                            controller: _trainingCalController,
                            label: 'Training',
                            icon: Icons.fitness_center_rounded,
                            color: FGColors.accent,
                            enabled: !widget.isFromCoach,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: _buildCalorieInput(
                            controller: _restCalController,
                            label: 'Repos',
                            icon: Icons.bedtime_rounded,
                            color: const Color(0xFF9B59B6),
                            enabled: !widget.isFromCoach,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),

                    // Macros section
                    _buildSectionTitle('Macronutriments (jour training)'),
                    const SizedBox(height: Spacing.sm),
                    _buildMacroInput(
                      controller: _proteinController,
                      label: 'Protéines',
                      unit: 'g',
                      color: const Color(0xFFE74C3C),
                      icon: Icons.egg_outlined,
                      enabled: !widget.isFromCoach,
                    ),
                    const SizedBox(height: Spacing.md),
                    _buildMacroInput(
                      controller: _carbsController,
                      label: 'Glucides',
                      unit: 'g',
                      color: const Color(0xFF3498DB),
                      icon: Icons.grain,
                      enabled: !widget.isFromCoach,
                    ),
                    const SizedBox(height: Spacing.md),
                    _buildMacroInput(
                      controller: _fatController,
                      label: 'Lipides',
                      unit: 'g',
                      color: const Color(0xFFF39C12),
                      icon: Icons.water_drop_outlined,
                      enabled: !widget.isFromCoach,
                    ),
                    const SizedBox(height: Spacing.xxl),

                    // Delete button (only for own plans)
                    if (!widget.isFromCoach) ...[
                      GestureDetector(
                        onTap: _isLoading ? null : _confirmDelete,
                        child: Container(
                          padding: const EdgeInsets.all(Spacing.md),
                          decoration: BoxDecoration(
                            color: FGColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(Spacing.md),
                            border: Border.all(
                              color: FGColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: FGColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: Spacing.sm),
                              Text(
                                'Supprimer ce plan',
                                style: FGTypography.body.copyWith(
                                  color: FGColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.xl),
                  ],
                ),
              ),
              // Save button
              if (!widget.isFromCoach)
                Container(
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    color: FGColors.background,
                    border: Border(
                      top: BorderSide(color: FGColors.glassBorder),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: GestureDetector(
                      onTap: (_isLoading || !_hasChanges) ? null : _savePlan,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                        decoration: BoxDecoration(
                          gradient: (_hasChanges && !_isLoading)
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2ECC71),
                                    Color(0xFF27AE60),
                                  ],
                                )
                              : null,
                          color: (_hasChanges && !_isLoading)
                              ? null
                              : FGColors.glassSurface,
                          borderRadius: BorderRadius.circular(Spacing.md),
                          boxShadow: (_hasChanges && !_isLoading)
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2ECC71)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      FGColors.textOnAccent,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Enregistrer',
                                  style: FGTypography.body.copyWith(
                                    color: (_hasChanges && !_isLoading)
                                        ? FGColors.textOnAccent
                                        : FGColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: FGTypography.caption.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: enabled ? FGColors.glassSurface : FGColors.glassSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: FGColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: FGTypography.body.copyWith(
                color: enabled ? FGColors.textPrimary : FGColors.textSecondary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: FGTypography.body.copyWith(
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: Spacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: Spacing.xs),
              Text(
                label,
                style: FGTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: FGTypography.h2.copyWith(
                    fontSize: 28,
                    color: enabled ? FGColors.textPrimary : FGColors.textSecondary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                'kcal',
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInput({
    required TextEditingController controller,
    required String label,
    required String unit,
    required Color color,
    required IconData icon,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Spacing.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              label,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.right,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w700,
                color: enabled ? color : FGColors.textSecondary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            unit,
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
