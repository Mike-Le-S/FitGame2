# Profile Remaining Bugfixes — Archive/Delete + Achievements

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix bugs #7 (fake delete/reset) and #8 (4 incomplete achievements) in the profile Danger Zone.

**Architecture:** 1 Supabase migration (columns + 3 RPCs + enriched check_achievements) + 2 Flutter files modified.

**Tech Stack:** Flutter/Dart, Supabase (PostgreSQL)

---

## Task 1: Supabase migration — archived_at + RPCs + check_achievements

### 1a: Add `archived_at` column to 4 tables

```sql
ALTER TABLE public.workout_sessions
ADD COLUMN IF NOT EXISTS archived_at timestamptz DEFAULT NULL;

ALTER TABLE public.daily_nutrition_logs
ADD COLUMN IF NOT EXISTS archived_at timestamptz DEFAULT NULL;

ALTER TABLE public.health_metrics
ADD COLUMN IF NOT EXISTS archived_at timestamptz DEFAULT NULL;

ALTER TABLE public.user_achievements
ADD COLUMN IF NOT EXISTS archived_at timestamptz DEFAULT NULL;
```

### 1b: RPC `archive_user_data`

Archives all user data (soft delete) and resets profile stats.

```sql
CREATE OR REPLACE FUNCTION public.archive_user_data(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.workout_sessions SET archived_at = now() WHERE user_id = p_user_id AND archived_at IS NULL;
  UPDATE public.daily_nutrition_logs SET archived_at = now() WHERE user_id = p_user_id AND archived_at IS NULL;
  UPDATE public.health_metrics SET archived_at = now() WHERE user_id = p_user_id AND archived_at IS NULL;
  UPDATE public.user_achievements SET archived_at = now() WHERE user_id = p_user_id AND archived_at IS NULL;
  UPDATE public.profiles SET total_sessions = 0, current_streak = 0 WHERE id = p_user_id;
END;
$$;
```

### 1c: RPC `restore_user_data`

Restores archived data and recalculates stats.

```sql
CREATE OR REPLACE FUNCTION public.restore_user_data(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sessions integer;
BEGIN
  UPDATE public.workout_sessions SET archived_at = NULL WHERE user_id = p_user_id AND archived_at IS NOT NULL;
  UPDATE public.daily_nutrition_logs SET archived_at = NULL WHERE user_id = p_user_id AND archived_at IS NOT NULL;
  UPDATE public.health_metrics SET archived_at = NULL WHERE user_id = p_user_id AND archived_at IS NOT NULL;
  UPDATE public.user_achievements SET archived_at = NULL WHERE user_id = p_user_id AND archived_at IS NOT NULL;

  -- Recalculate total_sessions
  SELECT count(*) INTO v_sessions FROM public.workout_sessions WHERE user_id = p_user_id AND archived_at IS NULL;
  UPDATE public.profiles SET total_sessions = v_sessions WHERE id = p_user_id;
  -- Note: streak recalculation is complex, leave at 0 — will rebuild naturally
END;
$$;
```

### 1d: RPC `delete_all_user_data`

Hard deletes all user data (irréversible). Does NOT delete the profile or auth account.

```sql
CREATE OR REPLACE FUNCTION public.delete_all_user_data(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.user_achievements WHERE user_id = p_user_id;
  DELETE FROM public.daily_nutrition_logs WHERE user_id = p_user_id;
  DELETE FROM public.health_metrics WHERE user_id = p_user_id;
  DELETE FROM public.workout_sessions WHERE user_id = p_user_id;
  DELETE FROM public.activity_feed WHERE user_id = p_user_id;
  DELETE FROM public.challenges WHERE creator_id = p_user_id;
  DELETE FROM public.friendships WHERE user_id = p_user_id OR friend_id = p_user_id;
  DELETE FROM public.notifications WHERE user_id = p_user_id;
  UPDATE public.profiles SET total_sessions = 0, current_streak = 0, avatar_index = 0 WHERE id = p_user_id;
END;
$$;
```

### 1e: Enriched `check_achievements` RPC

DROP and recreate the existing `check_achievements` function with 4 new criteria handlers. Keep existing handlers (`total_sessions`, `streak`, `friend_count`) and add:

- **`pr_count`**: Count workout_sessions with non-empty `personal_records` JSONB array
- **`session_volume`**: Max `total_volume_kg` in a single session
- **`challenge_wins`**: Count challenges where user has completed (check `participants` JSONB)
- **`nutrition_streak`**: Count max consecutive days in `daily_nutrition_logs`

All queries must include `AND archived_at IS NULL` filter.

**IMPORTANT:** First read the existing `check_achievements` function body using:
```sql
SELECT prosrc FROM pg_proc WHERE proname = 'check_achievements';
```
Then extend it with the new handlers while preserving the existing logic.

---

## Task 2: Flutter — Add 3 service methods

**File:** `fitgame/lib/core/services/supabase_service.dart`

Add 3 new static methods (after the existing `checkAchievements` method):

```dart
/// Archive all user data (soft delete, recoverable)
static Future<void> archiveUserData() async {
  final userId = currentUser?.id;
  if (userId == null) return;
  await client.rpc('archive_user_data', params: {'p_user_id': userId});
}

/// Restore previously archived data
static Future<void> restoreUserData() async {
  final userId = currentUser?.id;
  if (userId == null) return;
  await client.rpc('restore_user_data', params: {'p_user_id': userId});
}

/// Hard delete all user data (irréversible)
static Future<void> deleteAllUserData() async {
  final userId = currentUser?.id;
  if (userId == null) return;
  await client.rpc('delete_all_user_data', params: {'p_user_id': userId});
}
```

Also add a method to check if user has archived data:

```dart
/// Check if user has archived data that can be restored
static Future<bool> hasArchivedData() async {
  final userId = currentUser?.id;
  if (userId == null) return false;
  final result = await client
      .from('workout_sessions')
      .select('id')
      .eq('user_id', userId)
      .not('archived_at', 'is', null)
      .limit(1);
  return (result as List).isNotEmpty;
}
```

---

## Task 3: Flutter — Fix Danger Zone UI

**File:** `fitgame/lib/features/profile/sheets/advanced_settings_sheet.dart`

### 3a: Replace "Réinitialiser la progression" handler

Replace the fake handler with a real confirmation dialog:
- Show dialog with TextField
- User must type "RESET" to confirm
- Loading state with CircularProgressIndicator
- Call `SupabaseService.archiveUserData()`
- SnackBar success: "Données archivées. Vous pouvez les restaurer depuis les paramètres avancés."
- Pop the sheet

### 3b: Replace "Supprimer toutes les données" handler

Replace the fake handler with:
- Show dialog with TextField
- User must type "SUPPRIMER" to confirm
- Red warning text: "Cette action est irréversible. Toutes vos données seront définitivement supprimées."
- Loading state
- Call `SupabaseService.deleteAllUserData()`
- SnackBar success: "Toutes les données ont été supprimées."
- Pop the sheet

### 3c: Add "Restaurer mes données" button

Add a new button in the Danger Zone section (above the existing 2 buttons):
- Only visible when `hasArchivedData()` returns true
- Green accent color (not red)
- Calls `SupabaseService.restoreUserData()`
- SnackBar: "Données restaurées avec succès."

Check `hasArchivedData()` in the sheet's `initState` and store result in a `_hasArchivedData` bool.

---

## Agent Dispatch Strategy

| Agent | Tasks | Files | Depends on |
|-------|-------|-------|------------|
| **Agent A** | Task 1 (all) | Supabase migration | None |
| **Agent B** | Task 2 | `supabase_service.dart` | Agent A |
| **Agent C** | Task 3 | `advanced_settings_sheet.dart` | Agent A |

Agent A runs first. Agents B and C run in parallel after A completes.
