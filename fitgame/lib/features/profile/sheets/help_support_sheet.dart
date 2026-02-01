import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';

/// FAQ item model
class FAQItem {
  final String question;
  final String answer;
  final IconData icon;

  const FAQItem({
    required this.question,
    required this.answer,
    required this.icon,
  });
}

/// Sheet d'aide et support avec FAQ et contact
class HelpSupportSheet extends StatefulWidget {
  const HelpSupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const HelpSupportSheet(),
    );
  }

  @override
  State<HelpSupportSheet> createState() => _HelpSupportSheetState();
}

class _HelpSupportSheetState extends State<HelpSupportSheet> {
  int? _expandedIndex;

  static const List<FAQItem> _faqItems = [
    FAQItem(
      question: 'Comment créer un programme d\'entraînement ?',
      answer:
          'Dans l\'onglet Entraînement, appuie sur le bouton + en haut à droite. '
          'Tu peux choisir entre un programme guidé (plusieurs semaines) ou une séance libre. '
          'Suis les étapes pour personnaliser ton programme avec tes exercices préférés.',
      icon: Icons.fitness_center_rounded,
    ),
    FAQItem(
      question: 'Comment suivre ma nutrition ?',
      answer:
          'Dans l\'onglet Nutrition, tu peux créer ton plan alimentaire pour les jours d\'entraînement et de repos. '
          'Ajoute tes repas, sélectionne les aliments dans la bibliothèque, et suis tes macros en temps réel. '
          'Tu peux aussi scanner des codes-barres pour ajouter rapidement des aliments.',
      icon: Icons.restaurant_rounded,
    ),
    FAQItem(
      question: 'Qu\'est-ce que le "Respect" dans le social ?',
      answer:
          'Le Respect est notre façon de féliciter tes amis pour leurs séances ! '
          'Quand un ami termine un entraînement, tu peux lui donner du Respect pour l\'encourager. '
          'C\'est comme un like, mais version FitGame. Plus tu en donnes, plus tu en reçois !',
      icon: Icons.favorite_rounded,
    ),
    FAQItem(
      question: 'Comment fonctionnent les défis ?',
      answer:
          'Les défis te permettent de te mesurer à tes amis sur des objectifs précis : '
          'atteindre un certain poids au bench, faire un nombre de tractions, etc. '
          'Crée un défi, invite tes amis, et le premier à atteindre l\'objectif gagne ! '
          'Tu peux voir ta progression et celle de tes amis en temps réel.',
      icon: Icons.emoji_events_rounded,
    ),
    FAQItem(
      question: 'Comment synchroniser avec Apple Health ?',
      answer:
          'Va dans Profil > Préférences > Apple Health. '
          'Autorise FitGame à accéder à tes données de santé. '
          'Tes séances, ton poids et tes données de récupération seront automatiquement synchronisés.',
      icon: Icons.favorite_border_rounded,
    ),
    FAQItem(
      question: 'Mes données sont-elles sauvegardées ?',
      answer:
          'Oui ! Avec iCloud activé, toutes tes données sont automatiquement sauvegardées. '
          'Tu peux aussi exporter tes données manuellement dans Profil > Paramètres avancés > Export.',
      icon: Icons.cloud_rounded,
    ),
    FAQItem(
      question: 'Comment modifier mon programme en cours ?',
      answer:
          'Dans l\'onglet Entraînement, appuie sur "Modifier Programme" dans les actions rapides. '
          'Tu pourras ajuster les exercices, les poids, ajouter des semaines de deload, etc. '
          'Les modifications s\'appliquent à partir de la prochaine séance.',
      icon: Icons.edit_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      'Aide & Support',
                      style: FGTypography.h3,
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

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact section
                      _buildContactSection(),
                      const SizedBox(height: Spacing.xl),

                      // FAQ section
                      Text(
                        'QUESTIONS FRÉQUENTES',
                        style: FGTypography.caption.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: FGColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),

                      ...List.generate(_faqItems.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: _buildFAQItem(index, _faqItems[index]),
                        );
                      }),

                      const SizedBox(height: Spacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FGColors.accent.withValues(alpha: 0.15),
            FGColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Spacing.lg),
        border: Border.all(
          color: FGColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: FGColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: FGColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Besoin d\'aide ?',
            style: FGTypography.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Notre équipe est là pour t\'aider',
            style: FGTypography.body.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Email copié : support@fitgame.pro'),
                        backgroundColor: FGColors.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Discord',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Rejoins notre Discord : discord.gg/fitgame'),
                        backgroundColor: const Color(0xFF5865F2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        decoration: BoxDecoration(
          color: FGColors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: FGColors.textPrimary,
              size: 18,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(int index, FAQItem item) {
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isExpanded
              ? FGColors.accent.withValues(alpha: 0.08)
              : FGColors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isExpanded
                ? FGColors.accent.withValues(alpha: 0.3)
                : FGColors.glassBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? FGColors.accent.withValues(alpha: 0.2)
                        : FGColors.glassBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: isExpanded ? FGColors.accent : FGColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    item.question,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isExpanded ? FGColors.textPrimary : FGColors.textSecondary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: isExpanded ? FGColors.accent : FGColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: Spacing.md, left: 52),
                child: Text(
                  item.answer,
                  style: FGTypography.body.copyWith(
                    color: FGColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              crossFadeState:
                  isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
