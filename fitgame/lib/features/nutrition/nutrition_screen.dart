import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/health_service.dart';
import 'sheets/edit_food_sheet.dart';
import 'sheets/duplicate_day_sheet.dart';
import 'sheets/edit_plan_sheet.dart';
import 'sheets/food_add_sheet.dart';
import 'sheets/barcode_scanner_sheet.dart';
import 'sheets/contribute_food_sheet.dart';
import 'sheets/favorite_foods_sheet.dart';
import 'sheets/meal_templates_sheet.dart';
import 'sheets/plans_modal_sheet.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/meal_card.dart';
import 'widgets/macro_dashboard.dart';
import 'widgets/day_selector.dart';
import 'widgets/calorie_balance_card.dart';
import 'create/new_plan_creation_flow.dart';
import '../../shared/widgets/fg_mesh_gradient.dart';

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

  // Supabase state
  List<Map<String, dynamic>> _myDietPlans = [];
  List<Map<String, dynamic>> _assignedDietPlans = [];
  Map<String, dynamic>? _activePlan; // Currently active diet plan
  final Map<int, String> _dayTypeIds = {}; // dayIndex → day_type_id
  String? _activePlanName;

  // Realtime listener reference
  void Function(Map<String, dynamic>)? _assignmentListener;

  // Health data for calorie balance
  int _caloriesBurned = 0;
  int? _caloriesPredicted;
  bool _isLoadingHealth = true;

  // Daily tracking (separate from plan)
  Map<String, dynamic>? _todayLog;
  List<Map<String, dynamic>> _trackingWeeklyPlan = [];
  final bool _isTrackingMode = true; // true = editing daily log, false = editing plan

  // === MACRO TARGETS ===
  // Macro targets based on goal and training/rest day (mutable for coach plans)
  final Map<String, Map<String, int>> _macroTargets = {
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
    _loadHealthData();
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

    await _loadDietPlans();
    // Load today's tracking log
    await _loadOrCreateTodayLog();
  }

  Future<void> _loadDietPlans() async {
    if (!SupabaseService.isAuthenticated) return;

    try {
      final results = await Future.wait([
        SupabaseService.getDietPlans(),
        SupabaseService.getAssignedDietPlans(),
        SupabaseService.getActiveDietPlan(),
      ]);

      final myPlans = results[0] as List<Map<String, dynamic>>;
      final assignedPlans = results[1] as List<Map<String, dynamic>>;
      final activePlan = results[2] as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        _myDietPlans = myPlans;
        _assignedDietPlans = assignedPlans;

        // Use the active plan if set
        if (activePlan != null) {
          _applyDietPlan(activePlan, isFromCoach: false);
        } else if (assignedPlans.isNotEmpty) {
          // If there's an assigned plan from coach, use it as active
          _applyDietPlan(assignedPlans.first, isFromCoach: true);
        } else if (myPlans.isNotEmpty) {
          // Otherwise use first own plan
          _applyDietPlan(myPlans.first, isFromCoach: false);
        } else {
          // No plan at all
          _activePlan = null;
          _activePlanName = null;
        }
      });
    } catch (e) {
      debugPrint('Error loading nutrition data: $e');
    }
  }

  Future<void> _loadOrCreateTodayLog() async {
    if (!SupabaseService.isAuthenticated) return;

    final today = DateTime.now();

    try {
      // Try to load existing log
      var log = await SupabaseService.getNutritionLog(today);

      if (log == null && _activePlan != null) {
        // Create new log from active plan
        final planMeals = _weeklyPlan[_getTodayIndex()]['meals'] as List;
        final mealsForLog = planMeals.map((meal) {
          return {
            'name': meal['name'],
            'foods': (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f)).toList(),
            'plan_foods': (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f)).toList(),
          };
        }).toList();

        log = await SupabaseService.upsertNutritionLog(
          date: today,
          dietPlanId: _activePlan!['id'] as String?,
          meals: mealsForLog,
          caloriesConsumed: _getDayTotals(_getTodayIndex())['cal'] ?? 0,
        );
      }

      if (mounted && log != null) {
        setState(() {
          _todayLog = log;
          _applyLogToTrackingPlan(log!);
        });
      }
    } catch (e) {
      debugPrint('Error loading daily log: $e');
    }
  }

  void _applyLogToTrackingPlan(Map<String, dynamic> log) {
    final logMeals = log['meals'] as List? ?? [];

    // Create tracking weekly plan from log for today
    _trackingWeeklyPlan = List.generate(7, (index) {
      if (index == _getTodayIndex()) {
        return {
          'meals': logMeals.map((meal) {
            return {
              'name': meal['name'],
              'icon': _getMealIcon(meal['name'] as String? ?? ''),
              'foods': (meal['foods'] as List? ?? []).map((f) => Map<String, dynamic>.from(f)).toList(),
              'plan_foods': (meal['plan_foods'] as List? ?? []).map((f) => Map<String, dynamic>.from(f)).toList(),
            };
          }).toList(),
        };
      }
      return _weeklyPlan.isNotEmpty ? _weeklyPlan[index] : {'meals': []};
    });
  }

  int _getTodayIndex() {
    return DateTime.now().weekday - 1; // 0 = Monday
  }

  bool get _isToday => _selectedDayIndex == _getTodayIndex();

  Future<void> _loadHealthData() async {
    setState(() => _isLoadingHealth = true);

    try {
      final healthService = HealthService();

      // Check/request authorization
      if (!healthService.isAuthorized) {
        await healthService.requestAuthorization();
      }

      // Get today's activity data
      final today = DateTime.now();
      final activity = await healthService.getActivityData(today);

      // Get prediction
      final predicted = await healthService.predictDailyCalories();

      if (mounted) {
        setState(() {
          _caloriesBurned = activity?.totalCaloriesBurned ?? 0;
          _caloriesPredicted = predicted;
          _isLoadingHealth = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading health data: $e');
      if (mounted) {
        setState(() => _isLoadingHealth = false);
      }
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

    // Load day types and weekly schedule from Supabase
    _loadDayTypesAndSchedule(plan['id'] as String);
  }

  Future<void> _loadDayTypesAndSchedule(String planId) async {
    try {
      final schedule = await SupabaseService.getWeeklySchedule(planId);

      if (!mounted) return;

      // Build weekly plan from schedule
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        // Find the schedule entry for this day
        final daySchedule = schedule.firstWhere(
          (s) => s['day_of_week'] == dayIndex,
          orElse: () => <String, dynamic>{},
        );

        final dayType = daySchedule['day_type'] as Map<String, dynamic>?;
        if (dayType != null) {
          // Store day_type_id for saving back later
          final dayTypeId = dayType['id'] as String?;
          if (dayTypeId != null) {
            _dayTypeIds[dayIndex] = dayTypeId;
          }

          final meals = (dayType['meals'] as List? ?? []).map((meal) {
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

          if (meals.isNotEmpty) {
            setState(() {
              _weeklyPlan[dayIndex]['meals'] = meals;
            });
          }

          // Use is_training flag from day_type
          if (dayType['is_training'] == true) {
            _trainingDays.add(dayIndex);
          } else {
            _trainingDays.remove(dayIndex);
          }
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading day types: $e');
      // Fallback to old behavior with plan meals
      final planMeals = _activePlan?['meals'] as List?;
      if (planMeals != null && planMeals.isNotEmpty) {
        _applyMealsFromPlanLegacy(planMeals);
      }
    }
  }

  void _applyMealsFromPlanLegacy(List planMeals) {
    // Convert plan meals to weekly plan format (legacy support)
    final dayMeals = planMeals.map((meal) {
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

    // Apply to all days
    for (int i = 0; i < 7; i++) {
      if (dayMeals.isNotEmpty) {
        _weeklyPlan[i]['meals'] = dayMeals.map((meal) {
          return {
            'name': meal['name'],
            'icon': meal['icon'],
            'foods': (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f)).toList(),
          };
        }).toList();
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
            // Edit button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context); // Close selector first
                _showEditPlanSheet(plan, isFromCoach: isFromCoach);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: FGColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
            if (!isActive) ...[
              const SizedBox(width: Spacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: FGColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditPlanSheet(Map<String, dynamic> plan, {required bool isFromCoach}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EditPlanSheet(
        plan: plan,
        isFromCoach: isFromCoach,
        onSave: () {
          Navigator.pop(context);
          _loadData(); // Reload to get updated data
        },
        onDelete: () {
          Navigator.pop(context);
          _handlePlanDeleted(plan);
        },
      ),
    );
  }

  void _handlePlanDeleted(Map<String, dynamic> deletedPlan) {
    // If deleted plan was active, need to select another
    final wasActive = _activePlan == deletedPlan;

    // Reload data
    _loadData();

    if (wasActive) {
      // Will auto-select first available plan in _loadData
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Plan supprimé - nouveau plan activé'),
          backgroundColor: FGColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
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
    // Use tracking plan for today, regular plan for other days
    final targetPlan = (_isTrackingMode && dayIndex == _getTodayIndex())
        ? _trackingWeeklyPlan
        : _weeklyPlan;

    if (targetPlan.isEmpty || dayIndex >= targetPlan.length) {
      return {'cal': 0, 'p': 0, 'c': 0, 'f': 0};
    }

    final dayPlan = targetPlan[dayIndex];
    int totalCal = 0, totalP = 0, totalC = 0, totalF = 0;

    for (final meal in dayPlan['meals'] as List? ?? []) {
      for (final food in meal['foods'] as List) {
        totalCal += food['cal'] as int? ?? 0;
        totalP += food['p'] as int? ?? 0;
        totalC += food['c'] as int? ?? 0;
        totalF += food['f'] as int? ?? 0;
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
          FGMeshGradient.nutrition(animation: _pulseAnimation),
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
            // Mon plan button
            GestureDetector(
              onTap: () => _showPlansModal(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _activePlan != null
                      ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
                      : FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(Spacing.md),
                  border: Border.all(
                    color: _activePlan != null
                        ? const Color(0xFF2ECC71).withValues(alpha: 0.4)
                        : FGColors.glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      color: _activePlan != null
                          ? const Color(0xFF2ECC71)
                          : FGColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      _activePlan != null ? 'Mon plan' : 'Aucun plan',
                      style: FGTypography.caption.copyWith(
                        color: _activePlan != null
                            ? const Color(0xFF2ECC71)
                            : FGColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _activePlan != null
                          ? const Color(0xFF2ECC71)
                          : FGColors.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            // Create diet button
            GestureDetector(
              onTap: () => _openPlanCreation(),
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
          // Day title + training/rest toggle
          Row(
            children: [
              Text(
                _dayFullNames[dayIndex],
                style: FGTypography.h2,
              ),
              const SizedBox(width: Spacing.sm),
              // Tappable training/rest badge
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (_trainingDays.contains(dayIndex)) {
                      _trainingDays.remove(dayIndex);
                    } else {
                      _trainingDays.add(dayIndex);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: isTraining
                        ? LinearGradient(
                            colors: [
                              FGColors.accent,
                              FGColors.accent.withValues(alpha: 0.7),
                            ],
                          )
                        : null,
                    color: isTraining ? null : FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.xs),
                    border: isTraining
                        ? null
                        : Border.all(color: FGColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTraining
                            ? Icons.fitness_center_rounded
                            : Icons.bedtime_rounded,
                        color: isTraining
                            ? FGColors.textOnAccent
                            : FGColors.textSecondary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTraining ? 'TRAINING' : 'REPOS',
                        style: FGTypography.caption.copyWith(
                          color: isTraining
                              ? FGColors.textOnAccent
                              : FGColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: isTraining
                            ? FGColors.textOnAccent.withValues(alpha: 0.7)
                            : FGColors.textSecondary.withValues(alpha: 0.7),
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),

          // Calorie Balance Card
          CalorieBalanceCard(
            caloriesConsumed: dayTotals['cal'] ?? 0,
            caloriesBurned: _caloriesBurned,
            caloriesPredicted: _caloriesPredicted,
            calorieTarget: target,
            goalType: _goalType,
            isLoading: _isLoadingHealth,
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
    // Use tracking plan for today, regular plan for other days
    final targetPlan = (_isTrackingMode && dayIndex == _getTodayIndex())
        ? _trackingWeeklyPlan
        : _weeklyPlan;

    if (targetPlan.isEmpty || dayIndex >= targetPlan.length) {
      return [const SizedBox.shrink()];
    }

    final dayPlan = targetPlan[dayIndex];
    final meals = dayPlan['meals'] as List;

    final widgets = <Widget>[];

    for (int i = 0; i < meals.length; i++) {
      final meal = meals[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: MealCard(
            meal: meal,
            onAddFood: () => _showFoodLibrary(dayIndex, meal['name'] as String),
            onEditFood: (food) => _showEditFood(dayIndex, meal['name'] as String, food),
            canDelete: meals.length > 1, // Can delete if more than 1 meal
            onDelete: meals.length > 1
                ? () => _confirmDeleteMeal(dayIndex, i)
                : null,
          ),
        ),
      );
    }

    // Add meal button
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: GestureDetector(
          onTap: () => _showAddMealDialog(dayIndex),
          child: Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              color: FGColors.glassSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Spacing.lg),
              border: Border.all(
                color: FGColors.glassBorder,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: FGColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Ajouter un repas',
                  style: FGTypography.body.copyWith(
                    color: FGColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return widgets;
  }

  void _showAddMealDialog(int dayIndex) {
    final controller = TextEditingController();
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FGColors.glassSurface,
        title: Text('Nouveau repas', style: FGTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nom du repas',
              style: FGTypography.caption.copyWith(color: FGColors.textSecondary),
            ),
            const SizedBox(height: Spacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              style: FGTypography.body,
              decoration: InputDecoration(
                hintText: 'Ex: Collation, Pré-workout...',
                hintStyle: FGTypography.body.copyWith(
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: FGColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  borderSide: BorderSide(color: FGColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  borderSide: BorderSide(color: FGColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  borderSide: BorderSide(color: FGColors.accent),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            // Quick preset buttons
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                _buildMealPresetChip(controller, 'Petit-déjeuner', Icons.wb_sunny_rounded),
                _buildMealPresetChip(controller, 'Brunch', Icons.brunch_dining),
                _buildMealPresetChip(controller, 'Déjeuner', Icons.restaurant_rounded),
                _buildMealPresetChip(controller, 'Collation', Icons.apple),
                _buildMealPresetChip(controller, 'Goûter', Icons.cookie),
                _buildMealPresetChip(controller, 'Pré-workout', Icons.fitness_center),
                _buildMealPresetChip(controller, 'Post-workout', Icons.sports_score),
                _buildMealPresetChip(controller, 'Dîner', Icons.nights_stay_rounded),
              ],
            ),
          ],
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
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _addMealToDay(dayIndex, name);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Ajouter',
              style: FGTypography.body.copyWith(color: FGColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPresetChip(TextEditingController controller, String name, IconData icon) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.text = name;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: FGColors.glassBorder,
          borderRadius: BorderRadius.circular(Spacing.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: FGColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              name,
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMealToDay(int dayIndex, String mealName) {
    setState(() {
      final meals = _weeklyPlan[dayIndex]['meals'] as List;
      meals.add({
        'name': mealName,
        'icon': _getMealIcon(mealName),
        'foods': <Map<String, dynamic>>[],
      });
    });
    _saveDietPlanChanges();
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Repas "$mealName" ajouté'),
        backgroundColor: FGColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _confirmDeleteMeal(int dayIndex, int mealIndex) {
    final meals = _weeklyPlan[dayIndex]['meals'] as List;
    final mealName = meals[mealIndex]['name'] as String;

    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FGColors.glassSurface,
        title: Text('Supprimer "$mealName" ?', style: FGTypography.h3),
        content: Text(
          'Ce repas et tous ses aliments seront supprimés.',
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
              _deleteMeal(dayIndex, mealIndex);
              Navigator.pop(context);
            },
            child: Text(
              'Supprimer',
              style: FGTypography.body.copyWith(color: FGColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMeal(int dayIndex, int mealIndex) {
    final meals = _weeklyPlan[dayIndex]['meals'] as List;
    final mealName = meals[mealIndex]['name'] as String;

    setState(() {
      meals.removeAt(mealIndex);
    });
    _saveDietPlanChanges();
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Repas "$mealName" supprimé'),
        backgroundColor: FGColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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

  void _openPlanCreation({Map<String, dynamic>? existingPlan}) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NewPlanCreationFlow(existingPlan: existingPlan),
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
    if (result == true && mounted) {
      _loadDietPlans();
    }
  }

  // ============================================
  // BOTTOM SHEETS
  // ============================================

  void _showPlansModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlansModalSheet(
        activePlan: _activePlan,
        allPlans: _myDietPlans,
        onPlanChanged: () {
          _loadDietPlans();
        },
        onEditPlan: (plan) {
          _openPlanCreation(existingPlan: plan);
        },
        onCreatePlan: () {
          _openPlanCreation();
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
      builder: (sheetContext) => FoodAddSheet(
        onSelectFood: (food) {
          _addFoodToMeal(dayIndex, mealName, food);
          Navigator.pop(sheetContext);
        },
        onScanRequested: () {
          Navigator.pop(sheetContext);
          _showBarcodeScanner(dayIndex, mealName);
        },
        onFavoritesRequested: () {
          Navigator.pop(sheetContext);
          _showFavoriteFoods(dayIndex, mealName);
        },
        onTemplatesRequested: () {
          Navigator.pop(sheetContext);
          _showMealTemplates(dayIndex, mealName);
        },
      ),
    );
  }

  void _showBarcodeScanner(int dayIndex, String mealName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BarcodeScannerSheet(
        onFoodFound: (food) {
          Navigator.pop(sheetContext);
          _addFoodToMeal(dayIndex, mealName, food);
        },
        onFoodNotFound: (barcode) {
          Navigator.pop(sheetContext);
          _showContributeFoodSheet(barcode, dayIndex, mealName);
        },
      ),
    );
  }

  void _showContributeFoodSheet(String barcode, int dayIndex, String mealName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ContributeFoodSheet(
        barcode: barcode,
        onContributed: (food) {
          Navigator.pop(sheetContext);
          _addFoodToMeal(dayIndex, mealName, food);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Merci pour votre contribution !'),
              backgroundColor: FGColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFavoriteFoods(int dayIndex, String mealName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => FavoriteFoodsSheet(
        onSelectFood: (food) {
          _addFoodToMeal(dayIndex, mealName, food);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _showMealTemplates(int dayIndex, String mealName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => MealTemplatesSheet(
        onSelectTemplate: (foods) {
          for (final food in foods) {
            _addFoodToMeal(dayIndex, mealName, food);
          }
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _addFoodToMeal(int dayIndex, String mealName, Map<String, dynamic> food) {
    setState(() {
      final targetPlan = _isTrackingMode && _isToday ? _trackingWeeklyPlan : _weeklyPlan;
      if (targetPlan.isEmpty || dayIndex >= targetPlan.length) return;
      final meals = targetPlan[dayIndex]['meals'] as List;
      for (final meal in meals) {
        if (meal['name'] == mealName) {
          (meal['foods'] as List).add(Map<String, dynamic>.from(food));
          break;
        }
      }
    });

    if (_isTrackingMode && _isToday) {
      _saveTrackingLog();
    } else {
      _saveDietPlanChanges();
    }

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
      final targetPlan = _isTrackingMode && _isToday ? _trackingWeeklyPlan : _weeklyPlan;
      if (targetPlan.isEmpty || dayIndex >= targetPlan.length) return;
      final meals = targetPlan[dayIndex]['meals'] as List;
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

    if (_isTrackingMode && _isToday) {
      _saveTrackingLog();
    } else {
      _saveDietPlanChanges();
    }

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

  Future<void> _saveTrackingLog() async {
    if (_todayLog == null || _trackingWeeklyPlan.isEmpty) return;

    final todayMeals = _trackingWeeklyPlan[_getTodayIndex()]['meals'] as List;
    final mealsForSave = todayMeals.map((meal) {
      return {
        'name': meal['name'],
        'foods': meal['foods'],
        'plan_foods': meal['plan_foods'] ?? meal['foods'],
      };
    }).toList();

    final totals = _getDayTotals(_getTodayIndex());

    try {
      await SupabaseService.upsertNutritionLog(
        date: DateTime.now(),
        dietPlanId: _activePlan?['id'] as String?,
        meals: mealsForSave,
        caloriesConsumed: totals['cal'] ?? 0,
        caloriesBurned: _caloriesBurned,
        caloriesBurnedPredicted: _caloriesPredicted,
      );
    } catch (e) {
      debugPrint('Error saving tracking log: $e');
    }
  }

  void _deleteFood(int dayIndex, String mealName, Map<String, dynamic> food) {
    setState(() {
      final targetPlan = _isTrackingMode && _isToday ? _trackingWeeklyPlan : _weeklyPlan;
      if (targetPlan.isEmpty || dayIndex >= targetPlan.length) return;
      final meals = targetPlan[dayIndex]['meals'] as List;
      for (final meal in meals) {
        if (meal['name'] == mealName) {
          (meal['foods'] as List).remove(food);
          break;
        }
      }
    });

    if (_isTrackingMode && _isToday) {
      _saveTrackingLog();
    } else {
      _saveDietPlanChanges();
    }

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
    _saveDietPlanChanges(); // Persist to Supabase
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
    _saveDietPlanChanges(); // Persist to Supabase
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

  /// Save current diet plan changes to Supabase (per day_type)
  Future<void> _saveDietPlanChanges() async {
    if (_activePlan == null || _activePlan!['id'] == null) return;

    try {
      // Save meals per day_type (not per-day, since multiple days share a type)
      final savedTypeIds = <String>{};

      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final typeId = _dayTypeIds[dayIndex];
        if (typeId == null || savedTypeIds.contains(typeId)) continue;
        savedTypeIds.add(typeId);

        final mealsForSave = (_weeklyPlan[dayIndex]['meals'] as List).map((meal) {
          return {
            'name': meal['name'],
            'foods': (meal['foods'] as List).map((food) {
              return {
                'name': food['name'],
                'quantity': food['quantity'] ?? '',
                'calories': food['cal'] ?? food['calories'] ?? 0,
                'protein': food['p'] ?? food['protein'] ?? 0,
                'carbs': food['c'] ?? food['carbs'] ?? 0,
                'fat': food['f'] ?? food['fat'] ?? 0,
              };
            }).toList(),
          };
        }).toList();

        await SupabaseService.updateDayType(typeId, {'meals': mealsForSave});
      }

      // Also update the diet_plans.meals as legacy fallback
      final mondayMeals = (_weeklyPlan[0]['meals'] as List).map((meal) {
        return {
          'name': meal['name'],
          'foods': (meal['foods'] as List).map((food) {
            return {
              'name': food['name'],
              'quantity': food['quantity'] ?? '',
              'calories': food['cal'] ?? food['calories'] ?? 0,
              'protein': food['p'] ?? food['protein'] ?? 0,
              'carbs': food['c'] ?? food['carbs'] ?? 0,
              'fat': food['f'] ?? food['fat'] ?? 0,
            };
          }).toList(),
        };
      }).toList();

      await SupabaseService.updateDietPlan(
        _activePlan!['id'] as String,
        {'meals': mondayMeals},
      );
    } catch (e) {
      debugPrint('Error saving diet plan: $e');
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
}



