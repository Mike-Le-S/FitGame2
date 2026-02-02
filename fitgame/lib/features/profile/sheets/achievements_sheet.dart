import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';

/// Modèle pour un accomplissement
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool unlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0
  final String? progressLabel;
  final AchievementRarity rarity;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.unlockedAt,
    this.progress = 0.0,
    this.progressLabel,
    this.rarity = AchievementRarity.common,
  });
}

enum AchievementRarity { common, rare, epic, legendary }

/// Sheet affichant la liste complète des accomplissements
class AchievementsSheet extends StatelessWidget {
  const AchievementsSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AchievementsSheet(),
    );
  }

  // Empty list - achievements will be loaded from backend when implemented
  static const List<Achievement> _achievements = [];

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return FGColors.textSecondary;
      case AchievementRarity.rare:
        return const Color(0xFF3498DB);
      case AchievementRarity.epic:
        return const Color(0xFF9B59B6);
      case AchievementRarity.legendary:
        return FGColors.warning;
    }
  }

  String _getRarityLabel(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Commun';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Épique';
      case AchievementRarity.legendary:
        return 'Légendaire';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _achievements.where((a) => a.unlocked).length;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: FGColors.glassBorder,
              width: 1,
            ),
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
                    color: FGColors.textSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accomplissements',
                          style: FGTypography.h3,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _achievements.isEmpty
                              ? 'Bientôt disponible'
                              : '$unlockedCount/${_achievements.length} débloqués',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (_achievements.isNotEmpty)
                      // Progress ring
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: unlockedCount / _achievements.length,
                              backgroundColor: FGColors.glassBorder,
                              valueColor: const AlwaysStoppedAnimation(FGColors.accent),
                              strokeWidth: 4,
                            ),
                            Center(
                              child: Text(
                                '${((unlockedCount / _achievements.length) * 100).round()}%',
                                style: FGTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
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

              // List or empty state
              Expanded(
                child: _achievements.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                        itemCount: _achievements.length,
                        itemBuilder: (context, index) {
                          final achievement = _achievements[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.sm),
                            child: _buildAchievementCard(achievement),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: FGColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: FGColors.accent,
                size: 40,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Accomplissements',
              style: FGTypography.h3,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Les accomplissements seront bientôt disponibles.\nContinue à t\'entraîner pour débloquer des récompenses !',
              textAlign: TextAlign.center,
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final rarityColor = _getRarityColor(achievement.rarity);

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? FGColors.accent.withValues(alpha: 0.08)
            : FGColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(
          color: achievement.unlocked
              ? FGColors.accent.withValues(alpha: 0.3)
              : FGColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: achievement.unlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        rarityColor.withValues(alpha: 0.3),
                        rarityColor.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: achievement.unlocked ? null : FGColors.glassBorder.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: achievement.unlocked
                  ? Border.all(color: rarityColor.withValues(alpha: 0.5))
                  : null,
              boxShadow: achievement.unlocked
                  ? [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              achievement.icon,
              size: 24,
              color: achievement.unlocked
                  ? rarityColor
                  : FGColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: Spacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.name,
                        style: FGTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: achievement.unlocked
                              ? FGColors.textPrimary
                              : FGColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getRarityLabel(achievement.rarity),
                        style: FGTypography.caption.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: rarityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                    fontSize: 11,
                  ),
                ),

                // Progress bar (if not unlocked)
                if (!achievement.unlocked && achievement.progress > 0) ...[
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: achievement.progress,
                              backgroundColor: FGColors.glassBorder,
                              valueColor: AlwaysStoppedAnimation(
                                rarityColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (achievement.progressLabel != null) ...[
                        const SizedBox(width: Spacing.sm),
                        Text(
                          achievement.progressLabel!,
                          style: FGTypography.caption.copyWith(
                            fontSize: 10,
                            color: FGColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // Unlocked indicator
                if (achievement.unlocked) ...[
                  const SizedBox(height: Spacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: FGColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Débloqué',
                        style: FGTypography.caption.copyWith(
                          fontSize: 10,
                          color: FGColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
