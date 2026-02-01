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

  // Mock achievements data
  static const List<Achievement> _achievements = [
    // Débloqués
    Achievement(
      id: 'first_pr',
      name: 'Premier PR',
      description: 'Établir ton premier record personnel',
      icon: Icons.emoji_events_rounded,
      unlocked: true,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'streak_7',
      name: '7 Jours de Feu',
      description: 'Maintenir une série de 7 jours consécutifs',
      icon: Icons.local_fire_department_rounded,
      unlocked: true,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: '100_workouts',
      name: 'Centurion',
      description: 'Compléter 100 séances d\'entraînement',
      icon: Icons.fitness_center_rounded,
      unlocked: true,
      rarity: AchievementRarity.rare,
    ),
    // En progression
    Achievement(
      id: 'streak_30',
      name: 'Marathon',
      description: 'Maintenir une série de 30 jours',
      icon: Icons.directions_run_rounded,
      unlocked: false,
      progress: 0.4,
      progressLabel: '12/30 jours',
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'volume_50t',
      name: 'Volume Master',
      description: 'Soulever 50 tonnes en une semaine',
      icon: Icons.trending_up_rounded,
      unlocked: false,
      progress: 0.65,
      progressLabel: '32.5/50 tonnes',
      rarity: AchievementRarity.epic,
    ),
    Achievement(
      id: 'iron_will',
      name: 'Volonté de Fer',
      description: 'Ne jamais sauter une séance prévue pendant 2 mois',
      icon: Icons.psychology_rounded,
      unlocked: false,
      progress: 0.25,
      progressLabel: '2/8 semaines',
      rarity: AchievementRarity.epic,
    ),
    // Verrouillés
    Achievement(
      id: '500_workouts',
      name: 'Légende',
      description: 'Compléter 500 séances d\'entraînement',
      icon: Icons.military_tech_rounded,
      unlocked: false,
      progress: 0.29,
      progressLabel: '147/500',
      rarity: AchievementRarity.legendary,
    ),
    Achievement(
      id: 'streak_365',
      name: 'Une Année de Fer',
      description: 'Maintenir une série de 365 jours',
      icon: Icons.calendar_today_rounded,
      unlocked: false,
      progress: 0.03,
      progressLabel: '12/365 jours',
      rarity: AchievementRarity.legendary,
    ),
    Achievement(
      id: 'perfect_week',
      name: 'Semaine Parfaite',
      description: 'Compléter toutes les séances prévues 4 semaines de suite',
      icon: Icons.star_rounded,
      unlocked: false,
      progress: 0.5,
      progressLabel: '2/4 semaines',
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'early_bird',
      name: 'Lève-Tôt',
      description: 'Terminer 20 séances avant 8h du matin',
      icon: Icons.wb_sunny_rounded,
      unlocked: false,
      progress: 0.15,
      progressLabel: '3/20 séances',
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'night_owl',
      name: 'Oiseau de Nuit',
      description: 'Terminer 20 séances après 22h',
      icon: Icons.nightlight_rounded,
      unlocked: false,
      progress: 0.35,
      progressLabel: '7/20 séances',
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'social_butterfly',
      name: 'Papillon Social',
      description: 'Donner 100 respect à tes amis',
      icon: Icons.favorite_rounded,
      unlocked: false,
      progress: 0.72,
      progressLabel: '72/100',
      rarity: AchievementRarity.rare,
    ),
  ];

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
                          '$unlockedCount/${_achievements.length} débloqués',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
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

              // List
              Expanded(
                child: ListView.builder(
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
