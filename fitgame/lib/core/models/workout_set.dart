/// Core domain model for a workout set
class WorkoutSet {
  final int targetReps;
  final double targetWeight;
  final bool isWarmup;
  int actualReps;
  double actualWeight;
  bool isCompleted;

  WorkoutSet({
    required this.targetReps,
    required this.targetWeight,
    this.isWarmup = false,
  })  : actualReps = targetReps,
        actualWeight = targetWeight,
        isCompleted = false;
}
