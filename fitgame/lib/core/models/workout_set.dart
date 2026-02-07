/// Core domain model for a workout set
class WorkoutSet {
  final int targetReps;
  final double targetWeight;
  final bool isWarmup;
  final bool isMaxReps;
  int actualReps;
  double actualWeight;
  bool isCompleted;

  WorkoutSet({
    required this.targetReps,
    required this.targetWeight,
    this.isWarmup = false,
    this.isMaxReps = false,
  })  : actualReps = isMaxReps ? 0 : targetReps,
        actualWeight = targetWeight,
        isCompleted = false;
}
