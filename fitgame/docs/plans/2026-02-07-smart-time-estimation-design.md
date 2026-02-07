# Smart Time Estimation — Design Document

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add intelligent remaining time estimation during workouts, with transition tracking, live adjustment, and detailed time breakdown on the completion screen.

**Architecture:** Track 3 time categories (set execution, rest, transition) per set/exercise. Estimate remaining time using historical averages with in-session refinement. Display estimate in session insights card, alert gently on long transitions, show full time breakdown on workout complete screen.

**Tech Stack:** Flutter, Supabase (JSONB storage in existing sessions table)

---

## 1. Data Model

### New fields on `WorkoutSet` (in-memory model)

```dart
class WorkoutSet {
  // Existing fields...
  int? actualDurationSeconds;  // Time from set becoming active to validation tap
  int? actualRestSeconds;      // Actual rest taken (including +30s extensions)
}
```

### New fields on `Exercise` (in-memory model)

```dart
class Exercise {
  // Existing fields...
  int? transitionSeconds;  // Time between last set of prev exercise and first set of this one, minus rest
}
```

### New class: `TimeStats`

```dart
class TimeStats {
  final int totalDuration;        // Total workout seconds
  final int tensionTime;          // Σ actualDurationSeconds (all sets)
  final int totalRestTime;        // Σ actualRestSeconds (all sets)
  final int totalTransitionTime;  // Σ transitionSeconds (all exercises)
  final double avgTransition;     // Average transition seconds
  final double efficiencyScore;   // tensionTime / totalDuration × 100
}
```

### Supabase storage

When saving session to Supabase, each set in the JSON gets:
```json
{
  "actualWeight": 80,
  "actualReps": 10,
  "actualDurationSeconds": 35,
  "actualRestSeconds": 95
}
```

Each exercise gets:
```json
{
  "name": "Bench Press",
  "transitionSeconds": 72
}
```

This data feeds the historical averages for future sessions.

---

## 2. Time Tracking Logic (in active_workout_screen.dart)

### New state variables

```dart
DateTime? _currentSetStartTime;       // When current set became active
DateTime? _lastExerciseEndTime;       // When last exercise's final set was validated
DateTime? _currentRestStartTime;      // When rest timer started
bool _isInTransition = false;         // True between exercises (after rest ends)
```

### Set duration tracking

- When a set becomes the active set (either on screen load, after rest ends, or after exercise change): `_currentSetStartTime = DateTime.now()`
- When `_validateSet()` is called: `currentSet.actualDurationSeconds = DateTime.now().difference(_currentSetStartTime!).inSeconds`

### Rest duration tracking

- In `_startRestTimer()`: `_currentRestStartTime = DateTime.now()`
- When rest ends (timer reaches 0) or skip: `currentSet.actualRestSeconds = DateTime.now().difference(_currentRestStartTime!).inSeconds`
- Also capture on skip rest

### Transition tracking

- When `_validateSet()` processes the **last set of an exercise**: `_lastExerciseEndTime = DateTime.now()`
- When `_validateSet()` processes the **first set of the next exercise**:
  ```dart
  transitionBrute = now - _lastExerciseEndTime
  transitionNette = transitionBrute - actualRestSeconds (of the rest between exercises)
  nextExercise.transitionSeconds = transitionNette
  ```

---

## 3. Estimation Algorithm

### `_calculateEstimatedRemainingSeconds()` → int

```
remaining = 0

For each remaining set (not completed, not warmup for simplicity):
  setTime = historicalAvg(exercise) ?? sessionAvg(exercise) ?? (3 * targetReps + 5)
  restTime = exercise.restSeconds (configured)
  remaining += setTime + restTime

For each remaining exercise transition:
  transitionTime = lastMeasuredTransition ?? sessionAvgTransition ?? 60
  remaining += transitionTime

// Don't count rest after the very last set
remaining -= lastSetRest
```

### Historical averages

- On `_loadLastSessionData()`, also extract `actualDurationSeconds` per set → store in `_lastSessionAvgSetDuration[exerciseName]`
- Fallback chain: historical avg → current session avg → formula (3s/rep + 5s)

### Live refinement

- After each `_validateSet()`, recalculate. The estimate improves as more real data comes in.
- The time NEVER goes below 0. If real time exceeds estimate, remaining shows 0 or adjusts upward.

---

## 4. UI: Time Estimate in Session Insights Card

### Placement

Between the progress bar and the "next exercise" row:

```
[Volume | Séries | Exos Restants]
[========== progress bar =========]
⏱ ~25 min restantes                    ← NEW
[▶ Next: Bench Press  4×10]
```

### Formatting

- `>= 60 min`: "~1h 05 restantes"
- `>= 1 min`: "~25 min restantes"
- `< 1 min`: "< 1 min"
- Color: `FGColors.textSecondary` normally, `FGColors.success` when < 5 min

### Transition alert (alerte douce)

When user is on first set of a new exercise AND time since `_lastExerciseEndTime` exceeds `restSeconds + 90s`:
- Time estimate text turns `FGColors.warning` (orange)
- Small ⚡ icon appears before the timer icon
- Reverts to normal once the set is validated

---

## 5. UI: Workout Complete Screen — Time Breakdown

### New section below existing stats

```
┌──────────────────────────────────┐
│  RÉPARTITION DU TEMPS            │
│                                  │
│  ████████░░░░░░░  (stacked bar)  │
│  🟠 Exercice  ⬜ Repos  ⚫ Transit│
│                                  │
│  Sous tension    12min 30s       │
│  Repos total     18min 00s       │
│  Transitions     4min 20s (moy 52s) │
│                                  │
│  Score efficacité: 36%  ⚡       │
│  (temps sous tension / total)    │
└──────────────────────────────────┘
```

### Stacked bar

- 3 segments: accent (exercise), glassBorder (rest), warning (transition)
- Proportional to actual time spent
- Height: 8px, rounded corners

### Efficiency score colors

- `> 35%`: FGColors.success (green)
- `20-35%`: FGColors.warning (orange)
- `< 20%`: FGColors.error (red)

### Data passed to WorkoutCompleteSheet

```dart
WorkoutCompleteSheet(
  duration: _workoutSeconds,
  totalVolume: _totalVolume,
  exerciseCount: _exercises.length,
  timeStats: TimeStats(...),  // NEW
)
```

---

## 6. Files to Modify

| File | Changes |
|------|---------|
| `lib/core/models/workout_set.dart` | Add `actualDurationSeconds`, `actualRestSeconds` fields |
| `lib/core/models/exercise.dart` | Add `transitionSeconds` field |
| `lib/core/models/time_stats.dart` | **NEW** — TimeStats class |
| `lib/features/workout/tracking/active_workout_screen.dart` | Time tracking state, estimation logic, insights card update, transition alert |
| `lib/features/workout/tracking/sheets/workout_complete_sheet.dart` | Time breakdown section with stacked bar + efficiency score |

---

## 7. What We're NOT Doing (YAGNI)

- No per-exercise time goals or targets
- No push notifications for long transitions
- No comparison with other users
- No weekly/monthly time analytics (future)
- No modification of rest timer behavior
- No separate transition timer UI
