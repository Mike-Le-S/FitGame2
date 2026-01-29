import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import 'sheets/goal_selector_sheet.dart';
import 'sheets/generate_ai_sheet.dart';
import 'sheets/food_library_sheet.dart';
import 'sheets/edit_food_sheet.dart';
import 'sheets/duplicate_day_sheet.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/meal_card.dart';
import 'widgets/macro_dashboard.dart';
import 'widgets/day_selector.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ringController;
  late PageController _dayPageController;

  int _selectedDayIndex = 0; // 0 = Monday

  // Training days (orange glow)
  final Set<int> _trainingDays = {0, 2, 4}; // Mon, Wed, Fri

  // Goal type: 'bulk', 'cut', 'maintain'
  String _goalType = 'bulk';

  // === MOCK DATA ===
  // Macro targets based on goal and training/rest day
  Map<String, Map<String, int>> get _macroTargets => {
        'bulk': {
          'training': 3200,
          'rest': 2800,
          'protein': 180,
          'carbs': 380,
          'fat': 90,
        },
        'cut': {
          'training': 2400,
          'rest': 2000,
          'protein': 200,
          'carbs': 200,
          'fat': 70,
        },
        'maintain': {
          'training': 2800,
          'rest': 2500,
          'protein': 170,
          'carbs': 300,
          'fat': 80,
        },
      };

  // Weekly meal plan - each day has 4 meals
  final List<Map<String, dynamic>> _weeklyPlan = [
    // Monday (Training)
    {
      'meals': [
        {
          'name': 'Petit-déjeuner',
          'icon': Icons.wb_sunny_rounded,
          'foods': [
            {'name': 'Flocons d\'avoine', 'quantity': '80g', 'cal': 304, 'p': 12, 'c': 54, 'f': 6},
            {'name': 'Banane', 'quantity': '1 moyenne', 'cal': 105, 'p': 1, 'c': 27, 'f': 0},
            {'name': 'Whey Protein', 'quantity': '30g', 'cal': 120, 'p': 24, 'c': 3, 'f': 1},
            {'name': 'Beurre de cacahuète', 'quantity': '20g', 'cal': 118, 'p': 5, 'c': 4, 'f': 10},
          ],
        },
        {
          'name': 'Déjeuner',
          'icon': Icons.restaurant_rounded,
          'foods': [
            {'name': 'Poulet grillé', 'quantity': '200g', 'cal': 330, 'p': 62, 'c': 0, 'f': 7},
            {'name': 'Riz basmati', 'quantity': '150g cuit', 'cal': 195, 'p': 4, 'c': 45, 'f': 0},
            {'name': 'Brocolis', 'quantity': '150g', 'cal': 51, 'p': 4, 'c': 10, 'f': 1},
            {'name': 'Huile d\'olive', 'quantity': '15ml', 'cal': 120, 'p': 0, 'c': 0, 'f': 14},
          ],
        },
        {
          'name': 'Collation',
          'icon': Icons.apple,
          'foods': [
            {'name': 'Fromage blanc 0%', 'quantity': '200g', 'cal': 100, 'p': 16, 'c': 8, 'f': 0},
            {'name': 'Amandes', 'quantity': '30g', 'cal': 174, 'p': 6, 'c': 6, 'f': 15},
            {'name': 'Myrtilles', 'quantity': '100g', 'cal': 57, 'p': 1, 'c': 14, 'f': 0},
          ],
        },
        {
          'name': 'Dîner',
          'icon': Icons.nights_stay_rounded,
          'foods': [
            {'name': 'Saumon', 'quantity': '180g', 'cal': 367, 'p': 40, 'c': 0, 'f': 22},
            {'name': 'Patate douce', 'quantity': '200g', 'cal': 172, 'p': 3, 'c': 40, 'f': 0},
            {'name': 'Salade verte', 'quantity': '100g', 'cal': 15, 'p': 1, 'c': 3, 'f': 0},
            {'name': 'Vinaigrette', 'quantity': '20ml', 'cal': 90, 'p': 0, 'c': 1, 'f': 10},
          ],
        },
      ],
    },
    // Tuesday (Rest)
    {
      'meals': [
        {
          'name': 'Petit-déjeuner',
          'icon': Icons.wb_sunny_rounded,
          'foods': [
            {'name': 'Oeufs brouillés', 'quantity': '3 oeufs', 'cal': 219, 'p': 18, 'c': 2, 'f': 15},
            {'name': 'Pain complet', 'quantity': '2 tranches', 'cal': 160, 'p': 8, 'c': 28, 'f': 2},
            {'name': 'Avocat', 'quantity': '1/2', 'cal': 160, 'p': 2, 'c': 8, 'f': 15},
          ],
        },
        {
          'name': 'Déjeuner',
          'icon': Icons.restaurant_rounded,
          'foods': [
            {'name': 'Boeuf haché 5%', 'quantity': '150g', 'cal': 232, 'p': 32, 'c': 0, 'f': 11},
            {'name': 'Pâtes complètes', 'quantity': '100g sec', 'cal': 348, 'p': 14, 'c': 66, 'f': 3},
            {'name': 'Sauce tomate', 'quantity': '100g', 'cal': 32, 'p': 2, 'c': 6, 'f': 0},
          ],
        },
        {
          'name': 'Collation',
          'icon': Icons.apple,
          'foods': [
            {'name': 'Yaourt grec', 'quantity': '170g', 'cal': 100, 'p': 17, 'c': 6, 'f': 1},
            {'name': 'Miel', 'quantity': '15g', 'cal': 46, 'p': 0, 'c': 12, 'f': 0},
          ],
        },
        {
          'name': 'Dîner',
          'icon': Icons.nights_stay_rounded,
          'foods': [
            {'name': 'Thon en conserve', 'quantity': '140g', 'cal': 154, 'p': 34, 'c': 0, 'f': 1},
            {'name': 'Quinoa', 'quantity': '100g cuit', 'cal': 120, 'p': 4, 'c': 21, 'f': 2},
            {'name': 'Légumes grillés', 'quantity': '200g', 'cal': 80, 'p': 3, 'c': 16, 'f': 1},
          ],
        },
      ],
    },
    // Wednesday (Training)
    {
      'meals': [
        {
          'name': 'Petit-déjeuner',
          'icon': Icons.wb_sunny_rounded,
          'foods': [
            {'name': 'Pancakes protéinés', 'quantity': '3 pancakes', 'cal': 350, 'p': 30, 'c': 40, 'f': 8},
            {'name': 'Sirop d\'érable', 'quantity': '30ml', 'cal': 78, 'p': 0, 'c': 20, 'f': 0},
            {'name': 'Fruits rouges', 'quantity': '100g', 'cal': 43, 'p': 1, 'c': 10, 'f': 0},
          ],
        },
        {
          'name': 'Déjeuner',
          'icon': Icons.restaurant_rounded,
          'foods': [
            {'name': 'Escalope de dinde', 'quantity': '200g', 'cal': 236, 'p': 50, 'c': 0, 'f': 3},
            {'name': 'Riz complet', 'quantity': '150g cuit', 'cal': 166, 'p': 4, 'c': 35, 'f': 1},
            {'name': 'Haricots verts', 'quantity': '150g', 'cal': 47, 'p': 3, 'c': 10, 'f': 0},
          ],
        },
        {
          'name': 'Collation',
          'icon': Icons.apple,
          'foods': [
            {'name': 'Shake post-training', 'quantity': '1 shaker', 'cal': 280, 'p': 35, 'c': 30, 'f': 3},
            {'name': 'Banane', 'quantity': '1 moyenne', 'cal': 105, 'p': 1, 'c': 27, 'f': 0},
          ],
        },
        {
          'name': 'Dîner',
          'icon': Icons.nights_stay_rounded,
          'foods': [
            {'name': 'Cabillaud', 'quantity': '200g', 'cal': 164, 'p': 36, 'c': 0, 'f': 1},
            {'name': 'Purée de pommes de terre', 'quantity': '200g', 'cal': 176, 'p': 3, 'c': 36, 'f': 3},
            {'name': 'Épinards', 'quantity': '100g', 'cal': 23, 'p': 3, 'c': 4, 'f': 0},
          ],
        },
      ],
    },
    // Thursday (Rest)
    {
      'meals': [
        {
          'name': 'Petit-déjeuner',
          'icon': Icons.wb_sunny_rounded,
          'foods': [
            {'name': 'Muesli', 'quantity': '60g', 'cal': 222, 'p': 6, 'c': 42, 'f': 4},
            {'name': 'Lait demi-écrémé', 'quantity': '200ml', 'cal': 92, 'p': 6, 'c': 10, 'f': 3},
            {'name': 'Pomme', 'quantity': '1 moyenne', 'cal': 95, 'p': 0, 'c': 25, 'f': 0},
          ],
        },
        {
          'name': 'Déjeuner',
          'icon': Icons.restaurant_rounded,
          'foods': [
            {'name': 'Tofu ferme', 'quantity': '150g', 'cal': 144, 'p': 15, 'c': 4, 'f': 8},
            {'name': 'Nouilles soba', 'quantity': '100g sec', 'cal': 336, 'p': 14, 'c': 74, 'f': 1},
            {'name': 'Légumes sautés', 'quantity': '150g', 'cal': 75, 'p': 3, 'c': 12, 'f': 2},
          ],
        },
        {
          'name': 'Collation',
          'icon': Icons.apple,
          'foods': [
            {'name': 'Cottage cheese', 'quantity': '150g', 'cal': 103, 'p': 14, 'c': 4, 'f': 4},
            {'name': 'Noix', 'quantity': '20g', 'cal': 131, 'p': 3, 'c': 3, 'f': 13},
          ],
        },
        {
          'name': 'Dîner',
          'icon': Icons.nights_stay_rounded,
          'foods': [
            {'name': 'Omelette', 'quantity': '4 oeufs', 'cal': 292, 'p': 24, 'c': 2, 'f': 20},
            {'name': 'Champignons', 'quantity': '100g', 'cal': 22, 'p': 3, 'c': 3, 'f': 0},
            {'name': 'Pain aux céréales', 'quantity': '50g', 'cal': 130, 'p': 5, 'c': 24, 'f': 2},
          ],
        },
      ],
    },
    // Friday (Training)
    {
      'meals': [
        {
          'name': 'Petit-déjeuner',
          'icon': Icons.wb_sunny_rounded,
          'foods': [
            {'name': 'Smoothie bowl', 'quantity': '1 bol', 'cal': 380, 'p': 25, 'c': 55, 'f': 8},
            {'name': 'Granola', 'quantity': '40g', 'cal': 180, 'p': 4, 'c': 28, 'f': 7},
          ],
        },
        {
          'name': 'Déjeuner',
          'icon': Icons.restaurant_rounded,
          'foods': [
            {'name': 'Filet de porc', 'quantity': '180g', 'cal': 234, 'p': 42, 'c': 0, 'f': 7},
            {'name': 'Boulgour', 'quantity': '100g cuit', 'cal': 83, 'p': 3, 'c': 19, 'f': 0},
            {'name': 'Courgettes grillées', 'quantity': '150g', 'cal': 27, 'p': 2, 'c': 5, 'f': 0},
          ],
        },
        {
          'name': 'Collation',
          'icon': Icons.apple,
          'foods': [
            {'name': 'Barre protéinée', 'quantity': '1 barre', 'cal': 220, 'p': 20, 'c': 22, 'f': 8},
            {'name': 'Orange', 'quantity': '1 moyenne', 'cal': 62, 'p': 1, 'c': 15, 'f': 0},
          ],
        },
        {
          'name': 'Dîner',
          'icon': Icons.nights_stay_rounded,
          'foods': [
            {'name': 'Crevettes', 'quantity': '200g', 'cal': 198, 'p': 46, 'c': 0, 'f': 2},
            {'name': 'Risotto', 'quantity': '200g', 'cal': 280, 'p': 6, 'c': 52, 'f': 6},
            {'name': 'Parmesan', 'quantity': '20g', 'cal': 83, 'p': 8, 'c': 1, 'f': 6},
          ],
        },
      ],
    },
    // Saturday (Rest)
    {
      'meals': [
        {
          'name': 'Petit-déjeuner',
          'icon': Icons.wb_sunny_rounded,
          'foods': [
            {'name': 'Oeufs bénédicte', 'quantity': '2 oeufs', 'cal': 380, 'p': 18, 'c': 22, 'f': 25},
            {'name': 'Jus d\'orange', 'quantity': '200ml', 'cal': 90, 'p': 2, 'c': 21, 'f': 0},
          ],
        },
        {
          'name': 'Déjeuner',
          'icon': Icons.restaurant_rounded,
          'foods': [
            {'name': 'Salade César', 'quantity': '1 portion', 'cal': 350, 'p': 22, 'c': 12, 'f': 25},
            {'name': 'Pain ciabatta', 'quantity': '60g', 'cal': 158, 'p': 5, 'c': 32, 'f': 1},
          ],
        },
        {
          'name': 'Collation',
          'icon': Icons.apple,
          'foods': [
            {'name': 'Houmous', 'quantity': '100g', 'cal': 166, 'p': 8, 'c': 14, 'f': 10},
            {'name': 'Crudités', 'quantity': '150g', 'cal': 50, 'p': 2, 'c': 10, 'f': 0},
          ],
        },
        {
          'name': 'Dîner',
          'icon': Icons.nights_stay_rounded,
          'foods': [
            {'name': 'Pizza maison', 'quantity': '1/2 pizza', 'cal': 450, 'p': 20, 'c': 50, 'f': 18},
            {'name': 'Salade', 'quantity': '100g', 'cal': 20, 'p': 1, 'c': 4, 'f': 0},
          ],
        },
      ],
    },
    // Sunday (Rest)
    {
      'meals': [
        {
          'name': 'Petit-déjeuner',
          'icon': Icons.wb_sunny_rounded,
          'foods': [
            {'name': 'French toast', 'quantity': '3 tranches', 'cal': 340, 'p': 12, 'c': 42, 'f': 14},
            {'name': 'Bacon', 'quantity': '3 tranches', 'cal': 129, 'p': 9, 'c': 0, 'f': 10},
          ],
        },
        {
          'name': 'Déjeuner',
          'icon': Icons.restaurant_rounded,
          'foods': [
            {'name': 'Rôti de boeuf', 'quantity': '150g', 'cal': 280, 'p': 38, 'c': 0, 'f': 14},
            {'name': 'Gratin dauphinois', 'quantity': '150g', 'cal': 180, 'p': 5, 'c': 18, 'f': 10},
            {'name': 'Haricots', 'quantity': '100g', 'cal': 35, 'p': 2, 'c': 8, 'f': 0},
          ],
        },
        {
          'name': 'Collation',
          'icon': Icons.apple,
          'foods': [
            {'name': 'Fromage', 'quantity': '40g', 'cal': 160, 'p': 10, 'c': 1, 'f': 13},
            {'name': 'Raisins', 'quantity': '100g', 'cal': 69, 'p': 1, 'c': 18, 'f': 0},
          ],
        },
        {
          'name': 'Dîner',
          'icon': Icons.nights_stay_rounded,
          'foods': [
            {'name': 'Soupe de légumes', 'quantity': '300ml', 'cal': 90, 'p': 3, 'c': 15, 'f': 2},
            {'name': 'Tartine fromage', 'quantity': '2 tranches', 'cal': 240, 'p': 12, 'c': 24, 'f': 11},
          ],
        },
      ],
    },
  ];

  final List<String> _dayNames = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
  final List<String> _dayFullNames = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.05, end: 0.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _dayPageController = PageController(initialPage: _selectedDayIndex);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _dayPageController.dispose();
    super.dispose();
  }

  // Calculate daily totals
  Map<String, int> _getDayTotals(int dayIndex) {
    final dayPlan = _weeklyPlan[dayIndex];
    int totalCal = 0, totalP = 0, totalC = 0, totalF = 0;

    for (final meal in dayPlan['meals'] as List) {
      for (final food in meal['foods'] as List) {
        totalCal += food['cal'] as int;
        totalP += food['p'] as int;
        totalC += food['c'] as int;
        totalF += food['f'] as int;
      }
    }

    return {'cal': totalCal, 'p': totalP, 'c': totalC, 'f': totalF};
  }

  int _getCalorieTarget(int dayIndex) {
    final isTraining = _trainingDays.contains(dayIndex);
    final targets = _macroTargets[_goalType]!;
    return isTraining ? targets['training']! : targets['rest']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          _buildMeshGradient(),
          SafeArea(
            child: Column(
              children: [
                // Fixed header + day selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Spacing.lg),
                      _buildHeader(),
                      const SizedBox(height: Spacing.lg),
                      DaySelector(
                        selectedDayIndex: _selectedDayIndex,
                        trainingDays: _trainingDays.toList(),
                        dayNames: _dayNames,
                        pageController: _dayPageController,
                        onDaySelected: (index) {
                          setState(() => _selectedDayIndex = index);
                        },
                        getDayTotals: _getDayTotals,
                        getCalorieTarget: _getCalorieTarget,
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: PageView.builder(
                    controller: _dayPageController,
                    onPageChanged: (index) {
                      setState(() => _selectedDayIndex = index);
                      HapticFeedback.selectionClick();
                    },
                    itemCount: 7,
                    itemBuilder: (context, index) => _buildDayContent(index),
                  ),
                ),
              ],
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
            // Green/teal gradient for nutrition theme
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2ECC71).withValues(alpha: _pulseAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FGColors.accent.withValues(alpha: _pulseAnimation.value * 0.5),
                      Colors.transparent,
                    ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NUTRITION',
              style: FGTypography.caption.copyWith(
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: FGColors.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Plan semaine',
              style: FGTypography.h1.copyWith(fontSize: 32),
            ),
          ],
        ),
        Row(
          children: [
            // Goal selector chip
            GestureDetector(
              onTap: () => _showGoalSelector(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(Spacing.md),
                  border: Border.all(color: FGColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _goalType == 'bulk'
                          ? Icons.trending_up_rounded
                          : _goalType == 'cut'
                              ? Icons.trending_down_rounded
                              : Icons.remove_rounded,
                      color: FGColors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      _goalType == 'bulk'
                          ? 'Prise'
                          : _goalType == 'cut'
                              ? 'Sèche'
                              : 'Maintien',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            // AI Generate button
            GestureDetector(
              onTap: () => _showGenerateSheet(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FGColors.accent,
                      FGColors.accent.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  boxShadow: [
                    BoxShadow(
                      color: FGColors.accentGlow,
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: FGColors.textOnAccent,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildDayContent(int dayIndex) {
    final dayTotals = _getDayTotals(dayIndex);
    final isTraining = _trainingDays.contains(dayIndex);
    final target = _getCalorieTarget(dayIndex);
    final targets = _macroTargets[_goalType]!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day title + training badge
          Row(
            children: [
              Text(
                _dayFullNames[dayIndex],
                style: FGTypography.h2,
              ),
              const SizedBox(width: Spacing.sm),
              if (isTraining)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        FGColors.accent,
                        FGColors.accent.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(Spacing.xs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fitness_center_rounded,
                        color: FGColors.textOnAccent,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TRAINING',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textOnAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.lg),

          // Macro Dashboard
          MacroDashboard(
            totals: dayTotals,
            calorieTarget: target,
            targets: targets,
            animation: _ringController,
          ),
          const SizedBox(height: Spacing.lg),

          // Meals
          ..._buildMealCards(dayIndex),

          // Quick actions
          const SizedBox(height: Spacing.lg),
          _buildQuickActions(dayIndex),

          const SizedBox(height: Spacing.xxl),
        ],
      ),
    );
  }


  List<Widget> _buildMealCards(int dayIndex) {
    final dayPlan = _weeklyPlan[dayIndex];
    final meals = dayPlan['meals'] as List;

    return meals.map<Widget>((meal) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: MealCard(
          meal: meal,
          onAddFood: () => _showFoodLibrary(dayIndex, meal['name'] as String),
          onEditFood: (food) => _showEditFood(dayIndex, meal['name'] as String, food),
        ),
      );
    }).toList();
  }

  Widget _buildQuickActions(int dayIndex) {
    return Row(
      children: [
        Expanded(
          child: QuickActionButton(
            icon: Icons.copy_rounded,
            label: 'Dupliquer',
            onTap: () => _showDuplicateSheet(dayIndex),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: QuickActionButton(
            icon: Icons.refresh_rounded,
            label: 'Réinitialiser',
            onTap: () => _confirmReset(dayIndex),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: QuickActionButton(
            icon: Icons.share_rounded,
            label: 'Partager',
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Share functionality
            },
          ),
        ),
      ],
    );
  }

  // ============================================
  // BOTTOM SHEETS
  // ============================================

  void _showGoalSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalSelectorSheet(
        currentGoal: _goalType,
        onSelect: (goal) {
          setState(() => _goalType = goal);
          _ringController.reset();
          _ringController.forward();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showGenerateSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GenerateAISheet(
        onGenerate: (preferences) {
          // TODO: Implement AI generation
          Navigator.pop(context);
          _showGeneratingAnimation();
        },
      ),
    );
  }

  void _showGeneratingAnimation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(FGColors.accent),
              ),
            ),
            const SizedBox(width: Spacing.md),
            const Text('Génération du plan en cours...'),
          ],
        ),
        backgroundColor: FGColors.glassSurface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFoodLibrary(int dayIndex, String mealName) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FoodLibrarySheet(
        onSelectFood: (food) {
          // TODO: Add food to meal
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditFood(int dayIndex, String mealName, Map<String, dynamic> food) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EditFoodSheet(
        food: food,
        onSave: (updatedFood) {
          // TODO: Update food
          Navigator.pop(context);
        },
        onDelete: () {
          // TODO: Delete food
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDuplicateSheet(int dayIndex) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DuplicateDaySheet(
        sourceDay: dayIndex,
        dayNames: _dayFullNames,
        onDuplicate: (targetDays) {
          // TODO: Duplicate to selected days
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jour dupliqué vers ${targetDays.length} jour(s)'),
              backgroundColor: FGColors.success,
            ),
          );
        },
      ),
    );
  }

  void _confirmReset(int dayIndex) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FGColors.glassSurface,
        title: Text(
          'Réinitialiser ${_dayFullNames[dayIndex]} ?',
          style: FGTypography.h3,
        ),
        content: Text(
          'Tous les repas de ce jour seront supprimés.',
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
              // TODO: Reset day
              Navigator.pop(context);
            },
            child: Text(
              'Réinitialiser',
              style: FGTypography.body.copyWith(color: FGColors.error),
            ),
          ),
        ],
      ),
    );
  }
}



