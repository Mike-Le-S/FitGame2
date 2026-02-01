import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';

enum LegalDocumentType { terms, privacy }

/// Sheet affichant les documents légaux (CGU et Politique de confidentialité)
class LegalSheet extends StatelessWidget {
  final LegalDocumentType documentType;

  const LegalSheet({
    super.key,
    required this.documentType,
  });

  static Future<void> show(
    BuildContext context, {
    required LegalDocumentType type,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LegalSheet(documentType: type),
    );
  }

  String get _title {
    switch (documentType) {
      case LegalDocumentType.terms:
        return 'Conditions d\'utilisation';
      case LegalDocumentType.privacy:
        return 'Politique de confidentialité';
    }
  }

  String get _lastUpdated => '15 janvier 2025';

  List<Map<String, String>> get _sections {
    switch (documentType) {
      case LegalDocumentType.terms:
        return _termsSections;
      case LegalDocumentType.privacy:
        return _privacySections;
    }
  }

  static const List<Map<String, String>> _termsSections = [
    {
      'title': '1. Acceptation des conditions',
      'content':
          'En utilisant FitGame, vous acceptez d\'être lié par les présentes conditions d\'utilisation. '
              'Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.\n\n'
              'FitGame se réserve le droit de modifier ces conditions à tout moment. '
              'Les modifications entreront en vigueur dès leur publication dans l\'application.',
    },
    {
      'title': '2. Description du service',
      'content':
          'FitGame est une application de suivi d\'entraînement et de nutrition qui permet aux utilisateurs de :\n\n'
              '• Créer et suivre des programmes d\'entraînement personnalisés\n'
              '• Enregistrer leurs performances et progressions\n'
              '• Planifier leur nutrition et suivre leurs macros\n'
              '• Interagir avec d\'autres utilisateurs via les fonctionnalités sociales\n'
              '• Participer à des défis sportifs',
    },
    {
      'title': '3. Compte utilisateur',
      'content':
          'Pour utiliser certaines fonctionnalités de FitGame, vous devez créer un compte. '
              'Vous êtes responsable de la confidentialité de vos identifiants de connexion.\n\n'
              'Vous acceptez de fournir des informations exactes et de les maintenir à jour. '
              'FitGame peut suspendre ou supprimer votre compte en cas de violation de ces conditions.',
    },
    {
      'title': '4. Utilisation acceptable',
      'content':
          'Vous vous engagez à utiliser FitGame de manière responsable et à ne pas :\n\n'
              '• Publier du contenu offensant, diffamatoire ou illégal\n'
              '• Harceler ou intimider d\'autres utilisateurs\n'
              '• Tenter d\'accéder aux comptes d\'autres utilisateurs\n'
              '• Utiliser l\'application à des fins commerciales non autorisées\n'
              '• Interférer avec le fonctionnement normal du service',
    },
    {
      'title': '5. Propriété intellectuelle',
      'content':
          'Tout le contenu de FitGame (logos, designs, textes, fonctionnalités) est protégé par le droit d\'auteur '
              'et appartient à FitGame ou à ses concédants de licence.\n\n'
              'Vous conservez les droits sur le contenu que vous publiez, mais accordez à FitGame une licence '
              'pour l\'utiliser dans le cadre du service.',
    },
    {
      'title': '6. Avertissement santé',
      'content':
          'FitGame n\'est pas un substitut à un avis médical professionnel. '
              'Consultez toujours un professionnel de santé avant de commencer un nouveau programme d\'exercice ou de nutrition.\n\n'
              'FitGame décline toute responsabilité en cas de blessure ou de problème de santé '
              'résultant de l\'utilisation de l\'application.',
    },
    {
      'title': '7. Limitation de responsabilité',
      'content':
          'FitGame est fourni "tel quel" sans garantie d\'aucune sorte. '
              'Nous ne garantissons pas que le service sera ininterrompu ou exempt d\'erreurs.\n\n'
              'En aucun cas FitGame ne sera responsable des dommages indirects, accessoires ou consécutifs '
              'résultant de l\'utilisation ou de l\'impossibilité d\'utiliser le service.',
    },
    {
      'title': '8. Contact',
      'content':
          'Pour toute question concernant ces conditions d\'utilisation, vous pouvez nous contacter à :\n\n'
              'Email : legal@fitgame.pro\n'
              'Adresse : FitGame SAS, 42 rue du Sport, 75001 Paris, France',
    },
  ];

  static const List<Map<String, String>> _privacySections = [
    {
      'title': '1. Données collectées',
      'content':
          'FitGame collecte les données suivantes pour fournir et améliorer le service :\n\n'
              '• Informations de compte : nom, email, mot de passe (chiffré)\n'
              '• Données d\'entraînement : exercices, poids, répétitions, durées\n'
              '• Données de nutrition : repas, aliments, macros\n'
              '• Données de santé : poids corporel, sommeil (si autorisé)\n'
              '• Données sociales : amis, messages, défis',
    },
    {
      'title': '2. Utilisation des données',
      'content': 'Vos données sont utilisées pour :\n\n'
          '• Fournir les fonctionnalités de l\'application\n'
          '• Personnaliser votre expérience\n'
          '• Générer des statistiques et suivre vos progrès\n'
          '• Améliorer nos services via des analyses anonymisées\n'
          '• Vous envoyer des notifications (si autorisées)',
    },
    {
      'title': '3. Partage des données',
      'content':
          'FitGame ne vend jamais vos données personnelles. Nous pouvons partager vos données avec :\n\n'
              '• Vos amis : performances et défis (selon vos paramètres de confidentialité)\n'
              '• Prestataires techniques : hébergement, analytics (données anonymisées)\n'
              '• Autorités : si requis par la loi',
    },
    {
      'title': '4. Stockage et sécurité',
      'content': 'Vos données sont stockées de manière sécurisée :\n\n'
          '• Chiffrement en transit (HTTPS/TLS)\n'
          '• Chiffrement au repos des données sensibles\n'
          '• Serveurs hébergés dans l\'Union Européenne\n'
          '• Sauvegardes régulières et redondantes',
    },
    {
      'title': '5. Apple Health',
      'content':
          'Si vous choisissez d\'activer la synchronisation avec Apple Health :\n\n'
              '• FitGame peut lire et écrire des données de santé\n'
              '• Ces données restent sur votre appareil ou dans iCloud\n'
              '• FitGame n\'envoie jamais ces données à ses serveurs\n'
              '• Vous pouvez révoquer l\'accès à tout moment dans les Réglages iOS',
    },
    {
      'title': '6. Vos droits (RGPD)',
      'content': 'Conformément au RGPD, vous disposez des droits suivants :\n\n'
          '• Accès : obtenir une copie de vos données\n'
          '• Rectification : corriger vos données inexactes\n'
          '• Effacement : supprimer vos données\n'
          '• Portabilité : exporter vos données\n'
          '• Opposition : refuser certains traitements\n\n'
          'Exercez ces droits via Profil > Paramètres avancés ou par email.',
    },
    {
      'title': '7. Cookies et analytics',
      'content':
          'FitGame utilise des technologies de suivi pour améliorer le service :\n\n'
              '• Analytics anonymisées (si autorisées dans les paramètres)\n'
              '• Rapports de crash (si autorisés)\n'
              '• Aucun cookie publicitaire\n\n'
              'Vous pouvez désactiver ces options dans Profil > Paramètres avancés.',
    },
    {
      'title': '8. Conservation des données',
      'content':
          'Vos données sont conservées tant que votre compte est actif. Après suppression du compte :\n\n'
              '• Données personnelles : supprimées sous 30 jours\n'
              '• Données anonymisées : peuvent être conservées pour statistiques\n'
              '• Sauvegardes : supprimées lors de la rotation (90 jours max)',
    },
    {
      'title': '9. Contact DPO',
      'content':
          'Pour toute question relative à la protection de vos données :\n\n'
              'Délégué à la Protection des Données\n'
              'Email : dpo@fitgame.pro\n'
              'Adresse : FitGame SAS, 42 rue du Sport, 75001 Paris, France',
    },
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: FGTypography.h3,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dernière mise à jour : $_lastUpdated',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.lg),
                      child: _buildSection(
                        title: section['title']!,
                        content: section['content']!,
                      ),
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

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FGTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            color: FGColors.accent,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          content,
          style: FGTypography.body.copyWith(
            color: FGColors.textSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
