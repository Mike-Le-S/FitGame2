import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/fg_colors.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/workout/workout_screen.dart';
import 'features/health/health_screen.dart';
import 'features/nutrition/nutrition_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/social/social_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase
  await SupabaseService.initialize();

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
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper that listens to auth state and shows appropriate screen
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: FGColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: FGColors.accent,
              ),
            ),
          );
        }

        // Check if user is authenticated
        final session = snapshot.data?.session;
        if (session != null) {
          return const MainNavigation();
        }

        // Show auth screen if not authenticated
        return const AuthScreen();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _screens = [
    HomeScreen(onNavigateToTab: _navigateToTab),
    const WorkoutScreen(),
    const SocialScreen(),
    const NutritionScreen(),
    const HealthScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Clamp index to valid range (safety for hot reload)
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: FGColors.background,
          border: Border(
            top: BorderSide(
              color: FGColors.glassBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Accueil',
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.fitness_center_rounded,
                    label: 'Entraînement',
                    index: 1,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.people_rounded,
                    label: 'Social',
                    index: 2,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.restaurant_rounded,
                    label: 'Nutrition',
                    index: 3,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.favorite_rounded,
                    label: 'Santé',
                    index: 4,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    index: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? FGColors.accent : FGColors.textSecondary,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? FGColors.accent : FGColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
