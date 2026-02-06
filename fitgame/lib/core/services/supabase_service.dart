import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  // ignore: unused_field - subscription kept alive for auth state cleanup
  static StreamSubscription<AuthState>? _authSubscription;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    // Listen for logout to cleanup realtime subscriptions
    _authSubscription = client.auth.onAuthStateChange.listen((authState) {
      if (authState.session == null) {
        // User logged out - cleanup realtime channel
        _cleanupRealtimeChannel();
      }
    });
  }

  static void _cleanupRealtimeChannel() {
    _assignmentListeners.clear();
    if (_assignmentsChannel != null) {
      client.removeChannel(_assignmentsChannel!);
      _assignmentsChannel = null;
    }
  }

  // ============================================
  // Auth helpers
  // ============================================

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Sign up with email
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'athlete',
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );

    // Profile is auto-created by handle_new_user() trigger
    // Metadata (full_name, role) is passed via signUp data above

    return response;
  }

  // Sign in with email
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  static Future<AuthResponse> signInWithGoogle() async {
    // OAuth Client IDs loaded from .env
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']!;
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS ? iosClientId : null,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Connexion Google annulée');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('Impossible de récupérer le token Google');
    }

    final response = await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    // Create profile if it doesn't exist
    if (response.user != null) {
      final existingProfile = await client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (existingProfile == null) {
        await client.from('profiles').insert({
          'id': response.user!.id,
          'email': response.user!.email ?? googleUser.email,
          'full_name': googleUser.displayName ?? 'Utilisateur',
          'avatar_url': googleUser.photoUrl,
          'role': 'athlete',
        });
      }
    }

    return response;
  }

  // Sign out
  static Future<void> signOut() async {
    // Sign out from Google as well
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign out errors
    }
    await client.auth.signOut();
  }

  // ============================================
  // Profile
  // ============================================

  // Get current user profile
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    if (currentUser == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .single();

    return response;
  }

  // Update profile
  static Future<void> updateProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;

    await client
        .from('profiles')
        .update(data)
        .eq('id', currentUser!.id);
  }

  // ============================================
  // Programs
  // ============================================

  /// Fetch all programs for the current user
  static Future<List<Map<String, dynamic>>> getPrograms() async {
    if (currentUser == null) return [];

    final response = await client
        .from('programs')
        .select()
        .eq('created_by', currentUser!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch programs assigned to the current user (as athlete)
  static Future<List<Map<String, dynamic>>> getAssignedPrograms() async {
    if (currentUser == null) return [];

    // Get active assignments
    final assignments = await client
        .from('assignments')
        .select('program_id')
        .eq('student_id', currentUser!.id)
        .eq('status', 'active')
        .not('program_id', 'is', null);

    if (assignments.isEmpty) return [];

    final programIds = assignments
        .map((a) => a['program_id'] as String)
        .toList();

    final response = await client
        .from('programs')
        .select()
        .inFilter('id', programIds);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get a single program by ID
  static Future<Map<String, dynamic>?> getProgram(String id) async {
    try {
      final response = await client
          .from('programs')
          .select()
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Create a new program
  static Future<Map<String, dynamic>> createProgram({
    required String name,
    String? description,
    required String goal,
    int durationWeeks = 8,
    int? deloadFrequency,
    required List<Map<String, dynamic>> days,
  }) async {
    if (currentUser == null) throw Exception('Non authentifié');

    final response = await client
        .from('programs')
        .insert({
          'created_by': currentUser!.id,
          'name': name,
          'description': description,
          'goal': goal,
          'duration_weeks': durationWeeks,
          'deload_frequency': deloadFrequency,
          'days': days,
        })
        .select()
        .single();

    return response;
  }

  /// Update a program
  static Future<void> updateProgram(String id, Map<String, dynamic> data) async {
    await client
        .from('programs')
        .update(data)
        .eq('id', id);
  }

  /// Delete a program
  static Future<void> deleteProgram(String id) async {
    await client
        .from('programs')
        .delete()
        .eq('id', id);
  }

  // ============================================
  // Workout Sessions
  // ============================================

  /// Fetch workout sessions for the current user
  static Future<List<Map<String, dynamic>>> getWorkoutSessions({
    int limit = 50,
    String? programId,
  }) async {
    if (currentUser == null) return [];

    var query = client
        .from('workout_sessions')
        .select()
        .eq('user_id', currentUser!.id);

    if (programId != null) {
      query = query.eq('program_id', programId);
    }

    final response = await query
        .order('started_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get a single workout session
  static Future<Map<String, dynamic>?> getWorkoutSession(String id) async {
    try {
      final response = await client
          .from('workout_sessions')
          .select()
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Start a new workout session
  static Future<Map<String, dynamic>> startWorkoutSession({
    String? programId,
    required String dayName,
    required List<Map<String, dynamic>> exercises,
  }) async {
    if (currentUser == null) throw Exception('Non authentifié');

    final response = await client
        .from('workout_sessions')
        .insert({
          'user_id': currentUser!.id,
          'program_id': programId,
          'day_name': dayName,
          'started_at': DateTime.now().toIso8601String(),
          'exercises': exercises,
        })
        .select()
        .single();

    return response;
  }

  /// Complete a workout session
  static Future<void> completeWorkoutSession({
    required String sessionId,
    required int durationMinutes,
    required double totalVolumeKg,
    required int totalSets,
    required List<Map<String, dynamic>> exercises,
    List<Map<String, dynamic>>? personalRecords,
    String? notes,
  }) async {
    await client
        .from('workout_sessions')
        .update({
          'completed_at': DateTime.now().toIso8601String(),
          'duration_minutes': durationMinutes,
          'total_volume_kg': totalVolumeKg,
          'total_sets': totalSets,
          'exercises': exercises,
          'personal_records': personalRecords ?? [],
          'notes': notes,
        })
        .eq('id', sessionId);

    // Update profile stats
    if (currentUser != null) {
      try {
        await client.rpc('increment_total_sessions', params: {
          'p_user_id': currentUser!.id,
        });
      } catch (e) {
        debugPrint('Error incrementing total_sessions: $e');
      }
    }
  }

  /// Update user's workout streak
  static Future<int> updateStreak() async {
    if (currentUser == null) return 0;
    try {
      final result = await client.rpc('update_streak', params: {
        'p_user_id': currentUser!.id,
      });
      return (result as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Error updating streak: $e');
      return 0;
    }
  }

  /// Delete/cancel a workout session
  static Future<void> deleteWorkoutSession(String id) async {
    await client
        .from('workout_sessions')
        .delete()
        .eq('id', id);
  }

  /// Get exercise history (for PR tracking)
  static Future<List<Map<String, dynamic>>> getExerciseHistory(
    String exerciseName, {
    int limit = 20,
  }) async {
    if (currentUser == null) return [];

    // Get sessions that contain this exercise
    final response = await client
        .from('workout_sessions')
        .select('id, completed_at, exercises')
        .eq('user_id', currentUser!.id)
        .not('completed_at', 'is', null)
        .order('completed_at', ascending: false)
        .limit(100);

    // Filter and extract exercise data
    final List<Map<String, dynamic>> history = [];

    for (final session in response) {
      final exercises = session['exercises'] as List? ?? [];
      for (final ex in exercises) {
        if (ex['exerciseName']?.toString().toLowerCase() ==
            exerciseName.toLowerCase()) {
          history.add({
            'date': session['completed_at'],
            'sets': ex['sets'] ?? [],
          });
        }
      }
      if (history.length >= limit) break;
    }

    return history;
  }

  // ============================================
  // Diet Plans
  // ============================================

  /// Fetch all diet plans for the current user
  static Future<List<Map<String, dynamic>>> getDietPlans() async {
    if (currentUser == null) return [];

    final response = await client
        .from('diet_plans')
        .select()
        .eq('created_by', currentUser!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch diet plans assigned to the current user (as athlete)
  static Future<List<Map<String, dynamic>>> getAssignedDietPlans() async {
    if (currentUser == null) return [];

    // Get active assignments
    final assignments = await client
        .from('assignments')
        .select('diet_plan_id')
        .eq('student_id', currentUser!.id)
        .eq('status', 'active')
        .not('diet_plan_id', 'is', null);

    if (assignments.isEmpty) return [];

    final planIds = assignments
        .map((a) => a['diet_plan_id'] as String)
        .toList();

    final response = await client
        .from('diet_plans')
        .select()
        .inFilter('id', planIds);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get a single diet plan
  static Future<Map<String, dynamic>?> getDietPlan(String id) async {
    try {
      final response = await client
          .from('diet_plans')
          .select()
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Create a new diet plan
  static Future<Map<String, dynamic>> createDietPlan({
    required String name,
    required String goal,
    required int trainingCalories,
    required int restCalories,
    required Map<String, dynamic> trainingMacros,
    required Map<String, dynamic> restMacros,
    required List<Map<String, dynamic>> meals,
    List<Map<String, dynamic>>? supplements,
    String? notes,
  }) async {
    if (currentUser == null) throw Exception('Non authentifié');

    final response = await client
        .from('diet_plans')
        .insert({
          'created_by': currentUser!.id,
          'name': name,
          'goal': goal,
          'training_calories': trainingCalories,
          'rest_calories': restCalories,
          'training_macros': trainingMacros,
          'rest_macros': restMacros,
          'meals': meals,
          'supplements': supplements ?? [],
          'notes': notes,
        })
        .select()
        .single();

    return response;
  }

  /// Update a diet plan
  static Future<void> updateDietPlan(String id, Map<String, dynamic> data) async {
    await client
        .from('diet_plans')
        .update(data)
        .eq('id', id);
  }

  /// Delete a diet plan
  static Future<void> deleteDietPlan(String id) async {
    await client
        .from('diet_plans')
        .delete()
        .eq('id', id);
  }

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

  /// Update favorite food use count
  static Future<void> updateFavoriteFoodUsage(String id) async {
    try {
      await client.rpc('increment_food_use_count', params: {
        'p_table': 'user_favorite_foods',
        'p_id': id,
      });
    } catch (e) {
      debugPrint('Error updating food usage: $e');
    }
  }

  /// Remove a food from favorites
  static Future<void> removeFavoriteFood(String id) async {
    await client
        .from('user_favorite_foods')
        .delete()
        .eq('id', id);
  }

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
    try {
      await client.rpc('increment_food_use_count', params: {
        'p_table': 'community_foods',
        'p_id': id,
      });
    } catch (e) {
      debugPrint('Error incrementing community food: $e');
    }
  }

  // ============================================
  // Assignments (Coach-Student)
  // ============================================

  /// Get all assignments for the current user
  static Future<List<Map<String, dynamic>>> getAssignments() async {
    if (currentUser == null) return [];

    final response = await client
        .from('assignments')
        .select('*, programs(*), diet_plans(*)')
        .eq('student_id', currentUser!.id)
        .eq('status', 'active');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get coach info if user has a coach
  static Future<Map<String, dynamic>?> getCoachInfo() async {
    if (currentUser == null) return null;

    final profile = await getCurrentProfile();
    if (profile == null || profile['coach_id'] == null) return null;

    try {
      final response = await client
          .from('profiles')
          .select('id, full_name, email, avatar_url')
          .eq('id', profile['coach_id'])
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // Realtime Subscriptions
  // ============================================

  static RealtimeChannel? _assignmentsChannel;
  static final List<void Function(Map<String, dynamic>)> _assignmentListeners = [];

  /// Add a listener for assignment changes
  /// Returns an ID to use when removing the listener
  static void addAssignmentListener(void Function(Map<String, dynamic>) listener) {
    _assignmentListeners.add(listener);

    // Initialize channel if not already done
    if (_assignmentsChannel == null && currentUser != null) {
      _initAssignmentsChannel();
    }
  }

  /// Remove a listener for assignment changes
  static void removeAssignmentListener(void Function(Map<String, dynamic>) listener) {
    _assignmentListeners.remove(listener);

    // Cleanup channel if no more listeners
    if (_assignmentListeners.isEmpty && _assignmentsChannel != null) {
      client.removeChannel(_assignmentsChannel!);
      _assignmentsChannel = null;
    }
  }

  /// Initialize the realtime channel for assignments
  static void _initAssignmentsChannel() {
    // Capture userId to avoid race condition if user logs out during setup
    final userId = currentUser?.id;
    if (userId == null) return;

    try {
      _assignmentsChannel = client
          .channel('assignments-realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'assignments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'student_id',
              value: userId,
            ),
            callback: (payload) {
              final newAssignment = payload.newRecord;
              // Copy list to avoid concurrent modification
              final listeners = List.from(_assignmentListeners);
              for (final listener in listeners) {
                listener(newAssignment);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'assignments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'student_id',
              value: userId,
            ),
            callback: (payload) {
              final updatedAssignment = payload.newRecord;
              // Copy list to avoid concurrent modification
              final listeners = List.from(_assignmentListeners);
              for (final listener in listeners) {
                listener(updatedAssignment);
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Failed to initialize realtime channel: $e');
    }
  }

  /// Legacy method - kept for compatibility
  @Deprecated('Use addAssignmentListener() instead')
  static void subscribeToAssignments({
    void Function(Map<String, dynamic>)? onNewAssignment,
  }) {
    if (onNewAssignment != null) {
      addAssignmentListener(onNewAssignment);
    }
  }

  /// Legacy method - kept for compatibility
  @Deprecated('Use removeAssignmentListener() instead')
  static void unsubscribeFromAssignments() {
    _cleanupRealtimeChannel();
  }

  // ============================================
  // SOCIAL - Friends, Activity, Notifications
  // ============================================

  /// Get friends list (accepted friendships)
  static Future<List<Map<String, dynamic>>> getFriends() async {
    if (currentUser == null) return [];

    final response = await client
        .from('friendships')
        .select('*, friend:profiles!friendships_friend_id_fkey(*)')
        .eq('user_id', currentUser!.id)
        .eq('status', 'accepted');

    final reverseResponse = await client
        .from('friendships')
        .select('*, friend:profiles!friendships_user_id_fkey(*)')
        .eq('friend_id', currentUser!.id)
        .eq('status', 'accepted');

    return [
      ...List<Map<String, dynamic>>.from(response),
      ...List<Map<String, dynamic>>.from(reverseResponse),
    ];
  }

  /// Get pending friend requests received
  static Future<List<Map<String, dynamic>>> getPendingFriendRequests() async {
    if (currentUser == null) return [];

    final response = await client
        .from('friendships')
        .select('*, sender:profiles!friendships_user_id_fkey(*)')
        .eq('friend_id', currentUser!.id)
        .eq('status', 'pending');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Send a friend request
  static Future<void> sendFriendRequest(String friendId) async {
    if (currentUser == null) throw Exception('Non authentifié');

    await client.from('friendships').insert({
      'user_id': currentUser!.id,
      'friend_id': friendId,
      'status': 'pending',
    });
  }

  /// Accept a friend request
  static Future<void> acceptFriendRequest(String friendshipId) async {
    await client
        .from('friendships')
        .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', friendshipId);
  }

  /// Get activity feed (own + friends)
  static Future<List<Map<String, dynamic>>> getActivityFeed({int limit = 20}) async {
    if (currentUser == null) return [];

    // Get friend IDs
    final friends = await getFriends();
    final friendIds = friends
        .map((f) => f['friend']?['id'] as String?)
        .where((id) => id != null)
        .toList();

    // Include own ID
    final userIds = [currentUser!.id, ...friendIds];

    final response = await client
        .from('activity_feed')
        .select('*, user:profiles(*)')
        .inFilter('user_id', userIds)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create activity (workout completed, PR, etc.)
  static Future<void> createActivity({
    required String activityType,
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUser == null) return;

    await client.from('activity_feed').insert({
      'user_id': currentUser!.id,
      'activity_type': activityType,
      'title': title,
      'description': description,
      'metadata': metadata ?? {},
    });
  }

  /// Get notifications
  static Future<List<Map<String, dynamic>>> getNotifications({bool unreadOnly = false}) async {
    if (currentUser == null) return [];

    List<dynamic> response;
    if (unreadOnly) {
      response = await client
          .from('notifications')
          .select()
          .eq('user_id', currentUser!.id)
          .isFilter('read_at', null)
          .order('created_at', ascending: false)
          .limit(50);
    } else {
      response = await client
          .from('notifications')
          .select()
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false)
          .limit(50);
    }

    return List<Map<String, dynamic>>.from(response);
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  /// Get unread notifications count
  static Future<int> getUnreadNotificationsCount() async {
    if (currentUser == null) return 0;

    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', currentUser!.id)
        .isFilter('read_at', null);

    return (response as List).length;
  }

  // ============================================
  // Challenges
  // ============================================

  /// Get all challenges for the current user (created by or participating in)
  static Future<List<Map<String, dynamic>>> getChallenges() async {
    if (currentUser == null) return [];

    try {
      // Get challenges where user is creator or participant
      final response = await client
          .from('challenges')
          .select()
          .or('creator_id.eq.${currentUser!.id},participants.cs.["${currentUser!.id}"]')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching challenges: $e');
      return [];
    }
  }

  /// Create a new challenge
  static Future<Map<String, dynamic>> createChallenge({
    required String title,
    required String exerciseName,
    required String type, // 'weight', 'reps', 'time', 'custom'
    required double targetValue,
    required String unit,
    DateTime? deadline,
    required List<String> participantIds,
  }) async {
    if (currentUser == null) throw Exception('Non authentifié');

    final profile = await getCurrentProfile();
    final creatorName = profile?['full_name'] ?? 'Utilisateur';

    // Build initial participants list including creator
    final participants = [
      {
        'id': currentUser!.id,
        'name': creatorName,
        'avatar_url': profile?['avatar_url'] ?? '',
        'current_value': 0.0,
        'has_completed': false,
      },
      ...participantIds.map((id) => {
        'id': id,
        'current_value': 0.0,
        'has_completed': false,
      }),
    ];

    final response = await client
        .from('challenges')
        .insert({
          'creator_id': currentUser!.id,
          'creator_name': creatorName,
          'title': title,
          'exercise_name': exerciseName,
          'type': type,
          'target_value': targetValue,
          'unit': unit,
          'deadline': deadline?.toIso8601String(),
          'status': 'active',
          'participants': participants,
        })
        .select()
        .single();

    // Create notifications for invited participants
    for (final participantId in participantIds) {
      await client.from('notifications').insert({
        'user_id': participantId,
        'type': 'challenge_invite',
        'title': 'Nouveau défi !',
        'body': '$creatorName t\'a invité au défi "$title"',
        'data': {'challenge_id': response['id']},
      });
    }

    return response;
  }

  /// Join an existing challenge
  static Future<void> joinChallenge(String challengeId) async {
    if (currentUser == null) throw Exception('Non authentifié');

    final profile = await getCurrentProfile();

    // Get current challenge
    final challenge = await client
        .from('challenges')
        .select()
        .eq('id', challengeId)
        .single();

    final participants = List<Map<String, dynamic>>.from(
      challenge['participants'] ?? [],
    );

    // Check if already participating
    final alreadyIn = participants.any((p) => p['id'] == currentUser!.id);
    if (alreadyIn) return;

    // Add user to participants
    participants.add({
      'id': currentUser!.id,
      'name': profile?['full_name'] ?? 'Utilisateur',
      'avatar_url': profile?['avatar_url'] ?? '',
      'current_value': 0.0,
      'has_completed': false,
    });

    await client
        .from('challenges')
        .update({'participants': participants})
        .eq('id', challengeId);
  }

  // ============================================
  // Health Metrics
  // ============================================

  /// Save daily health metrics to Supabase
  static Future<void> saveHealthMetrics({
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
    final userId = currentUser?.id;
    if (userId == null) return;

    await client.from('health_metrics').upsert({
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
  static Future<List<Map<String, dynamic>>> getHealthMetrics({
    required String startDate,
    required String endDate,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('health_metrics')
        .select()
        .eq('user_id', userId)
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date');
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // Activity Respects
  // ============================================

  /// Toggle respect on an activity (like/unlike)
  static Future<Map<String, dynamic>> toggleRespect(String activityId) async {
    final response = await client.rpc('toggle_respect', params: {
      'p_activity_id': activityId,
    });
    return Map<String, dynamic>.from(response);
  }

  /// Check if current user has given respect to activities
  static Future<Set<String>> getMyRespects(List<String> activityIds) async {
    final userId = currentUser?.id;
    if (userId == null || activityIds.isEmpty) return {};

    final response = await client
        .from('activity_respects')
        .select('activity_id')
        .eq('user_id', userId)
        .inFilter('activity_id', activityIds);

    return Set<String>.from(
      (response as List).map((r) => r['activity_id'] as String),
    );
  }

  // ============================================
  // Achievements
  // ============================================

  /// Get all achievement definitions with user's unlock status
  static Future<List<Map<String, dynamic>>> getAchievements() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final definitions = await client
        .from('achievement_definitions')
        .select()
        .order('sort_order');

    final unlocked = await client
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
  static Future<List<String>> checkAchievements() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final result = await client.rpc('check_achievements', params: {
      'p_user_id': userId,
    });

    return List<String>.from(result['new_achievements'] ?? []);
  }

  /// Update challenge progress for current user
  static Future<void> updateChallengeProgress(
    String challengeId,
    double newValue,
  ) async {
    if (currentUser == null) return;

    final challenge = await client
        .from('challenges')
        .select()
        .eq('id', challengeId)
        .single();

    final participants = List<Map<String, dynamic>>.from(
      challenge['participants'] ?? [],
    );
    final targetValue = (challenge['target_value'] as num?)?.toDouble() ?? 0;

    // Update user's progress
    for (int i = 0; i < participants.length; i++) {
      if (participants[i]['id'] == currentUser!.id) {
        participants[i]['current_value'] = newValue;
        if (newValue >= targetValue) {
          participants[i]['has_completed'] = true;
          participants[i]['completed_at'] = DateTime.now().toIso8601String();
        }
        break;
      }
    }

    await client
        .from('challenges')
        .update({'participants': participants})
        .eq('id', challengeId);
  }

  /// Get active challenges where current user participates
  static Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    if (currentUser == null) return [];
    try {
      final response = await client
          .from('challenges')
          .select()
          .eq('status', 'active');

      // Filter to challenges where user is a participant
      return List<Map<String, dynamic>>.from(response).where((c) {
        final participants = c['participants'] as List? ?? [];
        return participants.any((p) => (p as Map)['id'] == currentUser!.id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching active challenges: $e');
      return [];
    }
  }
}
