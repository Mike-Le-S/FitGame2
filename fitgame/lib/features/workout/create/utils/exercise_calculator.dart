/// Utility class for calculating exercise sets based on training mode
class ExerciseCalculator {
  ExerciseCalculator._();

  /// Get display label for training mode
  static String getModeLabel(String mode) {
    switch (mode) {
      case 'rpt':
        return 'RPT';
      case 'pyramid':
        return 'Pyramidal';
      case 'dropset':
        return 'Dropset';
      default:
        return 'Classique';
    }
  }

  /// Get warmup description based on training mode
  static String getWarmupDescription(String mode) {
    switch (mode) {
      case 'rpt':
        return '2 séries: 60%×8, 80%×5';
      case 'classic':
        return '1 série: 50%×10';
      case 'dropset':
        return '1 série: 50%×10';
      default:
        return 'Adapté au mode';
    }
  }

  /// Calculate preview sets based on training mode
  static List<Map<String, dynamic>> calculateSets({
    required String mode,
    required int sets,
    required int reps,
    required bool warmup,
  }) {
    List<Map<String, dynamic>> result = [];

    // Add warmup sets
    if (warmup) {
      if (mode == 'rpt') {
        result.add({'number': 0, 'weight': '60%', 'reps': 8, 'warmup': true});
        result.add({'number': 0, 'weight': '80%', 'reps': 5, 'warmup': true});
      } else {
        result.add({'number': 0, 'weight': '50%', 'reps': 10, 'warmup': true});
      }
    }

    // Add working sets based on mode
    switch (mode) {
      case 'classic':
        for (int i = 0; i < sets; i++) {
          result.add({
            'number': i + 1,
            'weight': '100%',
            'reps': reps,
            'warmup': false,
          });
        }
        break;

      case 'rpt':
        for (int i = 0; i < sets; i++) {
          final weightPercent = 100 - (i * 10);
          final currentReps = reps - (i * 2);
          result.add({
            'number': i + 1,
            'weight': '$weightPercent%',
            'reps': currentReps > 1 ? currentReps : 1,
            'warmup': false,
          });
        }
        break;

      case 'pyramid':
        // Ascending phase
        final ascending = (sets / 2).ceil();
        for (int i = 0; i < ascending; i++) {
          final weightPercent = 70 + (i * 10);
          final currentReps = reps - (i * 2);
          result.add({
            'number': i + 1,
            'weight': '$weightPercent%',
            'reps': currentReps > 1 ? currentReps : 1,
            'warmup': i == 0, // First set is warmup
          });
        }
        // Descending phase
        final descending = sets - ascending;
        for (int i = 0; i < descending; i++) {
          final weightPercent = 100 - ((i + 1) * 10);
          final currentReps = reps + ((i + 1) * 2);
          result.add({
            'number': ascending + i + 1,
            'weight': '$weightPercent%',
            'reps': currentReps,
            'warmup': false,
          });
        }
        break;

      case 'dropset':
        // Main set
        result.add({
          'number': 1,
          'weight': '100%',
          'reps': reps,
          'warmup': false,
        });
        // Drops
        result.add({
          'number': 2,
          'weight': '80%',
          'reps': reps + 2,
          'warmup': false,
        });
        result.add({
          'number': 3,
          'weight': '60%',
          'reps': reps + 4,
          'warmup': false,
        });
        result.add({
          'number': 4,
          'weight': '40%',
          'reps': reps + 6,
          'warmup': false,
        });
        break;
    }

    return result;
  }

  /// Generate custom sets from a mode template with absolute weights
  static List<Map<String, dynamic>> generateCustomSets({
    required String mode,
    required int sets,
    required int reps,
    required double baseWeight,
  }) {
    final result = <Map<String, dynamic>>[];

    switch (mode) {
      case 'classic':
        for (int i = 0; i < sets; i++) {
          result.add({
            'reps': reps,
            'weight': baseWeight,
            'isWarmup': false,
          });
        }
        break;

      case 'rpt':
        for (int i = 0; i < sets; i++) {
          final weight = (baseWeight * (1.0 - i * 0.1)).roundToDouble();
          final currentReps = reps + (i * 2);
          result.add({
            'reps': currentReps,
            'weight': weight > 0 ? weight : 0,
            'isWarmup': false,
          });
        }
        break;

      case 'pyramid':
        final ascending = (sets / 2).ceil();
        for (int i = 0; i < ascending; i++) {
          final weight = (baseWeight * (0.7 + i * 0.1)).roundToDouble();
          final currentReps = reps - (i * 2);
          result.add({
            'reps': currentReps > 1 ? currentReps : 1,
            'weight': weight,
            'isWarmup': i == 0,
          });
        }
        final descending = sets - ascending;
        for (int i = 0; i < descending; i++) {
          final weight = (baseWeight * (1.0 - (i + 1) * 0.1)).roundToDouble();
          final currentReps = reps + ((i + 1) * 2);
          result.add({
            'reps': currentReps,
            'weight': weight > 0 ? weight : 0,
            'isWarmup': false,
          });
        }
        break;

      case 'dropset':
        result.add({'reps': reps, 'weight': baseWeight, 'isWarmup': false});
        result.add({'reps': reps + 2, 'weight': (baseWeight * 0.8).roundToDouble(), 'isWarmup': false});
        result.add({'reps': reps + 4, 'weight': (baseWeight * 0.6).roundToDouble(), 'isWarmup': false});
        result.add({'reps': reps + 6, 'weight': (baseWeight * 0.4).roundToDouble(), 'isWarmup': false});
        break;

      default:
        for (int i = 0; i < sets; i++) {
          result.add({
            'reps': reps,
            'weight': baseWeight,
            'isWarmup': false,
          });
        }
    }

    return result;
  }

  /// Estimate workout duration in minutes
  static int estimateDuration(List<Map<String, dynamic>> exercises, {int avgRestSeconds = 90}) {
    int totalSets = 0;
    for (final ex in exercises) {
      final customSets = ex['customSets'] as List?;
      if (customSets != null) {
        totalSets += customSets.length;
      } else {
        totalSets += (ex['sets'] as int? ?? 3);
        if (ex['warmup'] == true || ex['warmupEnabled'] == true) totalSets += 1;
      }
    }
    // ~45s per set + rest between sets
    final workTime = totalSets * 45;
    final restTime = (totalSets - exercises.length).clamp(0, 999) * avgRestSeconds;
    return ((workTime + restTime) / 60).ceil();
  }
}
