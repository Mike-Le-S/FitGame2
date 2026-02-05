import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/food_database_service.dart';
import 'food_quantity_sheet.dart';

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
  final _foodDb = FoodDatabaseService.instance;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentFoods = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadData() async {
    try {
      // Load favorites as recents
      final favorites = await SupabaseService.getFavoriteFoods();

      // Pre-load food database
      await _foodDb.load();

      if (mounted) {
        setState(() {
          _recentFoods = favorites.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _currentQuery) return;

    _currentQuery = query;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);

    try {
      final results = await _foodDb.search(query, limit: 30);

      if (mounted && query == _currentQuery) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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

          // Title + database info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ajouter un aliment', style: FGTypography.h3),
                    Text(
                      '${_foodDb.foodCount} aliments (FR + EN)',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
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
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher un aliment...',
                hintStyle: FGTypography.body.copyWith(
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search, color: FGColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                        },
                        child: const Icon(Icons.clear, color: FGColors.textSecondary),
                      )
                    : null,
                filled: true,
                fillColor: FGColors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacing.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Quick action buttons (only show when not searching)
          if (_searchResults.isEmpty && _currentQuery.isEmpty)
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
          if (_searchResults.isEmpty && _currentQuery.isEmpty)
            const SizedBox(height: Spacing.lg),

          // Content area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show search results
    if (_currentQuery.isNotEmpty) {
      if (_isSearching) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (_searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: FGColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Aucun résultat pour "$_currentQuery"',
                style: FGTypography.body.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Essayez en français ou anglais',
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              Text(
                'ex: "poulet", "riz", "chicken", "rice"',
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return _buildUsdaFoodItem(_searchResults[index]);
        },
      );
    }

    // Show recents when not searching
    return ListView(
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
            child: Column(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 48,
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'Recherchez un aliment',
                  style: FGTypography.body.copyWith(
                    color: FGColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Ex: poulet, banane, riz, chicken...',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._recentFoods.map((food) => _buildFavoriteItem(food)),
      ],
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

  Widget _buildUsdaFoodItem(Map<String, dynamic> usdaFood) {
    final name = usdaFood['name'] as String? ?? 'Aliment';
    final nutrients = usdaFood['nutrients'] as Map<String, dynamic>? ?? {};
    final cal = (nutrients['energy_kcal'] as num?)?.round() ?? 0;
    final protein = (nutrients['protein_g'] as num?)?.round() ?? 0;
    final category = usdaFood['category'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        final appFood = FoodDatabaseService.toAppFormat(usdaFood);
        _showQuantitySheet(appFood);
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF2ECC71),
                size: 22,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        '100g',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textSecondary,
                        ),
                      ),
                      if (category.isNotEmpty) ...[
                        Text(
                          ' · ',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            category,
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$cal',
                  style: FGTypography.body.copyWith(
                    color: FGColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'kcal',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: Spacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.xs),
              ),
              child: Text(
                '${protein}g P',
                style: FGTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuantitySheet(Map<String, dynamic> food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodQuantitySheet(
        food: food,
        onConfirm: (adjustedFood) {
          Navigator.pop(context); // Close FoodAddSheet
          widget.onSelectFood(adjustedFood);
        },
      ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> food) {
    final foodData = food['food_data'] as Map<String, dynamic>? ?? food;
    final name = foodData['name'] as String? ?? 'Aliment';
    final cal = foodData['cal'] as int? ?? 0;
    final quantity = foodData['quantity'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showQuantitySheet(foodData);
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
                Icons.star_rounded,
                color: FGColors.warning,
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
