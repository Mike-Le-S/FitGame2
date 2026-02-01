import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../models/friend.dart';

/// Bottom sheet for selecting friends (multi-select)
class FriendsListSheet extends StatefulWidget {
  const FriendsListSheet({
    super.key,
    required this.friends,
    required this.selectedIds,
    required this.onConfirm,
  });

  final List<Friend> friends;
  final Set<String> selectedIds;
  final Function(Set<String>) onConfirm;

  @override
  State<FriendsListSheet> createState() => _FriendsListSheetState();
}

class _FriendsListSheetState extends State<FriendsListSheet> {
  late Set<String> _selectedIds;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Friend> get _filteredFriends {
    if (_searchQuery.isEmpty) return widget.friends;
    return widget.friends
        .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleSelection(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: FGColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inviter des amis',
                  style: FGTypography.h3,
                ),
                Text(
                  '${_selectedIds.length} sélectionné${_selectedIds.length > 1 ? 's' : ''}',
                  style: FGTypography.bodySmall.copyWith(
                    color: FGColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Container(
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: FGColors.glassBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: FGTypography.body,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: FGTypography.body.copyWith(
                    color: FGColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: FGColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.md,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Friends List
          Flexible(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              itemCount: _filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = _filteredFriends[index];
                final isSelected = _selectedIds.contains(friend.id);
                return _buildFriendRow(friend, isSelected);
              },
            ),
          ),

          // Confirm Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: GestureDetector(
                onTap: _selectedIds.isNotEmpty
                    ? () {
                        HapticFeedback.mediumImpact();
                        widget.onConfirm(_selectedIds);
                        Navigator.pop(context);
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  decoration: BoxDecoration(
                    gradient: _selectedIds.isNotEmpty
                        ? LinearGradient(
                            colors: [
                              FGColors.accent,
                              FGColors.accent.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: _selectedIds.isEmpty ? FGColors.glassSurface : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'CONFIRMER (${_selectedIds.length})',
                      style: FGTypography.button.copyWith(
                        color: _selectedIds.isNotEmpty
                            ? FGColors.textOnAccent
                            : FGColors.textSecondary,
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
  }

  Widget _buildFriendRow(Friend friend, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSelection(friend.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? FGColors.accent.withValues(alpha: 0.1)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? FGColors.accent : FGColors.glassBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        FGColors.accent,
                        FGColors.accent.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                      style: FGTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: FGColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (friend.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: FGColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FGColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: Spacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        friend.lastActiveText,
                        style: FGTypography.caption.copyWith(
                          color: friend.isOnline
                              ? FGColors.success
                              : FGColors.textSecondary,
                        ),
                      ),
                      if (friend.streak > 0) ...[
                        const SizedBox(width: Spacing.sm),
                        Text(
                          '🔥 ${friend.streak}',
                          style: FGTypography.caption,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? FGColors.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? FGColors.accent : FGColors.glassBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: FGColors.textOnAccent,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
