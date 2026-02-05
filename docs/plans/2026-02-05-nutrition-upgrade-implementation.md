# Nutrition Screen Upgrade - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade the Nutrition screen with calorie balance tracking, plan vs daily tracking separation, and quick food adding (scanner, favorites, templates).

**Architecture:**
- 4 new Supabase tables for tracking, favorites, templates, and community foods
- New `CalorieBalanceCard` widget showing consumed vs burned calories from Apple Health
- Separate daily logs from plan templates - edits go to logs, plans stay intact
- New food adding flow with barcode scanner, favorites, and meal templates

**Tech Stack:** Flutter, Supabase, Apple HealthKit, OpenFoodFacts API, mobile_scanner

---

## Phase 1: Database & Dependencies

### Task 1: Add mobile_scanner dependency

**Files:**
- Modify: `fitgame/pubspec.yaml:30-57`

**Step 1: Add the dependency**

In `pubspec.yaml`, add under dependencies (after `google_mlkit_text_recognition`):

```yaml
  # Barcode scanner
  mobile_scanner: ^5.1.1
```

**Step 2: Install dependencies**

Run: `cd fitgame && flutter pub get`
Expected: Dependencies resolved successfully

**Step 3: Commit**

```bash
git add fitgame/pubspec.yaml fitgame/pubspec.lock
git commit -m "chore: add mobile_scanner dependency for barcode scanning"
```

---

### Task 2: Create Supabase migration for new tables

**Files:**
- Create: `fitgame/supabase/migrations/20260205_nutrition_upgrade.sql`

**Step 1: Create migration file**

Create the directory if needed: `mkdir -p fitgame/supabase/migrations`

Create file with content:

```sql
-- ============================================
-- Nutrition Upgrade Migration
-- ============================================

-- 1. Daily nutrition logs (tracking what user actually ate)
CREATE TABLE IF NOT EXISTS daily_nutrition_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  date DATE NOT NULL,
  diet_plan_id UUID REFERENCES diet_plans ON DELETE SET NULL,
  meals JSONB NOT NULL DEFAULT '[]',
  calories_consumed INT DEFAULT 0,
  calories_burned INT,
  calories_burned_predicted INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- 2. User favorite foods
CREATE TABLE IF NOT EXISTS user_favorite_foods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  food_data JSONB NOT NULL,
  use_count INT DEFAULT 1,
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Meal templates (saved meals for quick adding)
CREATE TABLE IF NOT EXISTS meal_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  name VARCHAR(100) NOT NULL,
  foods JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Community foods (crowdsourced nutrition data)
CREATE TABLE IF NOT EXISTS community_foods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  barcode VARCHAR(50) UNIQUE,
  name VARCHAR(200) NOT NULL,
  brand VARCHAR(100),
  nutrition_per_100g JSONB NOT NULL,
  image_url TEXT,
  contributed_by UUID REFERENCES auth.users,
  verified BOOLEAN DEFAULT FALSE,
  use_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Row Level Security
-- ============================================

ALTER TABLE daily_nutrition_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorite_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_foods ENABLE ROW LEVEL SECURITY;

-- Daily nutrition logs: users access own data only
CREATE POLICY "Users can select own nutrition logs" ON daily_nutrition_logs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own nutrition logs" ON daily_nutrition_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own nutrition logs" ON daily_nutrition_logs
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own nutrition logs" ON daily_nutrition_logs
  FOR DELETE USING (auth.uid() = user_id);

-- Favorite foods: users access own data only
CREATE POLICY "Users can select own favorite foods" ON user_favorite_foods
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own favorite foods" ON user_favorite_foods
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own favorite foods" ON user_favorite_foods
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own favorite foods" ON user_favorite_foods
  FOR DELETE USING (auth.uid() = user_id);

-- Meal templates: users access own data only
CREATE POLICY "Users can select own meal templates" ON meal_templates
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own meal templates" ON meal_templates
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own meal templates" ON meal_templates
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own meal templates" ON meal_templates
  FOR DELETE USING (auth.uid() = user_id);

-- Community foods: everyone reads, authenticated users insert
CREATE POLICY "Anyone can read community foods" ON community_foods
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert community foods" ON community_foods
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Contributors can update own community foods" ON community_foods
  FOR UPDATE USING (auth.uid() = contributed_by);

-- ============================================
-- Indexes for performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_daily_nutrition_logs_user_date
  ON daily_nutrition_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_user_favorite_foods_user
  ON user_favorite_foods(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_templates_user
  ON meal_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_community_foods_barcode
  ON community_foods(barcode);
```

**Step 2: Commit migration file**

```bash
git add fitgame/supabase/migrations/20260205_nutrition_upgrade.sql
git commit -m "feat: add Supabase migration for nutrition upgrade tables"
```

**Step 3: Apply migration to Supabase**

Go to Supabase dashboard → SQL Editor → Paste and run the migration.

---

### Task 3: Add Supabase service methods for new tables

**Files:**
- Modify: `fitgame/lib/core/services/supabase_service.dart`

**Step 1: Add Daily Nutrition Logs methods**

Add after the Diet Plans section (around line 529):

```dart
  // ============================================
  // Daily Nutrition Logs (Tracking)
  // ============================================

  /// Get nutrition log for a specific date
  static Future<Map<String, dynamic>?> getNutritionLog(DateTime date) async {
    if (currentUser == null) return null;

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await client
          .from('daily_nutrition_logs')
          .select()
          .eq('user_id', currentUser!.id)
          .eq('date', dateStr)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching nutrition log: $e');
      return null;
    }
  }

  /// Create or update nutrition log for a date
  static Future<Map<String, dynamic>> upsertNutritionLog({
    required DateTime date,
    String? dietPlanId,
    required List<Map<String, dynamic>> meals,
    required int caloriesConsumed,
    int? caloriesBurned,
    int? caloriesBurnedPredicted,
  }) async {
    if (currentUser == null) throw Exception('Non authentifié');

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('daily_nutrition_logs')
        .upsert({
          'user_id': currentUser!.id,
          'date': dateStr,
          'diet_plan_id': dietPlanId,
          'meals': meals,
          'calories_consumed': caloriesConsumed,
          'calories_burned': caloriesBurned,
          'calories_burned_predicted': caloriesBurnedPredicted,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,date')
        .select()
        .single();

    return response;
  }

  /// Get nutrition logs for date range (for predictions)
  static Future<List<Map<String, dynamic>>> getNutritionLogsRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (currentUser == null) return [];

    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('daily_nutrition_logs')
        .select()
        .eq('user_id', currentUser!.id)
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
```

**Step 2: Add Favorite Foods methods**

Add after the nutrition logs section:

```dart
  // ============================================
  // User Favorite Foods
  // ============================================

  /// Get all favorite foods for current user
  static Future<List<Map<String, dynamic>>> getFavoriteFoods() async {
    if (currentUser == null) return [];

    final response = await client
        .from('user_favorite_foods')
        .select()
        .eq('user_id', currentUser!.id)
        .order('use_count', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a food to favorites
  static Future<Map<String, dynamic>> addFavoriteFood(Map<String, dynamic> foodData) async {
    if (currentUser == null) throw Exception('Non authentifié');

    final response = await client
        .from('user_favorite_foods')
        .insert({
          'user_id': currentUser!.id,
          'food_data': foodData,
          'use_count': 1,
          'last_used_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return response;
  }

  /// Increment favorite food use count
  static Future<void> incrementFavoriteFoodUseCount(String id) async {
    await client.rpc('increment_favorite_food_count', params: {'food_id': id});
  }

  /// Remove a food from favorites
  static Future<void> removeFavoriteFood(String id) async {
    await client
        .from('user_favorite_foods')
        .delete()
        .eq('id', id);
  }

  /// Check if a food is favorited (by name match)
  static Future<bool> isFoodFavorited(String foodName) async {
    if (currentUser == null) return false;

    final response = await client
        .from('user_favorite_foods')
        .select('id')
        .eq('user_id', currentUser!.id)
        .limit(1);

    for (final fav in response) {
      final data = fav['food_data'] as Map<String, dynamic>?;
      if (data?['name']?.toString().toLowerCase() == foodName.toLowerCase()) {
        return true;
      }
    }
    return false;
  }
```

**Step 3: Add Meal Templates methods**

```dart
  // ============================================
  // Meal Templates
  // ============================================

  /// Get all meal templates for current user
  static Future<List<Map<String, dynamic>>> getMealTemplates() async {
    if (currentUser == null) return [];

    final response = await client
        .from('meal_templates')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a meal template
  static Future<Map<String, dynamic>> createMealTemplate({
    required String name,
    required List<Map<String, dynamic>> foods,
  }) async {
    if (currentUser == null) throw Exception('Non authentifié');

    final response = await client
        .from('meal_templates')
        .insert({
          'user_id': currentUser!.id,
          'name': name,
          'foods': foods,
        })
        .select()
        .single();

    return response;
  }

  /// Delete a meal template
  static Future<void> deleteMealTemplate(String id) async {
    await client
        .from('meal_templates')
        .delete()
        .eq('id', id);
  }
```

**Step 4: Add Community Foods methods**

```dart
  // ============================================
  // Community Foods
  // ============================================

  /// Search community foods by barcode
  static Future<Map<String, dynamic>?> getCommunityFoodByBarcode(String barcode) async {
    try {
      final response = await client
          .from('community_foods')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Search community foods by name
  static Future<List<Map<String, dynamic>>> searchCommunityFoods(String query) async {
    final response = await client
        .from('community_foods')
        .select()
        .ilike('name', '%$query%')
        .order('use_count', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Contribute a new community food
  static Future<Map<String, dynamic>> contributeCommunityFood({
    required String barcode,
    required String name,
    String? brand,
    required Map<String, dynamic> nutritionPer100g,
    String? imageUrl,
  }) async {
    if (currentUser == null) throw Exception('Non authentifié');

    final response = await client
        .from('community_foods')
        .insert({
          'barcode': barcode,
          'name': name,
          'brand': brand,
          'nutrition_per_100g': nutritionPer100g,
          'image_url': imageUrl,
          'contributed_by': currentUser!.id,
        })
        .select()
        .single();

    return response;
  }

  /// Increment community food use count
  static Future<void> incrementCommunityFoodUseCount(String id) async {
    await client.rpc('increment_community_food_count', params: {'food_id': id});
  }
```

**Step 5: Commit**

```bash
git add fitgame/lib/core/services/supabase_service.dart
git commit -m "feat: add Supabase service methods for nutrition tracking"
```

---

## Phase 2: Calorie Balance Card (Feature A)

### Task 4: Add calories history method to HealthService

**Files:**
- Modify: `fitgame/lib/core/services/health_service.dart`

**Step 1: Add method to get calories for past days**

Add after `getHealthSnapshot` method (around line 382):

```dart
  /// Get calories burned for multiple days (for prediction)
  Future<List<ActivityData>> getCaloriesHistory({int days = 7}) async {
    if (!_isAuthorized) {
      final authorized = await checkAuthorization();
      if (!authorized) return [];
    }

    final results = <ActivityData>[];
    final now = DateTime.now();

    for (int i = 1; i <= days; i++) {
      final date = now.subtract(Duration(days: i));
      final activity = await getActivityData(date);
      if (activity != null) {
        results.add(activity);
      }
    }

    return results;
  }

  /// Predict end-of-day calories based on current burn rate and history
  Future<int?> predictDailyCalories() async {
    final history = await getCaloriesHistory(days: 7);
    if (history.isEmpty) return null;

    final now = DateTime.now();
    final currentHour = now.hour + (now.minute / 60);

    // Get today's current calories
    final today = await getActivityData(now);
    if (today == null) return null;

    // Calculate average ratio at current time from history
    // (what percentage of daily total was burned by this hour)
    double totalRatio = 0;
    int validDays = 0;

    for (final day in history) {
      if (day.totalCaloriesBurned > 0) {
        // Assume linear burn throughout day for simplicity
        // In reality could use hourly data if available
        totalRatio += currentHour / 24;
        validDays++;
      }
    }

    if (validDays == 0) return null;

    final avgRatio = totalRatio / validDays;
    if (avgRatio <= 0) return null;

    // Predict: current / ratio = predicted total
    final predicted = today.totalCaloriesBurned / avgRatio;
    return predicted.round();
  }
```

**Step 2: Commit**

```bash
git add fitgame/lib/core/services/health_service.dart
git commit -m "feat: add calories history and prediction to HealthService"
```

---

### Task 5: Create CalorieBalanceCard widget

**Files:**
- Create: `fitgame/lib/features/nutrition/widgets/calorie_balance_card.dart`

**Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';

class CalorieBalanceCard extends StatelessWidget {
  final int caloriesConsumed;
  final int caloriesBurned;
  final int? caloriesPredicted;
  final int calorieTarget;
  final String goalType; // 'bulk', 'cut', 'maintain'
  final bool isLoading;

  const CalorieBalanceCard({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    this.caloriesPredicted,
    required this.calorieTarget,
    required this.goalType,
    this.isLoading = false,
  });

  int get balance => caloriesConsumed - caloriesBurned;

  bool get isDeficit => balance < 0;

  Color get balanceColor {
    if (goalType == 'cut') {
      return isDeficit ? FGColors.success : FGColors.warning;
    } else if (goalType == 'bulk') {
      return isDeficit ? FGColors.warning : FGColors.success;
    }
    // maintain
    return balance.abs() < 200 ? FGColors.success : FGColors.warning;
  }

  String get balanceLabel {
    if (goalType == 'cut') {
      return isDeficit ? 'Déficit' : 'Surplus';
    } else if (goalType == 'bulk') {
      return isDeficit ? 'Déficit' : 'Surplus';
    }
    return balance.abs() < 200 ? 'Équilibré' : (isDeficit ? 'Déficit' : 'Surplus');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.glassSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacing.lg),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: FGColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                'BILAN DU JOUR',
                style: FGTypography.caption.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: FGColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Main stats row
          if (isLoading)
            const Center(
              child: SizedBox(
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FGColors.accent,
                ),
              ),
            )
          else
            Row(
              children: [
                // Consumed
                Expanded(
                  child: _buildStatColumn(
                    label: 'Consommé',
                    value: caloriesConsumed,
                    color: FGColors.textPrimary,
                  ),
                ),
                // Burned
                Expanded(
                  child: _buildStatColumn(
                    label: 'Brûlé',
                    value: caloriesBurned,
                    color: FGColors.accent,
                    subtitle: 'Apple Santé',
                  ),
                ),
                // Balance
                Expanded(
                  child: _buildStatColumn(
                    label: 'Balance',
                    value: balance,
                    color: balanceColor,
                    showSign: true,
                    badge: balanceLabel,
                  ),
                ),
              ],
            ),

          // Prediction
          if (caloriesPredicted != null && !isLoading) ...[
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: FGColors.glassBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_graph_rounded,
                    color: FGColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      'Prédiction fin de journée: ~$caloriesPredicted kcal',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Progress bar
          const SizedBox(height: Spacing.md),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required int value,
    required Color color,
    String? subtitle,
    bool showSign = false,
    String? badge,
  }) {
    final displayValue = showSign && value > 0 ? '+$value' : value.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              displayValue,
              style: FGTypography.h2.copyWith(
                fontSize: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                'kcal',
                style: FGTypography.caption.copyWith(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: FGTypography.caption.copyWith(
              fontSize: 9,
              color: FGColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
        if (badge != null) ...[
          const SizedBox(height: Spacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: balanceColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Spacing.xs),
            ),
            child: Text(
              badge,
              style: FGTypography.caption.copyWith(
                fontSize: 9,
                color: balanceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = calorieTarget > 0
        ? (caloriesConsumed / calorieTarget).clamp(0.0, 1.5)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Objectif: $calorieTarget kcal',
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: FGTypography.caption.copyWith(
                color: progress > 1.0 ? FGColors.warning : FGColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: FGColors.glassBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 1.0 ? FGColors.warning : const Color(0xFF2ECC71),
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
```

**Step 2: Commit**

```bash
git add fitgame/lib/features/nutrition/widgets/calorie_balance_card.dart
git commit -m "feat: create CalorieBalanceCard widget"
```

---

### Task 6: Integrate CalorieBalanceCard into NutritionScreen

**Files:**
- Modify: `fitgame/lib/features/nutrition/nutrition_screen.dart`

**Step 1: Add imports**

Add at top with other imports:

```dart
import 'widgets/calorie_balance_card.dart';
import '../../core/services/health_service.dart';
```

**Step 2: Add state variables**

Add in `_NutritionScreenState` class (around line 43):

```dart
  // Health data for calorie balance
  int _caloriesBurned = 0;
  int? _caloriesPredicted;
  bool _isLoadingHealth = true;
```

**Step 3: Load health data in initState**

Add call in `initState()` after `_loadData()`:

```dart
    _loadHealthData();
```

**Step 4: Add _loadHealthData method**

Add after `_loadData()` method:

```dart
  Future<void> _loadHealthData() async {
    setState(() => _isLoadingHealth = true);

    try {
      final healthService = HealthService();

      // Check/request authorization
      if (!healthService.isAuthorized) {
        await healthService.requestAuthorization();
      }

      // Get today's activity data
      final today = DateTime.now();
      final activity = await healthService.getActivityData(today);

      // Get prediction
      final predicted = await healthService.predictDailyCalories();

      if (mounted) {
        setState(() {
          _caloriesBurned = activity?.totalCaloriesBurned ?? 0;
          _caloriesPredicted = predicted;
          _isLoadingHealth = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading health data: $e');
      if (mounted) {
        setState(() => _isLoadingHealth = false);
      }
    }
  }
```

**Step 5: Add CalorieBalanceCard to _buildDayContent**

In `_buildDayContent` method, add after the day title row and before MacroDashboard (around line 1043):

```dart
          // Calorie Balance Card
          CalorieBalanceCard(
            caloriesConsumed: dayTotals['cal'] ?? 0,
            caloriesBurned: _caloriesBurned,
            caloriesPredicted: _caloriesPredicted,
            calorieTarget: target,
            goalType: _goalType,
            isLoading: _isLoadingHealth,
          ),
          const SizedBox(height: Spacing.lg),
```

**Step 6: Commit**

```bash
git add fitgame/lib/features/nutrition/nutrition_screen.dart
git commit -m "feat: integrate CalorieBalanceCard into NutritionScreen"
```

---

## Phase 3: Plan vs Tracking Separation (Feature B)

### Task 7: Add tracking state to NutritionScreen

**Files:**
- Modify: `fitgame/lib/features/nutrition/nutrition_screen.dart`

**Step 1: Add state for daily log**

Add state variables (after health data variables):

```dart
  // Daily tracking (separate from plan)
  Map<String, dynamic>? _todayLog;
  List<Map<String, dynamic>> _trackingWeeklyPlan = [];
  bool _isTrackingMode = true; // true = editing daily log, false = editing plan
```

**Step 2: Add method to load/create daily log**

Add new method:

```dart
  Future<void> _loadOrCreateTodayLog() async {
    if (!SupabaseService.isAuthenticated) return;

    final today = DateTime.now();

    try {
      // Try to load existing log
      var log = await SupabaseService.getNutritionLog(today);

      if (log == null && _activePlan != null) {
        // Create new log from active plan
        final planMeals = _weeklyPlan[_selectedDayIndex]['meals'] as List;
        final mealsForLog = planMeals.map((meal) {
          return {
            'name': meal['name'],
            'icon': meal['icon'].toString(),
            'foods': (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f)).toList(),
            'plan_foods': (meal['foods'] as List).map((f) => Map<String, dynamic>.from(f)).toList(),
          };
        }).toList();

        log = await SupabaseService.upsertNutritionLog(
          date: today,
          dietPlanId: _activePlan!['id'] as String?,
          meals: mealsForLog,
          caloriesConsumed: _getDayTotals(_selectedDayIndex)['cal'] ?? 0,
        );
      }

      if (mounted && log != null) {
        setState(() {
          _todayLog = log;
          _applyLogToTrackingPlan(log!);
        });
      }
    } catch (e) {
      debugPrint('Error loading daily log: $e');
    }
  }

  void _applyLogToTrackingPlan(Map<String, dynamic> log) {
    final logMeals = log['meals'] as List? ?? [];

    // Create tracking weekly plan from log for today
    _trackingWeeklyPlan = List.generate(7, (index) {
      if (index == _getTodayIndex()) {
        return {
          'meals': logMeals.map((meal) {
            return {
              'name': meal['name'],
              'icon': _getMealIcon(meal['name'] as String? ?? ''),
              'foods': (meal['foods'] as List? ?? []).map((f) => Map<String, dynamic>.from(f)).toList(),
              'plan_foods': (meal['plan_foods'] as List? ?? []).map((f) => Map<String, dynamic>.from(f)).toList(),
            };
          }).toList(),
        };
      }
      return _weeklyPlan[index];
    });
  }

  int _getTodayIndex() {
    return DateTime.now().weekday - 1; // 0 = Monday
  }

  bool get _isToday => _selectedDayIndex == _getTodayIndex();
```

**Step 3: Update _loadData to also load tracking**

In `_loadData()`, add at the end before the closing brace:

```dart
      // Load today's tracking log
      await _loadOrCreateTodayLog();
```

**Step 4: Modify food editing to use tracking**

Update `_updateFood` method to save to log instead of plan when in tracking mode:

```dart
  void _updateFood(int dayIndex, String mealName, Map<String, dynamic> oldFood, Map<String, dynamic> newFood) {
    setState(() {
      final targetPlan = _isTrackingMode && _isToday ? _trackingWeeklyPlan : _weeklyPlan;
      final meals = targetPlan[dayIndex]['meals'] as List;
      for (final meal in meals) {
        if (meal['name'] == mealName) {
          final foods = meal['foods'] as List;
          final index = foods.indexOf(oldFood);
          if (index != -1) {
            foods[index] = Map<String, dynamic>.from(newFood);
          }
          break;
        }
      }
    });

    if (_isTrackingMode && _isToday) {
      _saveTrackingLog();
    } else {
      _saveDietPlanChanges();
    }

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newFood['name']} mis à jour'),
        backgroundColor: FGColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _saveTrackingLog() async {
    if (_todayLog == null) return;

    final todayMeals = _trackingWeeklyPlan[_getTodayIndex()]['meals'] as List;
    final mealsForSave = todayMeals.map((meal) {
      return {
        'name': meal['name'],
        'foods': meal['foods'],
        'plan_foods': meal['plan_foods'] ?? meal['foods'],
      };
    }).toList();

    final totals = _getDayTotals(_getTodayIndex());

    try {
      await SupabaseService.upsertNutritionLog(
        date: DateTime.now(),
        dietPlanId: _activePlan?['id'] as String?,
        meals: mealsForSave,
        caloriesConsumed: totals['cal'] ?? 0,
        caloriesBurned: _caloriesBurned,
        caloriesBurnedPredicted: _caloriesPredicted,
      );
    } catch (e) {
      debugPrint('Error saving tracking log: $e');
    }
  }
```

**Step 5: Update _buildDayContent to show plan vs actual**

Modify `_buildMealCards` to use tracking plan for today:

```dart
  List<Widget> _buildMealCards(int dayIndex) {
    // Use tracking plan for today, regular plan for other days
    final targetPlan = (_isTrackingMode && dayIndex == _getTodayIndex())
        ? _trackingWeeklyPlan
        : _weeklyPlan;

    if (targetPlan.isEmpty || dayIndex >= targetPlan.length) {
      return [const SizedBox.shrink()];
    }

    final dayPlan = targetPlan[dayIndex];
    final meals = dayPlan['meals'] as List;
    // ... rest of method stays the same
```

**Step 6: Commit**

```bash
git add fitgame/lib/features/nutrition/nutrition_screen.dart
git commit -m "feat: add plan vs tracking separation logic"
```

---

### Task 8: Update MealCard to show plan vs actual quantities

**Files:**
- Modify: `fitgame/lib/features/nutrition/widgets/meal_card.dart`

**Step 1: Read current file structure**

First check the current meal_card.dart structure, then add support for showing "120g / 150g prévu" when quantities differ.

**Step 2: Add plan_quantity display**

In the food item display, check if there's a `plan_quantity` field and show both values if they differ.

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/widgets/meal_card.dart
git commit -m "feat: show plan vs actual quantities in MealCard"
```

---

## Phase 4: Quick Food Adding (Feature C)

### Task 9: Create OpenFoodFacts service

**Files:**
- Create: `fitgame/lib/core/services/openfoodfacts_service.dart`

**Step 1: Create the service**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  /// Search for a product by barcode
  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/product/$barcode'),
        headers: {
          'User-Agent': 'FitGame/1.0 (Flutter App)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          return _parseProduct(data['product']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('OpenFoodFacts error: $e');
      return null;
    }
  }

  /// Search products by name
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?search_terms=$query&page_size=20&json=1'),
        headers: {
          'User-Agent': 'FitGame/1.0 (Flutter App)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List? ?? [];

        return products
            .map((p) => _parseProduct(p))
            .where((p) => p != null)
            .cast<Map<String, dynamic>>()
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('OpenFoodFacts search error: $e');
      return [];
    }
  }

  static Map<String, dynamic>? _parseProduct(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    // Get values per 100g
    final calories = nutriments['energy-kcal_100g'] ??
                     nutriments['energy_100g']?.toDouble()?.div(4.184) ?? 0;
    final protein = nutriments['proteins_100g'] ?? 0;
    final carbs = nutriments['carbohydrates_100g'] ?? 0;
    final fat = nutriments['fat_100g'] ?? 0;

    final name = product['product_name'] ?? product['product_name_fr'];
    if (name == null || name.toString().isEmpty) return null;

    return {
      'name': name,
      'brand': product['brands'] ?? '',
      'barcode': product['code'] ?? '',
      'quantity': '100g',
      'cal': (calories as num).round(),
      'p': (protein as num).round(),
      'c': (carbs as num).round(),
      'f': (fat as num).round(),
      'per_100g': {
        'cal': (calories as num).round(),
        'p': (protein as num).round(),
        'c': (carbs as num).round(),
        'f': (fat as num).round(),
      },
      'image_url': product['image_url'] ?? product['image_front_url'],
    };
  }
}
```

**Step 2: Commit**

```bash
git add fitgame/lib/core/services/openfoodfacts_service.dart
git commit -m "feat: create OpenFoodFacts API service"
```

---

### Task 10: Create FoodAddSheet (main food adding interface)

**Files:**
- Create: `fitgame/lib/features/nutrition/sheets/food_add_sheet.dart`

**Step 1: Create the sheet with tabs for search, scanner, favorites, templates**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class FoodAddSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelectFood;
  final VoidCallback? onScanRequested;
  final VoidCallback? onFavoritesRequested;
  final VoidCallback? onTemplatesRequested;

  const FoodAddSheet({
    super.key,
    required this.onSelectFood,
    this.onScanRequested,
    this.onFavoritesRequested,
    this.onTemplatesRequested,
  });

  @override
  State<FoodAddSheet> createState() => _FoodAddSheetState();
}

class _FoodAddSheetState extends State<FoodAddSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _recentFoods = [];
  List<Map<String, dynamic>> _favoriteFoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final favorites = await SupabaseService.getFavoriteFoods();

      if (mounted) {
        setState(() {
          _favoriteFoods = favorites.take(5).toList();
          _recentFoods = favorites.take(10).toList(); // Use favorites as recents for now
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                Text('Ajouter un aliment', style: FGTypography.h3),
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

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: TextField(
              controller: _searchController,
              style: FGTypography.body,
              decoration: InputDecoration(
                hintText: 'Rechercher un aliment...',
                hintStyle: FGTypography.body.copyWith(
                  color: FGColors.textSecondary.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search, color: FGColors.textSecondary),
                filled: true,
                fillColor: FGColors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacing.md),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                // TODO: Implement search
              },
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Quick action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                _buildQuickActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scanner',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onScanRequested?.call();
                  },
                ),
                const SizedBox(width: Spacing.md),
                _buildQuickActionButton(
                  icon: Icons.star_rounded,
                  label: 'Favoris',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onFavoritesRequested?.call();
                  },
                ),
                const SizedBox(width: Spacing.md),
                _buildQuickActionButton(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Templates',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onTemplatesRequested?.call();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Recent foods
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    children: [
                      Text(
                        'RÉCENTS',
                        style: FGTypography.caption.copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: FGColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      if (_recentFoods.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: Text(
                            'Aucun aliment récent',
                            style: FGTypography.body.copyWith(
                              color: FGColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ..._recentFoods.map((food) => _buildFoodItem(food)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.md),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: FGColors.accent, size: 28),
              const SizedBox(height: Spacing.xs),
              Text(
                label,
                style: FGTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    final foodData = food['food_data'] as Map<String, dynamic>? ?? food;
    final name = foodData['name'] as String? ?? 'Aliment';
    final cal = foodData['cal'] as int? ?? 0;
    final quantity = foodData['quantity'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onSelectFood(foodData);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: FGColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (quantity.isNotEmpty)
                    Text(
                      quantity,
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '$cal kcal',
              style: FGTypography.body.copyWith(
                color: FGColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            const Icon(
              Icons.add_circle_outline,
              color: FGColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add fitgame/lib/features/nutrition/sheets/food_add_sheet.dart
git commit -m "feat: create FoodAddSheet with quick actions"
```

---

### Task 11: Create BarcodeScannerSheet

**Files:**
- Create: `fitgame/lib/features/nutrition/sheets/barcode_scanner_sheet.dart`

**Step 1: Create scanner sheet using mobile_scanner**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/openfoodfacts_service.dart';
import '../../../core/services/supabase_service.dart';

class BarcodeScannerSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onFoodFound;
  final Function(String barcode) onFoodNotFound;

  const BarcodeScannerSheet({
    super.key,
    required this.onFoodFound,
    required this.onFoodNotFound,
  });

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isSearching = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isSearching) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastScannedCode) return;

    setState(() {
      _isSearching = true;
      _lastScannedCode = barcode;
    });

    HapticFeedback.mediumImpact();

    try {
      // 1. Search OpenFoodFacts
      var food = await OpenFoodFactsService.getProductByBarcode(barcode);

      // 2. If not found, search community foods
      if (food == null) {
        food = await SupabaseService.getCommunityFoodByBarcode(barcode);
        if (food != null) {
          // Convert community food format
          final nutrition = food['nutrition_per_100g'] as Map<String, dynamic>;
          food = {
            'name': food['name'],
            'brand': food['brand'],
            'barcode': barcode,
            'quantity': '100g',
            'cal': nutrition['cal'] ?? 0,
            'p': nutrition['p'] ?? 0,
            'c': nutrition['c'] ?? 0,
            'f': nutrition['f'] ?? 0,
          };
        }
      }

      if (mounted) {
        if (food != null) {
          Navigator.pop(context);
          widget.onFoodFound(food);
        } else {
          Navigator.pop(context);
          widget.onFoodNotFound(barcode);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: FGColors.accent),
                const SizedBox(width: Spacing.sm),
                Text('Scanner un code-barres', style: FGTypography.h3),
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

          // Scanner
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Spacing.lg),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onBarcodeDetected,
                  ),
                ),

                // Scanning overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isSearching ? FGColors.accent : Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(Spacing.lg),
                    ),
                  ),
                ),

                // Loading indicator
                if (_isSearching)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: FGColors.accent),
                          const SizedBox(height: Spacing.md),
                          Text(
                            'Recherche en cours...',
                            style: FGTypography.body.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Text(
              'Placez le code-barres dans le cadre',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add fitgame/lib/features/nutrition/sheets/barcode_scanner_sheet.dart
git commit -m "feat: create BarcodeScannerSheet with OpenFoodFacts integration"
```

---

### Task 12: Create ContributeFoodSheet

**Files:**
- Create: `fitgame/lib/features/nutrition/sheets/contribute_food_sheet.dart`

**Step 1: Create contribution form**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/supabase_service.dart';

class ContributeFoodSheet extends StatefulWidget {
  final String barcode;
  final Function(Map<String, dynamic>) onContributed;

  const ContributeFoodSheet({
    super.key,
    required this.barcode,
    required this.onContributed,
  });

  @override
  State<ContributeFoodSheet> createState() => _ContributeFoodSheetState();
}

class _ContributeFoodSheetState extends State<ContributeFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final nutritionPer100g = {
        'cal': int.parse(_caloriesController.text),
        'p': int.parse(_proteinController.text),
        'c': int.parse(_carbsController.text),
        'f': int.parse(_fatController.text),
      };

      await SupabaseService.contributeCommunityFood(
        barcode: widget.barcode,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        nutritionPer100g: nutritionPer100g,
      );

      final food = {
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'barcode': widget.barcode,
        'quantity': '100g',
        ...nutritionPer100g,
      };

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context);
        widget.onContributed(food);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: FGColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(Spacing.sm),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: FGColors.accent,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ajouter pour la communauté',
                               style: FGTypography.h3),
                          Text(
                            'Code: ${widget.barcode}',
                            style: FGTypography.caption.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                                        color: FGColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: FGColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Spacing.md),
                    border: Border.all(
                      color: FGColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: FGColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          'Cet aliment sera partagé avec tous les utilisateurs FitGame',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom du produit *',
                      hint: 'Ex: Yaourt nature 0%',
                      validator: (v) => v?.isEmpty == true
                          ? 'Requis'
                          : null,
                    ),
                    const SizedBox(height: Spacing.md),
                    _buildTextField(
                      controller: _brandController,
                      label: 'Marque (optionnel)',
                      hint: 'Ex: Danone',
                    ),
                    const SizedBox(height: Spacing.lg),

                    Text(
                      'VALEURS NUTRITIONNELLES POUR 100G',
                      style: FGTypography.caption.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: FGColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _caloriesController,
                            label: 'Calories *',
                            suffix: 'kcal',
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: _buildNumberField(
                            controller: _proteinController,
                            label: 'Protéines *',
                            suffix: 'g',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _carbsController,
                            label: 'Glucides *',
                            suffix: 'g',
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: _buildNumberField(
                            controller: _fatController,
                            label: 'Lipides *',
                            suffix: 'g',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xxl),
                  ],
                ),
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FGColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Spacing.md),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Contribuer',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FGTypography.caption.copyWith(
          color: FGColors.textSecondary,
        )),
        const SizedBox(height: Spacing.xs),
        TextFormField(
          controller: controller,
          style: FGTypography.body,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: FGTypography.body.copyWith(
              color: FGColors.textSecondary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: FGColors.glassSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.sm),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.sm),
              borderSide: const BorderSide(color: FGColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FGTypography.caption.copyWith(
          color: FGColors.textSecondary,
        )),
        const SizedBox(height: Spacing.xs),
        TextFormField(
          controller: controller,
          style: FGTypography.body,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v?.isEmpty == true ? 'Requis' : null,
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
            ),
            filled: true,
            fillColor: FGColors.glassSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.sm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
```

**Step 2: Commit**

```bash
git add fitgame/lib/features/nutrition/sheets/contribute_food_sheet.dart
git commit -m "feat: create ContributeFoodSheet for community contributions"
```

---

### Task 13: Create FavoriteFoodsSheet and MealTemplatesSheet

**Files:**
- Create: `fitgame/lib/features/nutrition/sheets/favorite_foods_sheet.dart`
- Create: `fitgame/lib/features/nutrition/sheets/meal_templates_sheet.dart`

These follow similar patterns to FoodAddSheet. Create simple list views with add/remove functionality.

**Step 1: Commit**

```bash
git add fitgame/lib/features/nutrition/sheets/favorite_foods_sheet.dart
git add fitgame/lib/features/nutrition/sheets/meal_templates_sheet.dart
git commit -m "feat: create FavoriteFoodsSheet and MealTemplatesSheet"
```

---

### Task 14: Wire everything together in NutritionScreen

**Files:**
- Modify: `fitgame/lib/features/nutrition/nutrition_screen.dart`

**Step 1: Update imports**

Add new imports:

```dart
import 'sheets/food_add_sheet.dart';
import 'sheets/barcode_scanner_sheet.dart';
import 'sheets/contribute_food_sheet.dart';
import 'sheets/favorite_foods_sheet.dart';
import 'sheets/meal_templates_sheet.dart';
```

**Step 2: Update _showFoodLibrary to use new FoodAddSheet**

Replace the existing `_showFoodLibrary` method:

```dart
  void _showFoodLibrary(int dayIndex, String mealName) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => FoodAddSheet(
        onSelectFood: (food) {
          _addFoodToMeal(dayIndex, mealName, food);
          Navigator.pop(sheetContext);
        },
        onScanRequested: () => _showBarcodeScanner(dayIndex, mealName),
        onFavoritesRequested: () => _showFavoriteFoods(dayIndex, mealName),
        onTemplatesRequested: () => _showMealTemplates(dayIndex, mealName),
      ),
    );
  }

  void _showBarcodeScanner(int dayIndex, String mealName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BarcodeScannerSheet(
        onFoodFound: (food) {
          _addFoodToMeal(dayIndex, mealName, food);
        },
        onFoodNotFound: (barcode) {
          _showContributeFoodSheet(barcode, dayIndex, mealName);
        },
      ),
    );
  }

  void _showContributeFoodSheet(String barcode, int dayIndex, String mealName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ContributeFoodSheet(
        barcode: barcode,
        onContributed: (food) {
          _addFoodToMeal(dayIndex, mealName, food);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Merci pour votre contribution !'),
              backgroundColor: FGColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFavoriteFoods(int dayIndex, String mealName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FavoriteFoodsSheet(
        onSelectFood: (food) {
          _addFoodToMeal(dayIndex, mealName, food);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMealTemplates(int dayIndex, String mealName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MealTemplatesSheet(
        onSelectTemplate: (foods) {
          for (final food in foods) {
            _addFoodToMeal(dayIndex, mealName, food);
          }
          Navigator.pop(context);
        },
      ),
    );
  }
```

**Step 3: Commit**

```bash
git add fitgame/lib/features/nutrition/nutrition_screen.dart
git commit -m "feat: wire up new food adding flow in NutritionScreen"
```

---

## Phase 5: Final Integration & Testing

### Task 15: Update CHANGELOG and documentation

**Files:**
- Modify: `fitgame/docs/CHANGELOG.md`
- Modify: `fitgame/docs/SCREENS.md`

**Step 1: Add changelog entry**

```markdown
## [Unreleased]

### Added
- Calorie Balance Card showing consumed vs burned calories (Apple Health integration)
- Daily nutrition tracking separate from plan templates
- Barcode scanner for quick food adding (OpenFoodFacts API)
- Community food contributions for missing products
- Favorite foods with usage tracking
- Meal templates for quick meal adding
- Calorie burn prediction based on 7-day history

### Changed
- NutritionScreen now shows tracking data for today, plan for other days
- Food editing saves to daily log, not plan template
```

**Step 2: Commit**

```bash
git add fitgame/docs/CHANGELOG.md fitgame/docs/SCREENS.md
git commit -m "docs: update CHANGELOG and SCREENS for nutrition upgrade"
```

---

### Task 16: Final commit and summary

**Step 1: Verify all changes**

Run: `flutter analyze` in fitgame directory
Expected: No errors

**Step 2: Create final summary commit if needed**

```bash
git log --oneline -10
```

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1 | 1-3 | Database setup (migration, Supabase methods, dependencies) |
| 2 | 4-6 | Calorie Balance Card (HealthService, widget, integration) |
| 3 | 7-8 | Plan vs Tracking separation (state management, UI updates) |
| 4 | 9-14 | Quick food adding (OpenFoodFacts, scanner, favorites, templates) |
| 5 | 15-16 | Documentation and final verification |

**Total Tasks:** 16
**Estimated commits:** ~15

---

**Plan complete and saved to `docs/plans/2026-02-05-nutrition-upgrade-implementation.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**
