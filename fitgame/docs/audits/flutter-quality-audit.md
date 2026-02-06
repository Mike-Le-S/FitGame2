# Flutter/Dart Code Quality Audit

**Date:** 2026-02-06
**Scope:** `fitgame/lib/` (~100+ Dart files)
**Auditor:** Claude Opus 4.6

---

## Executive Summary

The FitGame2 Flutter application is a well-designed fitness tracking app with a polished dark-mode glassmorphism UI. The design system (FGColors, FGTypography, Spacing, FGEffects) is consistent and well-structured. However, the codebase suffers from **significant architectural debt** that will increasingly impede development velocity and introduce bugs as features scale.

**Top concerns:**

1. **God-class anti-patterns** -- NutritionScreen (2089 lines), WorkoutScreen (1817 lines), HealthScreen (1450 lines), ProfileScreen (1263 lines), and SupabaseService (1399 lines) are far too large and violate single-responsibility principle.
2. **No state management** -- Pure `setState()` throughout the entire app. No Provider, Riverpod, Bloc, or similar. This causes tight coupling between UI and business logic.
3. **Duplicated code** -- Mesh gradient backgrounds, navigation transitions, snackbar patterns, and bottom sheet handles are copy-pasted across dozens of files.
4. **Race conditions** -- Read-then-write increment operations in SupabaseService create data corruption risks under concurrent access.
5. **Hardcoded data** -- Food library, achievements, macro presets, OAuth client IDs, and default calories are embedded in source code rather than externalized.

**Overall quality grade: C+** -- Functional and visually polished, but architecturally fragile.

---

## Architecture Assessment

### Strengths

- Clean feature-based folder structure (`features/{name}/screen.dart`, `widgets/`, `sheets/`, `painters/`, `models/`)
- Consistent design system with well-named constants and abstract utility classes
- Proper `const` constructors in shared widgets (FGGlassCard, FGNeonButton)
- Immutable model pattern used correctly in social models (Activity, Challenge, Friend) and diet models (FoodEntry, MealPlan)
- Good use of `mounted` checks after async operations in most screens
- Draft persistence in NewPlanCreationFlow using SharedPreferences
- Good widget extraction in ActiveWorkoutScreen (WorkoutHeader, StatsBar, SetCard, etc.)

### Weaknesses

- No dependency injection -- SupabaseService is accessed as static calls everywhere
- No repository/service abstraction layer between UI and data
- Business logic embedded in StatefulWidget `_State` classes
- No routing framework (manual `Navigator.push` with inline `PageRouteBuilder`)
- No error boundary or global error handling strategy
- No analytics or crash reporting integration
- Mixed language in comments and strings (French UI, English code)

---

## Critical Issues

### QF-001: Race Conditions in Database Increment Operations

**Severity:** CRITICAL
**Files:**
- `/Users/mike/projects/FitGame2/fitgame/lib/core/services/supabase_service.dart` (lines 816-835, 946-963)

Two methods use a non-atomic read-then-write pattern that creates race conditions under concurrent access:

```dart
// Line 816-835: updateFavoriteFoodUsage
static Future<void> updateFavoriteFoodUsage(String id) async {
  final current = await client
      .from('user_favorite_foods')
      .select('use_count')
      .eq('id', id)
      .single();

  await client
      .from('user_favorite_foods')
      .update({'use_count': (current['use_count'] as int) + 1, ...})
      .eq('id', id);
}
```

```dart
// Line 946-963: incrementCommunityFoodUseCount
static Future<void> incrementCommunityFoodUseCount(String id) async {
  final current = await client
      .from('community_foods')
      .select('use_count')
      .eq('id', id)
      .single();

  await client
      .from('community_foods')
      .update({'use_count': (current['use_count'] as int) + 1})
      .eq('id', id);
}
```

**Impact:** If two users increment simultaneously, one increment is lost. Community foods are shared, so this is a real concurrency scenario.

**Remediation:** Use a Postgres RPC function with `UPDATE ... SET use_count = use_count + 1` or Supabase's `.rpc()` for atomic increment. The `increment_total_sessions` RPC at line 368 proves this pattern already exists in the codebase.

---

### QF-002: Hardcoded OAuth Client IDs in Source Code

**Severity:** CRITICAL
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/core/services/supabase_service.dart` (lines 89-91)

```dart
const iosClientId = '241707453312-24n1s72q44oughb28s7fjhiaehgop7ss.apps.googleusercontent.com';
const webClientId = '241707453312-bcdt4drl7bi0t10pga3g83f9bp123384.apps.googleusercontent.com';
```

**Impact:** OAuth client IDs are committed to version history and cannot be rotated without a code change and redeployment.

**Remediation:** Move to environment variables via `--dart-define` or `flutter_dotenv`, consistent with how the Supabase URL and anon key are handled.

---

### QF-003: Error Swallowing in Critical Workout Path

**Severity:** CRITICAL
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/core/services/supabase_service.dart` (lines 366-377)

```dart
await client.rpc('increment_total_sessions', params: {
  'user_id': currentUser!.id,
}).catchError((_) {
  // Fallback: update directly
  client
      .from('profiles')
      .update({'total_sessions': client.rpc('get_total_sessions')})
      .eq('id', currentUser!.id);
});
```

**Impact:** The fallback query `client.rpc('get_total_sessions')` is passed as a `Future` object (not its resolved value) to the update call, resulting in a malformed query that silently fails. The user's session count is never incremented. Additionally, the fallback `.catchError` swallows any error from the RPC without logging.

**Remediation:** Await the RPC result in the fallback, add proper error logging, or simply rely on the atomic RPC and surface errors to the user.

---

## High Priority Issues

### QF-004: God-Class SupabaseService (1399 lines, all static)

**Severity:** HIGH
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/core/services/supabase_service.dart`

A single class with ~80 static methods covering: authentication, profile management, program CRUD, workout sessions, diet plans, day types, weekly schedules, nutrition logs, favorite foods, meal templates, community foods, coach-student assignments, realtime subscriptions, social feed, friends, activity, notifications, and challenges.

**Impact:**
- Impossible to unit test (no dependency injection, no interfaces)
- Impossible to mock for widget tests
- High cognitive load -- any developer must scan 1400 lines to find a method
- No separation of concerns -- mixing auth, CRUD, realtime, and social logic

**Remediation:** Split into domain-specific repositories:
- `AuthRepository` -- sign in/out, auth state
- `WorkoutRepository` -- programs, sessions
- `NutritionRepository` -- diet plans, foods, templates
- `SocialRepository` -- friends, activity, challenges
- `ProfileRepository` -- profile CRUD
- Inject via Provider/Riverpod for testability

---

### QF-005: God-Class NutritionScreen (2089 lines)

**Severity:** HIGH
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/nutrition_screen.dart`

Single StatefulWidget handling: weekly meal planning, day type management, food CRUD, tracking logs, health data integration, plan management, barcode scanning, template management, sharing, and AI generation.

**Impact:** Maintenance nightmare, impossible to test individual features, slow rebuild cycles.

**Remediation:** Extract into:
- `NutritionController` or `NutritionNotifier` (business logic)
- Separate widgets for each section (already partially done with `MealCard`, `MacroDashboard`)
- Move data loading to a repository layer

---

### QF-006: God-Class WorkoutScreen (1817 lines)

**Severity:** HIGH
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/workout/workout_screen.dart`

Same pattern as NutritionScreen -- full dashboard, program sheet, session cards, empty state, program management, all in one file.

**Impact:** Same as QF-005.

---

### QF-007: No State Management Solution

**Severity:** HIGH
**Files:** All screen files

Every screen uses `setState()` for all state changes. No Provider, Riverpod, Bloc, Cubit, or GetX.

**Impact:**
- Business logic is tightly coupled to widgets
- State cannot be shared between screens without passing callbacks
- No reactive data flow -- changes in one screen don't propagate to others
- Testing requires widget tests for everything (no unit tests for logic)

**Remediation:** Adopt Riverpod (recommended for this codebase size). Migrate incrementally, starting with SupabaseService decomposition.

---

### QF-008: Mutable Core Model (WorkoutSet)

**Severity:** HIGH
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/core/models/workout_set.dart`

```dart
class WorkoutSet {
  final double targetWeight;
  final int targetReps;
  final bool isWarmup;
  double actualWeight;  // MUTABLE
  int actualReps;       // MUTABLE
  bool isCompleted;     // MUTABLE

  WorkoutSet({...});
}
```

**Impact:** Mutable models break `setState` change detection, make debugging difficult, and prevent using `const` constructors. Changes to mutable fields don't trigger rebuilds unless explicitly wrapped in `setState`.

**Remediation:** Make all fields final, add `copyWith()` method, use immutable pattern consistent with `FoodEntry` and `MealPlan` in `diet_models.dart`.

---

### QF-009: Duplicated Mesh Gradient Code Across 7+ Files

**Severity:** HIGH
**Files:**
- `/Users/mike/projects/FitGame2/fitgame/lib/features/home/home_screen.dart`
- `/Users/mike/projects/FitGame2/fitgame/lib/features/workout/workout_screen.dart`
- `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/nutrition_screen.dart`
- `/Users/mike/projects/FitGame2/fitgame/lib/features/health/health_screen.dart`
- `/Users/mike/projects/FitGame2/fitgame/lib/features/social/social_screen.dart`
- `/Users/mike/projects/FitGame2/fitgame/lib/features/profile/profile_screen.dart`
- `/Users/mike/projects/FitGame2/fitgame/lib/features/workout/tracking/active_workout_screen.dart`
- `/Users/mike/projects/FitGame2/fitgame/lib/features/workout/create/program_creation_flow.dart`

Each file has its own `_buildMeshGradient()` method with slight variations (different colors, positions). This is 30-50 lines of nearly identical code duplicated 8+ times.

**Remediation:** Create a shared `FGMeshGradient` widget in `shared/widgets/` with configurable color parameters.

---

## Medium Priority Issues

### QF-010: IndexedStack with Getter Recreates Widgets on Every Build

**Severity:** MEDIUM
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/main.dart`

```dart
List<Widget> get _screens => [
  HomeScreen(onNavigateToTab: _navigateToTab),
  const WorkoutScreen(),
  const SocialScreen(),
  NutritionScreen(key: _nutritionScreenKey),
  const HealthScreen(),
  const ProfileScreen(),
];
```

**Impact:** The `_screens` getter creates a new List on every access. When used with `IndexedStack`, this means all 6 screen widgets are recreated on every build cycle, defeating IndexedStack's purpose of preserving state.

**Remediation:** Cache the list in a `late final` field initialized in `initState()`, or use a `final` list declaration.

---

### QF-011: Hardcoded Food Library in FoodLibrarySheet

**Severity:** MEDIUM
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/sheets/food_library_sheet.dart` (lines 148-159)

```dart
final List<Map<String, dynamic>> _foods = <Map<String, dynamic>>[
  {'name': 'Poulet grille', 'category': 'Proteines', 'cal': 165, 'p': 31, 'c': 0, 'f': 4, 'unit': '100g'},
  {'name': 'Riz basmati', 'category': 'Glucides', 'cal': 130, 'p': 3, 'c': 28, 'f': 0, 'unit': '100g cuit'},
  // ... 10 hardcoded foods
];
```

**Impact:** Users see only 10 static foods. Food created via the dialog is added to the in-memory list but lost on screen close. No persistence, no Supabase integration.

**Remediation:** Load from Supabase (community_foods table already exists) and combine with user favorites. Cache locally for offline support.

---

### QF-012: Hardcoded Achievements in ProfileScreen

**Severity:** MEDIUM
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/profile/profile_screen.dart` (lines 44-81)

Static list of 6 hardcoded achievements with fixed progress values. No backend integration.

**Impact:** Achievements never update based on user activity. Purely cosmetic.

**Remediation:** Move to backend-driven achievements computed from actual user data.

---

### QF-013: Missing `const` Constructors and Lint Warnings

**Severity:** MEDIUM
**Files:** Multiple

Several instances where `const` could be used but isn't:

- `TextStyle()` instances in `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/sheets/food_library_sheet.dart` (lines 393-415) -- `TextStyle` without `const`
- `Icon()` widgets missing `const` in multiple widget files
- `BoxDecoration` in `app_theme.dart` missing `const` on `BorderSide`

**Remediation:** Run `flutter analyze` and fix all `prefer_const_constructors` and `prefer_const_literals_to_create_immutables` warnings.

---

### QF-014: Duplicated Navigation Transition Code

**Severity:** MEDIUM
**Files:**
- `/Users/mike/projects/FitGame2/fitgame/lib/features/home/widgets/today_workout_card.dart` (lines 28-46)
- `/Users/mike/projects/FitGame2/fitgame/lib/features/workout/workout_screen.dart` (5+ occurrences)
- `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/nutrition_screen.dart`

The slide-up page transition pattern is duplicated verbatim across many files:

```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const TargetScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  ),
);
```

**Remediation:** Create a helper function or custom `PageRoute` class in `shared/` (e.g., `FGSlideUpRoute<T>`).

---

### QF-015: FGEffects Getters Create New Objects on Every Call

**Severity:** MEDIUM
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/core/theme/fg_effects.dart`

```dart
static List<BoxShadow> get neonGlow => [
  BoxShadow(
    color: FGColors.accent.withValues(alpha: 0.6),
    blurRadius: 20,
    spreadRadius: 0,
  ),
];
```

**Impact:** Each call creates new `BoxShadow` and `List` objects. Used in hot paths like animated buttons (e.g., _buildValidateButton in ActiveWorkoutScreen which rebuilds 60fps during pulse animation).

**Remediation:** Use `static final` instead of `static get` for constant shadow/effect lists.

---

### QF-016: _initializeExercisesForDays Called in build()

**Severity:** MEDIUM
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/workout/create/program_creation_flow.dart` (line 320)

```dart
@override
Widget build(BuildContext context) {
  if (_currentStep == 3) {
    _initializeExercisesForDays(); // Side effect in build!
  }
  ...
}
```

**Impact:** `build()` should be pure. This method has side effects (modifying state maps). It's called on every rebuild when step is 3, though `putIfAbsent` makes it idempotent in practice.

**Remediation:** Move to `_nextStep()` when transitioning to step 3, or use a flag to ensure single execution.

---

### QF-017: Untyped Map Data Throughout the Codebase

**Severity:** MEDIUM
**Files:** Nearly all files that handle data

Extensive use of `Map<String, dynamic>` for structured data instead of typed model classes:

- Meal data in MealCard: `widget.meal['foods'] as List`, `food['cal'] as int`
- Exercise data in ProgramCreationFlow: `_exercisesByDay[day]?[index]['mode']`
- Day types in NewPlanCreationFlow: `dayType['emoji'] as String? ?? '...'`

**Impact:** No compile-time safety, runtime cast exceptions possible, autocomplete doesn't work, refactoring is error-prone.

**Remediation:** Create typed model classes for meals, exercises, day types. The social models (Activity, Challenge, Friend) demonstrate the correct pattern.

---

### QF-018: TextEditingController Leak in FoodLibrarySheet Dialog

**Severity:** MEDIUM
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/sheets/food_library_sheet.dart` (lines 26-30)

```dart
void _showCreateFoodDialog(BuildContext context) {
  final nameController = TextEditingController();
  final calController = TextEditingController();
  final proteinController = TextEditingController();
  final carbsController = TextEditingController();
  final fatController = TextEditingController();
  // ... never disposed
}
```

**Impact:** 5 TextEditingControllers are created but never disposed. Minor memory leak per dialog invocation.

**Remediation:** Dispose controllers when the dialog closes, or use a StatefulWidget for the dialog content.

---

## Low Priority Issues

### QF-019: debugPrint Used for Error Logging

**Severity:** LOW
**Files:** Throughout `supabase_service.dart` and screen files

All error handling uses `debugPrint('Error: $e')` with no structured logging, no crash reporting, no log levels.

**Impact:** Errors in production are invisible. No ability to diagnose issues from user reports.

**Remediation:** Integrate a logging framework (e.g., `logger` package) and crash reporting (Sentry, Firebase Crashlytics).

---

### QF-020: FoodLibrarySheet State Class is Public

**Severity:** LOW
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/sheets/food_library_sheet.dart` (line 21)

```dart
class FoodLibrarySheetState extends State<FoodLibrarySheet> {
```

Similarly `EditFoodSheetState` in `edit_food_sheet.dart` (line 24).

**Impact:** State classes should be private (prefixed with `_`) unless they need to be accessed externally via a GlobalKey.

**Remediation:** Rename to `_FoodLibrarySheetState` and `_EditFoodSheetState` unless external access is needed.

---

### QF-021: Missing Equatable/Equality on Core Models

**Severity:** LOW
**Files:**
- `/Users/mike/projects/FitGame2/fitgame/lib/core/models/exercise.dart`
- `/Users/mike/projects/FitGame2/fitgame/lib/core/models/workout_set.dart`

Neither model implements `==` or `hashCode`, and neither extends `Equatable`.

**Impact:** List comparisons, `Set` operations, and state management libraries rely on equality checks.

**Remediation:** Add `Equatable` mixin or manually implement equality.

---

### QF-022: Hardcoded Calorie Values in HealthScreen

**Severity:** LOW
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/health/health_screen.dart`

Hardcoded `caloriesConsumed = 0`, `calorieGoal = 2200`, `vo2Max = 0.0`, and all trend values set to 0.

**Impact:** These are placeholder values for backend integration, but they're not flagged with TODO comments and could be mistaken for intentional defaults.

**Remediation:** Add `// TODO: Replace with real data from backend` comments and consider using a constants file for default values.

---

### QF-023: NewPlanCreationFlow is a 2090-line Single File

**Severity:** LOW
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart`

While better structured than NutritionScreen (uses step builders, has clear sections), this file is still very large at 2090 lines including an embedded `_MacroPieChartPainter`.

**Remediation:** Extract each step builder into its own widget file (like ProgramCreationFlow does with NameStep, CycleStep, DaysStep, ExercisesStep). Extract `_MacroPieChartPainter` to `painters/` directory.

---

### QF-024: Unused Import of dart:math

**Severity:** LOW
**File:** `/Users/mike/projects/FitGame2/fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart` (line 2)

`import 'dart:math';` is imported but only used in the private `_MacroPieChartPainter` class. The import is valid but could be localized.

---

## Hardcoded / Mock Data Inventory

| Location | Data | Status | Backend Ready? |
|----------|------|--------|----------------|
| `supabase_service.dart:89-91` | OAuth client IDs | HARDCODED | No -- should be env vars |
| `food_library_sheet.dart:148-159` | 10 food items | HARDCODED | Yes -- community_foods table exists |
| `profile_screen.dart:44-81` | 6 achievements | HARDCODED | No -- no achievements table |
| `health_screen.dart` | calorieGoal=2200, caloriesConsumed=0 | PLACEHOLDER | Partial -- HealthKit provides some |
| `new_plan_creation_flow.dart:29-41` | Suggestion defaults & macro presets | HARDCODED | Could be user-configurable |
| `nutrition_screen.dart:68-90` | Macro targets (P:30%, C:45%, F:25%) | HARDCODED | Yes -- diet_plans table has macros |
| `nutrition_screen.dart:95-159` | Weekly plan structure (7 empty days) | HARDCODED | Yes -- weekly_schedule table exists |
| `program_creation_flow.dart:131` | Default goal `'bulk'` | HARDCODED | Should be user-selected |
| `active_workout_screen.dart:713` | Calorie estimate multiplier `0.05` | MAGIC NUMBER | Should be configurable |

---

## Performance Concerns

| ID | Issue | Location | Severity |
|----|-------|----------|----------|
| QF-P1 | `_screens` getter recreates 6 widgets per build in IndexedStack | `main.dart` | MEDIUM |
| QF-P2 | `FGEffects.neonGlow` getter allocates new objects on every call, used in 60fps animations | `fg_effects.dart` | MEDIUM |
| QF-P3 | `BackdropFilter` in FGGlassCard is expensive, used extensively | `fg_glass_card.dart` | LOW (acceptable for design) |
| QF-P4 | `AnimatedCrossFade` in MealCard always builds both children | `meal_card.dart` | LOW |
| QF-P5 | `_filteredFoods` getter recomputes on every build | `food_library_sheet.dart` | LOW |
| QF-P6 | WorkoutTimer triggers full `setState` every second | `active_workout_screen.dart:193-197` | LOW (timer screen) |
| QF-P7 | `_calculateDayTypeCalories` iterates all meals for each day type card render | `new_plan_creation_flow.dart` | LOW |

---

## Tech Debt Summary

| Category | Count | Examples |
|----------|-------|---------|
| God classes (>500 lines) | 6 | NutritionScreen, WorkoutScreen, HealthScreen, ProfileScreen, SupabaseService, NewPlanCreationFlow |
| Duplicated code patterns | 3 major | Mesh gradient (8 files), nav transitions (5+ files), snackbar patterns (10+ files) |
| Missing abstractions | 4 | No routing, no state management, no DI, no repository layer |
| Untyped data structures | ~20 | Map<String, dynamic> used for meals, exercises, day types, foods |
| Hardcoded data | 9 | See inventory above |
| Race conditions | 2 | updateFavoriteFoodUsage, incrementCommunityFoodUseCount |
| Memory leaks | 1 | TextEditingControllers in FoodLibrarySheet dialog |

---

## Action Plan

### Phase 1: Critical Fixes (1-2 days)

1. **QF-001** -- Replace read-then-write increments with atomic RPC calls
2. **QF-002** -- Move OAuth client IDs to environment variables
3. **QF-003** -- Fix broken fallback in completeWorkoutSession

### Phase 2: Quick Wins (3-5 days)

4. **QF-010** -- Cache `_screens` list in MainNavigation
5. **QF-015** -- Change `FGEffects` getters to `static final`
6. **QF-009** -- Extract shared `FGMeshGradient` widget
7. **QF-014** -- Create `FGSlideUpRoute` helper
8. **QF-013** -- Run `flutter analyze` and fix all lint warnings
9. **QF-020** -- Make State classes private
10. **QF-016** -- Move `_initializeExercisesForDays` out of `build()`

### Phase 3: Architectural Improvements (2-4 weeks)

11. **QF-004** -- Split SupabaseService into domain repositories
12. **QF-007** -- Introduce Riverpod for state management (start with 1 feature)
13. **QF-017** -- Create typed models for meals, exercises, day types
14. **QF-008** -- Make WorkoutSet immutable with copyWith

### Phase 4: Feature Completion (ongoing)

15. **QF-005/006** -- Decompose NutritionScreen and WorkoutScreen
16. **QF-011** -- Connect food library to Supabase community_foods
17. **QF-012** -- Backend-driven achievements
18. **QF-019** -- Integrate structured logging and crash reporting
19. **QF-023** -- Extract NewPlanCreationFlow steps into separate widgets

---

*This audit covers ~45 files read in detail across 4 phases. Some lower-visibility files (painters, modals, smaller widgets) were not individually reviewed but would benefit from the same architectural improvements described above.*
