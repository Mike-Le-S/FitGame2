import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';
import 'widgets/progress_dots.dart';

class NewPlanCreationFlow extends StatefulWidget {
  final Map<String, dynamic>? existingPlan;

  const NewPlanCreationFlow({super.key, this.existingPlan});

  @override
  State<NewPlanCreationFlow> createState() => _NewPlanCreationFlowState();
}

class _NewPlanCreationFlowState extends State<NewPlanCreationFlow> {
  static const _draftKey = 'nutrition_plan_draft';
  static const _nutritionGreen = Color(0xFF2ECC71);
  static const _totalSteps = 6;

  static const _suggestionDefaults = {
    'Prise de masse': {'goal': 'bulk', 'cal': 3200, 'restCal': 2800, 'protein': 30, 'carbs': 45, 'fat': 25},
    'Sèche été': {'goal': 'cut', 'cal': 2400, 'restCal': 2000, 'protein': 40, 'carbs': 35, 'fat': 25},
    'Nutrition équilibrée': {'goal': 'maintain', 'cal': 2800, 'restCal': 2500, 'protein': 30, 'carbs': 45, 'fat': 25},
    'Plan personnalisé': {'goal': 'maintain', 'cal': 2800, 'restCal': 2400, 'protein': 30, 'carbs': 45, 'fat': 25},
  };

  static const _macroPresets = {
    'Équilibré': {'protein': 30, 'carbs': 45, 'fat': 25},
    'High Protein': {'protein': 40, 'carbs': 35, 'fat': 25},
    'Low Carb': {'protein': 35, 'carbs': 25, 'fat': 40},
    'Keto': {'protein': 25, 'carbs': 5, 'fat': 70},
  };

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final Set<int> _visitedSteps = {0};

  // Step 1: Identity
  final _nameController = TextEditingController();
  String? _selectedSuggestion;

  // Step 2: Objective & Calories
  String _goalType = 'maintain';
  int _trainingCalories = 2800;
  int _restCalories = 2400;
  bool _caloriesLinked = true;

  // Step 3: Macros
  int _proteinPercent = 30;
  int _carbsPercent = 45;
  int _fatPercent = 25;

  // Step 4: Day Types
  List<Map<String, dynamic>> _dayTypes = [
    {'name': 'Entraînement', 'emoji': '💪', 'color': 0xFFFF6B35},
    {'name': 'Repos', 'emoji': '😴', 'color': 0xFF3498DB},
  ];

  // Step 5: Weekly Schedule
  Map<int, int> _weeklySchedule = {
    0: 0, 1: 1, 2: 0, 3: 1, 4: 0, 5: 1, 6: 1,
  };

  bool _isSaving = false;

  final List<String> _stepTitles = [
    'Identité',
    'Objectif',
    'Macros',
    'Types de jour',
    'Semaine',
    'Confirmation',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingPlan != null) {
      _loadExistingPlan();
    } else {
      _loadDraft();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ============================================
  // LOAD EXISTING PLAN
  // ============================================

  void _loadExistingPlan() {
    final plan = widget.existingPlan!;
    _nameController.text = plan['name'] as String? ?? '';
    _goalType = plan['goal'] as String? ?? 'maintain';
    _trainingCalories = plan['training_calories'] as int? ?? 2800;
    _restCalories = plan['rest_calories'] as int? ?? 2400;

    final macros = plan['training_macros'] as Map<String, dynamic>?;
    if (macros != null) {
      final totalCal = _trainingCalories > 0 ? _trainingCalories : 2800;
      _proteinPercent = (((macros['protein'] as int? ?? 0) * 4 / totalCal) * 100).round();
      _carbsPercent = (((macros['carbs'] as int? ?? 0) * 4 / totalCal) * 100).round();
      _fatPercent = 100 - _proteinPercent - _carbsPercent;
    }
  }

  // ============================================
  // DRAFT MANAGEMENT
  // ============================================

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = {
      'name': _nameController.text,
      'suggestion': _selectedSuggestion,
      'goalType': _goalType,
      'trainingCalories': _trainingCalories,
      'restCalories': _restCalories,
      'caloriesLinked': _caloriesLinked,
      'proteinPercent': _proteinPercent,
      'carbsPercent': _carbsPercent,
      'fatPercent': _fatPercent,
      'dayTypes': _dayTypes,
      'weeklySchedule': _weeklySchedule.map((k, v) => MapEntry(k.toString(), v)),
      'currentStep': _currentStep,
      'visitedSteps': _visitedSteps.toList(),
    };
    await prefs.setString(_draftKey, jsonEncode(draft));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    if (draftJson == null) return;

    try {
      final draft = jsonDecode(draftJson) as Map<String, dynamic>;
      setState(() {
        _nameController.text = draft['name'] as String? ?? '';
        _selectedSuggestion = draft['suggestion'] as String?;
        _goalType = draft['goalType'] as String? ?? 'maintain';
        _trainingCalories = draft['trainingCalories'] as int? ?? 2800;
        _restCalories = draft['restCalories'] as int? ?? 2400;
        _caloriesLinked = draft['caloriesLinked'] as bool? ?? true;
        _proteinPercent = draft['proteinPercent'] as int? ?? 30;
        _carbsPercent = draft['carbsPercent'] as int? ?? 45;
        _fatPercent = draft['fatPercent'] as int? ?? 25;

        if (draft['dayTypes'] != null) {
          _dayTypes = List<Map<String, dynamic>>.from(
            (draft['dayTypes'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }

        if (draft['weeklySchedule'] != null) {
          final schedMap = draft['weeklySchedule'] as Map<String, dynamic>;
          _weeklySchedule = schedMap.map((k, v) => MapEntry(int.parse(k), v as int));
        }

        final savedStep = draft['currentStep'] as int? ?? 0;
        _currentStep = savedStep;

        if (draft['visitedSteps'] != null) {
          _visitedSteps.addAll(
            (draft['visitedSteps'] as List).map((e) => e as int),
          );
        }
      });

      // Jump to saved step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentStep);
        }
      });
    } catch (e) {
      debugPrint('Error loading draft: $e');
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  // ============================================
  // NAVIGATION
  // ============================================

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentStep++;
        _visitedSteps.add(_currentStep);
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      _saveDraft();
    } else {
      _savePlan();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _confirmExit();
    }
  }

  void _jumpToStep(int step) {
    if (_visitedSteps.contains(step)) {
      HapticFeedback.selectionClick();
      setState(() => _currentStep = step);
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // ============================================
  // EXIT CONFIRMATION
  // ============================================

  Future<void> _confirmExit() async {
    HapticFeedback.lightImpact();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FGColors.glassSurface,
        title: Text('Quitter la création ?', style: FGTypography.h3),
        content: Text(
          'Tu peux sauvegarder ton brouillon pour reprendre plus tard.',
          style: FGTypography.body.copyWith(color: FGColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'continue'),
            child: Text(
              'Continuer',
              style: FGTypography.body.copyWith(color: _nutritionGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'draft'),
            child: Text(
              'Sauvegarder brouillon',
              style: FGTypography.body.copyWith(color: FGColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: Text(
              'Supprimer',
              style: FGTypography.body.copyWith(color: FGColors.error),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    switch (result) {
      case 'draft':
        await _saveDraft();
        if (mounted) Navigator.of(context).pop(false);
        break;
      case 'delete':
        await _clearDraft();
        if (mounted) Navigator.of(context).pop(false);
        break;
      case 'continue':
      default:
        break;
    }
  }

  // ============================================
  // VALIDATION
  // ============================================

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _goalType.isNotEmpty && _trainingCalories > 0;
      case 2:
        return (_proteinPercent + _carbsPercent + _fatPercent) == 100;
      case 3:
        return _dayTypes.isNotEmpty;
      case 4:
        return _weeklySchedule.length == 7;
      case 5:
        return true;
      default:
        return false;
    }
  }

  // ============================================
  // SAVE PLAN
  // ============================================

  Future<void> _savePlan() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      final proteinGrams = (_trainingCalories * _proteinPercent / 100 / 4).round();
      final carbsGrams = (_trainingCalories * _carbsPercent / 100 / 4).round();
      final fatGrams = (_trainingCalories * _fatPercent / 100 / 9).round();

      final macros = {
        'protein': proteinGrams,
        'carbs': carbsGrams,
        'fat': fatGrams,
      };

      if (widget.existingPlan != null) {
        await SupabaseService.updateDietPlan(
          widget.existingPlan!['id'] as String,
          {
            'name': _nameController.text.trim(),
            'goal': _goalType,
            'training_calories': _trainingCalories,
            'rest_calories': _restCalories,
            'training_macros': macros,
            'rest_macros': macros,
          },
        );
      } else {
        final plan = await SupabaseService.createDietPlan(
          name: _nameController.text.trim(),
          goal: _goalType,
          trainingCalories: _trainingCalories,
          restCalories: _restCalories,
          trainingMacros: macros,
          restMacros: macros,
          meals: [],
        );

        final planId = plan['id'] as String;

        // Create day types
        final dayTypeIds = <String>[];
        for (int i = 0; i < _dayTypes.length; i++) {
          final dt = await SupabaseService.createDayType(
            dietPlanId: planId,
            name: _dayTypes[i]['name'] as String,
            emoji: _dayTypes[i]['emoji'] as String? ?? '📅',
            sortOrder: i,
          );
          dayTypeIds.add(dt['id'] as String);
        }

        // Create weekly schedule
        final schedule = <int, String>{};
        for (final entry in _weeklySchedule.entries) {
          final typeIndex = entry.value;
          if (typeIndex < dayTypeIds.length) {
            schedule[entry.key] = dayTypeIds[typeIndex];
          }
        }
        await SupabaseService.setWeeklySchedule(
          dietPlanId: planId,
          schedule: schedule,
        );

        // Activate the new plan
        await SupabaseService.activateDietPlan(planId);
      }

      await _clearDraft();

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error saving plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: FGColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.sm,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _previousStep,
                      child: Container(
                        width: 40,
                        height: 40,
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
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existingPlan != null
                                ? 'MODIFIER LE PLAN'
                                : 'NOUVEAU PLAN',
                            style: FGTypography.caption.copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: FGColors.textSecondary,
                            ),
                          ),
                          Text(
                            _stepTitles[_currentStep],
                            style: FGTypography.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _nutritionGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_currentStep + 1}/$_totalSteps',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress dots
              ProgressDots(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                visitedSteps: _visitedSteps,
                onStepTapped: _jumpToStep,
              ),

              // Steps PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1Identity(),
                    _buildStep2ObjectiveCalories(),
                    _buildStep3Macros(),
                    _buildStep4Placeholder(),
                    _buildStep5Placeholder(),
                    _buildStep6Placeholder(),
                  ],
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: GestureDetector(
                  onTap: _canProceed() && !_isSaving ? _nextStep : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _canProceed()
                          ? LinearGradient(
                              colors: [
                                _nutritionGreen,
                                _nutritionGreen.withValues(alpha: 0.8),
                              ],
                            )
                          : null,
                      color: _canProceed() ? null : FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.md),
                      boxShadow: _canProceed()
                          ? [
                              BoxShadow(
                                color: _nutritionGreen.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep == _totalSteps - 1
                                  ? 'CRÉER MON PLAN'
                                  : 'CONTINUER',
                              style: FGTypography.button.copyWith(
                                color: _canProceed()
                                    ? FGColors.textOnAccent
                                    : FGColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // PLACEHOLDER STEP BUILDERS
  // ============================================

  Widget _buildStep1Identity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Crée ton\nplan',
            style: FGTypography.h1.copyWith(
              color: _nutritionGreen,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Donne un nom à ton plan nutrition ou choisis un modèle.',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xl),

          // Name TextField
          Container(
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(Spacing.md),
              border: Border.all(color: FGColors.glassBorder),
            ),
            child: TextField(
              controller: _nameController,
              style: FGTypography.body,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nom du plan...',
                hintStyle: FGTypography.body.copyWith(
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.restaurant_menu_rounded,
                  color: _nutritionGreen.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.md,
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Suggestion chips
          Text(
            'SUGGESTIONS',
            style: FGTypography.caption.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: _suggestionDefaults.entries.map((entry) {
              final isSelected = _selectedSuggestion == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedSuggestion = entry.key;
                    _nameController.text = entry.key;
                    _goalType = entry.value['goal'] as String;
                    _trainingCalories = entry.value['cal'] as int;
                    _restCalories = entry.value['restCal'] as int;
                    _proteinPercent = entry.value['protein'] as int;
                    _carbsPercent = entry.value['carbs'] as int;
                    _fatPercent = entry.value['fat'] as int;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _nutritionGreen.withValues(alpha: 0.15)
                        : FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.xl),
                    border: Border.all(
                      color: isSelected
                          ? _nutritionGreen
                          : FGColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    entry.key,
                    style: FGTypography.body.copyWith(
                      color: isSelected ? _nutritionGreen : FGColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.xxl),
        ],
      ),
    );
  }

  Widget _buildStep2ObjectiveCalories() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Ton\nobjectif',
            style: FGTypography.h1.copyWith(color: _nutritionGreen),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Choisis ton objectif et ajuste tes calories.',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xl),

          // Goal cards
          _buildGoalCards(),
          const SizedBox(height: Spacing.xl),

          // Calorie section title
          Text(
            'CALORIES QUOTIDIENNES',
            style: FGTypography.caption.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Training calories
          _buildCalorieCard(
            label: 'Jour entraînement',
            icon: Icons.fitness_center_rounded,
            calories: _trainingCalories,
            onChanged: (val) {
              setState(() {
                _trainingCalories = val;
                if (_caloriesLinked) {
                  _restCalories = (val - 400).clamp(1000, 6000);
                }
              });
            },
          ),
          const SizedBox(height: Spacing.sm),

          // Link toggle
          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _caloriesLinked = !_caloriesLinked);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _caloriesLinked
                      ? _nutritionGreen.withValues(alpha: 0.15)
                      : FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(Spacing.xl),
                  border: Border.all(
                    color: _caloriesLinked ? _nutritionGreen : FGColors.glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _caloriesLinked ? Icons.link_rounded : Icons.link_off_rounded,
                      color: _caloriesLinked ? _nutritionGreen : FGColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      _caloriesLinked ? 'Liés (-400 kcal)' : 'Indépendants',
                      style: FGTypography.caption.copyWith(
                        color: _caloriesLinked ? _nutritionGreen : FGColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),

          // Rest calories
          _buildCalorieCard(
            label: 'Jour repos',
            icon: Icons.bedtime_rounded,
            calories: _restCalories,
            onChanged: (val) {
              setState(() => _restCalories = val);
            },
          ),
          const SizedBox(height: Spacing.xxl),
        ],
      ),
    );
  }

  Widget _buildGoalCards() {
    final goals = [
      {'key': 'bulk', 'label': 'Prise de masse', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFFE74C3C)},
      {'key': 'maintain', 'label': 'Maintien', 'icon': Icons.balance_rounded, 'color': const Color(0xFF3498DB)},
      {'key': 'cut', 'label': 'Sèche', 'icon': Icons.trending_down_rounded, 'color': const Color(0xFFF39C12)},
    ];

    return Row(
      children: goals.map((goal) {
        final isSelected = _goalType == goal['key'];
        final color = goal['color'] as Color;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: goal != goals.last ? Spacing.sm : 0,
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _goalType = goal['key'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  vertical: Spacing.lg,
                  horizontal: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(Spacing.md),
                  border: Border.all(
                    color: isSelected ? color : FGColors.glassBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      goal['icon'] as IconData,
                      color: isSelected ? color : FGColors.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      goal['label'] as String,
                      style: FGTypography.caption.copyWith(
                        color: isSelected ? color : FGColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalorieCard({
    required String label,
    required IconData icon,
    required int calories,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: _nutritionGreen, size: 24),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
                Text(
                  '$calories kcal',
                  style: FGTypography.h3.copyWith(
                    color: FGColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _buildIncrementButton(
            icon: Icons.remove_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged((calories - 100).clamp(1000, 6000));
            },
          ),
          const SizedBox(width: Spacing.sm),
          _buildIncrementButton(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged((calories + 100).clamp(1000, 6000));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncrementButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _nutritionGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Spacing.sm),
          border: Border.all(color: _nutritionGreen.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: _nutritionGreen, size: 20),
      ),
    );
  }

  Widget _buildStep3Macros() {
    final proteinGrams = (_trainingCalories * _proteinPercent / 100 / 4).round();
    final carbsGrams = (_trainingCalories * _carbsPercent / 100 / 4).round();
    final fatGrams = (_trainingCalories * _fatPercent / 100 / 9).round();
    final total = _proteinPercent + _carbsPercent + _fatPercent;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            'Répartition\nmacros',
            style: FGTypography.h1.copyWith(color: _nutritionGreen),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Ajuste la répartition de tes macronutriments.',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.lg),

          // Preset chips
          Text(
            'PRESETS',
            style: FGTypography.caption.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: _macroPresets.entries.map((entry) {
              final isActive = _proteinPercent == entry.value['protein'] &&
                  _carbsPercent == entry.value['carbs'] &&
                  _fatPercent == entry.value['fat'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _proteinPercent = entry.value['protein'] as int;
                    _carbsPercent = entry.value['carbs'] as int;
                    _fatPercent = entry.value['fat'] as int;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _nutritionGreen.withValues(alpha: 0.15)
                        : FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.xl),
                    border: Border.all(
                      color: isActive ? _nutritionGreen : FGColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    entry.key,
                    style: FGTypography.caption.copyWith(
                      color: isActive ? _nutritionGreen : FGColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.xl),

          // Pie chart
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _MacroPieChartPainter(
                  proteinPercent: _proteinPercent,
                  carbsPercent: _carbsPercent,
                  fatPercent: _fatPercent,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total%',
                        style: FGTypography.h2.copyWith(
                          color: total == 100 ? _nutritionGreen : FGColors.error,
                        ),
                      ),
                      Text(
                        total == 100 ? 'Parfait' : 'Ajuster',
                        style: FGTypography.caption.copyWith(
                          color: total == 100 ? _nutritionGreen : FGColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Sliders
          _buildMacroSlider(
            label: 'Protéines',
            percent: _proteinPercent,
            grams: proteinGrams,
            color: const Color(0xFFE74C3C),
            unit: 'g (x4 kcal)',
            onChanged: (val) => _adjustMacros('protein', val),
          ),
          const SizedBox(height: Spacing.md),
          _buildMacroSlider(
            label: 'Glucides',
            percent: _carbsPercent,
            grams: carbsGrams,
            color: const Color(0xFF3498DB),
            unit: 'g (x4 kcal)',
            onChanged: (val) => _adjustMacros('carbs', val),
          ),
          const SizedBox(height: Spacing.md),
          _buildMacroSlider(
            label: 'Lipides',
            percent: _fatPercent,
            grams: fatGrams,
            color: const Color(0xFFF39C12),
            unit: 'g (x9 kcal)',
            onChanged: (val) => _adjustMacros('fat', val),
          ),
          const SizedBox(height: Spacing.xxl),
        ],
      ),
    );
  }

  void _adjustMacros(String changed, int newValue) {
    setState(() {
      switch (changed) {
        case 'protein':
          final diff = newValue - _proteinPercent;
          _proteinPercent = newValue;
          // Distribute the difference between the other two
          if (_carbsPercent - diff ~/ 2 >= 0 && _fatPercent - (diff - diff ~/ 2) >= 0) {
            _carbsPercent -= diff ~/ 2;
            _fatPercent -= (diff - diff ~/ 2);
          } else {
            _carbsPercent = (100 - _proteinPercent) ~/ 2;
            _fatPercent = 100 - _proteinPercent - _carbsPercent;
          }
          break;
        case 'carbs':
          final diff = newValue - _carbsPercent;
          _carbsPercent = newValue;
          if (_proteinPercent - diff ~/ 2 >= 0 && _fatPercent - (diff - diff ~/ 2) >= 0) {
            _proteinPercent -= diff ~/ 2;
            _fatPercent -= (diff - diff ~/ 2);
          } else {
            _proteinPercent = (100 - _carbsPercent) ~/ 2;
            _fatPercent = 100 - _carbsPercent - _proteinPercent;
          }
          break;
        case 'fat':
          final diff = newValue - _fatPercent;
          _fatPercent = newValue;
          if (_proteinPercent - diff ~/ 2 >= 0 && _carbsPercent - (diff - diff ~/ 2) >= 0) {
            _proteinPercent -= diff ~/ 2;
            _carbsPercent -= (diff - diff ~/ 2);
          } else {
            _proteinPercent = (100 - _fatPercent) ~/ 2;
            _carbsPercent = 100 - _fatPercent - _proteinPercent;
          }
          break;
      }

      // Clamp all values
      _proteinPercent = _proteinPercent.clamp(0, 100);
      _carbsPercent = _carbsPercent.clamp(0, 100);
      _fatPercent = _fatPercent.clamp(0, 100);
    });
  }

  Widget _buildMacroSlider({
    required String label,
    required int percent,
    required int grams,
    required Color color,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                label,
                style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: FGTypography.h3.copyWith(color: color),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '$grams$unit',
                style: FGTypography.caption.copyWith(color: FGColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: percent.toDouble(),
              min: 0,
              max: 80,
              divisions: 80,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                onChanged(val.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Placeholder() {
    return const Center(child: Text('Step 4', style: TextStyle(color: Colors.white)));
  }

  Widget _buildStep5Placeholder() {
    return const Center(child: Text('Step 5', style: TextStyle(color: Colors.white)));
  }

  Widget _buildStep6Placeholder() {
    return const Center(child: Text('Step 6', style: TextStyle(color: Colors.white)));
  }
}

class _MacroPieChartPainter extends CustomPainter {
  final int proteinPercent;
  final int carbsPercent;
  final int fatPercent;

  static const _proteinColor = Color(0xFFE74C3C);
  static const _carbsColor = Color(0xFF3498DB);
  static const _fatColor = Color(0xFFF39C12);

  _MacroPieChartPainter({
    required this.proteinPercent,
    required this.carbsPercent,
    required this.fatPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 20.0;
    const startAngle = -pi / 2;

    final total = proteinPercent + carbsPercent + fatPercent;
    if (total == 0) return;

    final segments = [
      (proteinPercent / total, _proteinColor),
      (carbsPercent / total, _carbsColor),
      (fatPercent / total, _fatColor),
    ];

    // Background track
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw segments
    var currentAngle = startAngle;
    for (final (fraction, color) in segments) {
      if (fraction <= 0) continue;
      final sweepAngle = 2 * pi * fraction;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle - 0.04, // Small gap between segments
        false,
        paint,
      );
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroPieChartPainter oldDelegate) {
    return oldDelegate.proteinPercent != proteinPercent ||
        oldDelegate.carbsPercent != carbsPercent ||
        oldDelegate.fatPercent != fatPercent;
  }
}
