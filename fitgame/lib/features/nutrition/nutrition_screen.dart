import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/supabase_service.dart';
import 'sheets/goal_selector_sheet.dart';
import 'sheets/food_library_sheet.dart';
import 'sheets/edit_food_sheet.dart';
import 'sheets/duplicate_day_sheet.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/meal_card.dart';
import 'widgets/macro_dashboard.dart';
import 'widgets/day_selector.dart';
import 'create/diet_creation_flow.dart';

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
  Set<int> _trainingDays = {0, 2, 4}; // Mon, Wed, Fri

  // Goal type: 'bulk', 'cut', 'maintain'
  String _goalType = 'bulk';

  // Supabase state
  List<Map<String, dynamic>> _myDietPlans = [];
  List<Map<String, dynamic>> _assignedDietPlans = [];
  Map<String, dynamic>? _activePlan; // Currently active diet plan
  String? _activePlanName;

  // Realtime listener reference
  void Function(Map<String, dynamic>)? _assignmentListener;

  // === MACRO TARGETS ===
  // Macro targets based on goal and training/rest day (mutable for coach plans)
  Map<String, Map<String, int>> _macroTargets = {
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

  // Weekly meal plan - each day has 4 meals (mutable for CRUD operations)
  // Real data - fetched from backend
  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _weeklyPlan = [
    // Monday
    {
      'meals': [
        {'name': 'Petit-déjeuner', 'icon': Icons.wb_sunny_rounded, 'foods': []},
        {'name': 'Déjeuner', 'icon': Icons.restaurant_rounded, 'foods': []},
        {'name': 'Collation', 'icon': Icons.apple, 'foods': []},
        {'name': 'Dîner', 'icon': Icons.nights_stay_rounded, 'foods': []},
      ],
    },
    // Tuesday
    {
      'meals': [
        {'name': 'Petit-déjeuner', 'icon': Icons.wb_sunny_rounded, 'foods': []},
        {'name': 'Déjeuner', 'icon': Icons.restaurant_rounded, 'foods': []},
        {'name': 'Collation', 'icon': Icons.apple, 'foods': []},
        {'name': 'Dîner', 'icon': Icons.nights_stay_rounded, 'foods': []},
      ],
    },
    // Wednesday
    {
      'meals': [
        {'name': 'Petit-déjeuner', 'icon': Icons.wb_sunny_rounded, 'foods': []},
        {'name': 'Déjeuner', 'icon': Icons.restaurant_rounded, 'foods': []},
        {'name': 'Collation', 'icon': Icons.apple, 'foods': []},
        {'name': 'Dîner', 'icon': Icons.nights_stay_rounded, 'foods': []},
      ],
    },
    // Thursday
    {
      'meals': [
        {'name': 'Petit-déjeuner', 'icon': Icons.wb_sunny_rounded, 'foods': []},
        {'name': 'Déjeuner', 'icon': Icons.restaurant_rounded, 'foods': []},
        {'name': 'Collation', 'icon': Icons.apple, 'foods': []},
        {'name': 'Dîner', 'icon': Icons.nights_stay_rounded, 'foods': []},
      ],
    },
    // Friday
    {
      'meals': [
        {'name': 'Petit-déjeuner', 'icon': Icons.wb_sunny_rounded, 'foods': []},
        {'name': 'Déjeuner', 'icon': Icons.restaurant_rounded, 'foods': []},
        {'name': 'Collation', 'icon': Icons.apple, 'foods': []},
        {'name': 'Dîner', 'icon': Icons.nights_stay_rounded, 'foods': []},
      ],
    },
    // Saturday
    {
      'meals': [
        {'name': 'Petit-déjeuner', 'icon': Icons.wb_sunny_rounded, 'foods': []},
        {'name': 'Déjeuner', 'icon': Icons.restaurant_rounded, 'foods': []},
        {'name': 'Collation', 'icon': Icons.apple, 'foods': []},
        {'name': 'Dîner', 'icon': Icons.nights_stay_rounded, 'foods': []},
      ],
    },
    // Sunday
    {
      'meals': [
        {'name': 'Petit-déjeuner', 'icon': Icons.wb_sunny_rounded, 'foods': []},
        {'name': 'Déjeuner', 'icon': Icons.restaurant_rounded, 'foods': []},
        {'name': 'Collation', 'icon': Icons.apple, 'foods': []},
        {'name': 'Dîner', 'icon': Icons.nights_stay_rounded, 'foods': []},
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

    _loadData();
    _subscribeToAssignments();
  }

  void _subscribeToAssignments() {
    _assignmentListener = (assignment) {
      // Only react to diet plan assignments
      if (assignment['diet_plan_id'] != null) {
        _loadData();

        // Show snackbar notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nouveau plan nutrition assigné par votre coach !'),
              backgroundColor: FGColors.accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    };
    SupabaseService.addAssignmentListener(_assignmentListener!);
  }

  Future<void> _loadData() async {
    if (!SupabaseService.isAuthenticated) {
      return;
    }

    try {
      final results = await Future.wait([
        SupabaseService.getDietPlans(),
        SupabaseService.getAssignedDietPlans(),
      ]);

      final myPlans = results[0];
      final assignedPlans = results[1];

      if (!mounted) return;

      setState(() {
        _myDietPlans = myPlans;
        _assignedDietPlans = assignedPlans;

        // If there's an assigned plan from coach, use it as active
        if (assignedPlans.isNotEmpty) {
          _applyDietPlan(assignedPlans.first, isFromCoach: true);
        } else if (myPlans.isNotEmpty) {
          // Otherwise use first own plan
          _applyDietPlan(myPlans.first, isFromCoach: false);
        }
      });
    } catch (e) {
      debugPrint('Error loading nutrition data: $e');
    }
  }

  void _applyDietPlan(Map<String, dynamic> plan, {required bool isFromCoach}) {
    _activePlan = plan;
    _activePlanName = plan['name'] as String?;

    // Set goal type from plan
    final goal = plan['goal'] as String?;
    if (goal != null) {
      _goalType = goal;
    }

    // Update calorie targets from plan
    final trainingCal = plan['training_calories'] as int?;
    final restCal = plan['rest_calories'] as int?;
    final trainingMacros = plan['training_macros'] as Map<String, dynamic>?;

    if (trainingCal != null && restCal != null) {
      // Update macro targets based on plan
      _macroTargets[_goalType] = {
        'training': trainingCal,
        'rest': restCal,
        'protein': trainingMacros?['protein'] as int? ?? 180,
        'carbs': trainingMacros?['carbs'] as int? ?? 300,
        'fat': trainingMacros?['fat'] as int? ?? 80,
      };
    }

    // Apply meals from plan if available
    final planMeals = plan['meals'] as List?;
    if (planMeals != null && planMeals.isNotEmpty) {
      _applyMealsFromPlan(planMeals);
    }
  }

  void _applyMealsFromPlan(List planMeals) {
    // Convert plan meals to weekly plan format
    // Plan meals are templates - apply to all days based on training/rest
    final trainingDayMeals = planMeals.map((meal) {
      final foods = (meal['foods'] as List? ?? []).map((food) {
        return {
          'name': food['name'] ?? '',
          'quantity': food['quantity'] ?? '',
          'cal': food['calories'] ?? food['cal'] ?? 0,
          'p': food['protein'] ?? food['p'] ?? 0,
          'c': food['carbs'] ?? food['c'] ?? 0,
          'f': food['fat'] ?? food['f'] ?? 0,
        };
      }).toList();

      return {
        'name': meal['name'] ?? 'Repas',
        'icon': _getMealIcon(meal['name'] as String? ?? ''),
        'foods': foods,
      };
    }).toList();

    // Apply to training days
    for (int i = 0; i < 7; i++) {
      if (_trainingDays.contains(i)) {
        if (trainingDayMeals.isNotEmpty) {
          _weeklyPlan[i]['meals'] = trainingDayMeals.map((meal) {
            return {
              'name': meal['name'],
              'icon': meal['icon'],
              'foods': (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f)).toList(),
            };
          }).toList();
        }
      } else {
        // Rest days get the same meals for now (could be different in future)
        if (trainingDayMeals.isNotEmpty) {
          _weeklyPlan[i]['meals'] = trainingDayMeals.map((meal) {
            return {
              'name': meal['name'],
              'icon': meal['icon'],
              'foods': (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f)).toList(),
            };
          }).toList();
        }
      }
    }
  }

  IconData _getMealIcon(String mealName) {
    final lower = mealName.toLowerCase();
    if (lower.contains('petit') || lower.contains('breakfast')) {
      return Icons.wb_sunny_rounded;
    } else if (lower.contains('déjeuner') || lower.contains('lunch')) {
      return Icons.restaurant_rounded;
    } else if (lower.contains('collation') || lower.contains('snack')) {
      return Icons.apple;
    } else if (lower.contains('dîner') || lower.contains('dinner')) {
      return Icons.nights_stay_rounded;
    }
    return Icons.restaurant_rounded;
  }

  bool get _hasMultiplePlans =>
      _myDietPlans.length + _assignedDietPlans.length > 1;

  void _showPlanSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: FGColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FGColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Row(
                  children: [
                    Text('Mes plans nutrition', style: FGTypography.h3),
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  children: [
                    // Coach plans section
                    if (_assignedDietPlans.isNotEmpty) ...[
                      _buildPlanSectionHeader(
                        'Du coach',
                        Icons.person_outline,
                        FGColors.accent,
                      ),
                      const SizedBox(height: Spacing.sm),
                      ..._assignedDietPlans.map((plan) => Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.md),
                            child: _buildPlanItem(plan, isFromCoach: true),
                          )),
                      const SizedBox(height: Spacing.lg),
                    ],
                    // My plans section
                    if (_myDietPlans.isNotEmpty) ...[
                      _buildPlanSectionHeader(
                        'Mes plans',
                        Icons.restaurant_menu,
                        FGColors.textSecondary,
                      ),
                      const SizedBox(height: Spacing.sm),
                      ..._myDietPlans.map((plan) => Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.md),
                            child: _buildPlanItem(plan, isFromCoach: false),
                          )),
                    ],
                    const SizedBox(height: Spacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Spacing.sm),
        Text(
          title.toUpperCase(),
          style: FGTypography.caption.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanItem(Map<String, dynamic> plan, {required bool isFromCoach}) {
    final isActive = _activePlan == plan;
    final name = plan['name'] as String? ?? 'Sans nom';
    final goal = plan['goal'] as String?;
    final trainingCal = plan['training_calories'] as int?;

    String goalLabel = '';
    if (goal == 'bulk') goalLabel = 'Prise de masse';
    if (goal == 'cut') goalLabel = 'Sèche';
    if (goal == 'maintain') goalLabel = 'Maintien';

    return GestureDetector(
      onTap: () {
        setState(() {
          _applyDietPlan(plan, isFromCoach: isFromCoach);
        });
        Navigator.pop(context);
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan "$name" activé'),
            backgroundColor: FGColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: isActive
              ? FGColors.success.withValues(alpha: 0.08)
              : isFromCoach
                  ? FGColors.accent.withValues(alpha: 0.05)
                  : FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.lg),
          border: Border.all(
            color: isActive
                ? FGColors.success.withValues(alpha: 0.3)
                : isFromCoach
                    ? FGColors.accent.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? FGColors.success.withValues(alpha: 0.2)
                    : isFromCoach
                        ? FGColors.accent.withValues(alpha: 0.15)
                        : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Icon(
                isActive
                    ? Icons.check_rounded
                    : isFromCoach
                        ? Icons.person_outline
                        : Icons.restaurant_menu,
                color: isActive
                    ? FGColors.success
                    : isFromCoach
                        ? FGColors.accent
                        : FGColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: FGTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: Spacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FGColors.success,
                            borderRadius: BorderRadius.circular(Spacing.xs),
                          ),
                          child: Text(
                            'ACTIF',
                            style: FGTypography.caption.copyWith(
                              fontSize: 9,
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '$goalLabel${trainingCal != null ? ' • $trainingCal kcal' : ''}',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isActive)
              const Icon(
                Icons.chevron_right_rounded,
                color: FGColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_assignmentListener != null) {
      SupabaseService.removeAssignmentListener(_assignmentListener!);
    }
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
    final isCoachPlan = _activePlan != null && _assignedDietPlans.contains(_activePlan);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'NUTRITION',
                    style: FGTypography.caption.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textSecondary,
                    ),
                  ),
                  if (isCoachPlan) ...[
                    const SizedBox(width: Spacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: FGColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(Spacing.xs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 10,
                            color: FGColors.accent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'COACH',
                            style: FGTypography.caption.copyWith(
                              fontSize: 8,
                              color: FGColors.accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Spacing.xs),
              GestureDetector(
                onTap: _hasMultiplePlans ? _showPlanSelector : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _activePlanName ?? 'Plan semaine',
                        style: FGTypography.h2.copyWith(fontSize: 24),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_hasMultiplePlans) ...[
                      const SizedBox(width: Spacing.xs),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: FGColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
            // Create diet button
            GestureDetector(
              onTap: () => _openDietCreation(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2ECC71),
                      const Color(0xFF2ECC71).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: FGColors.textOnAccent,
                  size: 24,
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
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'ENTRAÎNEMENT',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textOnAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
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
            onTap: () => _shareDayPlan(dayIndex),
          ),
        ),
      ],
    );
  }

  // ============================================
  // NAVIGATION
  // ============================================

  void _openDietCreation() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DietCreationFlow(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
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

  void _shareDayPlan(int dayIndex) {
    HapticFeedback.lightImpact();

    final dayName = _dayFullNames[dayIndex];
    final dayPlan = _weeklyPlan[dayIndex];
    final totals = _getDayTotals(dayIndex);
    final isTraining = _trainingDays.contains(dayIndex);

    final buffer = StringBuffer();
    buffer.writeln('📅 $dayName ${isTraining ? "(Training)" : "(Rest)"}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();

    for (final meal in dayPlan['meals'] as List) {
      buffer.writeln('${_getMealEmoji(meal['name'] as String)} ${meal['name']}');
      for (final food in meal['foods'] as List) {
        buffer.writeln('  • ${food['name']} (${food['quantity']})');
        buffer.writeln('    ${food['cal']} kcal | P:${food['p']}g C:${food['c']}g F:${food['f']}g');
      }
      buffer.writeln();
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 Total: ${totals['cal']} kcal');
    buffer.writeln('🥩 Protéines: ${totals['p']}g');
    buffer.writeln('🍚 Glucides: ${totals['c']}g');
    buffer.writeln('🥑 Lipides: ${totals['f']}g');
    buffer.writeln();
    buffer.writeln('Généré avec FitGame Pro 💪');

    Share.share(buffer.toString());
  }

  String _getMealEmoji(String mealName) {
    switch (mealName) {
      case 'Petit-déjeuner':
        return '🌅';
      case 'Déjeuner':
        return '🍽️';
      case 'Collation':
        return '🍎';
      case 'Dîner':
        return '🌙';
      default:
        return '🍴';
    }
  }

  void _showFoodLibrary(int dayIndex, String mealName) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FoodLibrarySheet(
        onSelectFood: (food) {
          _addFoodToMeal(dayIndex, mealName, food);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addFoodToMeal(int dayIndex, String mealName, Map<String, dynamic> food) {
    setState(() {
      final meals = _weeklyPlan[dayIndex]['meals'] as List;
      for (final meal in meals) {
        if (meal['name'] == mealName) {
          (meal['foods'] as List).add(Map<String, dynamic>.from(food));
          break;
        }
      }
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food['name']} ajouté à $mealName'),
        backgroundColor: FGColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
          _updateFood(dayIndex, mealName, food, updatedFood);
          Navigator.pop(context);
        },
        onDelete: () {
          _deleteFood(dayIndex, mealName, food);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _updateFood(int dayIndex, String mealName, Map<String, dynamic> oldFood, Map<String, dynamic> newFood) {
    setState(() {
      final meals = _weeklyPlan[dayIndex]['meals'] as List;
      for (final meal in meals) {
        if (meal['name'] == mealName) {
          final foods = meal['foods'] as List;
          final index = foods.indexOf(oldFood);
          if (index != -1) {
            foods[index] = Map<String, dynamic>.from(newFood);
          }
          break;
        }
      }
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newFood['name']} mis à jour'),
        backgroundColor: FGColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _deleteFood(int dayIndex, String mealName, Map<String, dynamic> food) {
    setState(() {
      final meals = _weeklyPlan[dayIndex]['meals'] as List;
      for (final meal in meals) {
        if (meal['name'] == mealName) {
          (meal['foods'] as List).remove(food);
          break;
        }
      }
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food['name']} supprimé'),
        backgroundColor: FGColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
          _duplicateDayToTargets(dayIndex, targetDays);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _duplicateDayToTargets(int sourceIndex, List<int> targetDays) {
    setState(() {
      final sourceMeals = _weeklyPlan[sourceIndex]['meals'] as List;
      for (final targetIndex in targetDays) {
        if (targetIndex != sourceIndex) {
          // Deep copy meals to target day
          _weeklyPlan[targetIndex]['meals'] = sourceMeals.map((meal) {
            return {
              'name': meal['name'],
              'icon': meal['icon'],
              'foods': (meal['foods'] as List).map((food) {
                return Map<String, dynamic>.from(food);
              }).toList(),
            };
          }).toList();
        }
      }
    });
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Jour dupliqué vers ${targetDays.length} jour(s)'),
        backgroundColor: FGColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
              _resetDay(dayIndex);
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

  void _resetDay(int dayIndex) {
    setState(() {
      final meals = _weeklyPlan[dayIndex]['meals'] as List;
      for (final meal in meals) {
        (meal['foods'] as List).clear();
      }
    });
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_dayFullNames[dayIndex]} réinitialisé'),
        backgroundColor: FGColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}



