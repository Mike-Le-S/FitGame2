# Nutrition Workflow Redesign - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implémenter le nouveau workflow Nutrition avec types de jour réutilisables et séparation Plan/Tracking

**Architecture:** Nouvelles tables Supabase (day_types, weekly_schedule), nouveau flow de création en 3 étapes, refactoring de NutritionScreen pour charger depuis les types de jour

**Tech Stack:** Flutter/Dart, Supabase PostgreSQL, existing design system (FGColors, FGTypography, Spacing)

---

## Task 1: Migration Supabase - Nouvelles tables

**Files:**
- Create: `supabase/migrations/20260205_nutrition_day_types.sql`

**Step 1: Écrire la migration SQL**

```sql
-- Migration: Add day_types and weekly_schedule tables for nutrition workflow redesign

-- Add is_active and active_from columns to diet_plans if not exist
ALTER TABLE diet_plans
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS active_from DATE;

-- Create index for active plan lookup
CREATE INDEX IF NOT EXISTS idx_diet_plans_user_active
ON diet_plans(created_by, is_active)
WHERE is_active = true;

-- Day Types table
CREATE TABLE IF NOT EXISTS day_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    diet_plan_id UUID NOT NULL REFERENCES diet_plans(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    emoji TEXT DEFAULT '📅',
    meals JSONB NOT NULL DEFAULT '[]',
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Weekly Schedule table
CREATE TABLE IF NOT EXISTS weekly_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    diet_plan_id UUID NOT NULL REFERENCES diet_plans(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    day_type_id UUID NOT NULL REFERENCES day_types(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(diet_plan_id, day_of_week)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_day_types_plan ON day_types(diet_plan_id);
CREATE INDEX IF NOT EXISTS idx_weekly_schedule_plan ON weekly_schedule(diet_plan_id);
CREATE INDEX IF NOT EXISTS idx_weekly_schedule_day ON weekly_schedule(diet_plan_id, day_of_week);

-- RLS Policies for day_types
ALTER TABLE day_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view day_types of their plans"
ON day_types FOR SELECT
USING (
    diet_plan_id IN (
        SELECT id FROM diet_plans WHERE created_by = auth.uid()
    )
);

CREATE POLICY "Users can insert day_types to their plans"
ON day_types FOR INSERT
WITH CHECK (
    diet_plan_id IN (
        SELECT id FROM diet_plans WHERE created_by = auth.uid()
    )
);

CREATE POLICY "Users can update day_types of their plans"
ON day_types FOR UPDATE
USING (
    diet_plan_id IN (
        SELECT id FROM diet_plans WHERE created_by = auth.uid()
    )
);

CREATE POLICY "Users can delete day_types of their plans"
ON day_types FOR DELETE
USING (
    diet_plan_id IN (
        SELECT id FROM diet_plans WHERE created_by = auth.uid()
    )
);

-- RLS Policies for weekly_schedule
ALTER TABLE weekly_schedule ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view weekly_schedule of their plans"
ON weekly_schedule FOR SELECT
USING (
    diet_plan_id IN (
        SELECT id FROM diet_plans WHERE created_by = auth.uid()
    )
);

CREATE POLICY "Users can insert weekly_schedule to their plans"
ON weekly_schedule FOR INSERT
WITH CHECK (
    diet_plan_id IN (
        SELECT id FROM diet_plans WHERE created_by = auth.uid()
    )
);

CREATE POLICY "Users can update weekly_schedule of their plans"
ON weekly_schedule FOR UPDATE
USING (
    diet_plan_id IN (
        SELECT id FROM diet_plans WHERE created_by = auth.uid()
    )
);

CREATE POLICY "Users can delete weekly_schedule of their plans"
ON weekly_schedule FOR DELETE
USING (
    diet_plan_id IN (
        SELECT id FROM diet_plans WHERE created_by = auth.uid()
    )
);
```

**Step 2: Appliquer la migration via Supabase MCP**

Run: `mcp__plugin_supabase_supabase__apply_migration` avec name="nutrition_day_types"

**Step 3: Vérifier les tables créées**

Run: `mcp__plugin_supabase_supabase__list_tables` avec schemas=["public"]

**Step 4: Commit**

```bash
git add supabase/migrations/20260205_nutrition_day_types.sql
git commit -m "feat(db): add day_types and weekly_schedule tables for nutrition redesign"
```

---

## Task 2: SupabaseService - Méthodes Day Types

**Files:**
- Modify: `lib/core/services/supabase_service.dart`

**Step 1: Ajouter les méthodes CRUD pour day_types**

Ajouter après la section "Diet Plans" (ligne ~530):

```dart
// ============================================
// Day Types (for diet plans)
// ============================================

/// Get all day types for a diet plan
static Future<List<Map<String, dynamic>>> getDayTypes(String dietPlanId) async {
  final response = await client
      .from('day_types')
      .select()
      .eq('diet_plan_id', dietPlanId)
      .order('sort_order', ascending: true);

  return List<Map<String, dynamic>>.from(response);
}

/// Create a new day type
static Future<Map<String, dynamic>> createDayType({
  required String dietPlanId,
  required String name,
  String emoji = '📅',
  List<Map<String, dynamic>> meals = const [],
  int sortOrder = 0,
}) async {
  final response = await client
      .from('day_types')
      .insert({
        'diet_plan_id': dietPlanId,
        'name': name,
        'emoji': emoji,
        'meals': meals,
        'sort_order': sortOrder,
      })
      .select()
      .single();

  return response;
}

/// Update a day type
static Future<void> updateDayType(String id, Map<String, dynamic> data) async {
  await client
      .from('day_types')
      .update({...data, 'updated_at': DateTime.now().toIso8601String()})
      .eq('id', id);
}

/// Delete a day type
static Future<void> deleteDayType(String id) async {
  await client
      .from('day_types')
      .delete()
      .eq('id', id);
}
```

**Step 2: Vérifier que le code compile**

Run: `flutter analyze lib/core/services/supabase_service.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/core/services/supabase_service.dart
git commit -m "feat(supabase): add day_types CRUD methods"
```

---

## Task 3: SupabaseService - Méthodes Weekly Schedule

**Files:**
- Modify: `lib/core/services/supabase_service.dart`

**Step 1: Ajouter les méthodes pour weekly_schedule**

Ajouter après les méthodes day_types:

```dart
// ============================================
// Weekly Schedule (for diet plans)
// ============================================

/// Get weekly schedule for a diet plan
static Future<List<Map<String, dynamic>>> getWeeklySchedule(String dietPlanId) async {
  final response = await client
      .from('weekly_schedule')
      .select('*, day_type:day_types(*)')
      .eq('diet_plan_id', dietPlanId)
      .order('day_of_week', ascending: true);

  return List<Map<String, dynamic>>.from(response);
}

/// Get day type for a specific day of the week
static Future<Map<String, dynamic>?> getDayTypeForWeekday(String dietPlanId, int dayOfWeek) async {
  try {
    final response = await client
        .from('weekly_schedule')
        .select('*, day_type:day_types(*)')
        .eq('diet_plan_id', dietPlanId)
        .eq('day_of_week', dayOfWeek)
        .maybeSingle();

    return response?['day_type'] as Map<String, dynamic>?;
  } catch (e) {
    debugPrint('Error getting day type for weekday: $e');
    return null;
  }
}

/// Set day type for a specific day of the week (upsert)
static Future<void> setWeeklyScheduleDay({
  required String dietPlanId,
  required int dayOfWeek,
  required String dayTypeId,
}) async {
  await client
      .from('weekly_schedule')
      .upsert({
        'diet_plan_id': dietPlanId,
        'day_of_week': dayOfWeek,
        'day_type_id': dayTypeId,
      }, onConflict: 'diet_plan_id,day_of_week');
}

/// Set entire weekly schedule at once
static Future<void> setWeeklySchedule({
  required String dietPlanId,
  required Map<int, String> schedule, // dayOfWeek -> dayTypeId
}) async {
  // Delete existing schedule
  await client
      .from('weekly_schedule')
      .delete()
      .eq('diet_plan_id', dietPlanId);

  // Insert new schedule
  final rows = schedule.entries.map((e) => {
    'diet_plan_id': dietPlanId,
    'day_of_week': e.key,
    'day_type_id': e.value,
  }).toList();

  if (rows.isNotEmpty) {
    await client.from('weekly_schedule').insert(rows);
  }
}
```

**Step 2: Vérifier que le code compile**

Run: `flutter analyze lib/core/services/supabase_service.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/core/services/supabase_service.dart
git commit -m "feat(supabase): add weekly_schedule CRUD methods"
```

---

## Task 4: SupabaseService - Méthodes Plan actif

**Files:**
- Modify: `lib/core/services/supabase_service.dart`

**Step 1: Ajouter les méthodes pour gérer le plan actif**

Ajouter dans la section Diet Plans:

```dart
/// Get the active diet plan for current user
static Future<Map<String, dynamic>?> getActiveDietPlan() async {
  if (currentUser == null) return null;

  try {
    final response = await client
        .from('diet_plans')
        .select()
        .eq('created_by', currentUser!.id)
        .eq('is_active', true)
        .maybeSingle();

    return response;
  } catch (e) {
    debugPrint('Error getting active diet plan: $e');
    return null;
  }
}

/// Activate a diet plan (deactivates others)
static Future<void> activateDietPlan(String planId, {DateTime? activeFrom}) async {
  if (currentUser == null) throw Exception('Non authentifié');

  // Deactivate all other plans
  await client
      .from('diet_plans')
      .update({'is_active': false})
      .eq('created_by', currentUser!.id);

  // Activate the selected plan
  await client
      .from('diet_plans')
      .update({
        'is_active': true,
        'active_from': (activeFrom ?? DateTime.now()).toIso8601String().split('T')[0],
      })
      .eq('id', planId);
}

/// Deactivate current plan (no plan active)
static Future<void> deactivateAllDietPlans() async {
  if (currentUser == null) return;

  await client
      .from('diet_plans')
      .update({'is_active': false})
      .eq('created_by', currentUser!.id);
}
```

**Step 2: Vérifier que le code compile**

Run: `flutter analyze lib/core/services/supabase_service.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/core/services/supabase_service.dart
git commit -m "feat(supabase): add active diet plan management methods"
```

---

## Task 5: PlansModalSheet - Modal gestion des plans

**Files:**
- Create: `lib/features/nutrition/sheets/plans_modal_sheet.dart`

**Step 1: Créer le widget PlansModalSheet**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class PlansModalSheet extends StatefulWidget {
  final Map<String, dynamic>? activePlan;
  final List<Map<String, dynamic>> allPlans;
  final VoidCallback onPlanChanged;
  final Function(Map<String, dynamic>) onEditPlan;
  final VoidCallback onCreatePlan;

  const PlansModalSheet({
    super.key,
    this.activePlan,
    required this.allPlans,
    required this.onPlanChanged,
    required this.onEditPlan,
    required this.onCreatePlan,
  });

  @override
  State<PlansModalSheet> createState() => _PlansModalSheetState();
}

class _PlansModalSheetState extends State<PlansModalSheet> {
  bool _isLoading = false;

  String _getGoalLabel(String? goal) {
    switch (goal) {
      case 'bulk':
        return 'Prise de masse';
      case 'cut':
        return 'Sèche';
      case 'maintain':
        return 'Maintien';
      default:
        return '';
    }
  }

  Future<void> _showActivateDialog(Map<String, dynamic> plan) async {
    final result = await showModalBottomSheet<DateTime?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActivatePlanDialog(planName: plan['name'] as String? ?? 'Plan'),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService.activateDietPlan(plan['id'] as String, activeFrom: result);
        if (mounted) {
          Navigator.pop(context);
          widget.onPlanChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plan "${plan['name']}" activé'),
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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deactivatePlan() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.deactivateAllDietPlans();
      if (mounted) {
        Navigator.pop(context);
        widget.onPlanChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan désactivé'),
            backgroundColor: FGColors.warning,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherPlans = widget.allPlans
        .where((p) => p['id'] != widget.activePlan?['id'])
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                Text('Mes plans', style: FGTypography.h3),
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
          // Content
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    children: [
                      // Active plan section
                      if (widget.activePlan != null) ...[
                        Text(
                          'ACTIF',
                          style: FGTypography.caption.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: FGColors.success,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        _buildPlanCard(widget.activePlan!, isActive: true),
                        const SizedBox(height: Spacing.lg),
                      ],
                      // Other plans section
                      if (otherPlans.isNotEmpty) ...[
                        Text(
                          'AUTRES PLANS',
                          style: FGTypography.caption.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: FGColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        ...otherPlans.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: Spacing.md),
                              child: _buildPlanCard(p, isActive: false),
                            )),
                      ],
                      // Empty state
                      if (widget.allPlans.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(Spacing.xl),
                          child: Column(
                            children: [
                              Icon(
                                Icons.restaurant_menu_rounded,
                                size: 48,
                                color: FGColors.textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: Spacing.md),
                              Text(
                                'Aucun plan créé',
                                style: FGTypography.body.copyWith(
                                  color: FGColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: Spacing.lg),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onCreatePlan();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Spacing.lg,
                                    vertical: Spacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2ECC71),
                                    borderRadius: BorderRadius.circular(Spacing.md),
                                  ),
                                  child: Text(
                                    'Créer un plan',
                                    style: FGTypography.body.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: Spacing.lg),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, {required bool isActive}) {
    final name = plan['name'] as String? ?? 'Plan';
    final goal = plan['goal'] as String?;
    final trainingCal = plan['training_calories'] as int?;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isActive
            ? FGColors.success.withValues(alpha: 0.08)
            : FGColors.glassSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Spacing.lg),
        border: Border.all(
          color: isActive
              ? FGColors.success.withValues(alpha: 0.3)
              : FGColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: FGTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${_getGoalLabel(goal)}${trainingCal != null ? ' • $trainingCal kcal' : ''}',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
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
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    widget.onEditPlan(plan);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    decoration: BoxDecoration(
                      color: FGColors.glassBorder,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: Center(
                      child: Text(
                        'Modifier',
                        style: FGTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (isActive) {
                      _deactivatePlan();
                    } else {
                      _showActivateDialog(plan);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    decoration: BoxDecoration(
                      color: isActive
                          ? FGColors.warning.withValues(alpha: 0.2)
                          : const Color(0xFF2ECC71).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: Center(
                      child: Text(
                        isActive ? 'Désactiver' : 'Activer',
                        style: FGTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isActive ? FGColors.warning : const Color(0xFF2ECC71),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivatePlanDialog extends StatefulWidget {
  final String planName;

  const _ActivatePlanDialog({required this.planName});

  @override
  State<_ActivatePlanDialog> createState() => _ActivatePlanDialogState();
}

class _ActivatePlanDialogState extends State<_ActivatePlanDialog> {
  int _selectedOption = 0; // 0=now, 1=tomorrow, 2=custom
  DateTime _customDate = DateTime.now().add(const Duration(days: 2));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
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
          const SizedBox(height: Spacing.lg),
          Text(
            'Activer "${widget.planName}"',
            style: FGTypography.h3,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'À partir de :',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.lg),
          _buildOption(0, 'Maintenant'),
          const SizedBox(height: Spacing.sm),
          _buildOption(1, 'Demain'),
          const SizedBox(height: Spacing.sm),
          _buildDateOption(),
          const SizedBox(height: Spacing.xl),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    decoration: BoxDecoration(
                      color: FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.md),
                    ),
                    child: Center(
                      child: Text(
                        'Annuler',
                        style: FGTypography.body.copyWith(
                          color: FGColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    DateTime date;
                    switch (_selectedOption) {
                      case 0:
                        date = DateTime.now();
                        break;
                      case 1:
                        date = DateTime.now().add(const Duration(days: 1));
                        break;
                      default:
                        date = _customDate;
                    }
                    Navigator.pop(context, date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      borderRadius: BorderRadius.circular(Spacing.md),
                    ),
                    child: Center(
                      child: Text(
                        'Confirmer',
                        style: FGTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String label) {
    final isSelected = _selectedOption == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = index),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2ECC71)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2ECC71) : FGColors.glassBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: Spacing.md),
            Text(
              label,
              style: FGTypography.body.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOption() {
    final isSelected = _selectedOption == 2;
    return GestureDetector(
      onTap: () async {
        setState(() => _selectedOption = 2);
        final picked = await showDatePicker(
          context: context,
          initialDate: _customDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _customDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2ECC71)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2ECC71) : FGColors.glassBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: Spacing.md),
            Text(
              'Le ${_customDate.day}/${_customDate.month}/${_customDate.year}',
              style: FGTypography.body.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: FGColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Vérifier que le code compile**

Run: `flutter analyze lib/features/nutrition/sheets/plans_modal_sheet.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/features/nutrition/sheets/plans_modal_sheet.dart
git commit -m "feat(nutrition): add PlansModalSheet for plan management"
```

---

## Task 6: PlanCreationFlow - Nouveau flow 3 étapes (structure)

**Files:**
- Create: `lib/features/nutrition/create/plan_creation_flow.dart`

**Step 1: Créer la structure du flow**

```dart
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
  String? _createdPlanId;

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
        _createdPlanId = planId;
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

  void _editDayType(int index) {
    // TODO: Navigate to DayTypeEditorScreen
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Éditeur de type de jour - à implémenter'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
```

**Step 2: Vérifier que le code compile**

Run: `flutter analyze lib/features/nutrition/create/plan_creation_flow.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/features/nutrition/create/plan_creation_flow.dart
git commit -m "feat(nutrition): add PlanCreationFlow with 3-step wizard"
```

---

## Task 7: DayTypeEditorScreen - Éditeur de type de jour

**Files:**
- Create: `lib/features/nutrition/create/day_type_editor_screen.dart`

**Step 1: Créer l'écran d'édition**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../sheets/food_add_sheet.dart';
import '../widgets/meal_card.dart';

class DayTypeEditorScreen extends StatefulWidget {
  final Map<String, dynamic> dayType;
  final Function(Map<String, dynamic>) onSave;

  const DayTypeEditorScreen({
    super.key,
    required this.dayType,
    required this.onSave,
  });

  @override
  State<DayTypeEditorScreen> createState() => _DayTypeEditorScreenState();
}

class _DayTypeEditorScreenState extends State<DayTypeEditorScreen> {
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
      (widget.dayType['meals'] as List? ?? []).map((m) => Map<String, dynamic>.from(m)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave({
      ...widget.dayType,
      'name': _nameController.text.trim(),
      'emoji': _emoji,
      'meals': _meals,
    });
    Navigator.pop(context);
  }

  void _addMeal() {
    HapticFeedback.lightImpact();
    setState(() {
      _meals.add({
        'name': 'Nouveau repas',
        'foods': <Map<String, dynamic>>[],
      });
    });
  }

  void _showFoodLibrary(int mealIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => FoodAddSheet(
        onSelectFood: (food) {
          setState(() {
            (_meals[mealIndex]['foods'] as List).add(Map<String, dynamic>.from(food));
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      appBar: AppBar(
        backgroundColor: FGColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Éditer le type de jour', style: FGTypography.h3),
        actions: [
          TextButton(
            onPressed: _nameController.text.trim().isNotEmpty ? _save : null,
            child: Text(
              'Enregistrer',
              style: FGTypography.body.copyWith(
                color: _nameController.text.trim().isNotEmpty
                    ? const Color(0xFF2ECC71)
                    : FGColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          // Name & Emoji
          Row(
            children: [
              // Emoji picker
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: FGColors.glassSurface,
                    borderRadius: BorderRadius.circular(Spacing.md),
                    border: Border.all(color: FGColors.glassBorder),
                  ),
                  child: Center(
                    child: Text(_emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              // Name field
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: FGTypography.h3,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Nom du type',
                    hintStyle: FGTypography.h3.copyWith(
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
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          // Meals
          Text(
            'REPAS',
            style: FGTypography.caption.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          ..._meals.asMap().entries.map((entry) {
            final index = entry.key;
            final meal = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: _buildMealEditor(index, meal),
            );
          }),
          // Add meal button
          GestureDetector(
            onTap: _addMeal,
            child: Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: FGColors.glassSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(Spacing.lg),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: FGColors.textSecondary, size: 20),
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
        ],
      ),
    );
  }

  Widget _buildMealEditor(int index, Map<String, dynamic> meal) {
    final foods = meal['foods'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.glassSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Spacing.lg),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: meal['name'] as String? ?? ''),
                  style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
                  onChanged: (value) {
                    setState(() => _meals[index]['name'] = value);
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
                  child: Icon(Icons.delete_outline, color: FGColors.error, size: 20),
                ),
            ],
          ),
          if (foods.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            ...foods.asMap().entries.map((foodEntry) {
              final food = foodEntry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${food['name']} (${food['quantity'] ?? ''})',
                        style: FGTypography.bodySmall,
                      ),
                    ),
                    Text(
                      '${food['cal'] ?? 0} kcal',
                      style: FGTypography.caption.copyWith(color: FGColors.accent),
                    ),
                    const SizedBox(width: Spacing.sm),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          (meal['foods'] as List).removeAt(foodEntry.key);
                        });
                      },
                      child: Icon(Icons.close, color: FGColors.textSecondary, size: 16),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: Spacing.md),
          GestureDetector(
            onTap: () => _showFoodLibrary(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: const Color(0xFF2ECC71), size: 18),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    'Ajouter un aliment',
                    style: FGTypography.caption.copyWith(
                      color: const Color(0xFF2ECC71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: FGColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choisir une icône', style: FGTypography.h3),
            const SizedBox(height: Spacing.lg),
            Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.md,
              children: _availableEmojis.map((e) {
                final isSelected = e == _emoji;
                return GestureDetector(
                  onTap: () {
                    setState(() => _emoji = e);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2ECC71).withValues(alpha: 0.2)
                          : FGColors.glassSurface,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2ECC71) : FGColors.glassBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + Spacing.lg),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Vérifier que le code compile**

Run: `flutter analyze lib/features/nutrition/create/day_type_editor_screen.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/features/nutrition/create/day_type_editor_screen.dart
git commit -m "feat(nutrition): add DayTypeEditorScreen for editing day type meals"
```

---

## Task 8: Intégrer DayTypeEditorScreen dans PlanCreationFlow

**Files:**
- Modify: `lib/features/nutrition/create/plan_creation_flow.dart`

**Step 1: Importer et utiliser DayTypeEditorScreen**

Ajouter l'import en haut du fichier:
```dart
import 'day_type_editor_screen.dart';
```

Modifier la méthode `_editDayType`:
```dart
void _editDayType(int index) {
  HapticFeedback.lightImpact();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (ctx) => DayTypeEditorScreen(
        dayType: _dayTypes[index],
        onSave: (updatedDayType) {
          setState(() {
            _dayTypes[index] = updatedDayType;
          });
        },
      ),
    ),
  );
}
```

**Step 2: Vérifier que le code compile**

Run: `flutter analyze lib/features/nutrition/create/plan_creation_flow.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/features/nutrition/create/plan_creation_flow.dart
git commit -m "feat(nutrition): integrate DayTypeEditorScreen into PlanCreationFlow"
```

---

## Task 9: Refactoring NutritionScreen - Header simplifié

**Files:**
- Modify: `lib/features/nutrition/nutrition_screen.dart`

**Step 1: Ajouter les imports**

Ajouter en haut du fichier:
```dart
import 'sheets/plans_modal_sheet.dart';
import 'create/plan_creation_flow.dart';
```

**Step 2: Modifier le header**

Remplacer la méthode `_buildHeader()` (lignes ~916-1078) par:

```dart
Widget _buildHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Column(
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
              _dayFullNames[_selectedDayIndex],
              style: FGTypography.h2.copyWith(fontSize: 24),
            ),
          ],
        ),
      ),
      Row(
        children: [
          // Plan selector button
          GestureDetector(
            onTap: _showPlansModal,
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
                    Icons.restaurant_menu_rounded,
                    color: _activePlan != null ? const Color(0xFF2ECC71) : FGColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    _activePlan != null
                        ? (_activePlanName ?? 'Plan').length > 12
                            ? '${(_activePlanName ?? 'Plan').substring(0, 12)}...'
                            : (_activePlanName ?? 'Plan')
                        : 'Aucun plan',
                    style: FGTypography.caption.copyWith(
                      color: _activePlan != null ? FGColors.textPrimary : FGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: Spacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: FGColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          // Create plan button
          GestureDetector(
            onTap: _openPlanCreation,
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
```

**Step 3: Ajouter les méthodes de navigation**

Ajouter après `_buildHeader()`:

```dart
void _showPlansModal() {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => PlansModalSheet(
      activePlan: _activePlan,
      allPlans: [..._myDietPlans, ..._assignedDietPlans],
      onPlanChanged: _loadData,
      onEditPlan: (plan) => _openPlanEdition(plan),
      onCreatePlan: _openPlanCreation,
    ),
  );
}

void _openPlanCreation() {
  HapticFeedback.mediumImpact();
  Navigator.push(
    context,
    MaterialPageRoute(builder: (ctx) => const PlanCreationFlow()),
  ).then((result) {
    if (result == true) {
      _loadData();
    }
  });
}

void _openPlanEdition(Map<String, dynamic> plan) {
  HapticFeedback.mediumImpact();
  Navigator.push(
    context,
    MaterialPageRoute(builder: (ctx) => PlanCreationFlow(existingPlan: plan)),
  ).then((result) {
    if (result == true) {
      _loadData();
    }
  });
}
```

**Step 4: Supprimer l'ancienne méthode `_openDietCreation()`**

Supprimer les lignes ~1515-1536 (méthode `_openDietCreation`).

**Step 5: Supprimer le sélecteur de goal et les méthodes associées**

Supprimer:
- `_showGoalSelector()` et son appel
- Import de `GoalSelectorSheet` (si plus utilisé)

**Step 6: Vérifier que le code compile**

Run: `flutter analyze lib/features/nutrition/nutrition_screen.dart`
Expected: No issues (ou warnings mineurs à corriger)

**Step 7: Commit**

```bash
git add lib/features/nutrition/nutrition_screen.dart
git commit -m "refactor(nutrition): simplify header with new plan modal and creation flow"
```

---

## Task 10: NutritionScreen - Charger depuis day_types

**Files:**
- Modify: `lib/features/nutrition/nutrition_screen.dart`

**Step 1: Modifier `_loadData()` pour charger les day_types**

Remplacer la méthode `_loadData()` par:

```dart
Future<void> _loadData() async {
  if (!SupabaseService.isAuthenticated) {
    return;
  }

  try {
    // Load all plans
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
      _activePlan = activePlan;
      _activePlanName = activePlan?['name'] as String?;

      if (activePlan != null) {
        _goalType = activePlan['goal'] as String? ?? 'maintain';
        final trainingCal = activePlan['training_calories'] as int?;
        final restCal = activePlan['rest_calories'] as int?;
        if (trainingCal != null && restCal != null) {
          _macroTargets[_goalType] = {
            'training': trainingCal,
            'rest': restCal,
            'protein': 180,
            'carbs': 300,
            'fat': 80,
          };
        }
      }
    });

    // Load day types and schedule if there's an active plan
    if (activePlan != null) {
      await _loadDayTypesAndSchedule(activePlan['id'] as String);
    }

    // Load today's tracking log
    await _loadOrCreateTodayLog();
  } catch (e) {
    debugPrint('Error loading nutrition data: $e');
  }
}

Future<void> _loadDayTypesAndSchedule(String planId) async {
  try {
    final schedule = await SupabaseService.getWeeklySchedule(planId);

    if (!mounted) return;

    // Build weekly plan from schedule
    final newWeeklyPlan = List.generate(7, (dayIndex) {
      final scheduleEntry = schedule.firstWhere(
        (s) => s['day_of_week'] == dayIndex,
        orElse: () => {},
      );

      final dayType = scheduleEntry['day_type'] as Map<String, dynamic>?;
      if (dayType != null) {
        final meals = (dayType['meals'] as List? ?? []).map((meal) {
          return {
            'name': meal['name'] ?? 'Repas',
            'icon': _getMealIcon(meal['name'] as String? ?? ''),
            'foods': (meal['foods'] as List? ?? []).map((f) => Map<String, dynamic>.from(f)).toList(),
          };
        }).toList();

        // Update training days based on day type name
        final dayTypeName = (dayType['name'] as String? ?? '').toLowerCase();
        if (dayTypeName.contains('entraînement') ||
            dayTypeName.contains('training') ||
            dayTypeName.contains('muscu')) {
          _trainingDays.add(dayIndex);
        } else {
          _trainingDays.remove(dayIndex);
        }

        return {'meals': meals};
      }

      // Default empty meals
      return {
        'meals': [
          {'name': 'Petit-déjeuner', 'icon': Icons.wb_sunny_rounded, 'foods': []},
          {'name': 'Déjeuner', 'icon': Icons.restaurant_rounded, 'foods': []},
          {'name': 'Collation', 'icon': Icons.apple, 'foods': []},
          {'name': 'Dîner', 'icon': Icons.nights_stay_rounded, 'foods': []},
        ],
      };
    });

    setState(() {
      _weeklyPlan = newWeeklyPlan;
    });
  } catch (e) {
    debugPrint('Error loading day types: $e');
  }
}
```

**Step 2: Vérifier que le code compile**

Run: `flutter analyze lib/features/nutrition/nutrition_screen.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/features/nutrition/nutrition_screen.dart
git commit -m "feat(nutrition): load meals from day_types and weekly_schedule"
```

---

## Task 11: Nettoyage - Supprimer l'ancien DietCreationFlow

**Files:**
- Delete or archive: `lib/features/nutrition/create/diet_creation_flow.dart`
- Delete: `lib/features/nutrition/create/steps/name_step.dart`
- Delete: `lib/features/nutrition/create/steps/goal_step.dart`
- Delete: `lib/features/nutrition/create/steps/calories_step.dart`
- Delete: `lib/features/nutrition/create/steps/macros_step.dart`
- Delete: `lib/features/nutrition/create/steps/meals_step.dart`
- Delete: `lib/features/nutrition/create/steps/meal_names_step.dart`
- Delete: `lib/features/nutrition/create/steps/meal_planning_step.dart`
- Delete: `lib/features/nutrition/create/steps/supplements_step.dart`

**Step 1: Supprimer les anciens fichiers**

```bash
rm lib/features/nutrition/create/diet_creation_flow.dart
rm -rf lib/features/nutrition/create/steps/
rm -rf lib/features/nutrition/create/sheets/
```

**Step 2: Supprimer les imports inutilisés dans nutrition_screen.dart**

Retirer l'import:
```dart
import 'create/diet_creation_flow.dart';
```

**Step 3: Vérifier que le code compile**

Run: `flutter analyze`
Expected: No issues

**Step 4: Commit**

```bash
git add -A
git commit -m "chore(nutrition): remove old 8-step DietCreationFlow"
```

---

## Task 12: Mise à jour de la documentation

**Files:**
- Modify: `docs/SCREENS.md`
- Modify: `docs/CHANGELOG.md`

**Step 1: Mettre à jour SCREENS.md**

Ajouter/modifier la section Nutrition:

```markdown
### Écran Nutrition

**Header:**
- Titre "NUTRITION" + jour de la semaine
- Bouton "Mon plan ▼" → ouvre le modal de gestion des plans
- Bouton "+" → crée un nouveau plan (flow 3 étapes)

**Modal de gestion des plans:**
- Affiche le plan actif avec actions Modifier/Désactiver
- Liste les autres plans avec action Activer
- Dialog de choix de date d'activation (Maintenant/Demain/Date personnalisée)

**Création de plan (3 étapes):**
1. Infos générales (nom, objectif, calories)
2. Types de jour (créer des templates réutilisables)
3. Planning semaine (assigner les types aux jours)

**Vue quotidienne:**
- Repas pré-remplis depuis le plan actif
- Modifications temporaires (ne touchent pas au plan)
- CalorieBalanceCard avec données Apple Santé
```

**Step 2: Ajouter au CHANGELOG.md**

```markdown
## [Unreleased]

### Changed
- Refonte complète du workflow Nutrition
- Nouveau concept de "types de jour" (templates réutilisables)
- Flow de création de plan simplifié en 3 étapes
- Séparation claire Plan (template) vs Tracking (quotidien)

### Added
- Modal de gestion des plans avec activation datée
- Tables Supabase: day_types, weekly_schedule
- DayTypeEditorScreen pour éditer les repas d'un type de jour

### Removed
- Ancien flow de création en 8 étapes
- Sélecteur d'objectif dans le header (intégré au plan)
```

**Step 3: Commit**

```bash
git add docs/SCREENS.md docs/CHANGELOG.md
git commit -m "docs: update documentation for nutrition workflow redesign"
```

---

## Résumé des tâches

| # | Tâche | Fichiers |
|---|-------|----------|
| 1 | Migration Supabase | `supabase/migrations/20260205_nutrition_day_types.sql` |
| 2 | SupabaseService - Day Types | `lib/core/services/supabase_service.dart` |
| 3 | SupabaseService - Weekly Schedule | `lib/core/services/supabase_service.dart` |
| 4 | SupabaseService - Plan actif | `lib/core/services/supabase_service.dart` |
| 5 | PlansModalSheet | `lib/features/nutrition/sheets/plans_modal_sheet.dart` |
| 6 | PlanCreationFlow (3 étapes) | `lib/features/nutrition/create/plan_creation_flow.dart` |
| 7 | DayTypeEditorScreen | `lib/features/nutrition/create/day_type_editor_screen.dart` |
| 8 | Intégration DayTypeEditor | `lib/features/nutrition/create/plan_creation_flow.dart` |
| 9 | NutritionScreen - Header | `lib/features/nutrition/nutrition_screen.dart` |
| 10 | NutritionScreen - Load day_types | `lib/features/nutrition/nutrition_screen.dart` |
| 11 | Nettoyage ancien code | Suppression fichiers |
| 12 | Documentation | `docs/SCREENS.md`, `docs/CHANGELOG.md` |
