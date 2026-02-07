/// Core domain model for a workout set
class WorkoutSet {
  final int targetReps;
  final double targetWeight;
  final bool isWarmup;
  final bool isMaxReps;
  int actualReps;
  double actualWeight;
  bool isCompleted;
  int? actualDurationSeconds; // Time from set active to validation
  int? actualRestSeconds; // Actual rest taken (including extensions)

  WorkoutSet({
    required this.targetReps,
    required this.targetWeight,
    this.isWarmup = false,
    this.isMaxReps = false,
  })  : actualReps = isMaxReps ? 0 : targetReps,
        actualWeight = targetWeight,
        isCompleted = false;
}
