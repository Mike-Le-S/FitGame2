import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/fg_colors.dart';
import 'core/theme/fg_typography.dart';
import 'core/constants/spacing.dart';
import 'shared/widgets/fg_glass_card.dart';
import 'shared/widgets/fg_neon_button.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FitGameApp());
}

class FitGameApp extends StatelessWidget {
  const FitGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitGame',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const DesignSystemTestScreen(),
    );
  }
}

/// Test screen to verify the design system components
class DesignSystemTestScreen extends StatelessWidget {
  const DesignSystemTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              FGColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'FITGAME',
                  style: FGTypography.display.copyWith(
                    color: FGColors.accent,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'Design System Test',
                  style: FGTypography.h2,
                ),
                const SizedBox(height: Spacing.xxl),

                // Glass Card
                FGGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Glass Card',
                        style: FGTypography.h3,
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        'This card has a glass-morphism effect with backdrop blur and subtle border.',
                        style: FGTypography.body.copyWith(
                          color: FGColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      Row(
                        children: [
                          Text(
                            '2,450',
                            style: FGTypography.numbers.copyWith(
                              color: FGColors.accent,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            'XP',
                            style: FGTypography.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // Another Glass Card
                FGGlassCard(
                  onTap: () {},
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: FGColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: FGColors.success,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Workout Complete',
                              style: FGTypography.h3,
                            ),
                            Text(
                              '+150 XP earned',
                              style: FGTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: FGColors.textSecondary,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Neon Button
                FGNeonButton(
                  label: 'Start Workout',
                  isExpanded: true,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Button pressed!',
                          style: FGTypography.body,
                        ),
                        backgroundColor: FGColors.glassSurface,
                      ),
                    );
                  },
                ),
                const SizedBox(height: Spacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
