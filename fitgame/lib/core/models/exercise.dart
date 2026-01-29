import 'workout_set.dart';

/// Core domain model for an exercise in a workout
class Exercise {
  final String name;
  final String muscle;
  final List<WorkoutSet> sets;
  final int restSeconds;
  final double previousBest;

  Exercise({
    required this.name,
    required this.muscle,
    required this.sets,
    required this.restSeconds,
    this.previousBest = 0,
  });
}
