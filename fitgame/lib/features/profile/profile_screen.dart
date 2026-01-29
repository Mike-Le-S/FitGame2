import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../shared/widgets/fg_glass_card.dart';

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

  // Mock user data
  final String _userName = 'Mike';
  final String _userEmail = 'mike@fitgame.pro';
  final int _totalWorkouts = 147;
  final int _currentStreak = 12;
  final String _memberSince = 'Jan 2025';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.1, end: 0.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          // === MESH GRADIENT BACKGROUND ===
          _buildMeshGradient(),

          // === MAIN CONTENT ===
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Spacing.lg),

                    // === HEADER ===
                    _buildHeader(),
                    const SizedBox(height: Spacing.xl),

                    // === PROFILE CARD ===
                    _buildProfileCard(),
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

  Widget _buildMeshGradient() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: FGColors.background),

            // Top-left subtle glow
            Positioned(
              top: -50,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FGColors.accent
                          .withValues(alpha: _pulseAnimation.value * 0.4),
                      FGColors.accent
                          .withValues(alpha: _pulseAnimation.value * 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Bottom-right glow
            Positioned(
              bottom: 200,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FGColors.accent
                          .withValues(alpha: _pulseAnimation.value * 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Text(
      'Profil',
      style: FGTypography.h1.copyWith(
        fontSize: 36,
      ),
    );
  }

  Widget _buildProfileCard() {
    return FGGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Top gradient section with avatar
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
                // Avatar
                Container(
                  width: 72,
                  height: 72,
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
                        color: FGColors.accent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _userName[0].toUpperCase(),
                      style: FGTypography.h1.copyWith(
                        fontSize: 32,
                        color: FGColors.textOnAccent,
                      ),
                    ),
                  ),
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
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        _userEmail,
                        style: FGTypography.bodySmall.copyWith(
                          color: FGColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Edit profile
                  },
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: FGColors.glassBorder,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: FGColors.textPrimary,
                      size: 20,
                    ),
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
                _buildProfileStat('$_totalWorkouts', 'Séances'),
                _buildStatDivider(),
                _buildProfileStat('$_currentStreak', 'Jours série'),
                _buildStatDivider(),
                _buildProfileStat(_memberSince, 'Membre'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: FGTypography.h3.copyWith(
              color: FGColors.accent,
              fontWeight: FontWeight.w900,
            ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: FGTypography.caption.copyWith(
        letterSpacing: 3,
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
              },
              isSubItem: true,
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.trending_up_outlined,
              title: 'Alertes progression',
              subtitle: 'Nouveau PR, objectifs atteints',
              value: _progressAlerts,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                setState(() => _progressAlerts = val);
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
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.sync_outlined,
            title: 'Apple Health',
            subtitle: 'Connecté',
            subtitleColor: FGColors.success,
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Health settings
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.backup_outlined,
            title: 'Sauvegarde',
            subtitle: 'iCloud activé',
            subtitleColor: FGColors.success,
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Backup settings
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
            icon: Icons.star_outline_rounded,
            title: 'Noter l\'app',
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Rate app
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.help_outline_rounded,
            title: 'Aide & Support',
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Help
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Terms
            },
          ),
          _buildDivider(),
          _buildNavigationTile(
            icon: Icons.shield_outlined,
            title: 'Politique de confidentialité',
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Privacy
            },
          ),
        ],
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
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: value
                  ? FGColors.accent.withValues(alpha: 0.15)
                  : FGColors.glassBorder,
              borderRadius: BorderRadius.circular(Spacing.sm),
            ),
            child: Icon(
              icon,
              color: value ? FGColors.accent : FGColors.textSecondary,
              size: 20,
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
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: FGColors.glassBorder,
              borderRadius: BorderRadius.circular(Spacing.sm),
            ),
            child: Icon(
              icon,
              color: FGColors.textSecondary,
              size: 20,
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
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Icon(
                icon,
                color: FGColors.textSecondary,
                size: 20,
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
              color: FGColors.textSecondary,
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
