import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/sheets/placeholder_sheet.dart';

class FoodLibrarySheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelectFood;

  const FoodLibrarySheet({required this.onSelectFood});

  @override
  State<FoodLibrarySheet> createState() => FoodLibrarySheetState();
}

class FoodLibrarySheetState extends State<FoodLibrarySheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tous';

  void _showCreateFoodDialog(BuildContext context) {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FGColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: FGColors.glassBorder),
        ),
        title: Text(
          'Créer un aliment',
          style: FGTypography.h3,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(nameController, 'Nom de l\'aliment'),
              const SizedBox(height: Spacing.sm),
              _buildDialogTextField(calController, 'Calories (kcal)', isNumber: true),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Expanded(child: _buildDialogTextField(proteinController, 'Protéines (g)', isNumber: true)),
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: _buildDialogTextField(carbsController, 'Glucides (g)', isNumber: true)),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              _buildDialogTextField(fatController, 'Lipides (g)', isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: FGTypography.body.copyWith(color: FGColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newFood = {
                  'name': nameController.text,
                  'category': 'Récents',
                  'cal': int.tryParse(calController.text) ?? 0,
                  'p': int.tryParse(proteinController.text) ?? 0,
                  'c': int.tryParse(carbsController.text) ?? 0,
                  'f': int.tryParse(fatController.text) ?? 0,
                  'unit': '100g',
                };
                setState(() {
                  _foods.insert(0, newFood);
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${nameController.text} ajouté à ta bibliothèque'),
                    backgroundColor: FGColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Créer',
              style: FGTypography.body.copyWith(
                color: FGColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.sm),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: FGTypography.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: FGTypography.body.copyWith(color: FGColors.textSecondary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  final List<String> _categories = [
    'Tous',
    'Récents',
    'Favoris',
    'Protéines',
    'Glucides',
    'Légumes',
    'Fruits',
    'Laitiers',
  ];

  final List<Map<String, dynamic>> _foods = <Map<String, dynamic>>[
    {'name': 'Poulet grillé', 'category': 'Protéines', 'cal': 165, 'p': 31, 'c': 0, 'f': 4, 'unit': '100g'},
    {'name': 'Riz basmati', 'category': 'Glucides', 'cal': 130, 'p': 3, 'c': 28, 'f': 0, 'unit': '100g cuit'},
    {'name': 'Brocolis', 'category': 'Légumes', 'cal': 34, 'p': 3, 'c': 7, 'f': 0, 'unit': '100g'},
    {'name': 'Oeuf entier', 'category': 'Protéines', 'cal': 155, 'p': 13, 'c': 1, 'f': 11, 'unit': '100g'},
    {'name': 'Saumon', 'category': 'Protéines', 'cal': 208, 'p': 20, 'c': 0, 'f': 13, 'unit': '100g'},
    {'name': 'Patate douce', 'category': 'Glucides', 'cal': 86, 'p': 2, 'c': 20, 'f': 0, 'unit': '100g'},
    {'name': 'Yaourt grec', 'category': 'Laitiers', 'cal': 59, 'p': 10, 'c': 4, 'f': 1, 'unit': '100g'},
    {'name': 'Banane', 'category': 'Fruits', 'cal': 89, 'p': 1, 'c': 23, 'f': 0, 'unit': '1 moyenne'},
    {'name': 'Amandes', 'category': 'Lipides', 'cal': 579, 'p': 21, 'c': 22, 'f': 50, 'unit': '100g'},
    {'name': 'Flocons d\'avoine', 'category': 'Glucides', 'cal': 389, 'p': 17, 'c': 66, 'f': 7, 'unit': '100g'},
  ];

  List<Map<String, dynamic>> get _filteredFoods {
    var foods = _foods;
    if (_selectedCategory != 'Tous') {
      foods = foods.where((f) => f['category'] == _selectedCategory).toList();
    }
    if (_searchController.text.isNotEmpty) {
      foods = foods
          .where((f) => (f['name'] as String)
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    }
    return foods;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: FGColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
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
                    Row(
                      children: [
                        Text('Ajouter un aliment', style: FGTypography.h3),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            PlaceholderSheet.show(
                              context,
                              title: 'Scanner de codes-barres',
                              message: 'Le scanner de codes-barres nécessite la caméra et sera disponible dans une prochaine version.',
                              icon: Icons.qr_code_scanner_rounded,
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: FGColors.glassSurface,
                              borderRadius: BorderRadius.circular(Spacing.sm),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: FGColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showCreateFoodDialog(context);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: FGColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(Spacing.sm),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: FGColors.accent,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    // Search bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                      decoration: BoxDecoration(
                        color: FGColors.glassSurface,
                        borderRadius: BorderRadius.circular(Spacing.md),
                        border: Border.all(color: FGColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: FGColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: FGTypography.body,
                              decoration: InputDecoration(
                                hintText: 'Rechercher un aliment...',
                                hintStyle: FGTypography.body.copyWith(
                                  color: FGColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: Spacing.md,
                                ),
                              ),
                              onChanged: (v) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    // Category chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: Spacing.sm),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? FGColors.accent.withValues(alpha: 0.2)
                                    : FGColors.glassSurface,
                                borderRadius: BorderRadius.circular(Spacing.sm),
                                border: Border.all(
                                  color: isSelected
                                      ? FGColors.accent
                                      : FGColors.glassBorder,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  cat,
                                  style: FGTypography.caption.copyWith(
                                    color: isSelected
                                        ? FGColors.accent
                                        : FGColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  itemCount: _filteredFoods.length,
                  itemBuilder: (context, index) {
                    final food = _filteredFoods[index];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSelectFood(food);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: Spacing.sm),
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: FGColors.glassSurface,
                          borderRadius: BorderRadius.circular(Spacing.md),
                          border: Border.all(color: FGColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food['name'] as String,
                                    style: FGTypography.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    food['unit'] as String,
                                    style: FGTypography.caption.copyWith(
                                      color: FGColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${food['cal']} kcal',
                                  style: FGTypography.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: FGColors.accent,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'P${food['p']}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: const Color(0xFFE74C3C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'C${food['c']}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: const Color(0xFF3498DB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'F${food['f']}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: const Color(0xFFF39C12),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: Spacing.sm),
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              color: FGColors.accent,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
