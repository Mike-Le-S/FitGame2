import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import 'program_creation_flow.dart';
import 'session_creation_screen.dart';

/// Initial choice screen: Create a program or a single session
class CreateChoiceScreen extends StatefulWidget {
  const CreateChoiceScreen({super.key});

  @override
  State<CreateChoiceScreen> createState() => _CreateChoiceScreenState();
}

class _CreateChoiceScreenState extends State<CreateChoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _pulseAnimation = Tween<double>(begin: 0.05, end: 0.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          // Animated accent glow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Positioned(
                top: -150,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        FGColors.accent.withValues(alpha: _pulseAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: Spacing.xxl),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Que veux-tu\ncréer ?',
                            style: FGTypography.h1.copyWith(
                              fontSize: 36,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            'Choisis ton type d\'entraînement',
                            style: FGTypography.body.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: Spacing.xxl),
                          _buildChoiceCard(
                            icon: Icons.calendar_month_rounded,
                            title: 'Programme',
                            subtitle: 'Planifie plusieurs semaines',
                            description:
                                'Crée un cycle complet avec progression, deload et suivi automatique',
                            isPrimary: true,
                            onTap: () => _navigateTo(const ProgramCreationFlow()),
                          ),
                          const SizedBox(height: Spacing.md),
                          _buildChoiceCard(
                            icon: Icons.bolt_rounded,
                            title: 'Séance unique',
                            subtitle: 'Entraînement rapide',
                            description:
                                'Une séance personnalisée pour aujourd\'hui ou plus tard',
                            isPrimary: false,
                            onTap: () =>
                                _navigateTo(const SessionCreationScreen()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(Spacing.sm),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: FGColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.accent.withValues(alpha: 0.12),
                    FGColors.accent.withValues(alpha: 0.04),
                  ],
                )
              : null,
          color: isPrimary ? null : FGColors.glassSurface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(Spacing.lg),
          border: Border.all(
            color: isPrimary
                ? FGColors.accent.withValues(alpha: 0.3)
                : FGColors.glassBorder,
            width: isPrimary ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? FGColors.accent.withValues(alpha: 0.2)
                        : FGColors.glassBorder,
                    borderRadius: BorderRadius.circular(Spacing.md),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? FGColors.accent : FGColors.textPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FGTypography.h3.copyWith(
                          color:
                              isPrimary ? FGColors.accent : FGColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: isPrimary ? FGColors.accent : FGColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Text(
              description,
              style: FGTypography.bodySmall.copyWith(
                color: FGColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );

    // If creation was successful, pass result back to workout screen
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }
}
