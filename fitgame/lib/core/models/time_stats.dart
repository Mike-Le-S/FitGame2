/// Time breakdown stats for a completed workout session
class TimeStats {
  final int totalDuration; // Total workout seconds
  final int tensionTime; // Σ actualDurationSeconds (all sets)
  final int totalRestTime; // Σ actualRestSeconds (all sets)
  final int totalTransitionTime; // Σ transitionSeconds (all exercises)
  final double avgTransition; // Average transition seconds
  final double efficiencyScore; // tensionTime / totalDuration × 100

  const TimeStats({
    required this.totalDuration,
    required this.tensionTime,
    required this.totalRestTime,
    required this.totalTransitionTime,
    required this.avgTransition,
    required this.efficiencyScore,
  });
}
