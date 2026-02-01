/// Model for a workout activity post in the social feed
class Activity {
  final String id;
  final String userName;
  final String userAvatarUrl;
  final String workoutName;
  final String muscles;
  final int durationMinutes;
  final double volumeKg;
  final int exerciseCount;
  final DateTime timestamp;
  final List<ExerciseSummary> topExercises;
  final PersonalRecord? pr;
  final int respectCount;
  final bool hasGivenRespect;
  final List<String> respectGivers;

  const Activity({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.workoutName,
    required this.muscles,
    required this.durationMinutes,
    required this.volumeKg,
    required this.exerciseCount,
    required this.timestamp,
    required this.topExercises,
    this.pr,
    required this.respectCount,
    required this.hasGivenRespect,
    required this.respectGivers,
  });
}

/// Summary of an exercise for display in activity card
class ExerciseSummary {
  final String name;
  final String shortName;
  final double weightKg;
  final int reps;

  const ExerciseSummary({
    required this.name,
    required this.shortName,
    required this.weightKg,
    required this.reps,
  });

  String get display {
    final weightStr = weightKg >= 0 ? '${weightKg.toStringAsFixed(weightKg.truncateToDouble() == weightKg ? 0 : 1)}kg' : '${weightKg.abs().toStringAsFixed(0)}kg';
    final prefix = weightKg >= 0 ? '' : '+';
    return '$prefix$weightStr × $reps';
  }
}

/// Personal record achieved during a workout
class PersonalRecord {
  final String exerciseName;
  final double value;
  final double gain;
  final String unit;

  const PersonalRecord({
    required this.exerciseName,
    required this.value,
    required this.gain,
    this.unit = 'kg',
  });
}
