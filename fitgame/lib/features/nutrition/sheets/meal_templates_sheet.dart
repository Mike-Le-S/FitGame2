import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class MealTemplatesSheet extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSelectTemplate;

  const MealTemplatesSheet({
    super.key,
    required this.onSelectTemplate,
  });

  @override
  State<MealTemplatesSheet> createState() => _MealTemplatesSheetState();
}

class _MealTemplatesSheetState extends State<MealTemplatesSheet> {
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await SupabaseService.getMealTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTemplate(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FGColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.md),
          side: const BorderSide(color: FGColors.glassBorder),
        ),
        title: Text(
          'Supprimer ce template ?',
          style: FGTypography.h3,
        ),
        content: Text(
          'Voulez-vous supprimer le template "$name" ?',
          style: FGTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: FGTypography.body.copyWith(
                color: FGColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      try {
        await SupabaseService.deleteMealTemplate(id);
        if (mounted) {
          setState(() {
            _templates.removeWhere((t) => t['id'] == id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Template supprime'),
              backgroundColor: FGColors.glassSurface,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Erreur lors de la suppression'),
              backgroundColor: FGColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  color: FGColors.accent,
                  size: 28,
                ),
                const SizedBox(width: Spacing.sm),
                Text('Mes templates', style: FGTypography.h3),
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
          const SizedBox(height: Spacing.md),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Text(
              'Tap pour ajouter tous les aliments du template',
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: FGColors.accent,
                    ),
                  )
                : _templates.isEmpty
                    ? _buildEmptyState()
                    : _buildTemplatesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(Spacing.lg),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: FGColors.textSecondary.withValues(alpha: 0.5),
              size: 40,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Aucun template',
            style: FGTypography.h3.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
            child: Text(
              'Creez des templates de repas pour ajouter rapidement plusieurs aliments en une fois',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return _buildTemplateItem(template);
      },
    );
  }

  Widget _buildTemplateItem(Map<String, dynamic> template) {
    final id = template['id'] as String? ?? '';
    final name = template['name'] as String? ?? 'Template';
    final foods = List<Map<String, dynamic>>.from(template['foods'] ?? []);
    final foodCount = foods.length;

    // Calculate total calories
    int totalCalories = 0;
    for (final food in foods) {
      totalCalories += (food['cal'] as int?) ?? 0;
    }

    // Get first 3 food names for preview
    final foodPreviews = foods
        .take(3)
        .map((f) => f['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final previewText = foodPreviews.join(', ');
    final hasMore = foods.length > 3;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onSelectTemplate(foods);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.md),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: FGColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(
                      color: FGColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$foodCount',
                        style: FGTypography.body.copyWith(
                          color: FGColors.accent,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      Text(
                        'items',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.accent,
                          fontSize: 10,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: FGTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$totalCalories kcal au total',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button
                GestureDetector(
                  onTap: () => _deleteTemplate(id, name),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: FGColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: FGColors.error,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const Icon(
                  Icons.add_circle_outline,
                  color: FGColors.textSecondary,
                ),
              ],
            ),
            if (previewText.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: FGColors.glassSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant_rounded,
                      color: FGColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        hasMore ? '$previewText...' : previewText,
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
