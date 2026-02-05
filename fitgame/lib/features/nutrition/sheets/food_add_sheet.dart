import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class FoodAddSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelectFood;
  final VoidCallback? onScanRequested;
  final VoidCallback? onFavoritesRequested;
  final VoidCallback? onTemplatesRequested;

  const FoodAddSheet({
    super.key,
    required this.onSelectFood,
    this.onScanRequested,
    this.onFavoritesRequested,
    this.onTemplatesRequested,
  });

  @override
  State<FoodAddSheet> createState() => _FoodAddSheetState();
}

class _FoodAddSheetState extends State<FoodAddSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _recentFoods = [];
  List<Map<String, dynamic>> _favoriteFoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final favorites = await SupabaseService.getFavoriteFoods();

      if (mounted) {
        setState(() {
          _favoriteFoods = favorites.take(5).toList();
          _recentFoods = favorites.take(10).toList(); // Use favorites as recents for now
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                Text('Ajouter un aliment', style: FGTypography.h3),
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

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: TextField(
              controller: _searchController,
              style: FGTypography.body,
              decoration: InputDecoration(
                hintText: 'Rechercher un aliment...',
                hintStyle: FGTypography.body.copyWith(
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search, color: FGColors.textSecondary),
                filled: true,
                fillColor: FGColors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacing.md),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                // TODO: Implement search
              },
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Quick action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                _buildQuickActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scanner',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onScanRequested?.call();
                  },
                ),
                const SizedBox(width: Spacing.md),
                _buildQuickActionButton(
                  icon: Icons.star_rounded,
                  label: 'Favoris',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onFavoritesRequested?.call();
                  },
                ),
                const SizedBox(width: Spacing.md),
                _buildQuickActionButton(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Templates',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onTemplatesRequested?.call();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Recent foods
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    children: [
                      Text(
                        'RÉCENTS',
                        style: FGTypography.caption.copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: FGColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      if (_recentFoods.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: Text(
                            'Aucun aliment récent',
                            style: FGTypography.body.copyWith(
                              color: FGColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ..._recentFoods.map((food) => _buildFoodItem(food)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.md),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: FGColors.accent, size: 28),
              const SizedBox(height: Spacing.xs),
              Text(
                label,
                style: FGTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    final foodData = food['food_data'] as Map<String, dynamic>? ?? food;
    final name = foodData['name'] as String? ?? 'Aliment';
    final cal = foodData['cal'] as int? ?? 0;
    final quantity = foodData['quantity'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onSelectFood(foodData);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: FGColors.textSecondary,
                size: 20,
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
                  if (quantity.isNotEmpty)
                    Text(
                      quantity,
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '$cal kcal',
              style: FGTypography.body.copyWith(
                color: FGColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            const Icon(
              Icons.add_circle_outline,
              color: FGColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
