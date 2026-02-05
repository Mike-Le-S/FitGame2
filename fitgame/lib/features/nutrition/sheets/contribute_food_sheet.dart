import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class ContributeFoodSheet extends StatefulWidget {
  final String barcode;
  final Function(Map<String, dynamic>) onContributed;

  const ContributeFoodSheet({
    super.key,
    required this.barcode,
    required this.onContributed,
  });

  @override
  State<ContributeFoodSheet> createState() => _ContributeFoodSheetState();
}

class _ContributeFoodSheetState extends State<ContributeFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final nutritionPer100g = {
        'cal': int.parse(_caloriesController.text),
        'p': int.parse(_proteinController.text),
        'c': int.parse(_carbsController.text),
        'f': int.parse(_fatController.text),
      };

      await SupabaseService.contributeCommunityFood(
        barcode: widget.barcode,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        nutritionPer100g: nutritionPer100g,
      );

      final food = {
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'barcode': widget.barcode,
        'quantity': '100g',
        ...nutritionPer100g,
      };

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context);
        widget.onContributed(food);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: FGColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(Spacing.sm),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: FGColors.accent,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ajouter pour la communaute',
                               style: FGTypography.h3),
                          Text(
                            'Code: ${widget.barcode}',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                                        color: FGColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: FGColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Spacing.md),
                    border: Border.all(
                      color: FGColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: FGColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          'Cet aliment sera partage avec tous les utilisateurs FitGame',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom du produit *',
                      hint: 'Ex: Yaourt nature 0%',
                      validator: (v) => v?.isEmpty == true
                          ? 'Requis'
                          : null,
                    ),
                    const SizedBox(height: Spacing.md),
                    _buildTextField(
                      controller: _brandController,
                      label: 'Marque (optionnel)',
                      hint: 'Ex: Danone',
                    ),
                    const SizedBox(height: Spacing.lg),

                    Text(
                      'VALEURS NUTRITIONNELLES POUR 100G',
                      style: FGTypography.caption.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: FGColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _caloriesController,
                            label: 'Calories *',
                            suffix: 'kcal',
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: _buildNumberField(
                            controller: _proteinController,
                            label: 'Proteines *',
                            suffix: 'g',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _carbsController,
                            label: 'Glucides *',
                            suffix: 'g',
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: _buildNumberField(
                            controller: _fatController,
                            label: 'Lipides *',
                            suffix: 'g',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xxl),
                  ],
                ),
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FGColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Spacing.md),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Contribuer',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FGTypography.caption.copyWith(
          color: FGColors.textSecondary,
        )),
        const SizedBox(height: Spacing.xs),
        TextFormField(
          controller: controller,
          style: FGTypography.body,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: FGTypography.body.copyWith(
              color: FGColors.textSecondary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: FGColors.glassSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.sm),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.sm),
              borderSide: const BorderSide(color: FGColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FGTypography.caption.copyWith(
          color: FGColors.textSecondary,
        )),
        const SizedBox(height: Spacing.xs),
        TextFormField(
          controller: controller,
          style: FGTypography.body,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v?.isEmpty == true ? 'Requis' : null,
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
            ),
            filled: true,
            fillColor: FGColors.glassSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.sm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
