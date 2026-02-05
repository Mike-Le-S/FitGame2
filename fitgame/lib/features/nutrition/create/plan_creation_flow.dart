import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class PlanCreationFlow extends StatefulWidget {
  final Map<String, dynamic>? existingPlan; // null = create, not null = edit

  const PlanCreationFlow({super.key, this.existingPlan});

  @override
  State<PlanCreationFlow> createState() => _PlanCreationFlowState();
}

class _PlanCreationFlowState extends State<PlanCreationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Plan info
  final _nameController = TextEditingController();
  String _goalType = 'maintain';
  int _trainingCalories = 2800;
  int _restCalories = 2500;

  // Step 2: Day types
  List<Map<String, dynamic>> _dayTypes = [];

  // Step 3: Weekly schedule (dayOfWeek -> dayTypeIndex)
  Map<int, int> _weeklySchedule = {};

  bool _isSaving = false;

  static const _nutritionGreen = Color(0xFF2ECC71);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.existingPlan != null) {
      // Edit mode - load existing data
      final plan = widget.existingPlan!;
      _nameController.text = plan['name'] as String? ?? '';
      _goalType = plan['goal'] as String? ?? 'maintain';
      _trainingCalories = plan['training_calories'] as int? ?? 2800;
      _restCalories = plan['rest_calories'] as int? ?? 2500;
      _loadExistingDayTypes();
    } else {
      // Create mode - initialize with defaults
      _dayTypes = [
        {
          'name': 'Jour entraînement',
          'emoji': '🏋️',
          'meals': _getDefaultMeals(),
        },
        {
          'name': 'Jour repos',
          'emoji': '😴',
          'meals': _getDefaultMeals(),
        },
      ];
      // Default schedule: Mon/Wed/Fri = training, rest otherwise
      _weeklySchedule = {0: 0, 1: 1, 2: 0, 3: 1, 4: 0, 5: 1, 6: 1};
    }
  }

  List<Map<String, dynamic>> _getDefaultMeals() {
    return [
      {'name': 'Petit-déjeuner', 'foods': []},
      {'name': 'Déjeuner', 'foods': []},
      {'name': 'Collation', 'foods': []},
      {'name': 'Dîner', 'foods': []},
    ];
  }

  Future<void> _loadExistingDayTypes() async {
    if (widget.existingPlan == null) return;

    final planId = widget.existingPlan!['id'] as String;
    final dayTypes = await SupabaseService.getDayTypes(planId);
    final schedule = await SupabaseService.getWeeklySchedule(planId);

    if (mounted) {
      setState(() {
        _dayTypes = dayTypes.map((dt) => {
          'id': dt['id'],
          'name': dt['name'],
          'emoji': dt['emoji'],
          'meals': dt['meals'] ?? [],
        }).toList();

        // Build schedule map
        for (final s in schedule) {
          final dayOfWeek = s['day_of_week'] as int;
          final dayTypeId = s['day_type_id'] as String;
          final index = _dayTypes.indexWhere((dt) => dt['id'] == dayTypeId);
          if (index >= 0) {
            _weeklySchedule[dayOfWeek] = index;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
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
      Navigator.pop(context);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _dayTypes.isNotEmpty;
      case 2:
        return _weeklySchedule.length == 7;
      default:
        return false;
    }
  }

  Future<void> _savePlan() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      String planId;

      if (widget.existingPlan != null) {
        // Update existing plan
        planId = widget.existingPlan!['id'] as String;
        await SupabaseService.updateDietPlan(planId, {
          'name': _nameController.text.trim(),
          'goal': _goalType,
          'training_calories': _trainingCalories,
          'rest_calories': _restCalories,
        });
      } else {
        // Create new plan
        final plan = await SupabaseService.createDietPlan(
          name: _nameController.text.trim(),
          goal: _goalType,
          trainingCalories: _trainingCalories,
          restCalories: _restCalories,
          trainingMacros: {},
          restMacros: {},
          meals: [],
        );
        planId = plan['id'] as String;
      }

      // Save day types
      final dayTypeIds = <String>[];
      for (int i = 0; i < _dayTypes.length; i++) {
        final dt = _dayTypes[i];
        if (dt['id'] != null) {
          // Update existing
          await SupabaseService.updateDayType(dt['id'] as String, {
            'name': dt['name'],
            'emoji': dt['emoji'],
            'meals': dt['meals'],
            'sort_order': i,
          });
          dayTypeIds.add(dt['id'] as String);
        } else {
          // Create new
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

      // Activate if new plan
      if (widget.existingPlan == null) {
        await SupabaseService.activateDietPlan(planId);
      }

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingPlan != null
                ? 'Plan mis à jour'
                : 'Plan créé et activé'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1PlanInfo(),
                  _buildStep2DayTypes(),
                  _buildStep3WeeklySchedule(),
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = ['Infos du plan', 'Types de jour', 'Planning semaine'];
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
            child: Text(
              titles[_currentStep],
              style: FGTypography.h3,
            ),
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

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, 0),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < _totalSteps - 1 ? Spacing.xs : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isCurrent ? 4 : 3,
                decoration: BoxDecoration(
                  color: isActive ? _nutritionGreen : FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: _nutritionGreen.withValues(alpha: 0.5), blurRadius: 8)]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1PlanInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.lg),
          Text(
            'NOM DU PLAN',
            style: FGTypography.caption.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: _nameController,
            style: FGTypography.body,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Ex: Prise de masse été',
              hintStyle: FGTypography.body.copyWith(
                color: FGColors.textSecondary.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: FGColors.glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacing.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            'OBJECTIF',
            style: FGTypography.caption.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              _buildGoalChip('bulk', 'Prise', Icons.trending_up_rounded),
              const SizedBox(width: Spacing.sm),
              _buildGoalChip('maintain', 'Maintien', Icons.remove_rounded),
              const SizedBox(width: Spacing.sm),
              _buildGoalChip('cut', 'Sèche', Icons.trending_down_rounded),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            'CALORIES CIBLES',
            style: FGTypography.caption.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildCalorieInput(
                  label: 'Training',
                  value: _trainingCalories,
                  icon: Icons.fitness_center_rounded,
                  color: FGColors.accent,
                  onChanged: (v) => setState(() => _trainingCalories = v),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _buildCalorieInput(
                  label: 'Repos',
                  value: _restCalories,
                  icon: Icons.bedtime_rounded,
                  color: const Color(0xFF9B59B6),
                  onChanged: (v) => setState(() => _restCalories = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChip(String value, String label, IconData icon) {
    final isSelected = _goalType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _goalType = value;
            // Update default calories based on goal
            switch (value) {
              case 'bulk':
                _trainingCalories = 3200;
                _restCalories = 2800;
                break;
              case 'cut':
                _trainingCalories = 2400;
                _restCalories = 2000;
                break;
              case 'maintain':
                _trainingCalories = 2800;
                _restCalories = 2500;
                break;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? _nutritionGreen.withValues(alpha: 0.15)
                : FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.md),
            border: Border.all(
              color: isSelected ? _nutritionGreen : FGColors.glassBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? _nutritionGreen : FGColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                label,
                style: FGTypography.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _nutritionGreen : FGColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieInput({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: Spacing.xs),
              Text(
                label,
                style: FGTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged((value - 100).clamp(1000, 5000));
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Icon(Icons.remove, color: color, size: 18),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: FGTypography.h2.copyWith(fontSize: 24),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged((value + 100).clamp(1000, 5000));
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Icon(Icons.add, color: color, size: 18),
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              'kcal',
              style: FGTypography.caption.copyWith(color: FGColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2DayTypes() {
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        const SizedBox(height: Spacing.lg),
        Text(
          'MES TYPES DE JOUR',
          style: FGTypography.caption.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        ..._dayTypes.asMap().entries.map((entry) {
          final index = entry.key;
          final dt = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: _buildDayTypeCard(index, dt),
          );
        }),
        // Add button
        GestureDetector(
          onTap: _addDayType,
          child: Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              color: FGColors.glassSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Spacing.lg),
              border: Border.all(color: FGColors.glassBorder, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: FGColors.textSecondary, size: 20),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Ajouter un type de jour',
                  style: FGTypography.body.copyWith(
                    color: FGColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayTypeCard(int index, Map<String, dynamic> dayType) {
    final meals = dayType['meals'] as List? ?? [];
    final mealCount = meals.length;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.glassSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Spacing.lg),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        children: [
          Text(dayType['emoji'] as String? ?? '📅', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayType['name'] as String? ?? 'Type',
                  style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$mealCount repas',
                  style: FGTypography.caption.copyWith(color: FGColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _editDayType(index),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: _nutritionGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Text(
                'Éditer',
                style: FGTypography.caption.copyWith(
                  color: _nutritionGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_dayTypes.length > 1) ...[
            const SizedBox(width: Spacing.sm),
            GestureDetector(
              onTap: () => _deleteDayType(index),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FGColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(Icons.delete_outline, color: FGColors.error, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addDayType() {
    HapticFeedback.lightImpact();
    setState(() {
      _dayTypes.add({
        'name': 'Nouveau type',
        'emoji': '📅',
        'meals': _getDefaultMeals(),
      });
    });
  }

  void _editDayType(int index) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => _DayTypeEditorSheet(
          dayType: Map<String, dynamic>.from(_dayTypes[index]),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _dayTypes[index] = result;
      });
    }
  }

  void _deleteDayType(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dayTypes.removeAt(index);
      // Update schedule to remove references to deleted type
      _weeklySchedule.updateAll((key, value) {
        if (value == index) return 0;
        if (value > index) return value - 1;
        return value;
      });
    });
  }

  Widget _buildStep3WeeklySchedule() {
    final dayNames = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        const SizedBox(height: Spacing.lg),
        Text(
          'PLANNING DE LA SEMAINE',
          style: FGTypography.caption.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        ...List.generate(7, (dayIndex) {
          final selectedTypeIndex = _weeklySchedule[dayIndex] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: FGColors.glassSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(Spacing.md),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      dayNames[dayIndex],
                      style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                      decoration: BoxDecoration(
                        color: FGColors.background,
                        borderRadius: BorderRadius.circular(Spacing.sm),
                        border: Border.all(color: FGColors.glassBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedTypeIndex < _dayTypes.length ? selectedTypeIndex : 0,
                          isExpanded: true,
                          dropdownColor: FGColors.glassSurface,
                          style: FGTypography.body,
                          items: _dayTypes.asMap().entries.map((entry) {
                            final dt = entry.value;
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Row(
                                children: [
                                  Text(dt['emoji'] as String? ?? '📅'),
                                  const SizedBox(width: Spacing.sm),
                                  Text(dt['name'] as String? ?? 'Type'),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              HapticFeedback.selectionClick();
                              setState(() => _weeklySchedule[dayIndex] = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomActions() {
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
                        ? (widget.existingPlan != null ? 'Enregistrer' : 'Créer le plan')
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
}

// Simple inline editor for day types (can be expanded later)
class _DayTypeEditorSheet extends StatefulWidget {
  final Map<String, dynamic> dayType;

  const _DayTypeEditorSheet({required this.dayType});

  @override
  State<_DayTypeEditorSheet> createState() => _DayTypeEditorSheetState();
}

class _DayTypeEditorSheetState extends State<_DayTypeEditorSheet> {
  late TextEditingController _nameController;
  late String _emoji;
  late List<Map<String, dynamic>> _meals;

  final List<String> _availableEmojis = [
    '🏋️', '💪', '🏃', '😴', '🧘', '🚴', '🏊', '⚽', '🎾', '🥊', '📅', '🔥', '💯', '🌟'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dayType['name'] as String? ?? '');
    _emoji = widget.dayType['emoji'] as String? ?? '📅';
    _meals = List<Map<String, dynamic>>.from(
      (widget.dayType['meals'] as List? ?? []).map((m) => Map<String, dynamic>.from(m as Map)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      appBar: AppBar(
        backgroundColor: FGColors.background,
        title: Text('Éditer le type', style: FGTypography.h3),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                ...widget.dayType,
                'name': _nameController.text.trim(),
                'emoji': _emoji,
                'meals': _meals,
              });
            },
            child: Text(
              'Sauvegarder',
              style: FGTypography.body.copyWith(
                color: const Color(0xFF2ECC71),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          // Name
          Text(
            'NOM',
            style: FGTypography.caption.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: _nameController,
            style: FGTypography.body,
            decoration: InputDecoration(
              filled: true,
              fillColor: FGColors.glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacing.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Emoji
          Text(
            'ICÔNE',
            style: FGTypography.caption.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: _availableEmojis.map((e) {
              final isSelected = _emoji == e;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _emoji = e);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2ECC71).withValues(alpha: 0.2)
                        : FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2ECC71) : FGColors.glassBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacing.xl),

          // Meals
          Row(
            children: [
              Text(
                'REPAS',
                style: FGTypography.caption.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: FGColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _meals.add({'name': 'Nouveau repas', 'foods': []});
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Text(
                    '+ Ajouter',
                    style: FGTypography.caption.copyWith(
                      color: const Color(0xFF2ECC71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ...List.generate(_meals.length, (index) {
            final meal = _meals[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: FGColors.glassSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(Spacing.md),
                  border: Border.all(color: FGColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.drag_handle, color: FGColors.textSecondary, size: 20),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: meal['name'] as String? ?? ''),
                        style: FGTypography.body,
                        onChanged: (value) {
                          _meals[index]['name'] = value;
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_meals.length > 1)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _meals.removeAt(index));
                        },
                        child: Icon(
                          Icons.remove_circle_outline,
                          color: FGColors.error,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
