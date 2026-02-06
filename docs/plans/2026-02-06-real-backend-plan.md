# Real Backend Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace all mock/hardcoded data with real Supabase connections across Flutter and React apps.

**Architecture:** We use Supabase as BaaS (PostgreSQL + Auth + Realtime + Storage). The Flutter app talks to Supabase via `supabase_service.dart`. The React coach-web uses Zustand stores with direct Supabase client calls. Both apps already have most core features connected — this plan fills the remaining gaps.

**Tech Stack:** Supabase (PostgreSQL, Realtime, Storage), Flutter/Dart, React/TypeScript/Zustand

**Current State:** ~80% connected. Core workout/nutrition/messaging/auth are real. Missing: calendar events, health persistence, home screen widgets, achievements, social respect, settings sync, header notifications.

---

## Phase 1: Database Migrations (Supabase)

### Task 1: Create `calendar_events` table

**Why:** Coach-web calendar page uses 100% mock data (events-store.ts has 5 hardcoded events, zero Supabase calls).

**Files:**
- Apply via Supabase MCP: `apply_migration`

**Step 1: Apply migration**

```sql
-- Create calendar_events table
CREATE TABLE public.calendar_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  student_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  type text NOT NULL CHECK (type IN ('workout', 'check-in', 'nutrition', 'note', 'holiday')),
  date date NOT NULL,
  time text, -- HH:mm format
  duration_minutes integer,
  completed boolean NOT NULL DEFAULT false,
  recurring boolean NOT NULL DEFAULT false,
  recurrence_rule text, -- RRULE format
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX idx_calendar_events_coach_id ON public.calendar_events(coach_id);
CREATE INDEX idx_calendar_events_student_id ON public.calendar_events(student_id);
CREATE INDEX idx_calendar_events_date ON public.calendar_events(date);

-- RLS
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Coaches can manage their own events"
  ON public.calendar_events FOR ALL
  USING ((SELECT auth.uid()) = coach_id)
  WITH CHECK ((SELECT auth.uid()) = coach_id);
```

**Step 2: Verify**

Run: `list_tables` via Supabase MCP, confirm `calendar_events` exists.

---

### Task 2: Create `health_metrics` table

**Why:** Health screen reads from HealthKit/Google Fit but never persists data. Coach can't see athlete health. No trends possible without historical data.

**Step 1: Apply migration**

```sql
-- Create health_metrics table for persisting health data
CREATE TABLE public.health_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date date NOT NULL,

  -- Sleep
  sleep_duration_minutes integer,
  sleep_score integer, -- 0-100
  deep_sleep_minutes integer,
  light_sleep_minutes integer,
  rem_sleep_minutes integer,
  awake_minutes integer,

  -- Heart
  resting_hr integer,
  avg_hr integer,
  max_hr integer,
  min_hr integer,
  hrv_ms double precision,

  -- Activity
  steps integer,
  active_calories integer,
  total_calories integer,
  distance_km double precision,

  -- Energy score (calculated)
  energy_score integer, -- 0-100

  source text NOT NULL DEFAULT 'apple_health' CHECK (source IN ('apple_health', 'google_fit', 'manual')),
  synced_at timestamptz DEFAULT now(),

  UNIQUE(user_id, date) -- One entry per user per day
);

-- Indexes
CREATE INDEX idx_health_metrics_user_id ON public.health_metrics(user_id);
CREATE INDEX idx_health_metrics_date ON public.health_metrics(date);
CREATE INDEX idx_health_metrics_user_date ON public.health_metrics(user_id, date);

-- RLS
ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own health data"
  ON public.health_metrics FOR ALL
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Coaches can read their athletes health data"
  ON public.health_metrics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = health_metrics.user_id
      AND profiles.coach_id = (SELECT auth.uid())
    )
  );
```

**Step 2: Verify**

Run: `list_tables` + `get_advisors(security)` to confirm table + RLS.

---

### Task 3: Create `activity_respects` table + update `activity_feed`

**Why:** Social screen shows respect counts but they're never persisted. Need a junction table for tracking who gave respect to which activity.

**Step 1: Apply migration**

```sql
-- Add respect_count to activity_feed
ALTER TABLE public.activity_feed
ADD COLUMN IF NOT EXISTS respect_count integer NOT NULL DEFAULT 0;

-- Create activity_respects junction table
CREATE TABLE public.activity_respects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id uuid NOT NULL REFERENCES public.activity_feed(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(activity_id, user_id) -- One respect per user per activity
);

CREATE INDEX idx_activity_respects_activity ON public.activity_respects(activity_id);
CREATE INDEX idx_activity_respects_user ON public.activity_respects(user_id);

ALTER TABLE public.activity_respects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can give respect"
  ON public.activity_respects FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can remove their respect"
  ON public.activity_respects FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Everyone can see respects"
  ON public.activity_respects FOR SELECT
  USING (true);

-- RPC to toggle respect atomically
CREATE OR REPLACE FUNCTION public.toggle_respect(p_activity_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_existed boolean;
BEGIN
  -- Try to delete existing respect
  DELETE FROM activity_respects
  WHERE activity_id = p_activity_id AND user_id = v_user_id;

  v_existed := FOUND;

  IF v_existed THEN
    -- Removed respect: decrement
    UPDATE activity_feed SET respect_count = GREATEST(respect_count - 1, 0)
    WHERE id = p_activity_id;
    RETURN jsonb_build_object('action', 'removed', 'respect_count',
      (SELECT respect_count FROM activity_feed WHERE id = p_activity_id));
  ELSE
    -- Add respect: insert + increment
    INSERT INTO activity_respects (activity_id, user_id) VALUES (p_activity_id, v_user_id);
    UPDATE activity_feed SET respect_count = respect_count + 1
    WHERE id = p_activity_id;
    RETURN jsonb_build_object('action', 'added', 'respect_count',
      (SELECT respect_count FROM activity_feed WHERE id = p_activity_id));
  END IF;
END;
$$;
```

---

### Task 4: Create `user_achievements` table

**Why:** Profile screen has 6 hardcoded achievements with fake unlock states. Need real tracking.

**Step 1: Apply migration**

```sql
-- Achievement definitions (seeded, immutable)
CREATE TABLE public.achievement_definitions (
  id text PRIMARY KEY, -- e.g. 'first_pr', 'streak_7'
  name text NOT NULL,
  description text NOT NULL,
  icon text NOT NULL, -- Icon name for Flutter
  category text NOT NULL CHECK (category IN ('workout', 'streak', 'social', 'nutrition', 'health')),
  criteria jsonb NOT NULL DEFAULT '{}', -- Machine-readable unlock criteria
  sort_order integer NOT NULL DEFAULT 0
);

-- User achievements (unlocked badges)
CREATE TABLE public.user_achievements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id text NOT NULL REFERENCES public.achievement_definitions(id) ON DELETE CASCADE,
  unlocked_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user ON public.user_achievements(user_id);

ALTER TABLE public.achievement_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read achievement definitions"
  ON public.achievement_definitions FOR SELECT
  USING (true);

CREATE POLICY "Users can read their own achievements"
  ON public.user_achievements FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

-- Seed initial achievements
INSERT INTO public.achievement_definitions (id, name, description, icon, category, criteria, sort_order) VALUES
  ('first_pr', 'Premier PR', 'Battre ton premier record personnel', 'emoji_events', 'workout', '{"type": "pr_count", "threshold": 1}', 1),
  ('streak_7', '7j Streak', 'Enchaîner 7 jours consécutifs', 'local_fire_department', 'streak', '{"type": "streak", "threshold": 7}', 2),
  ('streak_30', '30j Streak', 'Enchaîner 30 jours consécutifs', 'whatshot', 'streak', '{"type": "streak", "threshold": 30}', 3),
  ('sessions_10', '10 Séances', 'Compléter 10 séances', 'fitness_center', 'workout', '{"type": "total_sessions", "threshold": 10}', 4),
  ('sessions_50', '50 Séances', 'Compléter 50 séances', 'fitness_center', 'workout', '{"type": "total_sessions", "threshold": 50}', 5),
  ('sessions_100', '100 Séances', 'Compléter 100 séances', 'fitness_center', 'workout', '{"type": "total_sessions", "threshold": 100}', 6),
  ('social_5', '5 Amis', 'Ajouter 5 amis', 'people', 'social', '{"type": "friend_count", "threshold": 5}', 7),
  ('challenge_win', 'Champion', 'Gagner un défi', 'military_tech', 'social', '{"type": "challenge_wins", "threshold": 1}', 8),
  ('volume_1000', 'Tonne de Fer', 'Soulever 1000 kg en une séance', 'iron', 'workout', '{"type": "session_volume", "threshold": 1000}', 9),
  ('nutrition_7', 'Diète 7j', 'Tracker sa nutrition 7 jours de suite', 'restaurant', 'nutrition', '{"type": "nutrition_streak", "threshold": 7}', 10);

-- RPC to check and unlock achievements after a workout
CREATE OR REPLACE FUNCTION public.check_achievements(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile record;
  v_new_achievements text[] := '{}';
  v_def record;
  v_friend_count integer;
BEGIN
  SELECT * INTO v_profile FROM profiles WHERE id = p_user_id;

  FOR v_def IN SELECT * FROM achievement_definitions LOOP
    -- Skip already unlocked
    IF EXISTS (SELECT 1 FROM user_achievements WHERE user_id = p_user_id AND achievement_id = v_def.id) THEN
      CONTINUE;
    END IF;

    -- Check criteria
    CASE v_def.criteria->>'type'
      WHEN 'total_sessions' THEN
        IF v_profile.total_sessions >= (v_def.criteria->>'threshold')::int THEN
          INSERT INTO user_achievements (user_id, achievement_id) VALUES (p_user_id, v_def.id);
          v_new_achievements := array_append(v_new_achievements, v_def.id);
        END IF;
      WHEN 'streak' THEN
        IF v_profile.current_streak >= (v_def.criteria->>'threshold')::int THEN
          INSERT INTO user_achievements (user_id, achievement_id) VALUES (p_user_id, v_def.id);
          v_new_achievements := array_append(v_new_achievements, v_def.id);
        END IF;
      WHEN 'friend_count' THEN
        SELECT count(*) INTO v_friend_count FROM friendships
        WHERE (user_id = p_user_id OR friend_id = p_user_id) AND status = 'accepted';
        IF v_friend_count >= (v_def.criteria->>'threshold')::int THEN
          INSERT INTO user_achievements (user_id, achievement_id) VALUES (p_user_id, v_def.id);
          v_new_achievements := array_append(v_new_achievements, v_def.id);
        END IF;
      ELSE NULL; -- Other criteria checked elsewhere
    END CASE;
  END LOOP;

  RETURN jsonb_build_object('new_achievements', to_jsonb(v_new_achievements));
END;
$$;
```

---

## Phase 2: Coach-Web Backend Connections

### Task 5: Connect events-store to Supabase

**Why:** Calendar page is 100% mock. 5 hardcoded events, no persistence.

**Files:**
- Modify: `coach-web/src/store/events-store.ts`

**Step 1: Rewrite events-store with Supabase integration**

Replace the entire file. Follow the same pattern as `messages-store.ts` (which is the best reference for a real store):
- Import `supabase` from `@/lib/supabase`
- `fetchEvents()` → `supabase.from('calendar_events').select('*').eq('coach_id', coachId).order('date')`
- `addEvent()` → `supabase.from('calendar_events').insert({...}).select().single()`
- `updateEvent()` → `supabase.from('calendar_events').update({...}).eq('id', id)`
- `deleteEvent()` → `supabase.from('calendar_events').delete().eq('id', id)`
- `toggleComplete()` → `supabase.from('calendar_events').update({ completed: !current }).eq('id', id)`
- Remove all mock data
- Add `isLoading` and `error` state

Keep existing interface (`CalendarEvent` type in `types/index.ts`) — just add `coachId` field and map DB columns (`coach_id` → `coachId`, `student_id` → `studentId`).

**Step 2: Update CalendarEvent type in types/index.ts**

Add `coachId` and optional fields that match DB schema:
```typescript
interface CalendarEvent {
  id: string
  coachId: string
  studentId?: string
  title: string
  description?: string
  type: 'workout' | 'check-in' | 'nutrition' | 'note' | 'holiday'
  date: string
  time?: string
  durationMinutes?: number
  completed: boolean
  recurring?: boolean
  recurrenceRule?: string
}
```

**Step 3: Update calendar-page.tsx**

Add `useEffect` to call `fetchEvents()` on mount. The page already reads from `useEventsStore` so the UI should work once the store returns real data.

**Step 4: Build verify**

Run: `cd coach-web && npx vite build`

**Step 5: Commit**

```bash
git add coach-web/src/store/events-store.ts coach-web/src/types/index.ts coach-web/src/pages/calendar/calendar-page.tsx
git commit -m "feat: connect calendar events to Supabase (replace mock data)"
```

---

### Task 6: Connect header notifications to Supabase

**Why:** Header shows 3 hardcoded notifications. Real `notifications` table exists with 0 rows.

**Files:**
- Modify: `coach-web/src/components/layout/header.tsx`

**Step 1: Replace mock notifications with Supabase query**

Replace the mock array (lines 19-24) with a real fetch:
```typescript
const [notifications, setNotifications] = useState<any[]>([])

useEffect(() => {
  const coach = useAuthStore.getState().coach
  if (!coach) return

  const fetchNotifications = async () => {
    const { data } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', coach.id)
      .order('created_at', { ascending: false })
      .limit(10)
    setNotifications(data || [])
  }
  fetchNotifications()

  // Subscribe to realtime notifications
  const channel = supabase
    .channel('coach-notifications')
    .on('postgres_changes', {
      event: 'INSERT',
      schema: 'public',
      table: 'notifications',
      filter: `user_id=eq.${coach.id}`
    }, (payload) => {
      setNotifications(prev => [payload.new as any, ...prev])
    })
    .subscribe()

  return () => { supabase.removeChannel(channel) }
}, [])

const unreadCount = notifications.filter(n => !n.read_at).length
```

**Step 2: Build verify**

Run: `cd coach-web && npx vite build`

**Step 3: Commit**

```bash
git add coach-web/src/components/layout/header.tsx
git commit -m "feat: connect header notifications to Supabase realtime"
```

---

### Task 7: Persist coach settings to Supabase

**Why:** Settings stored in localStorage only — lost on browser clear, don't sync across devices.

**Files:**
- Modify: `coach-web/src/store/settings-store.ts`

**Step 1: Add Supabase sync to settings-store**

Keep the Zustand persist (for fast reads) but add write-through to `coaches` table:
- On `setTheme()`, `setAccentColor()`: also call `supabase.from('coaches').update({ theme, accent_color }).eq('id', coachId)`
- On `setNotification()`: also call `supabase.from('profiles').update({ notifications_enabled }).eq('id', coachId)` for the main toggle
- Add `loadFromDB()` method that fetches coach settings on login
- Call `loadFromDB()` from `auth-store.checkSession()` after successful login

**Step 2: Build verify**

Run: `cd coach-web && npx vite build`

**Step 3: Commit**

```bash
git add coach-web/src/store/settings-store.ts coach-web/src/store/auth-store.ts
git commit -m "feat: persist coach settings to Supabase"
```

---

### Task 8: Real compliance rate + student health data

**Why:** Compliance hardcoded to 85%. Student profile health charts use mock arrays.

**Files:**
- Modify: `coach-web/src/store/students-store.ts` (line 82)
- Modify: `coach-web/src/pages/students/student-profile-page.tsx` (lines 83-90)

**Step 1: Calculate real compliance rate**

In `students-store.ts`, replace `complianceRate: 85` with:
```typescript
// Calculate compliance: sessions this week / expected sessions per week
const thisWeekStart = new Date()
thisWeekStart.setDate(thisWeekStart.getDate() - thisWeekStart.getDay() + 1)
const sessionsThisWeek = sessions.filter(s =>
  new Date(s.completed_at) >= thisWeekStart
).length
const expectedPerWeek = 4 // Could come from program config
const complianceRate = Math.min(100, Math.round((sessionsThisWeek / expectedPerWeek) * 100))
```

**Step 2: Replace mock health data with real query**

In `student-profile-page.tsx`, replace mock arrays with:
```typescript
const [healthData, setHealthData] = useState<any[]>([])

useEffect(() => {
  const fetchHealth = async () => {
    const { data } = await supabase
      .from('health_metrics')
      .select('*')
      .eq('user_id', student.id)
      .gte('date', sevenDaysAgo)
      .order('date')
    setHealthData(data || [])
  }
  fetchHealth()
}, [student.id])

const weeklyProgress = healthData.map(d => d.energy_score || 0)
const weightData = healthData.map(d => d.total_calories || 0) // placeholder until weight tracking
const sleepData = healthData.map(d => (d.sleep_duration_minutes || 0) / 60)
const hrData = healthData.map(d => d.resting_hr || 0)
```

**Step 3: Build verify**

Run: `cd coach-web && npx vite build`

**Step 4: Commit**

```bash
git add coach-web/src/store/students-store.ts coach-web/src/pages/students/student-profile-page.tsx
git commit -m "feat: real compliance rate + health data from Supabase"
```

---

## Phase 3: Flutter Backend Connections

### Task 9: Persist health data to Supabase

**Why:** Health screen reads HealthKit but data is ephemeral. No history, no trends, coach can't see it.

**Files:**
- Modify: `fitgame/lib/core/services/supabase_service.dart`
- Modify: `fitgame/lib/features/health/health_screen.dart`

**Step 1: Add health methods to SupabaseService**

Add these methods to `supabase_service.dart`:
```dart
/// Save daily health metrics to Supabase
Future<void> saveHealthMetrics({
  required String date,
  int? sleepDurationMinutes,
  int? sleepScore,
  int? deepSleepMinutes,
  int? lightSleepMinutes,
  int? remSleepMinutes,
  int? awakeMinutes,
  int? restingHr,
  int? avgHr,
  int? maxHr,
  int? minHr,
  double? hrvMs,
  int? steps,
  int? activeCalories,
  int? totalCalories,
  double? distanceKm,
  int? energyScore,
  String source = 'apple_health',
}) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return;

  await _supabase.from('health_metrics').upsert({
    'user_id': userId,
    'date': date,
    'sleep_duration_minutes': sleepDurationMinutes,
    'sleep_score': sleepScore,
    'deep_sleep_minutes': deepSleepMinutes,
    'light_sleep_minutes': lightSleepMinutes,
    'rem_sleep_minutes': remSleepMinutes,
    'awake_minutes': awakeMinutes,
    'resting_hr': restingHr,
    'avg_hr': avgHr,
    'max_hr': maxHr,
    'min_hr': minHr,
    'hrv_ms': hrvMs,
    'steps': steps,
    'active_calories': activeCalories,
    'total_calories': totalCalories,
    'distance_km': distanceKm,
    'energy_score': energyScore,
    'source': source,
  }, onConflict: 'user_id,date');
}

/// Get health metrics for a date range
Future<List<Map<String, dynamic>>> getHealthMetrics({
  required String startDate,
  required String endDate,
}) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final response = await _supabase
    .from('health_metrics')
    .select()
    .eq('user_id', userId)
    .gte('date', startDate)
    .lte('date', endDate)
    .order('date');
  return List<Map<String, dynamic>>.from(response);
}
```

**Step 2: Call saveHealthMetrics after HealthKit sync**

In `health_screen.dart`, after `_loadHealthData()` successfully fetches from HealthKit, call:
```dart
// After _healthData is set, persist to Supabase
final today = DateTime.now().toIso8601String().substring(0, 10);
await SupabaseService().saveHealthMetrics(
  date: today,
  sleepDurationMinutes: _healthData?.sleep?.totalMinutes,
  deepSleepMinutes: _healthData?.sleep?.deepMinutes,
  lightSleepMinutes: _healthData?.sleep?.lightMinutes,
  remSleepMinutes: _healthData?.sleep?.remMinutes,
  awakeMinutes: _healthData?.sleep?.awakeMinutes,
  restingHr: _healthData?.heart?.restingHeartRate,
  avgHr: _healthData?.heart?.averageHeartRate,
  maxHr: _healthData?.heart?.maxHeartRate,
  minHr: _healthData?.heart?.minHeartRate,
  hrvMs: _healthData?.heart?.hrvMs,
  steps: _healthData?.activity?.steps,
  activeCalories: _healthData?.activity?.activeCaloriesBurned,
  totalCalories: _healthData?.activity?.totalCaloriesBurned,
  distanceKm: _healthData?.activity?.distanceKm,
  energyScore: _calculateEnergyScore(),
);
```

**Step 3: Implement 7-day trends**

Use `getHealthMetrics()` to fetch last 14 days, then calculate:
```dart
final metrics = await SupabaseService().getHealthMetrics(
  startDate: fourteenDaysAgo,
  endDate: today,
);
// Split into this week vs last week, compare averages
```

**Step 4: Verify**

Run: `cd fitgame && flutter analyze`

**Step 5: Commit**

```bash
git add fitgame/lib/core/services/supabase_service.dart fitgame/lib/features/health/health_screen.dart
git commit -m "feat: persist health data to Supabase + 7-day trends"
```

---

### Task 10: Connect home screen widgets to real data

**Why:** Sleep, macros, friend activity, and quick stats widgets all show zeros/empty.

**Files:**
- Modify: `fitgame/lib/features/home/home_screen.dart`
- Modify: `fitgame/lib/features/home/widgets/sleep_summary_widget.dart`
- Modify: `fitgame/lib/features/home/widgets/macro_summary_widget.dart`
- Modify: `fitgame/lib/features/home/widgets/friend_activity_peek.dart`
- Modify: `fitgame/lib/features/home/widgets/quick_stats_row.dart`

**Step 1: Add parameters to child widgets**

Each widget currently uses hardcoded final fields. Convert them to constructor parameters:

`sleep_summary_widget.dart`:
```dart
class SleepSummaryWidget extends StatelessWidget {
  final int totalSleepMinutes;
  final int sleepScore;
  final double deepPercent;
  final double remPercent;

  const SleepSummaryWidget({
    super.key,
    this.totalSleepMinutes = 0,
    this.sleepScore = 0,
    this.deepPercent = 0.0,
    this.remPercent = 0.0,
  });
```

Same pattern for `macro_summary_widget.dart` (currentCalories, targetCalories, protein/carbs/fat percents) and `quick_stats_row.dart` (calories, distance, steps).

**Step 2: Fetch data in home_screen.dart**

Add to `_loadData()`:
```dart
// Fetch today's health metrics
final healthMetrics = await SupabaseService().getHealthMetrics(
  startDate: today,
  endDate: today,
);

// Fetch today's nutrition log
final nutritionLog = await SupabaseService().getNutritionLog(today);

// Fetch recent activity feed (friends)
final activities = await SupabaseService().getActivityFeed();
```

**Step 3: Pass data to widgets**

```dart
SleepSummaryWidget(
  totalSleepMinutes: todayHealth?['sleep_duration_minutes'] ?? 0,
  sleepScore: todayHealth?['sleep_score'] ?? 0,
  deepPercent: /* calculate from minutes */,
  remPercent: /* calculate from minutes */,
),
```

**Step 4: Convert friend_activity_peek to accept data**

```dart
class FriendActivityPeek extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  const FriendActivityPeek({super.key, this.activities = const []});
```

**Step 5: Verify**

Run: `cd fitgame && flutter analyze`

**Step 6: Commit**

```bash
git add fitgame/lib/features/home/
git commit -m "feat: connect home screen widgets to real Supabase data"
```

---

### Task 11: Connect social respect system to Supabase

**Why:** Respect (likes) on activities are never persisted. Count resets on reload.

**Files:**
- Modify: `fitgame/lib/core/services/supabase_service.dart`
- Modify: `fitgame/lib/features/social/social_screen.dart`

**Step 1: Add respect methods to SupabaseService**

```dart
/// Toggle respect on an activity (like/unlike)
Future<Map<String, dynamic>> toggleRespect(String activityId) async {
  final response = await _supabase.rpc('toggle_respect', params: {
    'p_activity_id': activityId,
  });
  return Map<String, dynamic>.from(response);
}

/// Check if current user has given respect to activities
Future<Set<String>> getMyRespects(List<String> activityIds) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return {};

  final response = await _supabase
    .from('activity_respects')
    .select('activity_id')
    .eq('user_id', userId)
    .inFilter('activity_id', activityIds);

  return Set<String>.from(
    (response as List).map((r) => r['activity_id'] as String)
  );
}
```

**Step 2: Update social_screen.dart**

In `_loadData()`, after fetching activity feed:
```dart
// Fetch which activities I've respected
final activityIds = activities.map((a) => a['id'] as String).toList();
final myRespects = await SupabaseService().getMyRespects(activityIds);

// Map activities with respect info
for (final activity in activities) {
  activity['hasGivenRespect'] = myRespects.contains(activity['id']);
  activity['respectCount'] = activity['respect_count'] ?? 0;
}
```

On tap respect:
```dart
final result = await SupabaseService().toggleRespect(activityId);
setState(() {
  // Update local state with server response
});
```

**Step 3: Verify**

Run: `cd fitgame && flutter analyze`

**Step 4: Commit**

```bash
git add fitgame/lib/core/services/supabase_service.dart fitgame/lib/features/social/social_screen.dart
git commit -m "feat: persist social respect system to Supabase"
```

---

### Task 12: Replace hardcoded achievements with real data

**Why:** Profile screen shows 6 fake achievements. Real `user_achievements` table now exists.

**Files:**
- Modify: `fitgame/lib/core/services/supabase_service.dart`
- Modify: `fitgame/lib/features/profile/profile_screen.dart`

**Step 1: Add achievement methods to SupabaseService**

```dart
/// Get all achievement definitions with user's unlock status
Future<List<Map<String, dynamic>>> getAchievements() async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final definitions = await _supabase
    .from('achievement_definitions')
    .select()
    .order('sort_order');

  final unlocked = await _supabase
    .from('user_achievements')
    .select('achievement_id, unlocked_at')
    .eq('user_id', userId);

  final unlockedMap = {
    for (final u in unlocked) u['achievement_id']: u['unlocked_at']
  };

  return (definitions as List).map((def) {
    return {
      ...Map<String, dynamic>.from(def),
      'unlocked': unlockedMap.containsKey(def['id']),
      'unlocked_at': unlockedMap[def['id']],
    };
  }).toList();
}

/// Check and unlock achievements after an action
Future<List<String>> checkAchievements() async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final result = await _supabase.rpc('check_achievements', params: {
    'p_user_id': userId,
  });

  final newAchievements = List<String>.from(result['new_achievements'] ?? []);
  return newAchievements;
}
```

**Step 2: Replace hardcoded list in profile_screen.dart**

Remove the hardcoded `_achievements` list (lines 45-82). Instead:
```dart
List<Map<String, dynamic>> _achievements = [];

Future<void> _loadAchievements() async {
  final achievements = await SupabaseService().getAchievements();
  if (mounted) {
    setState(() => _achievements = achievements);
  }
}
```

Map the icon names from DB to Flutter Icons:
```dart
IconData _getIcon(String iconName) {
  switch (iconName) {
    case 'emoji_events': return Icons.emoji_events_rounded;
    case 'local_fire_department': return Icons.local_fire_department_rounded;
    case 'fitness_center': return Icons.fitness_center_rounded;
    case 'people': return Icons.people_rounded;
    case 'military_tech': return Icons.military_tech_rounded;
    case 'restaurant': return Icons.restaurant_rounded;
    default: return Icons.star_rounded;
  }
}
```

**Step 3: Call check_achievements after workout completion**

In `active_workout_screen.dart`, after `completeWorkoutSession()`:
```dart
final newAchievements = await SupabaseService().checkAchievements();
if (newAchievements.isNotEmpty) {
  // Show achievement unlock notification
}
```

**Step 4: Verify**

Run: `cd fitgame && flutter analyze`

**Step 5: Commit**

```bash
git add fitgame/lib/core/services/supabase_service.dart fitgame/lib/features/profile/profile_screen.dart fitgame/lib/features/workout/tracking/active_workout_screen.dart
git commit -m "feat: real achievements system from Supabase"
```

---

## Phase 4: Final Polish

### Task 13: Update CHANGELOG + docs

**Files:**
- Modify: `fitgame/docs/CHANGELOG.md`
- Modify: `docs/BACKEND_PLAN.md`

**Step 1: Add changelog entry**

```markdown
## 2026-02-06 - Real Backend Connections

### Database
- Created `calendar_events` table for coach calendar
- Created `health_metrics` table for health data persistence
- Created `activity_respects` table for social likes
- Created `achievement_definitions` + `user_achievements` tables
- Added `respect_count` column to `activity_feed`
- Added `toggle_respect()` and `check_achievements()` RPC functions

### Coach-Web
- Connected events-store to Supabase (replaced 100% mock calendar)
- Connected header notifications to Supabase Realtime
- Persisted coach settings to coaches table
- Calculated real compliance rate from workout sessions
- Connected student health charts to health_metrics table

### Flutter
- Persisted health data to Supabase after HealthKit sync
- Implemented 7-day health trends
- Connected home screen widgets (sleep, macros, friends, stats)
- Implemented social respect persistence
- Replaced hardcoded achievements with real system
```

**Step 2: Update BACKEND_PLAN.md**

Mark Phase 5 as complete. Add Phase 6 for future work (mobile messaging, avatar upload, exercise catalog DB).

**Step 3: Commit**

```bash
git add fitgame/docs/CHANGELOG.md docs/BACKEND_PLAN.md
git commit -m "docs: update CHANGELOG and backend plan for real backend connections"
```

---

## Summary

| # | Task | Platform | Impact |
|---|------|----------|--------|
| 1 | `calendar_events` table | DB | Enables coach calendar |
| 2 | `health_metrics` table | DB | Enables health persistence |
| 3 | `activity_respects` table | DB | Enables social likes |
| 4 | `user_achievements` tables | DB | Enables real badges |
| 5 | events-store → Supabase | React | Replaces 100% mock calendar |
| 6 | Header notifications → Supabase | React | Replaces mock notifications |
| 7 | Settings → Supabase | React | Cross-device sync |
| 8 | Compliance + health charts | React | Real student data |
| 9 | Health persistence | Flutter | HealthKit → Supabase |
| 10 | Home screen widgets | Flutter | Sleep/macros/friends real |
| 11 | Social respect system | Flutter | Likes persist |
| 12 | Achievements system | Flutter | Real badges |
| 13 | Docs update | Both | CHANGELOG + backend plan |

**Estimated tasks:** 13 tasks, ~4 DB migrations + 5 React files + 5 Flutter files + docs

**Not in scope (future):**
- Mobile messaging UI (needs new Flutter screen)
- Exercise catalog in DB (works fine hardcoded for now)
- Avatar upload to Supabase Storage
- Food/supplement catalog in DB (works fine hardcoded)
- VO2 Max tracking (HealthKit limitation)
- Online presence (Supabase Realtime Presence)
