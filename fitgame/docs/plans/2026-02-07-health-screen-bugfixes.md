# Health Screen Bugfixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 6 bugs in the health screen so data is correctly persisted, HealthKit workout writing works, heart history loads from Supabase, and synced_at stays fresh.

**Architecture:** Fixes span 3 Flutter files + 1 Supabase migration. No new files needed (except migration).

**Tech Stack:** Flutter/Dart, Supabase (PostgreSQL), HealthKit (via `health` package)

---

## Task 1: Save sleep score to Supabase (instead of null)

The `_calculateSleepScore()` method computes a 0-100 score, and `SleepData` model has a `.score` computed property — but `saveHealthMetrics()` always passes `sleepScore: null`.

**Files:**
- Modify: `fitgame/lib/features/health/health_screen.dart:131`

**Fix:** Replace line 131:

```dart
// BEFORE:
sleepScore: null,

// AFTER:
sleepScore: snapshot.sleep?.score,
```

That's it. `SleepData.score` (in `health_service.dart:485-504`) already computes a valid 0-100 score based on duration, deep sleep %, and REM %.

---

## Task 2: Write workouts to HealthKit after completion

`writeWorkout()` exists in `health_service.dart:442-461` but is never called. After workout completion, we need to write the session to Apple Health.

**Files:**
- Modify: `fitgame/lib/features/workout/tracking/active_workout_screen.dart`

### Fix 2a: Add HealthService import

Add after line 10 (`import '../../../core/services/supabase_service.dart';`):

```dart
import '../../../core/services/health_service.dart';
```

### Fix 2b: Add workout start timestamp

Add after line 53 (`int _workoutSeconds = 0;`):

```dart
  final DateTime _workoutStartTime = DateTime.now();
```

### Fix 2c: Write to HealthKit after saving to Supabase

In `_saveWorkoutSession()`, after the challenge progress update block (after the activity feed post block, around where the last `catch` is), add before the final closing `catch`:

Find the section after the activity feed creation (after `SupabaseService.createActivityFeedEntry(...)`) and add:

```dart
        // Write workout to Apple Health
        try {
          final healthService = HealthService();
          if (healthService.isAuthorized) {
            await healthService.writeWorkout(
              start: _workoutStartTime,
              end: DateTime.now(),
              caloriesBurned: (_totalVolume * 0.05).round(), // Rough estimate: ~50 kcal per 1000kg volume
            );
          }
        } catch (e) {
          debugPrint('Error writing workout to HealthKit: $e');
        }
```

This writes the workout to Apple Health so it shows up in the Fitness app and contributes to activity rings. The calorie estimate is approximate — it can be refined later with heart rate data.

---

## Task 3: Load heart history data from Supabase

The `_historyData` list in `HeartDetailSheet` is always empty. The sheet needs to fetch historical data from Supabase's `health_metrics` table when user selects 7-day or 14-day view.

**Files:**
- Modify: `fitgame/lib/features/health/sheets/heart_detail_sheet.dart`

### Fix 3a: Add SupabaseService import

Add after line 9 (`import '../models/heart_history_data.dart';`):

```dart
import '../../../core/services/supabase_service.dart';
```

### Fix 3b: Make _historyData mutable + add loading state

Replace line 97:

```dart
// BEFORE:
final List<HeartHistoryData> _historyData = [];

// AFTER:
List<HeartHistoryData> _historyData = [];
bool _isLoadingHistory = false;
```

### Fix 3c: Add history loading method

After the `dispose()` method (after line ~113), add:

```dart
  Future<void> _loadHistoryData(int days) async {
    if (_isLoadingHistory) return;
    setState(() => _isLoadingHistory = true);

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final metrics = await SupabaseService.getHealthMetrics(
        startDate: startDate.toIso8601String().substring(0, 10),
        endDate: endDate.toIso8601String().substring(0, 10),
      );

      final history = <HeartHistoryData>[];
      for (int i = 0; i < metrics.length; i++) {
        final m = metrics[i];
        final restingHr = m['resting_hr'] as int? ?? 0;
        final hrv = (m['hrv_ms'] as num?)?.round() ?? 0;
        if (restingHr == 0 && hrv == 0) continue; // Skip days with no heart data

        // Calculate trend vs previous day
        int trend = 0;
        if (i > 0) {
          final prevHrv = (metrics[i - 1]['hrv_ms'] as num?)?.round() ?? 0;
          if (hrv > prevHrv) trend = 1;
          else if (hrv < prevHrv) trend = -1;
        }

        final date = DateTime.parse(m['date'] as String);
        final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        final dayLabel = '${dayNames[date.weekday - 1]} ${date.day}';

        history.add(HeartHistoryData(
          day: dayLabel,
          restingHR: restingHr,
          hrv: hrv,
          trend: trend,
        ));
      }

      if (mounted) {
        setState(() {
          _historyData = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading heart history: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }
```

### Fix 3d: Trigger load on period tab change

Find the period selector tab handler (where `_selectedPeriod` is set). It should be an `onTap` that calls `setState(() { _selectedPeriod = index; })`.

Modify it to also trigger the data load when switching to 7-day or 14-day view:

```dart
onTap: () {
  setState(() => _selectedPeriod = index);
  if (index > 0) {
    _loadHistoryData(index == 1 ? 7 : 14);
  }
},
```

### Fix 3e: Add loading indicator in _buildHistoryView

In `_buildHistoryView()`, add at the top (before the `final data = ...` line):

```dart
    if (_isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.xl),
          child: CircularProgressIndicator(color: FGColors.accent),
        ),
      );
    }
```

---

## Task 4: Fix synced_at on upsert + add updated_at trigger (Supabase migration)

When `saveHealthMetrics()` upserts, `synced_at` keeps its original INSERT value because the app doesn't include it in the payload and `DEFAULT now()` only runs on INSERT.

**Files:**
- Supabase migration
- Modify: `fitgame/lib/core/services/supabase_service.dart:1379`

### Fix 4a: Add synced_at to upsert payload

In `supabase_service.dart`, inside the `saveHealthMetrics()` upsert map (line 1379), add:

```dart
'synced_at': DateTime.now().toUtc().toIso8601String(),
```

### Fix 4b: Supabase migration - add updated_at + clean indexes

```sql
-- Add updated_at column to health_metrics
ALTER TABLE public.health_metrics
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS set_health_metrics_updated_at ON public.health_metrics;
CREATE TRIGGER set_health_metrics_updated_at
  BEFORE UPDATE ON public.health_metrics
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Drop redundant indexes (covered by unique constraint on user_id,date)
DROP INDEX IF EXISTS idx_health_metrics_user_id;
DROP INDEX IF EXISTS idx_health_metrics_user_date;
```

---

## Task 5: Add VO2 Max to HealthKit read types

VO2 Max is displayed in the UI but never fetched. Add `HealthDataType.VO2_MAX` to the read list and expose it via HeartData.

**Files:**
- Modify: `fitgame/lib/core/services/health_service.dart`

### Fix 5a: Add VO2_MAX to _readTypes

After line 31 (`HealthDataType.HEART_RATE_VARIABILITY_SDNN,`), add:

```dart
    HealthDataType.VO2_MAX,
```

### Fix 5b: Fetch VO2 Max in getHeartData()

In `getHeartData()`, after fetching HRV data (around where `hrvData` is retrieved), add:

```dart
      // VO2 Max
      final vo2Data = healthData
          .where((d) => d.type == HealthDataType.VO2_MAX)
          .toList();
```

### Fix 5c: Add vo2Max to HeartData model

In the `HeartData` class (around line 540), add a `vo2Max` field:

```dart
  final double? vo2Max;
```

Update the constructor and the return statement in `getHeartData()` to include `vo2Max`.

### Fix 5d: Expose vo2Max in health_screen.dart

Replace line 68:

```dart
// BEFORE:
final double vo2Max = 0.0;

// AFTER:
double get vo2Max => _healthData?.heart?.vo2Max ?? 0.0;
```

---

## Task 6: Update CHANGELOG

Add changelog entry for all health screen fixes.

---

## Agent Dispatch Strategy

| Agent | Tasks | Files |
|-------|-------|-------|
| **Agent A** | Tasks 1, 5d | `health_screen.dart` (2 small edits) |
| **Agent B** | Task 2 | `active_workout_screen.dart` (3 edits) |
| **Agent C** | Task 3 | `heart_detail_sheet.dart` (5 edits) |
| **Agent D** | Tasks 4a, 5a-5c | `supabase_service.dart` + `health_service.dart` (service layer) |
| **Agent E** | Task 4b | Supabase migration |

Agents A, B, C, D, E can all run **in parallel** since they touch different files.
