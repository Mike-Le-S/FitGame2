import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../models/diet_models.dart';

// Steps
import 'steps/name_step.dart';
import 'steps/goal_step.dart';
import 'steps/calories_step.dart';
import 'steps/macros_step.dart';
import 'steps/meals_step.dart';
import 'steps/meal_names_step.dart';
import 'steps/meal_planning_step.dart';
import 'steps/supplements_step.dart';

// Sheets
import 'sheets/diet_success_modal.dart';

/// Multi-step diet creation flow
class DietCreationFlow extends StatefulWidget {
  const DietCreationFlow({super.key});

  @override
  State<DietCreationFlow> createState() => _DietCreationFlowState();
}

class _DietCreationFlowState extends State<DietCreationFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _currentStep = 0;
  final int _totalSteps = 8;

  // Diet data - Basic info
  String _dietName = '';
  String _goalType = 'maintain';
  int _trainingCalories = 2800;
  int _restCalories = 2500;
  int _proteinPercent = 30;
  int _carbsPercent = 45;
  int _fatPercent = 25;
  int _mealsPerDay = 4;

  // NEW: Meal names and icons
  List<String> _mealNames = [];
  List<IconData> _mealIcons = [];

  // NEW: Meal planning
  List<MealPlan> _trainingDayMeals = [];
  List<MealPlan> _restDayMeals = [];

  // NEW: Supplements
  List<SupplementEntry> _supplements = [];

  // Controllers
  late TextEditingController _nameController;

  // Nutrition theme color
  static const _nutritionGreen = Color(0xFF2ECC71);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _initializeMealData();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.05, end: 0.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initializeMealData() {
    _updateMealNamesFromCount(_mealsPerDay);
  }

  void _updateMealNamesFromCount(int count) {
    final defaultNames = mealNamesByCount[count] ?? [];
    _mealNames = List<String>.from(defaultNames);
    _mealIcons = defaultNames.map((name) => _getMealIconForName(name)).toList();
    _updateMealPlans();
  }

  IconData _getMealIconForName(String name) {
    if (name.contains('Petit-déjeuner')) return Icons.wb_sunny_rounded;
    if (name.contains('Déjeuner')) return Icons.restaurant_rounded;
    if (name.contains('Dîner')) return Icons.nights_stay_rounded;
    return Icons.apple;
  }

  void _updateMealPlans() {
    _trainingDayMeals = List.generate(
      _mealNames.length,
      (i) => MealPlan(
        name: _mealNames[i],
        icon: _mealIcons[i],
        foods: _trainingDayMeals.length > i ? _trainingDayMeals[i].foods : [],
      ),
    );
    _restDayMeals = List.generate(
      _mealNames.length,
      (i) => MealPlan(
        name: _mealNames[i],
        icon: _mealIcons[i],
        foods: _restDayMeals.length > i ? _restDayMeals[i].foods : [],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // === Navigation ===

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishCreation();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _isSaving = false;

  Future<void> _finishCreation() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      // Calculate macros in grams from percentages
      final trainingMacros = _calculateMacros(_trainingCalories);
      final restMacros = _calculateMacros(_restCalories);

      // Build meals array for database
      final meals = _trainingDayMeals.map((meal) => {
        'id': 'meal-${_trainingDayMeals.indexOf(meal)}',
        'name': meal.name,
        'foods': meal.foods.map((food) => {
          'id': food.id,
          'name': food.name,
          'quantity': food.quantity,
          'unit': food.unit,
          'calories': food.calories,
          'protein': food.protein,
          'carbs': food.carbs,
          'fat': food.fat,
        }).toList(),
      }).toList();

      // Build supplements array
      final supplements = _supplements.map((supp) => {
        'id': supp.id,
        'name': supp.name,
        'dosage': supp.dosage,
        'timing': supp.timing.name,
      }).toList();

      // Save to Supabase
      await SupabaseService.createDietPlan(
        name: _dietName,
        goal: _goalType,
        trainingCalories: _trainingCalories,
        restCalories: _restCalories,
        trainingMacros: trainingMacros,
        restMacros: restMacros,
        meals: meals,
        supplements: supplements,
      );

      if (mounted) {
        _showSuccessModal();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: FGColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Map<String, dynamic> _calculateMacros(int calories) {
    final protein = (calories * _proteinPercent / 100 / 4).round(); // 4 cal/g protein
    final carbs = (calories * _carbsPercent / 100 / 4).round(); // 4 cal/g carbs
    final fat = (calories * _fatPercent / 100 / 9).round(); // 9 cal/g fat
    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  void _showSuccessModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => DietSuccessModal(
        dietName: _dietName,
        goalType: _goalType,
        trainingCalories: _trainingCalories,
        mealsPerDay: _mealsPerDay,
        supplementsCount: _supplements.length,
        onDismiss: () {
          Navigator.pop(context); // Close modal
          Navigator.pop(context); // Close flow
        },
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Name
        return _dietName.trim().isNotEmpty;
      case 1: // Goal
        return _goalType.isNotEmpty;
      case 2: // Calories
        return _trainingCalories > 0 && _restCalories > 0;
      case 3: // Macros
        return _proteinPercent + _carbsPercent + _fatPercent == 100;
      case 4: // Meals count
        return _mealsPerDay >= 3 && _mealsPerDay <= 6;
      case 5: // Meal names
        return _mealNames.every((name) => name.trim().isNotEmpty);
      case 6: // Meal planning (optional)
        return true;
      case 7: // Supplements (optional)
        return true;
      default:
        return false;
    }
  }

  bool _isOptionalStep() {
    return _currentStep == 6 || _currentStep == 7;
  }

  void _updateCaloriesFromGoal(String goal) {
    setState(() {
      _goalType = goal;
      switch (goal) {
        case 'bulk':
          _trainingCalories = 3200;
          _restCalories = 2800;
          break;
        case 'cut':
          _trainingCalories = 2400;
          _restCalories = 2000;
          break;
        case 'maintain':
        default:
          _trainingCalories = 2800;
          _restCalories = 2500;
          break;
      }
    });
  }

  void _onMealsCountChanged(int count) {
    setState(() {
      _mealsPerDay = count;
      _updateMealNamesFromCount(count);
    });
  }

  // === Build ===

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
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Step 1: Name
                      DietNameStep(
                        controller: _nameController,
                        dietName: _dietName,
                        onNameChanged: (value) =>
                            setState(() => _dietName = value),
                      ),
                      // Step 2: Goal
                      GoalStep(
                        selectedGoal: _goalType,
                        onGoalChanged: _updateCaloriesFromGoal,
                      ),
                      // Step 3: Calories
                      CaloriesStep(
                        trainingCalories: _trainingCalories,
                        restCalories: _restCalories,
                        onTrainingCaloriesChanged: (value) =>
                            setState(() => _trainingCalories = value),
                        onRestCaloriesChanged: (value) =>
                            setState(() => _restCalories = value),
                      ),
                      // Step 4: Macros
                      MacrosStep(
                        proteinPercent: _proteinPercent,
                        carbsPercent: _carbsPercent,
                        fatPercent: _fatPercent,
                        trainingCalories: _trainingCalories,
                        onProteinChanged: (value) =>
                            setState(() => _proteinPercent = value),
                        onCarbsChanged: (value) =>
                            setState(() => _carbsPercent = value),
                        onFatChanged: (value) =>
                            setState(() => _fatPercent = value),
                        onPresetSelected: (p, c, f) {
                          setState(() {
                            _proteinPercent = p;
                            _carbsPercent = c;
                            _fatPercent = f;
                          });
                        },
                      ),
                      // Step 5: Meals count
                      MealsStep(
                        mealsPerDay: _mealsPerDay,
                        onMealsChanged: _onMealsCountChanged,
                      ),
                      // Step 6: Meal names
                      MealNamesStep(
                        mealNames: _mealNames,
                        mealIcons: _mealIcons,
                        onMealNamesChanged: (names) {
                          setState(() {
                            _mealNames = names;
                            _updateMealPlans();
                          });
                        },
                        onMealIconsChanged: (icons) {
                          setState(() {
                            _mealIcons = icons;
                            _updateMealPlans();
                          });
                        },
                      ),
                      // Step 7: Meal planning
                      MealPlanningStep(
                        trainingDayMeals: _trainingDayMeals,
                        restDayMeals: _restDayMeals,
                        trainingCalories: _trainingCalories,
                        restCalories: _restCalories,
                        proteinPercent: _proteinPercent,
                        carbsPercent: _carbsPercent,
                        fatPercent: _fatPercent,
                        onTrainingMealsChanged: (meals) =>
                            setState(() => _trainingDayMeals = meals),
                        onRestMealsChanged: (meals) =>
                            setState(() => _restDayMeals = meals),
                      ),
                      // Step 8: Supplements
                      SupplementsStep(
                        supplements: _supplements,
                        onSupplementsChanged: (supplements) =>
                            setState(() => _supplements = supplements),
                      ),
                    ],
                  ),
                ),
                _buildBottomActions(),
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
                      _nutritionGreen.withValues(alpha: _pulseAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1ABC9C)
                          .withValues(alpha: _pulseAnimation.value * 0.6),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.lg, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _previousStep,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(Spacing.sm),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: Icon(
                _currentStep == 0
                    ? Icons.close_rounded
                    : Icons.arrow_back_rounded,
                color: FGColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Étape ${_currentStep + 1}/$_totalSteps',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, 0),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: index < _totalSteps - 1 ? Spacing.xs : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isCurrent ? 4 : 3,
                decoration: BoxDecoration(
                  color: isActive ? _nutritionGreen : FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: _nutritionGreen.withValues(alpha: 0.5),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomActions() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canProceed = _canProceed();
    final isOptional = _isOptionalStep();

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FGColors.background.withValues(alpha: 0),
            FGColors.background,
          ],
        ),
      ),
      child: Row(
        children: [
          // Skip button for optional steps
          if (isOptional)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: GestureDetector(
                  onTap: isLastStep ? _finishCreation : _nextStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    decoration: BoxDecoration(
                      color: FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      border: Border.all(color: FGColors.glassBorder),
                    ),
                    child: Center(
                      child: Text(
                        'Passer',
                        style: FGTypography.body.copyWith(
                          color: FGColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            flex: isOptional ? 2 : 1,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canProceed ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _nutritionGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _nutritionGreen.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  elevation: canProceed ? 4 : 0,
                  shadowColor: _nutritionGreen.withValues(alpha: 0.5),
                ),
                child: Text(
                  isLastStep ? 'Créer le plan' : 'Continuer',
                  style: FGTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
