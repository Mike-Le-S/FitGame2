import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/fg_colors.dart';
import 'features/home/home_screen.dart';
import 'features/workout/workout_screen.dart';
import 'features/health/health_screen.dart';
import 'features/nutrition/nutrition_screen.dart';
import 'features/profile/profile_screen.dart';

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
      home: const MainNavigation(),
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

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutScreen(),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.fitness_center_rounded,
                  label: 'Entraînement',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.restaurant_rounded,
                  label: 'Nutrition',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.favorite_rounded,
                  label: 'Santé',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  index: 4,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? FGColors.accent : FGColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? FGColors.accent : FGColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
