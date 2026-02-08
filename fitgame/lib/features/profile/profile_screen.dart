import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/fg_glass_card.dart';
import '../../shared/sheets/placeholder_sheet.dart';
import '../../shared/widgets/fg_mesh_gradient.dart';
import 'sheets/edit_profile_sheet.dart';
import 'sheets/advanced_settings_sheet.dart';
import 'sheets/achievements_sheet.dart';
import 'sheets/help_support_sheet.dart';
import 'sheets/legal_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Settings state
  bool _notificationsEnabled = true;
  bool _workoutReminders = true;
  bool _restDayReminders = false;
  bool _progressAlerts = true;
  String _weightUnit = 'kg';
  String _language = 'Français';

  // User data from Supabase
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  int _totalWorkouts = 0;
  int _currentStreak = 0;
  String _memberSince = '';
  int _avatarIndex = 0;

  // Achievements
  List<Map<String, dynamic>> _achievements = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.08, end: 0.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await SupabaseService.getCurrentProfile();
      final user = SupabaseService.currentUser;

      if (mounted && profile != null) {
        setState(() {
          _userName = profile['full_name'] ?? user?.email?.split('@')[0] ?? 'Utilisateur';
          _userEmail = user?.email ?? '';
          _totalWorkouts = profile['total_sessions'] ?? 0;
          _currentStreak = profile['current_streak'] ?? 0;
          _weightUnit = profile['weight_unit'] ?? 'kg';
          _language = profile['language'] == 'en' ? 'English' : 'Français';
          _notificationsEnabled = profile['notifications_enabled'] ?? true;
          _workoutReminders = profile['workout_reminders'] ?? true;
          _restDayReminders = profile['rest_day_reminders'] ?? false;
          _progressAlerts = profile['progress_alerts'] ?? true;
          final rawAvatar = profile['avatar_index'];
          _avatarIndex = (rawAvatar is int ? rawAvatar : 0).clamp(0, 7);

          // Format member since date
          final createdAt = DateTime.tryParse(profile['created_at'] ?? '');
          if (createdAt != null) {
            final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
            _memberSince = '${months[createdAt.month - 1]} ${createdAt.year.toString().substring(2)}';
          }

          _isLoading = false;
        });
      }

      // Load achievements from Supabase
      try {
        final achievements = await SupabaseService.getAchievements();
        if (mounted) {
          setState(() {
            _achievements = achievements.map((a) => <String, dynamic>{
              'id': a['id'],
              'name': a['name'],
              'icon': _getAchievementIcon(a['icon'] as String? ?? ''),
              'unlocked': a['unlocked'] ?? false,
            }).toList();
          });
        }
      } catch (e) {
        debugPrint('Error loading achievements: $e');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'whatshot':
        return Icons.whatshot_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'iron':
        return Icons.fitness_center_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  String _getAvatarEmoji(int index) {
    const avatars = ['\u{1F4AA}', '\u{1F3CB}\u{FE0F}', '\u{1F3C3}', '\u{1F9D8}', '\u{1F6B4}', '\u{26A1}', '\u{1F525}', '\u{1F3AF}'];
    if (index < 0 || index >= avatars.length) return avatars[0];
    return avatars[index];
  }

  /// Save a single setting to Supabase
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      await SupabaseService.updateProfile({key: value});
    } catch (e) {
      debugPrint('Error saving setting $key: $e');
      if (mounted) {
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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int get _unlockedCount =>
      _achievements.where((a) => a['unlocked'] as bool).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          // === MESH GRADIENT BACKGROUND ===
          FGMeshGradient.profile(animation: _pulseAnimation),

          // === MAIN CONTENT ===
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: FGColors.accent,
                      strokeWidth: 2,
                    ),
                  )
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Spacing.md),

                    // === HEADER ===
                    _buildHeader(),
                    const SizedBox(height: Spacing.lg),

                    // === HERO PROFILE CARD ===
                    _buildHeroProfileCard(),
                    const SizedBox(height: Spacing.xl),

                    // === ACHIEVEMENTS SECTION ===
                    _buildAchievementsSection(),
                    const SizedBox(height: Spacing.xl),

                    // === NOTIFICATIONS SECTION ===
                    _buildSectionTitle('Notifications'),
                    const SizedBox(height: Spacing.md),
                    _buildNotificationsSection(),
                    const SizedBox(height: Spacing.xl),

                    // === PREFERENCES SECTION ===
                    _buildSectionTitle('Préférences'),
                    const SizedBox(height: Spacing.md),
                    _buildPreferencesSection(),
                    const SizedBox(height: Spacing.xl),

                    // === ABOUT SECTION ===
                    _buildSectionTitle('À propos'),
                    const SizedBox(height: Spacing.md),
                    _buildAboutSection(),
                    const SizedBox(height: Spacing.xxl),

                    // === VERSION ===
                    Center(
                      child: Text(
                        'FitGame Pro v1.0.0',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROFIL',
              style: FGTypography.caption.copyWith(
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: FGColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tes réglages',
              style: FGTypography.h2.copyWith(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Settings gear icon
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            AdvancedSettingsSheet.show(context);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FGColors.glassSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Spacing.md),
              border: Border.all(color: FGColors.glassBorder),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: FGColors.textSecondary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroProfileCard() {
    return FGGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Top section with avatar and info
          Container(
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                // Avatar with glow
                Stack(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            FGColors.accent,
                            FGColors.accent.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: FGColors.accent.withValues(alpha: 0.5),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getAvatarEmoji(_avatarIndex),
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                    // Edit button overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await EditProfileSheet.show(
                            context,
                            currentName: _userName,
                            currentEmail: _userEmail,
                            currentAvatarIndex: _avatarIndex,
                          );
                          if (mounted) _loadUserProfile();
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: FGColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: FGColors.accent,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: FGColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: Spacing.lg),

                // Name & email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: FGTypography.h2.copyWith(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: FGTypography.bodySmall.copyWith(
                          color: FGColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                _buildProfileStat(
                  '$_totalWorkouts',
                  'Séances',
                  Icons.fitness_center_rounded,
                ),
                _buildStatDivider(),
                _buildProfileStat(
                  '$_currentStreak',
                  'Streak',
                  Icons.local_fire_department_rounded,
                  isStreak: true,
                ),
                _buildStatDivider(),
                _buildProfileStat(
                  _memberSince,
                  'Membre',
                  Icons.calendar_today_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String value, String label, IconData icon,
      {bool isStreak = false}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isStreak)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    icon,
                    size: 18,
                    color: FGColors.accent,
                  ),
                ),
              Text(
                value,
                style: FGTypography.h3.copyWith(
                  color: FGColors.accent,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: FGColors.glassBorder,
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ACCOMPLISSEMENTS',
              style: FGTypography.caption.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: FGColors.textSecondary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: FGColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: FGColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '$_unlockedCount/${_achievements.length}',
                style: FGTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: FGColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        FGGlassCard(
          onTap: () {
            HapticFeedback.lightImpact();
            AchievementsSheet.show(context);
          },
          child: Row(
            children: _achievements.take(5).map((achievement) {
              final isUnlocked = achievement['unlocked'] as bool;
              return _buildAchievementBadge(
                icon: achievement['icon'] as IconData,
                name: achievement['name'] as String,
                isUnlocked: isUnlocked,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required String name,
    required bool isUnlocked,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FGColors.accent.withValues(alpha: 0.25),
                        FGColors.accent.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: isUnlocked ? null : FGColors.glassBorder.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: isUnlocked
                  ? Border.all(
                      color: FGColors.accent.withValues(alpha: 0.4),
                    )
                  : null,
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: FGColors.accent.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isUnlocked
                  ? FGColors.accent
                  : FGColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FGTypography.caption.copyWith(
              fontSize: 8,
              fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w400,
              color: isUnlocked
                  ? FGColors.textPrimary
                  : FGColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
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

  Widget _buildNotificationsSection() {
    return FGGlassCard(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Activer toutes les notifications',
            value: _notificationsEnabled,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              setState(() => _notificationsEnabled = val);
              _saveSetting('notifications_enabled', val);
            },
          ),
          if (_notificationsEnabled) ...[
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.fitness_center_outlined,
              title: 'Rappels séances',
              subtitle: 'Notification avant chaque séance',
              value: _workoutReminders,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                setState(() => _workoutReminders = val);
                _saveSetting('workout_reminders', val);
              },
              isSubItem: true,
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.hotel_outlined,
              title: 'Jours de repos',
              subtitle: 'Rappel de récupération',
              value: _restDayReminders,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                setState(() => _restDayReminders = val);
                _saveSetting('rest_day_reminders', val);
              },
              isSubItem: true,
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.trending_up_outlined,
              title: 'Alertes de progression',
              subtitle: 'Nouveau PR, objectifs atteints',
              value: _progressAlerts,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                setState(() => _progressAlerts = val);
                _saveSetting('progress_alerts', val);
              },
              isSubItem: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return FGGlassCard(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Column(
        children: [
          _buildSelectionTile(
            icon: Icons.straighten_outlined,
            title: 'Unité de poids',
            value: _weightUnit,
            options: ['kg', 'lbs'],
            onChanged: (val) {
              HapticFeedback.lightImpact();
              setState(() => _weightUnit = val);
              _saveSetting('weight_unit', val);
            },
          ),
          _buildDivider(),
          _buildSelectionTile(
            icon: Icons.language_outlined,
            title: 'Langue',
            value: _language,
            options: ['Français', 'English'],
            onChanged: (val) {
              HapticFeedback.lightImpact();
              setState(() => _language = val);
              _saveSetting('language', val == 'English' ? 'en' : 'fr');
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.favorite_rounded,
            iconGradient: const [Color(0xFFFF5B7F), Color(0xFFFF8066)],
            title: 'Apple Health',
            subtitle: 'Connecté',
            subtitleColor: FGColors.success,
            onTap: () {
              HapticFeedback.lightImpact();
              PlaceholderSheet.show(
                context,
                title: 'Apple Health',
                message:
                    'Synchronisation avec Apple Health bientôt disponible.',
                icon: Icons.sync_outlined,
              );
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.cloud_outlined,
            iconGradient: const [Color(0xFF00D9FF), Color(0xFF6B5BFF)],
            title: 'Sauvegarde',
            subtitle: 'iCloud activé',
            subtitleColor: FGColors.success,
            onTap: () {
              HapticFeedback.lightImpact();
              PlaceholderSheet.show(
                context,
                title: 'Sauvegarde',
                message: 'Configuration iCloud bientôt disponible.',
                icon: Icons.backup_outlined,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return FGGlassCard(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Column(
        children: [
          _buildNavigationTile(
            icon: Icons.star_rounded,
            iconGradient: const [FGColors.accent, Color(0xFFFF8844)],
            title: 'Noter l\'app',
            onTap: () {
              HapticFeedback.lightImpact();
              PlaceholderSheet.show(
                context,
                title: 'Noter l\'app',
                message: 'Lien vers l\'App Store bientôt disponible.',
                icon: Icons.star_outline_rounded,
              );
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.help_outline_rounded,
            title: 'Aide & Support',
            onTap: () {
              HapticFeedback.lightImpact();
              HelpSupportSheet.show(context);
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () {
              HapticFeedback.lightImpact();
              LegalSheet.show(context, type: LegalDocumentType.terms);
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.shield_outlined,
            title: 'Politique de confidentialité',
            onTap: () {
              HapticFeedback.lightImpact();
              LegalSheet.show(context, type: LegalDocumentType.privacy);
            },
          ),
          _buildDivider(),
          _buildLogoutTile(),
        ],
      ),
    );
  }

  Widget _buildLogoutTile() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();

        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: FGColors.glassSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacing.lg),
            ),
            title: Text(
              'Déconnexion',
              style: FGTypography.h3.copyWith(
                color: FGColors.textPrimary,
              ),
            ),
            content: Text(
              'Êtes-vous sûr de vouloir vous déconnecter ?',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
              ),
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
                  'Déconnexion',
                  style: FGTypography.body.copyWith(
                    color: FGColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          await SupabaseService.signOut();
          // Navigation will be handled by auth state listener in main.dart
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.error.withValues(alpha: 0.25),
                    FGColors.error.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: FGColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                'Déconnexion',
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FGColors.error,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: FGColors.error.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isSubItem = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ).copyWith(left: isSubItem ? Spacing.xl : Spacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: value
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FGColors.accent.withValues(alpha: 0.25),
                        FGColors.accent.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: value ? null : FGColors.glassBorder,
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
                  style: FGTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
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
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? FGColors.accent : FGColors.glassBorder,
          boxShadow: value
              ? [
                  BoxShadow(
                    color: FGColors.accent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
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
            child: Text(
              title,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildSegmentedControl(
            value: value,
            options: options,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FGColors.glassBorder,
        borderRadius: BorderRadius.circular(Spacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option == value;
          return GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? FGColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(Spacing.sm - 2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: FGColors.accent.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                option,
                style: FGTypography.caption.copyWith(
                  color: isSelected
                      ? FGColors.textOnAccent
                      : FGColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    List<Color>? iconGradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: iconGradient != null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconGradient[0].withValues(alpha: 0.25),
                          iconGradient[1].withValues(alpha: 0.15),
                        ],
                      )
                    : null,
                color: iconGradient == null ? FGColors.glassBorder : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconGradient != null
                    ? iconGradient[0]
                    : FGColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                title,
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: FGTypography.caption.copyWith(
                  color: subtitleColor ?? FGColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: Spacing.sm),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: FGColors.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      color: FGColors.glassBorder.withValues(alpha: 0.5),
    );
  }
}
