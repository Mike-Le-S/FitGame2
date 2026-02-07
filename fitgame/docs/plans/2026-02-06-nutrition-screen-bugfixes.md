# Nutrition Screen Bugfixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 5 bugs in the nutrition screen so diet plan editing, daily log saving, and training day detection work correctly with real Supabase data.

**Architecture:** Fixes span 1 main file (nutrition_screen.dart) + 1 Supabase migration. No new files, no new dependencies.

**Tech Stack:** Flutter/Dart, Supabase (PostgreSQL)

---

## Task 1: Fix _saveDietPlanChanges to save per-day_type (not just Monday)

The `_saveDietPlanChanges()` method always saves `_weeklyPlan[0]` (Monday's meals) to `diet_plans.meals`, regardless of which day was edited. This causes **silent data loss** — editing Tuesday-Sunday meals appears to work but changes are never persisted.

The correct architecture uses `day_types` table (not `diet_plans.meals`) where each day maps to a day_type via `weekly_schedule`. When saving, we need to update the meals in the corresponding `day_type` row.

**Files:**
- Modify: `fitgame/lib/features/nutrition/nutrition_screen.dart`

### Fix 1a: Add `_dayTypeIds` state variable

After line 51 (`Map<String, dynamic>? _activePlan;`), add:

```dart
  Map<int, String> _dayTypeIds = {}; // dayIndex → day_type_id
```

### Fix 1b: Store day_type_id mapping in `_loadDayTypesAndSchedule()`

Inside the `if (dayType != null)` block at line 417, **before** the meals parsing, add:

```dart
          // Store day_type_id for saving back later
          final dayTypeId = dayType['id'] as String?;
          if (dayTypeId != null) {
            _dayTypeIds[dayIndex] = dayTypeId;
          }
```

### Fix 1c: Rewrite `_saveDietPlanChanges()` (lines 1993-2037)

Replace the entire method body:

```dart
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
```

---

## Task 2: Fix IconData serialization in daily log creation

In `_loadOrCreateTodayLog()`, when creating a new log from the active plan, `meal['icon'].toString()` produces `"Instance of 'IconData'"` as a string in the database. The icon field is useless in the DB since icons are reconstructed via `_getMealIcon()` on load.

**Files:**
- Modify: `fitgame/lib/features/nutrition/nutrition_screen.dart:284-291`

**Fix:** Replace lines 284-291 (the mealsForLog mapping):

```dart
        final mealsForLog = planMeals.map((meal) {
          return {
            'name': meal['name'],
            'foods': (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f)).toList(),
            'plan_foods': (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f)).toList(),
          };
        }).toList();
```

This removes the `'icon'` key entirely from the saved data — icons are reconstructed from meal names via `_getMealIcon()` when loading logs back.

---

## Task 3: Add is_training column to day_types (Supabase migration)

Training day detection currently relies on fragile string matching (`name.contains('entraînement') || name.contains('training') || name.contains('muscu')`). A proper boolean column is needed.

Also add missing `updated_at` triggers on `daily_nutrition_logs` and `day_types`.

**Files:**
- Supabase migration

**SQL:**

```sql
-- Add is_training boolean to day_types
ALTER TABLE public.day_types
ADD COLUMN IF NOT EXISTS is_training boolean DEFAULT false;

-- Set existing training day types based on name
UPDATE public.day_types
SET is_training = true
WHERE lower(name) LIKE '%entraînement%'
   OR lower(name) LIKE '%training%'
   OR lower(name) LIKE '%muscu%';

-- Create or replace the generic updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to daily_nutrition_logs
DROP TRIGGER IF EXISTS set_daily_nutrition_logs_updated_at ON public.daily_nutrition_logs;
CREATE TRIGGER set_daily_nutrition_logs_updated_at
  BEFORE UPDATE ON public.daily_nutrition_logs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Add trigger to day_types
DROP TRIGGER IF EXISTS set_day_types_updated_at ON public.day_types;
CREATE TRIGGER set_day_types_updated_at
  BEFORE UPDATE ON public.day_types
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
```

---

## Task 4: Use is_training flag instead of string matching

Replace the fragile string-matching logic in `_loadDayTypesAndSchedule()` with the `is_training` boolean from the DB.

**Files:**
- Modify: `fitgame/lib/features/nutrition/nutrition_screen.dart:443-451`

**Fix:** Replace lines 443-451:

```dart
          // Use is_training flag from day_type
          if (dayType['is_training'] == true) {
            _trainingDays.add(dayIndex);
          } else {
            _trainingDays.remove(dayIndex);
          }
```

---

## Task 5: Update CHANGELOG and SCREENS docs

Add changelog entry for all nutrition screen fixes.

---

## Summary

| Task | Bug | Files | Impact |
|------|-----|-------|--------|
| 1 | Save only saves Monday | nutrition_screen.dart | All days' meals persist correctly |
| 2 | IconData → "Instance of 'IconData'" in DB | nutrition_screen.dart | Clean JSONB data in daily logs |
| 3 | No is_training column + missing triggers | Supabase migration | Reliable training detection + timestamps |
| 4 | Training detection via string matching | nutrition_screen.dart | Uses DB boolean instead of fragile strings |
| 5 | Docs outdated | CHANGELOG.md | Documentation current |
