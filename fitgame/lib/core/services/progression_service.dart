import '../models/exercise.dart';
import '../models/workout_set.dart';

class ProgressionService {
  ProgressionService._();

  /// Check if progression conditions are met after completing a set
  /// Returns a suggestion message or null
  static String? checkProgression(Exercise exercise, WorkoutSet completedSet) {
    final progression = exercise.progression;
    if (progression == null) return null;

    final type = progression['type'] as String?;
    if (type != 'threshold') return null;

    final repThreshold = (progression['repThreshold'] as num?)?.toInt();
    final weightIncrement = (progression['weightIncrement'] as num?)?.toDouble();
    if (repThreshold == null || weightIncrement == null) return null;

    if (completedSet.actualReps >= repThreshold && !completedSet.isWarmup) {
      final newWeight = completedSet.actualWeight + weightIncrement;
      return 'Tu peux passer a ${newWeight.toStringAsFixed(newWeight == newWeight.toInt().toDouble() ? 0 : 1)} kg la prochaine fois !';
    }

    return null;
  }
}
