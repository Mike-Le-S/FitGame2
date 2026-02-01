import 'package:flutter/material.dart';

/// Wraps a widget with MaterialApp for testing
Widget wrapWithMaterialApp(Widget widget) {
  return MaterialApp(
    home: Scaffold(body: widget),
    theme: ThemeData.dark(),
  );
}

/// Wraps a widget with MaterialApp and a Scaffold
Widget wrapWithScaffold(Widget widget) {
  return MaterialApp(
    home: widget,
    theme: ThemeData.dark(),
  );
}

/// Creates a test environment file content
const String testEnvContent = '''
SUPABASE_URL=https://test.supabase.co
SUPABASE_ANON_KEY=test-anon-key
''';

/// Test user data
const Map<String, dynamic> testUserProfile = {
  'id': 'test-user-id',
  'email': 'test@fitgame.test',
  'full_name': 'Test User',
  'role': 'athlete',
  'coach_id': null,
  'total_sessions': 10,
  'current_streak': 5,
  'weight_unit': 'kg',
  'language': 'fr',
  'notifications_enabled': true,
  'goal': 'maintain',
};

/// Test program data
const Map<String, dynamic> testProgram = {
  'id': 'test-program-id',
  'created_by': 'test-user-id',
  'name': 'Test Program',
  'description': 'A test program',
  'goal': 'strength',
  'duration_weeks': 8,
  'deload_frequency': 4,
  'days': [
    {
      'id': 'day-1',
      'name': 'Push',
      'dayOfWeek': 1,
      'isRestDay': false,
      'exercises': [],
    },
  ],
};

/// Test workout session data
const Map<String, dynamic> testWorkoutSession = {
  'id': 'test-session-id',
  'user_id': 'test-user-id',
  'program_id': 'test-program-id',
  'day_name': 'Push',
  'started_at': '2026-02-01T10:00:00Z',
  'completed_at': '2026-02-01T11:00:00Z',
  'duration_minutes': 60,
  'total_volume_kg': 5000.0,
  'total_sets': 20,
  'exercises': [],
  'personal_records': [],
};

/// Test diet plan data
const Map<String, dynamic> testDietPlan = {
  'id': 'test-diet-id',
  'created_by': 'test-user-id',
  'name': 'Test Diet',
  'goal': 'maintain',
  'training_calories': 2500,
  'rest_calories': 2000,
  'training_macros': {'protein': 180, 'carbs': 280, 'fat': 70},
  'rest_macros': {'protein': 180, 'carbs': 200, 'fat': 65},
  'meals': [],
  'supplements': [],
};
