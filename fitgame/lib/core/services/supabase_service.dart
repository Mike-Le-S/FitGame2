import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
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

    // Create profile after signup
    if (response.user != null) {
      await client.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'role': role,
      });
    }

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

  // Sign out
  static Future<void> signOut() async {
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
      await client.rpc('increment_total_sessions', params: {
        'user_id': currentUser!.id,
      }).catchError((_) {
        // Fallback: update directly
        client
            .from('profiles')
            .update({'total_sessions': client.rpc('get_total_sessions')})
            .eq('id', currentUser!.id);
      });
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
}
