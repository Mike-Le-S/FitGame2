import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../shared/sheets/placeholder_sheet.dart';

/// Sheet pour les paramètres avancés (thème, données, export, reset)
class AdvancedSettingsSheet extends StatefulWidget {
  const AdvancedSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AdvancedSettingsSheet(),
    );
  }

  @override
  State<AdvancedSettingsSheet> createState() => _AdvancedSettingsSheetState();
}

class _AdvancedSettingsSheetState extends State<AdvancedSettingsSheet> {
  String _selectedTheme = 'Sombre';
  bool _analyticsEnabled = true;
  bool _crashReportsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: FGColors.glassBorder,
              width: 1,
            ),
          ),
          child: SafeArea(
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
                        'Paramètres avancés',
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
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === APPARENCE ===
                        _buildSectionTitle('Apparence'),
                        const SizedBox(height: Spacing.sm),
                        _buildThemeSelector(),
                        const SizedBox(height: Spacing.xl),

                        // === DONNÉES ===
                        _buildSectionTitle('Données & Confidentialité'),
                        const SizedBox(height: Spacing.sm),
                        _buildDataSection(),
                        const SizedBox(height: Spacing.xl),

                        // === EXPORT ===
                        _buildSectionTitle('Export'),
                        const SizedBox(height: Spacing.sm),
                        _buildExportSection(),
                        const SizedBox(height: Spacing.xl),

                        // === DANGER ZONE ===
                        _buildSectionTitle('Zone de danger'),
                        const SizedBox(height: Spacing.sm),
                        _buildDangerZone(),
                        const SizedBox(height: Spacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: FGTypography.caption.copyWith(
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
        color: FGColors.textSecondary,
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          _buildThemeOption('Sombre', Icons.dark_mode_rounded),
          _buildDivider(),
          _buildThemeOption('Clair', Icons.light_mode_rounded, comingSoon: true),
          _buildDivider(),
          _buildThemeOption('Système', Icons.settings_suggest_rounded, comingSoon: true),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String label, IconData icon, {bool comingSoon = false}) {
    final isSelected = _selectedTheme == label;
    return GestureDetector(
      onTap: comingSoon
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() => _selectedTheme = label);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? FGColors.accent.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? FGColors.accent : FGColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                label,
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: comingSoon ? FGColors.textSecondary : FGColors.textPrimary,
                ),
              ),
            ),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Bientôt',
                  style: FGTypography.caption.copyWith(
                    fontSize: 9,
                    color: FGColors.textSecondary,
                  ),
                ),
              )
            else if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: FGColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.analytics_outlined,
            title: 'Données analytiques',
            subtitle: 'Améliorer l\'app avec des statistiques anonymes',
            value: _analyticsEnabled,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _analyticsEnabled = val);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.bug_report_outlined,
            title: 'Rapports de crash',
            subtitle: 'Envoyer automatiquement les erreurs',
            value: _crashReportsEnabled,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _crashReportsEnabled = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value
                  ? FGColors.accent.withValues(alpha: 0.2)
                  : FGColors.glassBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? FGColors.accent : FGColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _buildCustomSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildCustomSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? FGColors.accent : FGColors.glassBorder,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? FGColors.textOnAccent : FGColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.download_rounded,
            title: 'Exporter mes données',
            subtitle: 'Télécharger toutes tes données en JSON',
            onTap: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Export en cours de préparation...'),
                  backgroundColor: FGColors.accent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.pop(context);
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.share_rounded,
            title: 'Partager mes stats',
            subtitle: 'Générer une image de tes performances',
            onTap: () {
              HapticFeedback.mediumImpact();
              PlaceholderSheet.show(
                context,
                title: 'Partage de stats',
                message: 'Génération d\'images bientôt disponible.',
                icon: Icons.share_rounded,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: FGColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: FGColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildDangerTile(
            icon: Icons.history_rounded,
            title: 'Réinitialiser la progression',
            subtitle: 'Remettre les stats à zéro',
            onTap: () => _showResetDialog('progression'),
          ),
          _buildDivider(isDanger: true),
          _buildDangerTile(
            icon: Icons.delete_forever_rounded,
            title: 'Supprimer toutes les données',
            subtitle: 'Action irréversible',
            onTap: () => _showResetDialog('données'),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FGColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: FGColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: FGColors.error,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: FGColors.error,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider({bool isDanger = false}) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
      color: isDanger
          ? FGColors.error.withValues(alpha: 0.1)
          : FGColors.glassBorder.withValues(alpha: 0.5),
    );
  }

  void _showResetDialog(String type) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FGColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: FGColors.glassBorder),
        ),
        title: Text(
          'Réinitialiser $type ?',
          style: FGTypography.h3,
        ),
        content: Text(
          'Cette action est irréversible. Toutes les $type seront supprimées.',
          style: FGTypography.body.copyWith(color: FGColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: FGTypography.body.copyWith(color: FGColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Les $type ont été réinitialisées'),
                  backgroundColor: FGColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Text(
              'Supprimer',
              style: FGTypography.body.copyWith(
                color: FGColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
