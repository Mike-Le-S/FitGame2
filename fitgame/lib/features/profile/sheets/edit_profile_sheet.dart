import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';

/// Sheet pour modifier le profil utilisateur
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentAvatarIndex,
  });

  final String currentName;
  final String currentEmail;
  final int currentAvatarIndex;

  static Future<void> show(
    BuildContext context, {
    required String currentName,
    required String currentEmail,
    required int currentAvatarIndex,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EditProfileSheet(
        currentName: currentName,
        currentEmail: currentEmail,
        currentAvatarIndex: currentAvatarIndex,
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late int _selectedAvatarIndex;
  bool _isSaving = false;

  // Avatars prédéfinis (emojis fitness)
  static const List<String> _avatars = [
    '💪',
    '🏋️',
    '🏃',
    '🧘',
    '🚴',
    '⚡',
    '🔥',
    '🎯',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _selectedAvatarIndex = widget.currentAvatarIndex.clamp(0, _avatars.length - 1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: FGColors.glassBorder,
              width: 1,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: Spacing.lg,
                right: Spacing.lg,
                top: Spacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: FGColors.textSecondary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Title
                    Text(
                      'Modifier le profil',
                      style: FGTypography.h3,
                    ),
                    const SizedBox(height: Spacing.xl),

                    // Avatar selector
                    Text(
                      'Avatar',
                      style: FGTypography.bodySmall.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _avatars.length,
                        separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedAvatarIndex;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedAvatarIndex = index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? FGColors.accent.withValues(alpha: 0.2)
                                    : FGColors.glassSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? FGColors.accent
                                      : FGColors.glassBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _avatars[index],
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Name field
                    Text(
                      'Nom',
                      style: FGTypography.bodySmall.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _buildTextField(_nameController, 'Votre nom'),
                    const SizedBox(height: Spacing.md),

                    // Email field
                    Text(
                      'Email',
                      style: FGTypography.bodySmall.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _buildTextField(_emailController, 'votre@email.com'),
                    const SizedBox(height: Spacing.xl),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: FGColors.glassBorder),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: FGTypography.body.copyWith(
                                color: FGColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FGColors.accent,
                              foregroundColor: FGColors.textOnAccent,
                              disabledBackgroundColor: FGColors.accent.withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: FGColors.textOnAccent,
                                    ),
                                  )
                                : Text(
                                    'Sauvegarder',
                                    style: FGTypography.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: FGColors.textOnAccent,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      await SupabaseService.updateProfile({
        'full_name': _nameController.text.trim(),
        'avatar_index': _selectedAvatarIndex,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil mis à jour'),
            backgroundColor: FGColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la sauvegarde'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        style: FGTypography.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: FGTypography.body.copyWith(
            color: FGColors.textSecondary.withValues(alpha: 0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.md,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
