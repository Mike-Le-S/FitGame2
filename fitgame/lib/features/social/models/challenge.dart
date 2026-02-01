/// Model for a challenge between friends
class Challenge {
  final String id;
  final String title;
  final String exerciseName;
  final ChallengeType type;
  final double targetValue;
  final String unit;
  final DateTime? deadline;
  final ChallengeStatus status;
  final String creatorId;
  final String creatorName;
  final List<ChallengeParticipant> participants;
  final DateTime createdAt;

  const Challenge({
    required this.id,
    required this.title,
    required this.exerciseName,
    required this.type,
    required this.targetValue,
    required this.unit,
    this.deadline,
    required this.status,
    required this.creatorId,
    required this.creatorName,
    required this.participants,
    required this.createdAt,
  });

  int get daysRemaining {
    if (deadline == null) return -1;
    return deadline!.difference(DateTime.now()).inDays;
  }

  ChallengeParticipant? get leader {
    if (participants.isEmpty) return null;
    final sorted = List<ChallengeParticipant>.from(participants)
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));
    return sorted.first;
  }
}

/// Type of challenge
enum ChallengeType {
  weight,   // First to reach X kg
  reps,     // Max reps at X kg
  time,     // Best time for X reps
  custom,   // Free description
}

/// Status of a challenge
enum ChallengeStatus {
  active,
  completed,
  expired,
}

/// A participant in a challenge
class ChallengeParticipant {
  final String id;
  final String name;
  final String avatarUrl;
  final double currentValue;
  final bool hasCompleted;
  final DateTime? completedAt;

  const ChallengeParticipant({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.currentValue,
    required this.hasCompleted,
    this.completedAt,
  });

  double progressPercent(double target) {
    if (target <= 0) return 0;
    return (currentValue / target).clamp(0.0, 1.0);
  }
}
