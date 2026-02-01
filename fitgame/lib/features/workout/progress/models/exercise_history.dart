/// Modèle pour une entrée d'historique de progression
class ExerciseProgressEntry {
  final DateTime date;
  final double weight;
  final int reps;
  final bool isPR;
  final String? sessionName;

  const ExerciseProgressEntry({
    required this.date,
    required this.weight,
    required this.reps,
    this.isPR = false,
    this.sessionName,
  });
}

/// Modèle pour l'historique complet d'un exercice
class ExerciseHistory {
  final String exerciseName;
  final String muscleGroup;
  final double currentPR;
  final List<ExerciseProgressEntry> entries;

  const ExerciseHistory({
    required this.exerciseName,
    required this.muscleGroup,
    required this.currentPR,
    required this.entries,
  });

  /// Calcule le pourcentage de progression depuis le début
  double get progressPercentage {
    if (entries.isEmpty) return 0;
    final firstWeight = entries.first.weight;
    if (firstWeight == 0) return 0;
    return ((currentPR - firstWeight) / firstWeight) * 100;
  }

  /// Calcule le gain en kg depuis le début
  double get totalGain {
    if (entries.isEmpty) return 0;
    return currentPR - entries.first.weight;
  }

  /// Nombre de semaines de progression
  int get weeksOfProgress {
    if (entries.length < 2) return 0;
    final firstDate = entries.first.date;
    final lastDate = entries.last.date;
    return (lastDate.difference(firstDate).inDays / 7).ceil();
  }

  /// Retourne uniquement les entrées qui sont des PRs
  List<ExerciseProgressEntry> get prEntries {
    return entries.where((e) => e.isPR).toList();
  }
}

/// Mock data pour démonstration
class MockExerciseData {
  static final benchPressHistory = ExerciseHistory(
    exerciseName: 'Bench Press',
    muscleGroup: 'Pectoraux',
    currentPR: 100.0,
    entries: [
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 42)),
        weight: 90,
        reps: 5,
        isPR: true,
        sessionName: 'Push Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 35)),
        weight: 87.5,
        reps: 6,
        isPR: false,
        sessionName: 'Push Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 28)),
        weight: 92.5,
        reps: 6,
        isPR: true,
        sessionName: 'Push Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 21)),
        weight: 90,
        reps: 7,
        isPR: false,
        sessionName: 'Push Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 14)),
        weight: 95,
        reps: 5,
        isPR: true,
        sessionName: 'Push Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 7)),
        weight: 97.5,
        reps: 4,
        isPR: false,
        sessionName: 'Push Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now(),
        weight: 100,
        reps: 5,
        isPR: true,
        sessionName: 'Push Day',
      ),
    ],
  );

  static final squatHistory = ExerciseHistory(
    exerciseName: 'Squat',
    muscleGroup: 'Quadriceps',
    currentPR: 140.0,
    entries: [
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 42)),
        weight: 120,
        reps: 5,
        isPR: true,
        sessionName: 'Leg Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 35)),
        weight: 125,
        reps: 5,
        isPR: true,
        sessionName: 'Leg Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 28)),
        weight: 122.5,
        reps: 6,
        isPR: false,
        sessionName: 'Leg Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 21)),
        weight: 130,
        reps: 5,
        isPR: true,
        sessionName: 'Leg Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 14)),
        weight: 135,
        reps: 4,
        isPR: true,
        sessionName: 'Leg Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 7)),
        weight: 132.5,
        reps: 6,
        isPR: false,
        sessionName: 'Leg Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now(),
        weight: 140,
        reps: 5,
        isPR: true,
        sessionName: 'Leg Day',
      ),
    ],
  );

  static final deadliftHistory = ExerciseHistory(
    exerciseName: 'Deadlift',
    muscleGroup: 'Dos',
    currentPR: 160.0,
    entries: [
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 42)),
        weight: 140,
        reps: 5,
        isPR: true,
        sessionName: 'Pull Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 35)),
        weight: 145,
        reps: 5,
        isPR: true,
        sessionName: 'Pull Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 28)),
        weight: 150,
        reps: 4,
        isPR: true,
        sessionName: 'Pull Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 21)),
        weight: 147.5,
        reps: 5,
        isPR: false,
        sessionName: 'Pull Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 14)),
        weight: 155,
        reps: 4,
        isPR: true,
        sessionName: 'Pull Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now().subtract(const Duration(days: 7)),
        weight: 157.5,
        reps: 3,
        isPR: true,
        sessionName: 'Pull Day',
      ),
      ExerciseProgressEntry(
        date: DateTime.now(),
        weight: 160,
        reps: 5,
        isPR: true,
        sessionName: 'Pull Day',
      ),
    ],
  );

  /// Récupère l'historique d'un exercice par son nom
  static ExerciseHistory? getHistory(String exerciseName) {
    switch (exerciseName.toLowerCase()) {
      case 'bench press':
        return benchPressHistory;
      case 'squat':
        return squatHistory;
      case 'deadlift':
        return deadliftHistory;
      default:
        return benchPressHistory; // Par défaut pour la démo
    }
  }
}
