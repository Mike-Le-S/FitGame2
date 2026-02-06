# Database Coherence Audit - FitGame2

Date: 2026-02-06
Supabase Project: `snqeueklxfdwxfrrpdvl`

## Executive Summary

The FitGame2 database schema contains **16 public tables** serving a Flutter mobile app and a React coach web portal. The audit found **5 critical issues (P0)**, **8 high issues (P1)**, **7 medium issues (P2)**, and **6 low issues (P3)**.

**Key findings:**
- **Missing `challenges` table**: Flutter code references a `challenges` table that does not exist in the database (will crash at runtime)
- **Missing RPC functions**: Code calls `increment_total_sessions` and `get_total_sessions` which do not exist
- **FK reference inconsistency**: 3 tables (`daily_nutrition_logs`, `user_favorite_foods`, `meal_templates`, `community_foods`) reference `auth.users.id` instead of `profiles.id`, creating divergence from the rest of the schema
- **Massive RLS performance issues**: 40+ RLS policies use `auth.uid()` without `(select ...)` wrapper, causing per-row re-evaluation
- **Flutter/React type divergence**: Several entities are modeled differently across the two apps
- **3 missing indexes on foreign keys** identified by Supabase advisor
- **`handle_new_user` function has mutable search path** (security vulnerability)
- **Duplicate profile creation**: Both `handle_new_user` trigger AND manual inserts in app code can create duplicate profiles

---

## Database Schema Overview

### Tables (16 total)

| Table | Rows | RLS | Description |
|-------|------|-----|-------------|
| `profiles` | 2 | Yes | User profiles (athlete/coach), links to `auth.users` |
| `coaches` | 0 | Yes | Extended coach details (theme, credentials) |
| `programs` | 1 | Yes | Workout programs (JSONB days) |
| `diet_plans` | 2 | Yes | Nutrition plans (JSONB meals/supplements) |
| `workout_sessions` | 0 | Yes | Completed workout sessions (JSONB exercises) |
| `assignments` | 0 | Yes | Coach-student program/diet assignments |
| `messages` | 0 | Yes | Direct messages between coach/student |
| `friendships` | 0 | Yes | Friend relationships with status |
| `activity_feed` | 0 | Yes | Social activity feed items |
| `notifications` | 0 | Yes | Push notifications |
| `daily_nutrition_logs` | 1 | Yes | Daily food tracking |
| `day_types` | 2 | Yes | Diet plan day type definitions |
| `weekly_schedule` | 7 | Yes | Maps weekdays to day types |
| `user_favorite_foods` | 0 | Yes | User's favorite foods |
| `meal_templates` | 0 | Yes | Saved meal templates |
| `community_foods` | 0 | Yes | User-contributed food database |

### Functions & Triggers

| Function | Type | Usage |
|----------|------|-------|
| `handle_new_user()` | FUNCTION | Trigger: auto-creates profile on `auth.users` INSERT |
| `update_updated_at()` | FUNCTION | Trigger: auto-updates `updated_at` on profiles, coaches, programs, diet_plans, assignments |

### Relationships Diagram

```
auth.users
    |
    |-- 1:1 --> profiles (id = auth.users.id, ON DELETE CASCADE)
    |               |
    |               |-- 1:1 --> coaches (id = profiles.id, ON DELETE CASCADE)
    |               |-- N:1 --> profiles (coach_id, ON DELETE SET NULL, self-ref)
    |               |
    |               |-- 1:N --> programs (created_by, ON DELETE CASCADE)
    |               |-- 1:N --> diet_plans (created_by, ON DELETE CASCADE)
    |               |-- 1:N --> workout_sessions (user_id, ON DELETE CASCADE)
    |               |-- 1:N --> assignments (coach_id, ON DELETE CASCADE)
    |               |-- 1:N --> assignments (student_id, ON DELETE CASCADE)
    |               |-- 1:N --> messages (sender_id, ON DELETE CASCADE)
    |               |-- 1:N --> messages (receiver_id, ON DELETE CASCADE)
    |               |-- 1:N --> friendships (user_id, ON DELETE CASCADE)
    |               |-- 1:N --> friendships (friend_id, ON DELETE CASCADE)
    |               |-- 1:N --> activity_feed (user_id, ON DELETE CASCADE)
    |               |-- 1:N --> notifications (user_id, ON DELETE CASCADE)
    |
    |-- 1:N --> daily_nutrition_logs (user_id, NO CASCADE!)
    |-- 1:N --> user_favorite_foods (user_id, NO CASCADE!)
    |-- 1:N --> meal_templates (user_id, NO CASCADE!)
    |-- 1:N --> community_foods (contributed_by, NO CASCADE!)

programs
    |-- 1:N --> workout_sessions (program_id, ON DELETE SET NULL)
    |-- 1:N --> assignments (program_id, ON DELETE CASCADE)

diet_plans
    |-- 1:N --> assignments (diet_plan_id, ON DELETE CASCADE)
    |-- 1:N --> daily_nutrition_logs (diet_plan_id, ON DELETE SET NULL)
    |-- 1:N --> day_types (diet_plan_id, ON DELETE CASCADE)
    |-- 1:N --> weekly_schedule (diet_plan_id, ON DELETE CASCADE)

day_types
    |-- 1:N --> weekly_schedule (day_type_id, ON DELETE CASCADE)
```

---

## Critical Issues (P0)

### [DB-001] Missing `challenges` table -- runtime crash

**Severity**: P0 - CRITICAL
**Impact**: Flutter app crashes when users access the Challenges feature

The Flutter `supabase_service.dart` contains full CRUD operations for a `challenges` table (lines 1248-1398) that does **not exist** in the database.

**Code references**:
- `/Users/mike/projects/FitGame2/fitgame/lib/core/services/supabase_service.dart:1254` - `client.from('challenges').select()`
- `/Users/mike/projects/FitGame2/fitgame/lib/core/services/supabase_service.dart:1298` - `client.from('challenges').insert({...})`
- `/Users/mike/projects/FitGame2/fitgame/lib/core/services/supabase_service.dart:1336` - `client.from('challenges').select()`
- `/Users/mike/projects/FitGame2/fitgame/lib/features/social/models/challenge.dart` - Full Dart model defined

**Expected schema** (from code):
```sql
-- columns: id, creator_id, creator_name, title, exercise_name, type, target_value, unit, deadline, status, participants (jsonb), created_at
```

**Fix SQL**:
```sql
CREATE TABLE public.challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  creator_name text NOT NULL,
  title text NOT NULL,
  exercise_name text NOT NULL,
  type text NOT NULL CHECK (type IN ('weight', 'reps', 'time', 'custom')),
  target_value numeric NOT NULL,
  unit text NOT NULL,
  deadline timestamptz,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'expired')),
  participants jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_challenges_creator ON public.challenges(creator_id);
CREATE INDEX idx_challenges_status ON public.challenges(status);

-- RLS policies
CREATE POLICY "Users can view challenges they participate in" ON public.challenges
  FOR SELECT USING (
    creator_id = (select auth.uid())
    OR participants @> jsonb_build_array(jsonb_build_object('id', (select auth.uid())::text))
  );

CREATE POLICY "Users can create challenges" ON public.challenges
  FOR INSERT WITH CHECK ((select auth.uid()) = creator_id);

CREATE POLICY "Creators can update their challenges" ON public.challenges
  FOR UPDATE USING ((select auth.uid()) = creator_id);
```

---

### [DB-002] Missing RPC functions -- runtime crash on workout completion

**Severity**: P0 - CRITICAL
**Impact**: `completeWorkoutSession()` calls non-existent RPC functions

**Code reference**: `/Users/mike/projects/FitGame2/fitgame/lib/core/services/supabase_service.dart:368-376`

```dart
await client.rpc('increment_total_sessions', params: {
  'user_id': currentUser!.id,
}).catchError((_) {
  // Fallback: update directly -- BUT this fallback also calls non-existent rpc
  client.from('profiles')
      .update({'total_sessions': client.rpc('get_total_sessions')})
      .eq('id', currentUser!.id);
});
```

Neither `increment_total_sessions` nor `get_total_sessions` exists. The fallback is also broken because it passes an RPC call as a value to `.update()`.

**Fix SQL**:
```sql
CREATE OR REPLACE FUNCTION public.increment_total_sessions(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE profiles
  SET total_sessions = COALESCE(total_sessions, 0) + 1
  WHERE id = p_user_id;
END;
$$;
```

---

### [DB-003] Duplicate profile creation via trigger + manual insert

**Severity**: P0 - CRITICAL
**Impact**: Race condition causes duplicate key violation on `profiles` table

The `handle_new_user()` trigger auto-creates a profile when a user signs up via `auth.users`. But BOTH Flutter (`supabase_service.dart:64`) and React (`auth-store.ts:157`) also manually insert into `profiles` after signup.

**Code references**:
- `/Users/mike/projects/FitGame2/fitgame/lib/core/services/supabase_service.dart:63-69` - Manual profile insert after signUp
- `/Users/mike/projects/FitGame2/coach-web/src/store/auth-store.ts:155-162` - Manual profile insert after signUp
- Database trigger: `handle_new_user()` on `auth.users` INSERT

**Impact**: The trigger fires first, creating the profile. Then the manual insert fails with a duplicate key error. Currently swallowed silently, but means `coach_id`, `goal`, and other fields set by manual insert are lost.

**Fix**: Either remove the trigger OR remove the manual inserts. Recommended: keep trigger, remove manual inserts, and enhance trigger to accept metadata:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, goal, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'athlete'),
    'maintain',
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$;
```

---

### [DB-004] FK reference inconsistency -- `auth.users` vs `profiles`

**Severity**: P0 - CRITICAL
**Impact**: Orphan records and missing cascade deletes when users are deleted

4 tables reference `auth.users.id` directly instead of `profiles.id`:

| Table | Column | Current FK Target | Missing CASCADE |
|-------|--------|-------------------|-----------------|
| `daily_nutrition_logs` | `user_id` | `auth.users.id` | NO CASCADE |
| `user_favorite_foods` | `user_id` | `auth.users.id` | NO CASCADE |
| `meal_templates` | `user_id` | `auth.users.id` | NO CASCADE |
| `community_foods` | `contributed_by` | `auth.users.id` | NO CASCADE |

All other user-owned tables reference `profiles.id` with `ON DELETE CASCADE`. These 4 tables will have orphaned rows when a user is deleted.

**Fix SQL**:
```sql
-- daily_nutrition_logs
ALTER TABLE public.daily_nutrition_logs DROP CONSTRAINT daily_nutrition_logs_user_id_fkey;
ALTER TABLE public.daily_nutrition_logs ADD CONSTRAINT daily_nutrition_logs_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- user_favorite_foods
ALTER TABLE public.user_favorite_foods DROP CONSTRAINT user_favorite_foods_user_id_fkey;
ALTER TABLE public.user_favorite_foods ADD CONSTRAINT user_favorite_foods_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- meal_templates
ALTER TABLE public.meal_templates DROP CONSTRAINT meal_templates_user_id_fkey;
ALTER TABLE public.meal_templates ADD CONSTRAINT meal_templates_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- community_foods
ALTER TABLE public.community_foods DROP CONSTRAINT community_foods_contributed_by_fkey;
ALTER TABLE public.community_foods ADD CONSTRAINT community_foods_contributed_by_fkey
  FOREIGN KEY (contributed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
```

---

### [DB-005] `handle_new_user` function has mutable search_path -- security vulnerability

**Severity**: P0 - CRITICAL (flagged by Supabase security advisor)
**Impact**: Potential SQL injection via search path manipulation

**Current state**: The `handle_new_user()` function does not set `search_path`, making it vulnerable.

**Fix SQL**:
```sql
ALTER FUNCTION public.handle_new_user() SET search_path = public;
```

---

## High Issues (P1)

### [DB-006] `notifications` INSERT policy always true -- security bypass

**Severity**: P1 - HIGH
**Impact**: Any authenticated user can insert notifications for ANY user

**Current policy**: `System can create notifications` -> `WITH CHECK (true)`
This allows any authenticated user to create notifications targeting any user_id.

**Code reference**: Flutter code inserts notifications with arbitrary `user_id` in `supabase_service.dart:1316`:
```dart
await client.from('notifications').insert({
  'user_id': participantId, // Can be ANY user
  ...
});
```

**Fix SQL**:
```sql
DROP POLICY "System can create notifications" ON public.notifications;
CREATE POLICY "Users can create notifications" ON public.notifications
  FOR INSERT WITH CHECK (
    (select auth.uid()) IS NOT NULL
  );
-- For truly system-level notifications, use a service_role key or database function
```

---

### [DB-007] Flutter/React `FoodEntry` type divergence

**Severity**: P1 - HIGH
**Impact**: Coach and athlete apps model the same entity differently, causing data interpretation errors

**Flutter** (`diet_models.dart:16-35`):
```dart
class FoodEntry {
  final String id;
  final String name;
  final String quantity;  // String type!
  final int calories;
  final int protein;      // Flat fields
  final int carbs;
  final int fat;
  final String unit;
}
```

**React** (`types/index.ts:114-121`):
```typescript
interface FoodEntry {
  id: string;
  name: string;
  calories: number;
  macros: Macros;          // Nested object!
  quantity: number;         // Number type!
  unit: string;
}
```

Key differences:
1. `quantity`: String in Flutter vs Number in React
2. Macros: Flat (`protein`, `carbs`, `fat`) in Flutter vs nested `macros: {protein, carbs, fat}` in React
3. These are stored as JSONB in `diet_plans.meals` -- whichever app writes first determines the format, and the other app will break reading it

---

### [DB-008] Flutter/React `WorkoutSession` type divergence

**Severity**: P1 - HIGH
**Impact**: Session data written by one app may not parse correctly in the other

**DB schema** (`workout_sessions.exercises` JSONB):
```
[{id, exerciseId, exerciseName, sets: [{setNumber, isWarmup, weightKg, reps, completed, rpe}]}]
```

**React** (`students-store.ts:16-31` WorkoutSession):
```typescript
exercises: Array<{
  exerciseName: string;
  muscleGroup?: string;
  sets: Array<{
    weight: number;      // "weight" not "weightKg"
    reps: number;
    isWarmup?: boolean;
  }>
}>
```

**React types** (`types/index.ts:93-102` WorkoutSession):
```typescript
interface WorkoutSession {
  id: string;
  programId: string;      // NOT nullable in type, but IS nullable in DB
  studentId: string;      // Maps to "user_id" in DB
  dayId: string;          // Maps to "day_name" in DB -- different semantics
  ...
}
```

Key mismatches:
1. `weight` vs `weightKg` in sets JSONB
2. `studentId` vs `user_id` (field name)
3. `dayId` vs `day_name` (different semantics -- ID vs text name)
4. `programId` required in type but nullable in DB

---

### [DB-009] Flutter/React `Message` type divergence

**Severity**: P1 - HIGH
**Impact**: React models a `conversationId` concept that doesn't exist in DB

**DB schema**: `messages` has `sender_id`, `receiver_id`, no `conversation_id`

**React type** (`types/index.ts:201-208`):
```typescript
interface Message {
  id: string;
  conversationId: string;   // Does NOT exist in DB
  senderId: string;
  content: string;
  sentAt: string;
  readAt?: string;
}
```

The React store artificially constructs `conversationId` = `studentId` at runtime (`messages-store.ts:37`). This is fragile -- if the DB adds a real conversation_id later, the React code would need refactoring.

---

### [DB-010] `CalendarEvent` and `events-store` not backed by any DB table

**Severity**: P1 - HIGH
**Impact**: Calendar data is ephemeral -- lost on page reload

**Code reference**: `/Users/mike/projects/FitGame2/coach-web/src/store/events-store.ts` uses mock data only, no Supabase calls. The `CalendarEvent` type (`types/index.ts:185-195`) references a `calendar_events` table that doesn't exist.

**Fix**: Either create a `calendar_events` table or document that this is intentionally local-only.

```sql
CREATE TABLE public.calendar_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  type text NOT NULL CHECK (type IN ('workout', 'nutrition', 'check-in', 'other')),
  date date NOT NULL,
  time text,
  duration integer,
  notes text,
  completed boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
```

---

### [DB-011] `settings-store` not persisted to DB

**Severity**: P1 - HIGH
**Impact**: Coach settings (theme, accent_color, 2FA) exist in DB (`coaches` table) but `settings-store.ts` only uses `zustand/persist` (localStorage), never syncing with the DB

**Code reference**: `/Users/mike/projects/FitGame2/coach-web/src/store/settings-store.ts` -- no Supabase calls at all

**DB fields available**: `coaches.theme`, `coaches.accent_color`, `coaches.two_factor_enabled`

These settings will be lost when the coach uses a different browser/device.

---

### [DB-012] `profiles.goal` field missing in coach-web `Profile` type

**Severity**: P1 - HIGH
**Impact**: Coach web `Profile` interface in `supabase.ts` is missing the `goal` field added in migration `20260201103738`

**Code reference**: `/Users/mike/projects/FitGame2/coach-web/src/lib/supabase.ts:13-27`

```typescript
export interface Profile {
  // ... missing: goal: Goal
}
```

The `goal` column exists in the DB (nullable, default `'maintain'`) and is used by `students-store.ts:70` (`profile.goal || 'maintain'`), but the TypeScript type doesn't declare it, relying on `any` casting.

---

### [DB-013] `diet_plans` columns `is_active` and `active_from` missing from React types

**Severity**: P1 - HIGH
**Impact**: Coach web cannot manage diet plan activation state

**DB columns**: `is_active` (boolean, default false), `active_from` (date, nullable)

**React `DietPlan` type** (`types/index.ts:138-152`): Does not include `isActive` or `activeFrom`

**React `nutrition-store.ts`**: `dbToDietPlan()` function (line 112-128) does not map these fields

Flutter code fully supports activation via `activateDietPlan()` and `deactivateAllDietPlans()`, but the coach web portal has no visibility into this.

---

## Medium Issues (P2)

### [DB-014] Missing indexes on foreign keys (Supabase advisor)

**Severity**: P2 - MEDIUM
**Impact**: Suboptimal query performance on JOINs

| Table | FK Column | Missing Index |
|-------|-----------|---------------|
| `community_foods` | `contributed_by` | No index |
| `daily_nutrition_logs` | `diet_plan_id` | No index |
| `weekly_schedule` | `day_type_id` | No index |

**Fix SQL**:
```sql
CREATE INDEX idx_community_foods_contributed_by ON public.community_foods(contributed_by);
CREATE INDEX idx_daily_nutrition_logs_diet_plan ON public.daily_nutrition_logs(diet_plan_id);
CREATE INDEX idx_weekly_schedule_day_type ON public.weekly_schedule(day_type_id);
```

---

### [DB-015] RLS policies use `auth.uid()` without `(select ...)` wrapper -- 40+ policies affected

**Severity**: P2 - MEDIUM
**Impact**: Every RLS policy re-evaluates `auth.uid()` per row instead of once per query

All 40+ RLS policies across all tables use `auth.uid()` directly. At scale this causes significant performance degradation.

**Affected tables**: profiles, coaches, messages, friendships, activity_feed, notifications, programs, workout_sessions, assignments, diet_plans, daily_nutrition_logs, user_favorite_foods, meal_templates, community_foods, day_types, weekly_schedule

**Fix pattern** (apply to ALL policies):
```sql
-- Example: Before
CREATE POLICY "..." ON public.profiles FOR SELECT USING (auth.uid() = id);
-- After
CREATE POLICY "..." ON public.profiles FOR SELECT USING ((select auth.uid()) = id);
```

---

### [DB-016] Multiple permissive SELECT policies on same tables

**Severity**: P2 - MEDIUM
**Impact**: Both policies execute for every SELECT query, degrading performance

Affected tables:
- `profiles`: "Users can view own profile" + "Coaches can view their students"
- `programs`: "Users can manage own programs" + "Students can view assigned programs"
- `diet_plans`: "Users can manage own diet plans" + "Students can view assigned diet plans"
- `workout_sessions`: "Users can manage own workout sessions" + "Coaches can view student sessions"
- `assignments`: "Coaches can manage own assignments" + "Students can view own assignments"

**Fix**: Merge into single policies per table with combined conditions, or use RESTRICTIVE policies.

---

### [DB-017] Flutter `SupplementEntry` has `icon` (IconData) field not serializable to DB

**Severity**: P2 - MEDIUM
**Impact**: When supplements are stored in `diet_plans.supplements` JSONB, the `icon` field cannot be serialized

**Code reference**: `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/models/diet_models.dart:102`
```dart
class SupplementEntry {
  final IconData icon;  // Flutter IconData -- NOT JSON serializable
  ...
}
```

**DB comment** on `diet_plans.supplements`: `Array of supplements: [{id, name, dosage, timing, reminderEnabled, reminderTime}]`

The DB expects `reminderEnabled` and `reminderTime`, but Flutter has `notificationsEnabled` and `reminderTime` (different field name). Also `icon` will either be lost or cause errors during serialization.

---

### [DB-018] Flutter `MealPlan` has `icon` (IconData) field not stored in DB

**Severity**: P2 - MEDIUM
**Impact**: Meal plan icons set in Flutter are lost when data round-trips through DB

**Code reference**: `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/models/diet_models.dart:63`
```dart
class MealPlan {
  final IconData icon;  // Not storable in JSONB
  ...
}
```

---

### [DB-019] `programs` missing `is_cycled`, `deload_enabled`, `deload_reduction` in code mappings

**Severity**: P2 - MEDIUM
**Impact**: DB columns exist but are never read/written by application code

**DB columns**: `is_cycled` (bool), `deload_enabled` (bool), `deload_reduction` (int)

**Flutter `createProgram()`** (`supabase_service.dart:236-261`): Does not send `is_cycled`, `deload_enabled`, `deload_reduction`

**React `programToDb()`** (`programs-store.ts:150-160`): Does not map `is_cycled`, `deload_enabled`, `deload_reduction`

**React `dbToProgram()`** (`programs-store.ts:134-147`): Does not read `is_cycled`, `deload_enabled`, `deload_reduction`

These columns are wasted storage.

---

### [DB-020] `workout_sessions.calories_burned` column unused

**Severity**: P2 - MEDIUM
**Impact**: DB has a `calories_burned` column (int, default 0) but no code writes to it

Neither Flutter `startWorkoutSession()` nor `completeWorkoutSession()` sets `calories_burned`. The column exists but is always 0.

---

## Low Issues (P3)

### [DB-021] `notifications.data` column is named `data` in DB but `metadata` in some code paths

**Severity**: P3 - LOW
**Impact**: Potential confusion but not a bug since Flutter code correctly uses `'metadata'` as key name in the notification body, and the DB column is `data` (different field)

Actually checking again -- the Flutter code at line 1322 uses:
```dart
'metadata': {'challenge_id': response['id']},
```
But the DB column is named `data`, not `metadata`. This means the metadata is stored in a column called `data` -- it works because JSONB is flexible, but the naming is inconsistent.

Wait -- re-checking: the `notifications` table has a column named `data` (jsonb). The Flutter code sends `'metadata'` as a key, but the Supabase insert maps field names to column names. So `'metadata'` would try to write to a `metadata` column that doesn't exist. The correct column name is `data`.

**Correction -- this is actually a P1 bug**: Flutter code at line 1322 inserts `'metadata'` key but the DB column is `data`. However, Supabase will silently ignore unknown columns, so the challenge_id data is simply **lost**.

**Fix**: Change `'metadata'` to `'data'` in the notifications insert.

---

### [DB-022] React `Program.assignedStudentIds` is synthetic, not in DB

**Severity**: P3 - LOW
**Impact**: No bug, but the React type (`types/index.ts:91`) includes `assignedStudentIds` which is not a DB column. It's correctly populated from the `assignments` table at runtime.

---

### [DB-023] React `DietPlan.assignedStudentIds` is synthetic, not in DB

**Severity**: P3 - LOW
**Impact**: Same as DB-022, for diet plans.

---

### [DB-024] `community_foods` name column is `varchar` while most others are `text`

**Severity**: P3 - LOW
**Impact**: Inconsistency only; `varchar` without length limit behaves identically to `text` in PostgreSQL.

---

### [DB-025] Flutter `Activity` model has `respectCount`, `hasGivenRespect`, `respectGivers` fields not in DB

**Severity**: P3 - LOW
**Impact**: The "respect" (like) system exists in the Flutter model but has no DB backing. Currently mock data only.

**Code reference**: `/Users/mike/projects/FitGame2/fitgame/lib/features/social/models/activity.dart:14-16`

---

### [DB-026] Flutter `Friend` model has `isOnline`, `totalWorkouts`, `streak` not directly in `friendships` table

**Severity**: P3 - LOW
**Impact**: The `friendships` table stores relationship status only. `isOnline`, `totalWorkouts`, `streak` must be derived from `profiles` table joins. Currently mock data only.

**Code reference**: `/Users/mike/projects/FitGame2/fitgame/lib/features/social/models/friend.dart:6-9`

---

## Schema-Code Comparison

### Table: `profiles`

| Column | DB Type | Nullable | Default | Flutter | React (`Profile`) | Match? | Issue |
|--------|---------|----------|---------|---------|--------------------|--------|-------|
| `id` | uuid | NO | - | via Map | `id: string` | OK | |
| `email` | text | NO | - | via Map | `email: string` | OK | |
| `full_name` | text | NO | - | via Map | `full_name: string` | OK | |
| `avatar_url` | text | YES | null | via Map | `avatar_url: string\|null` | OK | |
| `role` | text | NO | 'athlete' | via Map | `role: 'athlete'\|'coach'` | OK | |
| `coach_id` | uuid | YES | null | via Map | `coach_id: string\|null` | OK | |
| `total_sessions` | int | YES | 0 | via Map | `total_sessions: number` | OK | |
| `current_streak` | int | YES | 0 | via Map | `current_streak: number` | OK | |
| `weight_unit` | text | YES | 'kg' | via Map | `weight_unit: 'kg'\|'lbs'` | OK | |
| `language` | text | YES | 'fr' | via Map | `language: 'fr'\|'en'` | OK | |
| `notifications_enabled` | bool | YES | true | via Map | `notifications_enabled: boolean` | OK | |
| `goal` | text | YES | 'maintain' | via Map | **MISSING** | FAIL | DB-012 |
| `created_at` | timestamptz | YES | now() | via Map | `created_at: string` | OK | |
| `updated_at` | timestamptz | YES | now() | via Map | `updated_at: string` | OK | |

### Table: `diet_plans`

| Column | DB Type | Nullable | Default | Flutter (`createDietPlan`) | React (`DietPlan`) | Match? | Issue |
|--------|---------|----------|---------|----------------------------|--------------------|--------|-------|
| `id` | uuid | NO | gen_random_uuid() | OK | `id: string` | OK | |
| `created_by` | uuid | NO | - | OK | via `dietPlanToDb` | OK | |
| `name` | text | NO | - | OK | `name: string` | OK | |
| `goal` | text | NO | - | OK | `goal: Goal` | OK | |
| `training_calories` | int | NO | - | OK | `trainingCalories: number` | OK | |
| `rest_calories` | int | NO | - | OK | `restCalories: number` | OK | |
| `training_macros` | jsonb | NO | default | OK | `trainingMacros: Macros` | OK | |
| `rest_macros` | jsonb | NO | default | OK | `restMacros: Macros` | OK | |
| `meals` | jsonb | NO | '[]' | OK | `meals: MealPlan[]` | WARN | DB-007 |
| `supplements` | jsonb | NO | '[]' | OK | `supplements: SupplementEntry[]` | WARN | DB-017 |
| `notes` | text | YES | null | OK | `notes?: string` | OK | |
| `is_active` | bool | YES | false | OK (Flutter) | **MISSING** | FAIL | DB-013 |
| `active_from` | date | YES | null | OK (Flutter) | **MISSING** | FAIL | DB-013 |
| `created_at` | timestamptz | YES | now() | OK | `createdAt: string` | OK | |
| `updated_at` | timestamptz | YES | now() | OK | `updatedAt: string` | OK | |

### Table: `challenges` (MISSING FROM DB)

| Expected Column | Expected Type | Flutter Type | Issue |
|-----------------|---------------|--------------|-------|
| `id` | uuid | `String id` | DB-001 |
| `creator_id` | uuid | `String creatorId` | DB-001 |
| `creator_name` | text | `String creatorName` | DB-001 |
| `title` | text | `String title` | DB-001 |
| `exercise_name` | text | `String exerciseName` | DB-001 |
| `type` | text | `ChallengeType` | DB-001 |
| `target_value` | numeric | `double targetValue` | DB-001 |
| `unit` | text | `String unit` | DB-001 |
| `deadline` | timestamptz | `DateTime? deadline` | DB-001 |
| `status` | text | `ChallengeStatus` | DB-001 |
| `participants` | jsonb | `List<ChallengeParticipant>` | DB-001 |
| `created_at` | timestamptz | `DateTime createdAt` | DB-001 |

---

## Missing Indexes Analysis

### Queries in code vs available indexes

| Query Pattern | File | Indexed? |
|---------------|------|----------|
| `profiles WHERE coach_id = X AND role = 'athlete'` | students-store.ts:103-106 | Partial (idx_profiles_coach_id exists, but composite with role would be better) |
| `assignments WHERE coach_id = X AND student_id IN (...)` | students-store.ts:115-120 | Yes (idx_assignments_coach_id, idx_assignments_student_id) |
| `workout_sessions WHERE user_id IN (...) AND completed_at IS NOT NULL` | students-store.ts:129-134 | Partial (idx_workout_sessions_user_id exists) |
| `diet_plans WHERE created_by = X AND is_active = true` | supabase_service.dart:537-540 | Yes (idx_diet_plans_user_active partial) |
| `daily_nutrition_logs WHERE user_id = X AND date = Y` | supabase_service.dart:717-719 | Yes (daily_nutrition_logs_user_id_date_key unique) |
| `community_foods WHERE barcode = X` | supabase_service.dart:900 | Yes (community_foods_barcode_key unique) |
| `community_foods WHERE name ILIKE '%X%'` | supabase_service.dart:913 | NO -- needs trigram index for ILIKE |
| `friendships WHERE status = 'accepted'` | activity_feed RLS policy | NO -- no index on status |

**Recommended additional indexes**:
```sql
-- For community foods search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_community_foods_name_trgm ON public.community_foods USING gin (name gin_trgm_ops);

-- For friendships status filtering (used in RLS)
CREATE INDEX idx_friendships_status ON public.friendships(status);

-- Composite index for coach student lookups
CREATE INDEX idx_profiles_coach_role ON public.profiles(coach_id, role) WHERE role = 'athlete';
```

---

## Performance Advisors Summary

### Unindexed Foreign Keys (3)
- `community_foods.contributed_by` -- Fix: DB-014
- `daily_nutrition_logs.diet_plan_id` -- Fix: DB-014
- `weekly_schedule.day_type_id` -- Fix: DB-014

### Auth RLS InitPlan (40+ policies)
All RLS policies use `auth.uid()` without `(select auth.uid())` wrapper. Fix: DB-015

### Multiple Permissive Policies (5 tables)
Tables `profiles`, `programs`, `diet_plans`, `workout_sessions`, `assignments` have multiple SELECT policies. Fix: DB-016

### Unused Indexes (17)
Most indexes are unused because the app has minimal data. These should be kept for production readiness but monitored.

### Security: Leaked Password Protection Disabled
Enable via Supabase dashboard: Auth > Settings > Password Security

### Security: `handle_new_user` mutable search_path
Fix: DB-005

### Security: `notifications` INSERT policy always true
Fix: DB-006

---

## Action Plan

| Priority | Issue ID | Title | SQL Effort | Code Effort |
|----------|----------|-------|------------|-------------|
| P0 | DB-001 | Create `challenges` table | 1h | 0 (code already exists) |
| P0 | DB-002 | Create `increment_total_sessions` RPC | 15min | Fix fallback code |
| P0 | DB-003 | Fix duplicate profile creation | 15min SQL | 30min code (remove manual inserts) |
| P0 | DB-004 | Fix FK references to use `profiles.id` | 30min | 0 |
| P0 | DB-005 | Fix `handle_new_user` search_path | 5min | 0 |
| P1 | DB-006 | Fix notifications INSERT policy | 10min | 0 |
| P1 | DB-007 | Align Flutter/React FoodEntry types | 0 | 2h (choose one format) |
| P1 | DB-008 | Align Flutter/React WorkoutSession types | 0 | 1h |
| P1 | DB-009 | Document Message conversationId pattern | 0 | 15min |
| P1 | DB-010 | Create `calendar_events` table or doc | 30min | 1h |
| P1 | DB-011 | Sync settings-store with `coaches` table | 0 | 1h |
| P1 | DB-012 | Add `goal` to React Profile type | 0 | 5min |
| P1 | DB-013 | Add `isActive`/`activeFrom` to React DietPlan | 0 | 30min |
| P2 | DB-014 | Create 3 missing FK indexes | 5min | 0 |
| P2 | DB-015 | Fix all RLS policies (40+) | 2h | 0 |
| P2 | DB-016 | Merge multiple permissive policies | 1h | 0 |
| P2 | DB-017 | Fix supplement field name mismatch | 0 | 30min |
| P2 | DB-018 | Handle MealPlan icon serialization | 0 | 30min |
| P2 | DB-019 | Remove or use unused program columns | 15min | 30min |
| P2 | DB-020 | Remove or use `calories_burned` column | 5min | 0 |
| P3 | DB-021 | Fix notification `metadata` -> `data` key | 0 | 5min |
| P3 | DB-025 | Plan "respect" system DB backing | 30min | Future |
| P3 | DB-026 | Document Friend model data sources | 0 | 15min |

---

## Entity-Relationship Corrections

### Suggested Migration: Fix All P0 Issues

```sql
-- Migration: fix_critical_coherence_issues

-- 1. Fix handle_new_user search_path and role support (DB-005, DB-003)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, goal, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'athlete'),
    'maintain',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- 2. Create increment_total_sessions RPC (DB-002)
CREATE OR REPLACE FUNCTION public.increment_total_sessions(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET total_sessions = COALESCE(total_sessions, 0) + 1
  WHERE id = p_user_id;
END;
$$;

-- 3. Fix FK references (DB-004)
ALTER TABLE public.daily_nutrition_logs
  DROP CONSTRAINT daily_nutrition_logs_user_id_fkey,
  ADD CONSTRAINT daily_nutrition_logs_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.user_favorite_foods
  DROP CONSTRAINT user_favorite_foods_user_id_fkey,
  ADD CONSTRAINT user_favorite_foods_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.meal_templates
  DROP CONSTRAINT meal_templates_user_id_fkey,
  ADD CONSTRAINT meal_templates_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.community_foods
  DROP CONSTRAINT community_foods_contributed_by_fkey,
  ADD CONSTRAINT community_foods_contributed_by_fkey
    FOREIGN KEY (contributed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 4. Create challenges table (DB-001)
CREATE TABLE public.challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  creator_name text NOT NULL,
  title text NOT NULL,
  exercise_name text NOT NULL,
  type text NOT NULL CHECK (type IN ('weight', 'reps', 'time', 'custom')),
  target_value numeric NOT NULL,
  unit text NOT NULL,
  deadline timestamptz,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'expired')),
  participants jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_challenges_creator ON public.challenges(creator_id);
CREATE INDEX idx_challenges_status ON public.challenges(status);

CREATE POLICY "Users can view own and participated challenges" ON public.challenges
  FOR SELECT USING (
    creator_id = (select auth.uid())
    OR EXISTS (
      SELECT 1 FROM jsonb_array_elements(participants) p
      WHERE p->>'id' = (select auth.uid())::text
    )
  );
CREATE POLICY "Users can create challenges" ON public.challenges
  FOR INSERT WITH CHECK ((select auth.uid()) = creator_id);
CREATE POLICY "Participants can update challenges" ON public.challenges
  FOR UPDATE USING (
    creator_id = (select auth.uid())
    OR EXISTS (
      SELECT 1 FROM jsonb_array_elements(participants) p
      WHERE p->>'id' = (select auth.uid())::text
    )
  );

-- 5. Create missing FK indexes (DB-014)
CREATE INDEX idx_community_foods_contributed_by ON public.community_foods(contributed_by);
CREATE INDEX idx_daily_nutrition_logs_diet_plan ON public.daily_nutrition_logs(diet_plan_id);
CREATE INDEX idx_weekly_schedule_day_type ON public.weekly_schedule(day_type_id);

-- 6. Fix notifications INSERT policy (DB-006)
DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;
CREATE POLICY "Authenticated can create notifications" ON public.notifications
  FOR INSERT WITH CHECK ((select auth.uid()) IS NOT NULL);
```
