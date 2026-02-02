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

  /// Crée un historique vide
  factory ExerciseHistory.empty(String exerciseName) {
    return ExerciseHistory(
      exerciseName: exerciseName,
      muscleGroup: '',
      currentPR: 0,
      entries: [],
    );
  }
}
