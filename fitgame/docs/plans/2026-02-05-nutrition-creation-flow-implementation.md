# Nutrition Plan Creation Flow Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the two existing nutrition plan creation flows (3-step PlanCreationFlow + 8-step legacy DietCreationFlow) with a single unified 6-step flow combining day types architecture with full UX polish.

**Architecture:** A single `StatefulWidget` orchestrator using `PageView` + `PageController` for step navigation. Each step is an extracted widget receiving callbacks. State lives in the orchestrator. Draft auto-save via `SharedPreferences`. Progress dots widget handles clickable navigation to visited steps.

**Tech Stack:** Flutter, Supabase (existing service methods), SharedPreferences (drafts), existing design system (FGColors, FGTypography, Spacing, FGGlassCard, FGNeonButton)

**Design Doc:** `fitgame/docs/plans/2026-02-05-nutrition-creation-flow-redesign.md`

---

## Task 1: Progress Dots Widget

**Files:**
- Create: `fitgame/lib/features/nutrition/create/widgets/progress_dots.dart`

**Step 1: Create the progress dots widget**

This widget renders 6 dots connected by lines. Dots are: filled+glowing if active, filled if visited, outlined if unvisited. Visited dots are tappable.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/constants/spacing.dart';

class ProgressDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Set<int> visitedSteps;
  final ValueChanged<int>? onStepTapped;

  static const _nutritionGreen = Color(0xFF2ECC71);

  const ProgressDots({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.visitedSteps,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepBefore = index ~/ 2;
            final isActive = visitedSteps.contains(stepBefore + 1);
            return Expanded(
              child: Container(
                height: 2,
                color: isActive ? _nutritionGreen : FGColors.glassBorder,
              ),
            );
          }
          // Dot
          final step = index ~/ 2;
          final isCurrent = step == currentStep;
          final isVisited = visitedSteps.contains(step);
          return GestureDetector(
            onTap: isVisited && !isCurrent
                ? () {
                    HapticFeedback.selectionClick();
                    onStepTapped?.call(step);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 14 : 10,
              height: isCurrent ? 14 : 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent || isVisited ? _nutritionGreen : Colors.transparent,
                border: Border.all(
                  color: isCurrent || isVisited ? _nutritionGreen : FGColors.glassBorder,
                  width: 2,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: _nutritionGreen.withValues(alpha: 0.6), blurRadius: 8)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
```

**Step 2: Verify no analysis errors**

Run: `cd fitgame && flutter analyze lib/features/nutrition/create/widgets/progress_dots.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/create/widgets/progress_dots.dart
git commit -m "feat(nutrition): add ProgressDots widget for 6-step creation flow"
```

---

## Task 2: Main Orchestrator — Skeleton with Navigation

**Files:**
- Create: `fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 1: Create orchestrator with PageView, state, navigation, draft save/restore, and exit confirmation**

This is the core file. It manages all state, renders the header + progress dots + PageView + bottom button. Each step will be a placeholder initially — we'll fill them in subsequent tasks.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../models/diet_models.dart';
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

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final Set<int> _visitedSteps = {0};
  bool _isSaving = false;

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
    {
      'name': 'Jour entraînement',
      'emoji': '🏋️',
      'meals': <Map<String, dynamic>>[
        {'name': 'Petit-déjeuner', 'icon': 'wb_sunny_rounded', 'foods': <Map<String, dynamic>>[]},
        {'name': 'Déjeuner', 'icon': 'restaurant_rounded', 'foods': <Map<String, dynamic>>[]},
        {'name': 'Dîner', 'icon': 'nightlight_round', 'foods': <Map<String, dynamic>>[]},
      ],
    },
    {
      'name': 'Jour repos',
      'emoji': '🧘',
      'meals': <Map<String, dynamic>>[
        {'name': 'Petit-déjeuner', 'icon': 'wb_sunny_rounded', 'foods': <Map<String, dynamic>>[]},
        {'name': 'Déjeuner', 'icon': 'restaurant_rounded', 'foods': <Map<String, dynamic>>[]},
        {'name': 'Dîner', 'icon': 'nightlight_round', 'foods': <Map<String, dynamic>>[]},
      ],
    },
  ];

  // Step 5: Weekly Schedule
  Map<int, int> _weeklySchedule = {
    0: 0, 1: 1, 2: 0, 3: 1, 4: 0, 5: 1, 6: 1,
  };

  final _stepTitles = [
    'Identité',
    'Objectif & Calories',
    'Macros',
    'Types de jour',
    'Planning semaine',
    'Récapitulatif',
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
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // --- Draft Management ---

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = {
      'name': _nameController.text,
      'suggestion': _selectedSuggestion,
      'goal': _goalType,
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
        _goalType = draft['goal'] as String? ?? 'maintain';
        _trainingCalories = draft['trainingCalories'] as int? ?? 2800;
        _restCalories = draft['restCalories'] as int? ?? 2400;
        _caloriesLinked = draft['caloriesLinked'] as bool? ?? true;
        _proteinPercent = draft['proteinPercent'] as int? ?? 30;
        _carbsPercent = draft['carbsPercent'] as int? ?? 45;
        _fatPercent = draft['fatPercent'] as int? ?? 25;
        if (draft['dayTypes'] != null) {
          _dayTypes = List<Map<String, dynamic>>.from(
            (draft['dayTypes'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
        if (draft['weeklySchedule'] != null) {
          _weeklySchedule = (draft['weeklySchedule'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(int.parse(k), v as int));
        }
        final step = draft['currentStep'] as int? ?? 0;
        _currentStep = step;
        final visited = (draft['visitedSteps'] as List?)?.cast<int>().toSet();
        if (visited != null) _visitedSteps.addAll(visited);
      });
      if (_currentStep > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(_currentStep);
        });
      }
    } catch (_) {
      // Corrupted draft, ignore
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  void _loadExistingPlan() {
    final plan = widget.existingPlan!;
    _nameController.text = plan['name'] as String? ?? '';
    _goalType = plan['goal'] as String? ?? 'maintain';
    _trainingCalories = plan['training_calories'] as int? ?? 2800;
    _restCalories = plan['rest_calories'] as int? ?? 2400;
    final macros = plan['training_macros'] as Map<String, dynamic>?;
    if (macros != null) {
      _proteinPercent = macros['protein'] as int? ?? 30;
      _carbsPercent = macros['carbs'] as int? ?? 45;
      _fatPercent = macros['fat'] as int? ?? 25;
    }
    // Day types & schedule loaded async in step widgets
  }

  // --- Navigation ---

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep++;
        _visitedSteps.add(_currentStep);
      });
      _pageController.nextPage(
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
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _confirmExit();
    }
  }

  void _jumpToStep(int step) {
    if (step == _currentStep) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _confirmExit() async {
    if (_nameController.text.isEmpty && _currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FGColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Spacing.md)),
        title: Text('Quitter la création ?', style: FGTypography.h3),
        content: Text(
          'Tu as un brouillon en cours.',
          style: FGTypography.body.copyWith(color: FGColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'continue'),
            child: Text('Continuer', style: TextStyle(color: _nutritionGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text('Garder le brouillon', style: TextStyle(color: FGColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: Text('Supprimer', style: TextStyle(color: FGColors.error)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (result) {
      case 'continue':
        break;
      case 'save':
        await _saveDraft();
        if (mounted) Navigator.pop(context);
        break;
      case 'delete':
        await _clearDraft();
        if (mounted) Navigator.pop(context);
        break;
      default:
        break;
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _trainingCalories >= 1000 && _restCalories >= 1000;
      case 2:
        return (_proteinPercent + _carbsPercent + _fatPercent) == 100;
      case 3:
        return _dayTypes.isNotEmpty;
      case 4:
        return _weeklySchedule.length == 7;
      case 5:
        return true; // Recap is always valid
      default:
        return false;
    }
  }

  // --- Save ---

  Future<void> _savePlan() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final trainingMacros = {
        'protein': _proteinPercent,
        'carbs': _carbsPercent,
        'fat': _fatPercent,
      };

      String planId;

      if (widget.existingPlan != null) {
        planId = widget.existingPlan!['id'] as String;
        await SupabaseService.updateDietPlan(planId, {
          'name': _nameController.text.trim(),
          'goal': _goalType,
          'training_calories': _trainingCalories,
          'rest_calories': _restCalories,
          'training_macros': trainingMacros,
          'rest_macros': trainingMacros,
        });
      } else {
        final plan = await SupabaseService.createDietPlan(
          name: _nameController.text.trim(),
          goal: _goalType,
          trainingCalories: _trainingCalories,
          restCalories: _restCalories,
          trainingMacros: trainingMacros,
          restMacros: trainingMacros,
          meals: [],
        );
        planId = plan['id'] as String;
      }

      // Save day types
      final dayTypeIds = <String>[];
      for (int i = 0; i < _dayTypes.length; i++) {
        final dt = _dayTypes[i];
        if (dt['id'] != null) {
          await SupabaseService.updateDayType(dt['id'] as String, {
            'name': dt['name'],
            'emoji': dt['emoji'],
            'meals': dt['meals'],
            'sort_order': i,
          });
          dayTypeIds.add(dt['id'] as String);
        } else {
          final created = await SupabaseService.createDayType(
            dietPlanId: planId,
            name: dt['name'] as String,
            emoji: dt['emoji'] as String? ?? '📅',
            meals: List<Map<String, dynamic>>.from(dt['meals'] as List? ?? []),
            sortOrder: i,
          );
          dayTypeIds.add(created['id'] as String);
        }
      }

      // Save weekly schedule
      final scheduleMap = <int, String>{};
      for (final entry in _weeklySchedule.entries) {
        final dayTypeIndex = entry.value;
        if (dayTypeIndex < dayTypeIds.length) {
          scheduleMap[entry.key] = dayTypeIds[dayTypeIndex];
        }
      }
      await SupabaseService.setWeeklySchedule(
        dietPlanId: planId,
        schedule: scheduleMap,
      );

      if (widget.existingPlan == null) {
        await SupabaseService.activateDietPlan(planId);
      }

      await _clearDraft();

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingPlan != null ? 'Plan mis à jour' : 'Plan créé et activé'),
            backgroundColor: FGColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: FGColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              ProgressDots(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                visitedSteps: _visitedSteps,
                onStepTapped: _jumpToStep,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1Placeholder(),
                    _buildStep2Placeholder(),
                    _buildStep3Placeholder(),
                    _buildStep4Placeholder(),
                    _buildStep5Placeholder(),
                    _buildStep6Placeholder(),
                  ],
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
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
                _currentStep == 0 ? Icons.close_rounded : Icons.arrow_back_rounded,
                color: FGColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(_stepTitles[_currentStep], style: FGTypography.h3),
          ),
          Text(
            '${_currentStep + 1}/$_totalSteps',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canProceed = _canProceed();

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
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canProceed && !_isSaving ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _nutritionGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _nutritionGreen.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isLastStep
                        ? (widget.existingPlan != null ? 'Enregistrer' : 'Activer ce plan')
                        : 'Continuer',
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Placeholder step builders — replaced in Tasks 3-8
  Widget _buildStep1Placeholder() => Center(child: Text('Step 1', style: FGTypography.h2));
  Widget _buildStep2Placeholder() => Center(child: Text('Step 2', style: FGTypography.h2));
  Widget _buildStep3Placeholder() => Center(child: Text('Step 3', style: FGTypography.h2));
  Widget _buildStep4Placeholder() => Center(child: Text('Step 4', style: FGTypography.h2));
  Widget _buildStep5Placeholder() => Center(child: Text('Step 5', style: FGTypography.h2));
  Widget _buildStep6Placeholder() => Center(child: Text('Step 6', style: FGTypography.h2));
}
```

**Step 2: Verify no analysis errors**

Run: `cd fitgame && flutter analyze lib/features/nutrition/create/new_plan_creation_flow.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart
git commit -m "feat(nutrition): add NewPlanCreationFlow orchestrator skeleton"
```

---

## Task 3: Step 1 — Identity

**Files:**
- Modify: `fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 1: Replace `_buildStep1Placeholder()` with the identity step**

The identity step shows a title, a text input for the plan name, and 4 suggestion chips. Tapping a chip pre-fills the name AND sets a `_selectedSuggestion` that will propagate smart defaults to steps 2-3.

```dart
// Add this mapping as a static const in the State class:
static const _suggestionDefaults = {
  'Prise de masse': {'goal': 'bulk', 'cal': 3200, 'restCal': 2800, 'protein': 30, 'carbs': 45, 'fat': 25},
  'Sèche été': {'goal': 'cut', 'cal': 2400, 'restCal': 2000, 'protein': 40, 'carbs': 35, 'fat': 25},
  'Nutrition équilibrée': {'goal': 'maintain', 'cal': 2800, 'restCal': 2500, 'protein': 30, 'carbs': 45, 'fat': 25},
  'Plan personnalisé': {'goal': 'maintain', 'cal': 2800, 'restCal': 2400, 'protein': 30, 'carbs': 45, 'fat': 25},
};

Widget _buildStep1Identity() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(Spacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.xl),
        Text(
          'Crée ton\nplan',
          style: FGTypography.h1.copyWith(fontSize: 32, height: 1.1),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Un nom qui reflète ton objectif nutritionnel',
          style: FGTypography.body.copyWith(color: FGColors.textSecondary),
        ),
        const SizedBox(height: Spacing.xxl),
        Container(
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.md),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: TextField(
            controller: _nameController,
            style: FGTypography.h3.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Ex: Prise de masse été',
              hintStyle: FGTypography.h3.copyWith(
                color: FGColors.textSecondary.withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(Spacing.lg),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          'SUGGESTIONS',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: _suggestionDefaults.keys.map((name) {
            final isSelected = _selectedSuggestion == name;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                final defaults = _suggestionDefaults[name]!;
                setState(() {
                  _selectedSuggestion = name;
                  _nameController.text = name;
                  _goalType = defaults['goal'] as String;
                  _trainingCalories = defaults['cal'] as int;
                  _restCalories = defaults['restCal'] as int;
                  _proteinPercent = defaults['protein'] as int;
                  _carbsPercent = defaults['carbs'] as int;
                  _fatPercent = defaults['fat'] as int;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _nutritionGreen.withValues(alpha: 0.15)
                      : FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(Spacing.xl),
                  border: Border.all(
                    color: isSelected ? _nutritionGreen : FGColors.glassBorder,
                  ),
                ),
                child: Text(
                  name,
                  style: FGTypography.bodySmall.copyWith(
                    color: isSelected ? _nutritionGreen : FGColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}
```

Replace `_buildStep1Placeholder()` call in the PageView with `_buildStep1Identity()`.

**Step 2: Verify no analysis errors**

Run: `cd fitgame && flutter analyze lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart
git commit -m "feat(nutrition): implement Step 1 - Identity with smart suggestion chips"
```

---

## Task 4: Step 2 — Objective & Calories

**Files:**
- Modify: `fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 1: Replace `_buildStep2Placeholder()` with the objective & calories step**

This combines goal selection (3 cards) with calorie configuration (2 cards with smart linking). When the user selects a goal, calories auto-fill. Training/rest calories are linked by default (-400 kcal gap) but the user can "unlink" them.

Key behaviors:
- Goal cards: Bulk (green icon, surplus description), Maintain (blue, balance), Cut (red, deficit)
- Calorie cards: -100/+100 buttons, tap on number for direct input
- Link toggle: chain icon between the two cards

```dart
Widget _buildStep2ObjectiveCalories() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(Spacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.md),
        Text(
          'OBJECTIF',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        ..._buildGoalCards(),
        const SizedBox(height: Spacing.xl),
        Text(
          'CALORIES QUOTIDIENNES',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        _buildCalorieCard(
          title: 'Jour entraînement',
          subtitle: 'Dépense élevée',
          icon: Icons.fitness_center_rounded,
          color: FGColors.accent,
          calories: _trainingCalories,
          onChanged: (val) {
            setState(() {
              _trainingCalories = val;
              if (_caloriesLinked) _restCalories = val - 400;
            });
          },
        ),
        const SizedBox(height: Spacing.sm),
        // Link toggle
        Center(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _caloriesLinked = !_caloriesLinked;
                if (_caloriesLinked) _restCalories = _trainingCalories - 400;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: _caloriesLinked
                    ? _nutritionGreen.withValues(alpha: 0.15)
                    : FGColors.glassSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _caloriesLinked ? _nutritionGreen : FGColors.glassBorder,
                ),
              ),
              child: Icon(
                _caloriesLinked ? Icons.link_rounded : Icons.link_off_rounded,
                color: _caloriesLinked ? _nutritionGreen : FGColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        _buildCalorieCard(
          title: 'Jour repos',
          subtitle: _caloriesLinked ? 'Lié (training - 400)' : 'Personnalisé',
          icon: Icons.self_improvement_rounded,
          color: _nutritionGreen,
          calories: _restCalories,
          onChanged: _caloriesLinked
              ? null
              : (val) => setState(() => _restCalories = val),
        ),
      ],
    ),
  );
}

List<Widget> _buildGoalCards() {
  final goals = [
    {'key': 'bulk', 'label': 'Prise de masse', 'icon': Icons.trending_up_rounded, 'desc': 'Surplus calorique', 'color': const Color(0xFF2ECC71), 'cal': 3200, 'rest': 2800},
    {'key': 'maintain', 'label': 'Maintien', 'icon': Icons.horizontal_rule_rounded, 'desc': 'Équilibre', 'color': const Color(0xFF3498DB), 'cal': 2800, 'rest': 2500},
    {'key': 'cut', 'label': 'Sèche', 'icon': Icons.trending_down_rounded, 'desc': 'Déficit calorique', 'color': const Color(0xFFE74C3C), 'cal': 2400, 'rest': 2000},
  ];

  return goals.map((g) {
    final isSelected = _goalType == g['key'];
    final color = g['color'] as Color;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _goalType = g['key'] as String;
            _trainingCalories = g['cal'] as int;
            _restCalories = g['rest'] as int;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.md),
            border: Border.all(
              color: isSelected ? color : FGColors.glassBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20)]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.2) : FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(g['icon'] as IconData, color: isSelected ? color : FGColors.textSecondary, size: 24),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g['label'] as String, style: FGTypography.body.copyWith(fontWeight: FontWeight.w600, color: isSelected ? color : FGColors.textPrimary)),
                    Text(g['desc'] as String, style: FGTypography.caption.copyWith(color: FGColors.textSecondary)),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }).toList();
}

Widget _buildCalorieCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required int calories,
  required ValueChanged<int>? onChanged,
}) {
  final isDisabled = onChanged == null;
  return Container(
    padding: const EdgeInsets.all(Spacing.lg),
    decoration: BoxDecoration(
      color: FGColors.glassSurface,
      borderRadius: BorderRadius.circular(Spacing.md),
      border: Border.all(color: isDisabled ? FGColors.glassBorder.withValues(alpha: 0.5) : FGColors.glassBorder),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: Spacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FGTypography.body.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: FGTypography.caption.copyWith(color: FGColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIncrementButton(Icons.remove_rounded, isDisabled ? null : () {
              HapticFeedback.lightImpact();
              if (calories > 1000) onChanged!(calories - 100);
            }),
            const SizedBox(width: Spacing.lg),
            Text(
              '$calories',
              style: FGTypography.h1.copyWith(
                fontSize: 40,
                color: isDisabled ? color.withValues(alpha: 0.5) : color,
              ),
            ),
            const SizedBox(width: Spacing.xs),
            Text('kcal', style: FGTypography.caption.copyWith(color: FGColors.textSecondary)),
            const SizedBox(width: Spacing.lg),
            _buildIncrementButton(Icons.add_rounded, isDisabled ? null : () {
              HapticFeedback.lightImpact();
              if (calories < 6000) onChanged!(calories + 100);
            }),
          ],
        ),
      ],
    ),
  );
}

Widget _buildIncrementButton(IconData icon, VoidCallback? onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        shape: BoxShape.circle,
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Icon(icon, color: onTap == null ? FGColors.glassBorder : FGColors.textPrimary, size: 22),
    ),
  );
}
```

Replace `_buildStep2Placeholder()` call with `_buildStep2ObjectiveCalories()`.

**Step 2: Verify no analysis errors**

Run: `cd fitgame && flutter analyze lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart
git commit -m "feat(nutrition): implement Step 2 - Objective & Calories with smart linking"
```

---

## Task 5: Step 3 — Macros with Pie Chart

**Files:**
- Modify: `fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 1: Replace `_buildStep3Placeholder()` with the macros step**

Includes: preset chips (Équilibré, High Protein, Low Carb, Keto), 3 interactive sliders with gram display, and an animated pie chart. The constraint: total must equal 100%. When one slider moves, the others adjust intelligently.

Key logic for intelligent slider adjustment:
- When protein changes by +X: subtract X/2 from carbs and X/2 from fat (clamped to min 10)
- Same pattern for each macro

Add a `_MacroPieChartPainter` CustomPainter inside the same file (private class).

```dart
// Macro presets
static const _macroPresets = {
  'Équilibré': {'p': 30, 'c': 45, 'f': 25},
  'High Protein': {'p': 40, 'c': 35, 'f': 25},
  'Low Carb': {'p': 35, 'c': 25, 'f': 40},
  'Keto': {'p': 30, 'c': 10, 'f': 60},
};

Widget _buildStep3Macros() {
  final totalPercent = _proteinPercent + _carbsPercent + _fatPercent;
  final isValid = totalPercent == 100;
  final proteinGrams = (_trainingCalories * _proteinPercent / 100 / 4).round();
  final carbsGrams = (_trainingCalories * _carbsPercent / 100 / 4).round();
  final fatGrams = (_trainingCalories * _fatPercent / 100 / 9).round();

  return SingleChildScrollView(
    padding: const EdgeInsets.all(Spacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.md),
        // Presets
        Text('PRESETS', style: FGTypography.caption.copyWith(color: FGColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: Spacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _macroPresets.entries.map((entry) {
              final isSelected = _proteinPercent == entry.value['p'] && _carbsPercent == entry.value['c'] && _fatPercent == entry.value['f'];
              return Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _proteinPercent = entry.value['p']!;
                      _carbsPercent = entry.value['c']!;
                      _fatPercent = entry.value['f']!;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? _nutritionGreen.withValues(alpha: 0.15) : FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.xl),
                      border: Border.all(color: isSelected ? _nutritionGreen : FGColors.glassBorder),
                    ),
                    child: Text(
                      entry.key,
                      style: FGTypography.bodySmall.copyWith(
                        color: isSelected ? _nutritionGreen : FGColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: Spacing.xl),

        // Pie chart
        Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _MacroPieChartPainter(
                protein: _proteinPercent,
                carbs: _carbsPercent,
                fat: _fatPercent,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$totalPercent%', style: FGTypography.h2.copyWith(
                      color: isValid ? _nutritionGreen : FGColors.error,
                    )),
                    Text('total', style: FGTypography.caption.copyWith(color: FGColors.textSecondary)),
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
          onChanged: (val) => _adjustMacros('protein', val),
        ),
        const SizedBox(height: Spacing.lg),
        _buildMacroSlider(
          label: 'Glucides',
          percent: _carbsPercent,
          grams: carbsGrams,
          color: const Color(0xFFF39C12),
          onChanged: (val) => _adjustMacros('carbs', val),
        ),
        const SizedBox(height: Spacing.lg),
        _buildMacroSlider(
          label: 'Lipides',
          percent: _fatPercent,
          grams: fatGrams,
          color: const Color(0xFF3498DB),
          onChanged: (val) => _adjustMacros('fat', val),
        ),
        if (!isValid)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.md),
            child: Text(
              'Le total doit être 100% (actuellement $totalPercent%)',
              style: FGTypography.caption.copyWith(color: FGColors.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    ),
  );
}

void _adjustMacros(String changed, int newValue) {
  setState(() {
    switch (changed) {
      case 'protein':
        final delta = newValue - _proteinPercent;
        _proteinPercent = newValue;
        _carbsPercent = (_carbsPercent - (delta / 2).round()).clamp(10, 60);
        _fatPercent = 100 - _proteinPercent - _carbsPercent;
        break;
      case 'carbs':
        final delta = newValue - _carbsPercent;
        _carbsPercent = newValue;
        _fatPercent = (_fatPercent - (delta / 2).round()).clamp(10, 60);
        _proteinPercent = 100 - _carbsPercent - _fatPercent;
        break;
      case 'fat':
        final delta = newValue - _fatPercent;
        _fatPercent = newValue;
        _proteinPercent = (_proteinPercent - (delta / 2).round()).clamp(10, 60);
        _carbsPercent = 100 - _fatPercent - _proteinPercent;
        break;
    }
    _proteinPercent = _proteinPercent.clamp(10, 60);
    _carbsPercent = _carbsPercent.clamp(10, 60);
    _fatPercent = _fatPercent.clamp(10, 60);
  });
}

Widget _buildMacroSlider({
  required String label,
  required int percent,
  required int grams,
  required Color color,
  required ValueChanged<int> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: Spacing.sm),
              Text(label, style: FGTypography.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              Text('$percent%', style: FGTypography.h3.copyWith(color: color)),
              const SizedBox(width: Spacing.sm),
              Text('(${grams}g)', style: FGTypography.caption.copyWith(color: FGColors.textSecondary)),
            ],
          ),
        ],
      ),
      const SizedBox(height: Spacing.sm),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: color,
          inactiveTrackColor: color.withValues(alpha: 0.2),
          thumbColor: color,
          overlayColor: color.withValues(alpha: 0.1),
          trackHeight: 8,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        ),
        child: Slider(
          value: percent.toDouble(),
          min: 10,
          max: 60,
          divisions: 50,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            onChanged(value.round());
          },
        ),
      ),
    ],
  );
}
```

**Step 2: Add the `_MacroPieChartPainter` class at the bottom of the file**

```dart
class _MacroPieChartPainter extends CustomPainter {
  final int protein;
  final int carbs;
  final int fat;

  _MacroPieChartPainter({required this.protein, required this.carbs, required this.fat});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final total = protein + carbs + fat;
    if (total == 0) return;

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 16..strokeCap = StrokeCap.round;
    const startAngle = -3.14159 / 2; // Start from top
    double currentAngle = startAngle;

    final segments = [
      {'value': protein, 'color': const Color(0xFFE74C3C)},
      {'value': carbs, 'color': const Color(0xFFF39C12)},
      {'value': fat, 'color': const Color(0xFF3498DB)},
    ];

    for (final segment in segments) {
      final sweepAngle = (segment['value'] as int) / total * 2 * 3.14159;
      paint.color = segment['color'] as Color;
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
  bool shouldRepaint(covariant _MacroPieChartPainter oldDelegate) =>
      protein != oldDelegate.protein || carbs != oldDelegate.carbs || fat != oldDelegate.fat;
}
```

Replace `_buildStep3Placeholder()` call with `_buildStep3Macros()`.

**Step 3: Verify no analysis errors**

Run: `cd fitgame && flutter analyze lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 4: Commit**

```bash
git add fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart
git commit -m "feat(nutrition): implement Step 3 - Macros with pie chart and smart sliders"
```

---

## Task 6: Day Type Editor Sheet

**Files:**
- Create: `fitgame/lib/features/nutrition/create/widgets/day_type_editor_sheet.dart`

**Step 1: Create the fullscreen bottom sheet for editing a day type**

This sheet lets the user edit a day type: name, emoji, and meals (as accordions with foods). It integrates with the existing `FoodAddSheet` for adding foods.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../sheets/food_add_sheet.dart';
import '../../sheets/food_quantity_sheet.dart';
import '../../models/diet_models.dart';

class DayTypeEditorSheet extends StatefulWidget {
  final Map<String, dynamic> dayType;
  final ValueChanged<Map<String, dynamic>> onSave;

  const DayTypeEditorSheet({
    super.key,
    required this.dayType,
    required this.onSave,
  });

  @override
  State<DayTypeEditorSheet> createState() => _DayTypeEditorSheetState();
}
```

The editor includes:
- Name text field
- Emoji grid selector (14 emojis: 🏋️ 🧘 💪 🏃 🚴 🏊 ⚡ 🔥 🍽️ 🥗 📅 🌙 🎯 ⭐)
- Meal accordions: each meal has a name, icon, expandable food list
- Add meal button at bottom
- Add food button inside each meal → opens FoodAddSheet → FoodQuantitySheet
- Delete meal (swipe or button, min 1 meal)
- Calculated total calories displayed at top

The full implementation follows the existing patterns from `plan_creation_flow.dart` lines 962-1333 (`_DayTypeEditorSheet`), adapted to use accordions instead of flat lists.

**Step 2: Verify no analysis errors**

Run: `cd fitgame && flutter analyze lib/features/nutrition/create/widgets/day_type_editor_sheet.dart`

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/create/widgets/day_type_editor_sheet.dart
git commit -m "feat(nutrition): add DayTypeEditorSheet with accordion meals and food integration"
```

---

## Task 7: Step 4 — Day Types

**Files:**
- Modify: `fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 1: Replace `_buildStep4Placeholder()` with the day types step**

Displays day type cards with: emoji, name, meal count, total calories, edit/duplicate/delete buttons. "Add type" button at bottom. Tap edit → opens `DayTypeEditorSheet`. Duplicate creates a copy with "(copie)" suffix.

```dart
// Import at top:
import 'widgets/day_type_editor_sheet.dart';

Widget _buildStep4DayTypes() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(Spacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.md),
        Text(
          'Configure les différents types de journée de ton plan.',
          style: FGTypography.body.copyWith(color: FGColors.textSecondary),
        ),
        const SizedBox(height: Spacing.lg),
        ..._dayTypes.asMap().entries.map((entry) {
          final index = entry.key;
          final dt = entry.value;
          final meals = dt['meals'] as List? ?? [];
          final totalCal = _calculateDayTypeCalories(meals);
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Container(
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
                      Text(dt['emoji'] as String? ?? '📅', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dt['name'] as String, style: FGTypography.body.copyWith(fontWeight: FontWeight.w600)),
                            Text('${meals.length} repas · $totalCal kcal', style: FGTypography.caption.copyWith(color: FGColors.textSecondary)),
                          ],
                        ),
                      ),
                      // Edit
                      IconButton(
                        icon: Icon(Icons.edit_rounded, color: _nutritionGreen, size: 20),
                        onPressed: () => _editDayType(index),
                      ),
                      // Duplicate
                      IconButton(
                        icon: Icon(Icons.copy_rounded, color: FGColors.textSecondary, size: 20),
                        onPressed: () => _duplicateDayType(index),
                      ),
                      // Delete (only if > 1)
                      if (_dayTypes.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: FGColors.error, size: 20),
                          onPressed: () => _deleteDayType(index),
                        ),
                    ],
                  ),
                  // Mini meal preview
                  if (meals.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: Row(
                        children: meals.take(5).map((m) {
                          return Padding(
                            padding: const EdgeInsets.only(right: Spacing.xs),
                            child: Chip(
                              label: Text(
                                (m as Map)['name'] as String? ?? 'Repas',
                                style: FGTypography.caption.copyWith(fontSize: 10),
                              ),
                              backgroundColor: FGColors.glassBorder,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        // Add day type button
        GestureDetector(
          onTap: _addDayType,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(Spacing.md),
              border: Border.all(color: _nutritionGreen.withValues(alpha: 0.3), style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: _nutritionGreen, size: 20),
                const SizedBox(width: Spacing.sm),
                Text('Ajouter un type de jour', style: FGTypography.body.copyWith(color: _nutritionGreen, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

int _calculateDayTypeCalories(List meals) {
  int total = 0;
  for (final meal in meals) {
    final foods = (meal as Map)['foods'] as List? ?? [];
    for (final food in foods) {
      total += ((food as Map)['calories'] as int?) ?? 0;
    }
  }
  return total;
}

void _editDayType(int index) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DayTypeEditorSheet(
      dayType: Map<String, dynamic>.from(_dayTypes[index]),
      onSave: (updated) {
        setState(() => _dayTypes[index] = updated);
        Navigator.pop(context);
      },
    ),
  );
}

void _duplicateDayType(int index) {
  HapticFeedback.mediumImpact();
  final original = _dayTypes[index];
  setState(() {
    _dayTypes.add({
      'name': '${original['name']} (copie)',
      'emoji': original['emoji'],
      'meals': List<Map<String, dynamic>>.from(
        (original['meals'] as List).map((m) => Map<String, dynamic>.from(m as Map)),
      ),
    });
  });
}

void _deleteDayType(int index) {
  if (_dayTypes.length <= 1) return;
  HapticFeedback.mediumImpact();
  setState(() {
    _dayTypes.removeAt(index);
    // Fix weekly schedule references
    _weeklySchedule.updateAll((key, value) {
      if (value >= _dayTypes.length) return _dayTypes.length - 1;
      return value;
    });
  });
}

void _addDayType() {
  HapticFeedback.mediumImpact();
  setState(() {
    _dayTypes.add({
      'name': 'Nouveau type',
      'emoji': '📅',
      'meals': <Map<String, dynamic>>[
        {'name': 'Petit-déjeuner', 'icon': 'wb_sunny_rounded', 'foods': <Map<String, dynamic>>[]},
        {'name': 'Déjeuner', 'icon': 'restaurant_rounded', 'foods': <Map<String, dynamic>>[]},
        {'name': 'Dîner', 'icon': 'nightlight_round', 'foods': <Map<String, dynamic>>[]},
      ],
    });
  });
  // Auto-open editor for new type
  WidgetsBinding.instance.addPostFrameCallback((_) => _editDayType(_dayTypes.length - 1));
}
```

Replace `_buildStep4Placeholder()` call with `_buildStep4DayTypes()`.

**Step 2: Verify no analysis errors**

Run: `cd fitgame && flutter analyze lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart
git commit -m "feat(nutrition): implement Step 4 - Day Types with edit/duplicate/delete"
```

---

## Task 8: Step 5 — Weekly Schedule

**Files:**
- Modify: `fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 1: Replace `_buildStep5Placeholder()` with the weekly schedule step**

7 rows (Mon-Sun), each with a custom inline selector for day type. Summary at bottom showing day distribution and weekly calorie average.

```dart
static const _dayNames = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
static const _dayNamesShort = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

Widget _buildStep5WeeklySchedule() {
  // Calculate summary
  final typeCounts = <int, int>{};
  for (final entry in _weeklySchedule.values) {
    typeCounts[entry] = (typeCounts[entry] ?? 0) + 1;
  }
  int totalWeeklyCal = 0;
  for (final entry in _weeklySchedule.entries) {
    final dtIndex = entry.value;
    if (dtIndex < _dayTypes.length) {
      final meals = _dayTypes[dtIndex]['meals'] as List? ?? [];
      totalWeeklyCal += _calculateDayTypeCalories(meals);
    }
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.all(Spacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.md),
        Text(
          'Assigne un type de jour à chaque journée de la semaine.',
          style: FGTypography.body.copyWith(color: FGColors.textSecondary),
        ),
        const SizedBox(height: Spacing.lg),
        // Calendar rows
        ...List.generate(7, (dayIndex) {
          final selectedTypeIndex = _weeklySchedule[dayIndex] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(Spacing.sm),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      _dayNamesShort[dayIndex],
                      style: FGTypography.body.copyWith(fontWeight: FontWeight.w600, color: FGColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showDayTypeSelector(dayIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                        decoration: BoxDecoration(
                          color: FGColors.glassBorder.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(Spacing.sm),
                        ),
                        child: Row(
                          children: [
                            Text(
                              selectedTypeIndex < _dayTypes.length
                                  ? _dayTypes[selectedTypeIndex]['emoji'] as String? ?? '📅'
                                  : '📅',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                selectedTypeIndex < _dayTypes.length
                                    ? _dayTypes[selectedTypeIndex]['name'] as String
                                    : 'Sélectionner',
                                style: FGTypography.body,
                              ),
                            ),
                            Icon(Icons.expand_more_rounded, color: FGColors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: Spacing.lg),
        // Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: _nutritionGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Spacing.md),
            border: Border.all(color: _nutritionGreen.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: typeCounts.entries.map((e) {
                  final dt = e.key < _dayTypes.length ? _dayTypes[e.key] : null;
                  if (dt == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                    child: Text(
                      '${dt['emoji']} ${e.value}j ${dt['name']}',
                      style: FGTypography.bodySmall.copyWith(color: FGColors.textSecondary),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                '~$totalWeeklyCal kcal / semaine',
                style: FGTypography.body.copyWith(color: _nutritionGreen, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showDayTypeSelector(int dayIndex) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: FGColors.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Spacing.lg)),
      ),
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(_dayNames[dayIndex], style: FGTypography.h3),
          const SizedBox(height: Spacing.md),
          ..._dayTypes.asMap().entries.map((entry) {
            final isSelected = _weeklySchedule[dayIndex] == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _weeklySchedule[dayIndex] = entry.key);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: isSelected ? _nutritionGreen.withValues(alpha: 0.1) : FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(color: isSelected ? _nutritionGreen : FGColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Text(entry.value['emoji'] as String? ?? '📅', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: Spacing.md),
                      Expanded(child: Text(entry.value['name'] as String, style: FGTypography.body.copyWith(fontWeight: FontWeight.w600))),
                      if (isSelected) Icon(Icons.check_circle_rounded, color: _nutritionGreen, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
  );
}
```

Replace `_buildStep5Placeholder()` call with `_buildStep5WeeklySchedule()`.

**Step 2: Verify no analysis errors**

Run: `cd fitgame && flutter analyze lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart
git commit -m "feat(nutrition): implement Step 5 - Weekly Schedule with custom selectors"
```

---

## Task 9: Step 6 — Recap & Validation

**Files:**
- Modify: `fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 1: Replace `_buildStep6Placeholder()` with the recap step**

A scrollable read-only summary of the entire plan. Each section is tappable to jump to its corresponding step.

```dart
Widget _buildStep6Recap() {
  final proteinGrams = (_trainingCalories * _proteinPercent / 100 / 4).round();
  final carbsGrams = (_trainingCalories * _carbsPercent / 100 / 4).round();
  final fatGrams = (_trainingCalories * _fatPercent / 100 / 9).round();

  return SingleChildScrollView(
    padding: const EdgeInsets.all(Spacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Spacing.md),
        // Plan name
        Center(
          child: Column(
            children: [
              Text('📋', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: Spacing.sm),
              Text(
                _nameController.text,
                style: FGTypography.h2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),

        // Objective section
        _buildRecapSection(
          stepIndex: 1,
          title: 'Objectif',
          child: Row(
            children: [
              _buildRecapPill(_goalLabel(), _goalColor()),
              const SizedBox(width: Spacing.sm),
              Text('🔥 $_trainingCalories kcal training', style: FGTypography.bodySmall),
              const SizedBox(width: Spacing.sm),
              Text('🧘 $_restCalories kcal repos', style: FGTypography.bodySmall),
            ],
          ),
        ),

        // Macros section
        _buildRecapSection(
          stepIndex: 2,
          title: 'Macros',
          child: Row(
            children: [
              _buildRecapMacroPill('P', _proteinPercent, proteinGrams, const Color(0xFFE74C3C)),
              const SizedBox(width: Spacing.sm),
              _buildRecapMacroPill('G', _carbsPercent, carbsGrams, const Color(0xFFF39C12)),
              const SizedBox(width: Spacing.sm),
              _buildRecapMacroPill('L', _fatPercent, fatGrams, const Color(0xFF3498DB)),
            ],
          ),
        ),

        // Day types section
        _buildRecapSection(
          stepIndex: 3,
          title: 'Types de jour',
          child: Column(
            children: _dayTypes.map((dt) {
              final meals = dt['meals'] as List? ?? [];
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: Row(
                  children: [
                    Text(dt['emoji'] as String? ?? '📅', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: Spacing.sm),
                    Text(dt['name'] as String, style: FGTypography.body),
                    const Spacer(),
                    Text('${meals.length} repas · ${_calculateDayTypeCalories(meals)} kcal',
                        style: FGTypography.caption.copyWith(color: FGColors.textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Weekly schedule section
        _buildRecapSection(
          stepIndex: 4,
          title: 'Planning semaine',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final dtIndex = _weeklySchedule[i] ?? 0;
              final dt = dtIndex < _dayTypes.length ? _dayTypes[dtIndex] : null;
              return Column(
                children: [
                  Text(_dayNamesShort[i], style: FGTypography.caption.copyWith(color: FGColors.textSecondary, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(dt?['emoji'] as String? ?? '📅', style: const TextStyle(fontSize: 20)),
                ],
              );
            }),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRecapSection({
  required int stepIndex,
  required String title,
  required Widget child,
}) {
  return GestureDetector(
    onTap: () => _jumpToStep(stepIndex),
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: FGTypography.body.copyWith(fontWeight: FontWeight.w600, color: FGColors.textSecondary)),
              Icon(Icons.edit_rounded, color: FGColors.textSecondary, size: 16),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          child,
        ],
      ),
    ),
  );
}

Widget _buildRecapPill(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(Spacing.sm),
    ),
    child: Text(label, style: FGTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
  );
}

Widget _buildRecapMacroPill(String letter, int percent, int grams, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(Spacing.sm),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: Spacing.xs),
        Text('$letter $percent% (${grams}g)', style: FGTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

String _goalLabel() {
  switch (_goalType) {
    case 'bulk': return 'Prise de masse';
    case 'cut': return 'Sèche';
    default: return 'Maintien';
  }
}

Color _goalColor() {
  switch (_goalType) {
    case 'bulk': return const Color(0xFF2ECC71);
    case 'cut': return const Color(0xFFE74C3C);
    default: return const Color(0xFF3498DB);
  }
}
```

Replace `_buildStep6Placeholder()` call with `_buildStep6Recap()`.

**Step 2: Verify no analysis errors**

Run: `cd fitgame && flutter analyze lib/features/nutrition/create/new_plan_creation_flow.dart`

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart
git commit -m "feat(nutrition): implement Step 6 - Recap with tappable sections"
```

---

## Task 10: Wire Entry Point & Integration

**Files:**
- Modify: `fitgame/lib/features/nutrition/nutrition_screen.dart`

**Step 1: Update `_openPlanCreation()` to use `NewPlanCreationFlow`**

In `nutrition_screen.dart`, find the `_openPlanCreation` method (around line 1586) and change the import and reference from `PlanCreationFlow` to `NewPlanCreationFlow`.

Add import at top:
```dart
import 'create/new_plan_creation_flow.dart';
```

Change the method body:
```dart
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
```

**Step 2: Verify no analysis errors on the full project**

Run: `cd fitgame && flutter analyze`
Expected: No issues found (or only pre-existing warnings)

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/nutrition_screen.dart
git commit -m "feat(nutrition): wire NewPlanCreationFlow as entry point from nutrition screen"
```

---

## Task 11: Update Documentation

**Files:**
- Modify: `fitgame/docs/CHANGELOG.md`
- Modify: `fitgame/docs/SCREENS.md`

**Step 1: Add changelog entry**

Add at the top of CHANGELOG.md:
```markdown
## [YYYY-MM-DD] - Nutrition Plan Creation Redesign

### Added
- New unified 6-step nutrition plan creation flow
- Smart suggestion chips that pre-fill goal, calories, and macros
- Animated pie chart for macro distribution visualization
- Clickable progress dots for free navigation between visited steps
- Auto-saved drafts via SharedPreferences
- Exit confirmation dialog with save/delete draft options
- Day type duplication feature
- Weekly calorie summary in schedule step
- Tappable recap sections for quick edits

### Changed
- Replaced dual creation flows (3-step PlanCreationFlow + 8-step DietCreationFlow) with single unified flow
- Merged Objective and Calories into one step
- Added intelligent calorie linking between training/rest days

### Improved
- Calorie adjustment with smart training↔rest linking
- Macro sliders with intelligent auto-balancing (total always 100%)
- Day type editor with accordion-style meal display
- Weekly schedule with custom inline selectors instead of native dropdowns
```

**Step 2: Update SCREENS.md**

Update the nutrition creation flow section to document the new 6-step flow and its navigation patterns.

**Step 3: Commit**

```bash
git add fitgame/docs/CHANGELOG.md fitgame/docs/SCREENS.md
git commit -m "docs: update changelog and screens for nutrition creation redesign"
```

---

## Task 12: Final Verification

**Step 1: Run full analysis**

Run: `cd fitgame && flutter analyze`
Expected: No new errors

**Step 2: Run existing tests**

Run: `cd fitgame && flutter test`
Expected: All existing tests pass (this is additive, not modifying tested code)

**Step 3: Manual verification checklist**

Verify on simulator (via mobile-mcp):
- [ ] Nutrition screen → tap "+" → new flow opens
- [ ] Step 1: Type name, tap suggestion chip → name fills, proceed
- [ ] Step 2: Select goal → calories auto-fill, link toggle works
- [ ] Step 3: Tap preset → sliders update, pie chart animates
- [ ] Step 4: Edit day type → sheet opens, add food works
- [ ] Step 5: Assign day types → summary updates
- [ ] Step 6: Recap shows all data, tap section → jumps to step
- [ ] Progress dots: tap visited dot → jumps to step
- [ ] Back button on step 1 → exit confirmation dialog
- [ ] Close app mid-flow → reopen → draft restored
- [ ] Complete flow → plan saved and activated

---

## Summary

| Task | Description | Files | Estimated Effort |
|------|-------------|-------|-----------------|
| 1 | Progress Dots Widget | 1 new | Small |
| 2 | Main Orchestrator Skeleton | 1 new | Medium |
| 3 | Step 1 — Identity | 1 modify | Small |
| 4 | Step 2 — Objective & Calories | 1 modify | Medium |
| 5 | Step 3 — Macros + Pie Chart | 1 modify | Medium |
| 6 | Day Type Editor Sheet | 1 new | Large |
| 7 | Step 4 — Day Types | 1 modify | Medium |
| 8 | Step 5 — Weekly Schedule | 1 modify | Medium |
| 9 | Step 6 — Recap | 1 modify | Medium |
| 10 | Wire Entry Point | 1 modify | Small |
| 11 | Documentation | 2 modify | Small |
| 12 | Final Verification | 0 | Small |

**Total new files:** 3 (progress_dots.dart, new_plan_creation_flow.dart, day_type_editor_sheet.dart)
**Total modified files:** 3 (nutrition_screen.dart, CHANGELOG.md, SCREENS.md)
**Estimated tasks:** 12

**Key dependency chain:** Task 1 → Task 2 → Tasks 3-9 (sequential, building on orchestrator) → Task 10 → Task 11 → Task 12
