import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class FavoriteFoodsSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelectFood;

  const FavoriteFoodsSheet({
    super.key,
    required this.onSelectFood,
  });

  @override
  State<FavoriteFoodsSheet> createState() => _FavoriteFoodsSheetState();
}

class _FavoriteFoodsSheetState extends State<FavoriteFoodsSheet> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await SupabaseService.getFavoriteFoods();
      if (mounted) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeFavorite(String id) async {
    HapticFeedback.mediumImpact();
    try {
      await SupabaseService.removeFavoriteFood(id);
      if (mounted) {
        setState(() {
          _favorites.removeWhere((f) => f['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Favori supprime'),
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
                  Icons.star_rounded,
                  color: FGColors.accent,
                  size: 28,
                ),
                const SizedBox(width: Spacing.sm),
                Text('Mes favoris', style: FGTypography.h3),
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
              'Tap pour ajouter, swipe pour supprimer',
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
                : _favorites.isEmpty
                    ? _buildEmptyState()
                    : _buildFavoritesList(),
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
              Icons.star_border_rounded,
              color: FGColors.textSecondary.withValues(alpha: 0.5),
              size: 40,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Aucun favori',
            style: FGTypography.h3.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
            child: Text(
              'Ajoutez des aliments en favoris depuis la bibliotheque pour les retrouver rapidement',
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

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final favorite = _favorites[index];
        return _buildFavoriteItem(favorite);
      },
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> favorite) {
    final id = favorite['id'] as String? ?? '';
    final foodData = favorite['food_data'] as Map<String, dynamic>? ?? {};
    final name = foodData['name'] as String? ?? 'Aliment';
    final cal = foodData['cal'] as int? ?? 0;
    final quantity = foodData['quantity'] as String? ?? '';
    final useCount = favorite['use_count'] as int? ?? 0;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        decoration: BoxDecoration(
          color: FGColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(Spacing.md),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_rounded,
          color: FGColors.error,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: FGColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacing.md),
              side: const BorderSide(color: FGColors.glassBorder),
            ),
            title: Text(
              'Supprimer ce favori ?',
              style: FGTypography.h3,
            ),
            content: Text(
              'Voulez-vous retirer "$name" de vos favoris ?',
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
      },
      onDismissed: (direction) => _removeFavorite(id),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          // Update usage count
          SupabaseService.updateFavoriteFoodUsage(id);
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: FGColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  border: Border.all(
                    color: FGColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: FGColors.accent,
                  size: 24,
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
                    Row(
                      children: [
                        if (quantity.isNotEmpty)
                          Text(
                            quantity,
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                        if (quantity.isNotEmpty && useCount > 0)
                          Text(
                            ' - ',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                        if (useCount > 0)
                          Text(
                            'Utilise $useCount fois',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$cal',
                    style: FGTypography.body.copyWith(
                      color: FGColors.accent,
                      fontWeight: FontWeight.w700,
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
              const SizedBox(width: Spacing.sm),
              const Icon(
                Icons.add_circle_outline,
                color: FGColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
