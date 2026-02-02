import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';

class HomeHeader extends StatelessWidget {
  final int currentStreak;
  final String userName;

  const HomeHeader({
    super.key,
    required this.currentStreak,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = userName.isNotEmpty ? userName : 'Utilisateur';
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                'Salut $displayName',
                style: FGTypography.h2.copyWith(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              _buildStreakBadge(),
            ],
          ),
        ),
        // Profile avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: FGColors.glassBorder,
              width: 2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FGColors.accent.withValues(alpha: 0.3),
                FGColors.accent.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Center(
            child: Text(
              avatarLetter,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: FGColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FGColors.accent.withValues(alpha: 0.2),
            FGColors.accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(
          color: FGColors.accent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            '$currentStreak j',
            style: FGTypography.caption.copyWith(
              color: FGColors.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
