import 'workout_set.dart';

/// Core domain model for an exercise in a workout
class Exercise {
  final String name;
  final String muscle;
  final List<WorkoutSet> sets;
  final int restSeconds;
  final double previousBest;
  final String notes;
  final String progressionRule;
  final Map<String, dynamic>? progression;
  final String weightType; // 'kg', 'bodyweight', 'bodyweight_plus'
  int? transitionSeconds; // Time to move from previous exercise (minus rest)

  Exercise({
    required this.name,
    required this.muscle,
    required this.sets,
    required this.restSeconds,
    this.previousBest = 0,
    this.notes = '',
    this.progressionRule = '',
    this.progression,
    this.weightType = 'kg',
  });
}
