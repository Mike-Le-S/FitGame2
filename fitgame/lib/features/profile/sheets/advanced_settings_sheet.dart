import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';
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
  bool _hasArchivedData = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkArchivedData();
  }

  Future<void> _checkArchivedData() async {
    try {
      final hasData = await SupabaseService.hasArchivedData();
      if (mounted) setState(() => _hasArchivedData = hasData);
    } catch (e) {
      debugPrint('Error checking archived data: $e');
    }
  }

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
          // Restore button — only visible when archived data exists
          if (_hasArchivedData) ...[
            _buildRestoreTile(),
            _buildDivider(isDanger: true),
          ],
          _buildDangerTile(
            icon: Icons.history_rounded,
            title: 'Réinitialiser la progression',
            subtitle: 'Remettre les stats à zéro',
            onTap: _isProcessing ? () {} : _showArchiveDialog,
          ),
          _buildDivider(isDanger: true),
          _buildDangerTile(
            icon: Icons.delete_forever_rounded,
            title: 'Supprimer toutes les données',
            subtitle: 'Action irréversible',
            onTap: _isProcessing ? () {} : _showDeleteDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreTile() {
    return GestureDetector(
      onTap: _isProcessing ? null : _showRestoreDialog,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FGColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restore_rounded,
                color: FGColors.success,
                size: 18,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restaurer mes données',
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: FGColors.success,
                    ),
                  ),
                  Text(
                    'Récupérer les données archivées',
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
              color: FGColors.success,
              size: 20,
            ),
          ],
        ),
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

  // ---------------------------------------------------------------------------
  // Restore dialog (simple confirmation, no text input needed)
  // ---------------------------------------------------------------------------
  void _showRestoreDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: FGColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: FGColors.glassBorder),
              ),
              title: Text(
                'Restaurer mes données ?',
                style: FGTypography.h3,
              ),
              content: Text(
                'Vos données archivées seront restaurées et votre progression recalculée.',
                style: FGTypography.body.copyWith(color: FGColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Annuler',
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final dialogNav = Navigator.of(dialogContext);
                          setDialogState(() {});
                          setState(() => _isProcessing = true);
                          try {
                            await SupabaseService.restoreUserData();
                            dialogNav.pop();
                            await _checkArchivedData();
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Données restaurées avec succès.',
                                ),
                                backgroundColor: FGColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            dialogNav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Erreur : $e'),
                                backgroundColor: FGColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isProcessing = false);
                            }
                          }
                        },
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FGColors.success,
                          ),
                        )
                      : Text(
                          'Restaurer',
                          style: FGTypography.body.copyWith(
                            color: FGColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Archive dialog (user must type "RESET" to confirm)
  // ---------------------------------------------------------------------------
  void _showArchiveDialog() {
    HapticFeedback.mediumImpact();
    final textController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canConfirm =
                textController.text.trim().toUpperCase() == 'RESET';
            return AlertDialog(
              backgroundColor: FGColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: FGColors.glassBorder),
              ),
              title: Text(
                'Réinitialiser la progression ?',
                style: FGTypography.h3,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vos données seront archivées et pourront être restaurées ultérieurement. '
                    'Vos stats seront remises à zéro.',
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Tapez RESET pour confirmer :',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: textController,
                    enabled: !_isProcessing,
                    onChanged: (_) => setDialogState(() {}),
                    style: FGTypography.body.copyWith(
                      color: FGColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'RESET',
                      hintStyle: FGTypography.body.copyWith(
                        color: FGColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: FGColors.glassBorder.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Annuler',
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: (canConfirm && !_isProcessing)
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final dialogNav = Navigator.of(dialogContext);
                          final sheetNav = Navigator.of(context);
                          setState(() => _isProcessing = true);
                          setDialogState(() {});
                          try {
                            await SupabaseService.archiveUserData();
                            dialogNav.pop();
                            sheetNav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Données archivées. Vous pouvez les restaurer depuis les paramètres avancés.',
                                ),
                                backgroundColor: FGColors.accent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            dialogNav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Erreur : $e'),
                                backgroundColor: FGColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isProcessing = false);
                            }
                          }
                        }
                      : null,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FGColors.error,
                          ),
                        )
                      : Text(
                          'Réinitialiser',
                          style: FGTypography.body.copyWith(
                            color: canConfirm
                                ? FGColors.error
                                : FGColors.error.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Delete dialog (user must type "SUPPRIMER" to confirm)
  // ---------------------------------------------------------------------------
  void _showDeleteDialog() {
    HapticFeedback.mediumImpact();
    final textController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canConfirm =
                textController.text.trim().toUpperCase() == 'SUPPRIMER';
            return AlertDialog(
              backgroundColor: FGColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: FGColors.glassBorder),
              ),
              title: Text(
                'Supprimer toutes les données ?',
                style: FGTypography.h3,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cette action est irréversible. Toutes vos données seront définitivement supprimées.',
                    style: FGTypography.body.copyWith(
                      color: FGColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Tapez SUPPRIMER pour confirmer :',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: textController,
                    enabled: !_isProcessing,
                    onChanged: (_) => setDialogState(() {}),
                    style: FGTypography.body.copyWith(
                      color: FGColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'SUPPRIMER',
                      hintStyle: FGTypography.body.copyWith(
                        color: FGColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: FGColors.glassBorder.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Annuler',
                    style: FGTypography.body.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: (canConfirm && !_isProcessing)
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final dialogNav = Navigator.of(dialogContext);
                          final sheetNav = Navigator.of(context);
                          setState(() => _isProcessing = true);
                          setDialogState(() {});
                          try {
                            await SupabaseService.deleteAllUserData();
                            dialogNav.pop();
                            sheetNav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Toutes les données ont été supprimées.',
                                ),
                                backgroundColor: FGColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            dialogNav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Erreur : $e'),
                                backgroundColor: FGColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isProcessing = false);
                            }
                          }
                        }
                      : null,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FGColors.error,
                          ),
                        )
                      : Text(
                          'Supprimer',
                          style: FGTypography.body.copyWith(
                            color: canConfirm
                                ? FGColors.error
                                : FGColors.error.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
