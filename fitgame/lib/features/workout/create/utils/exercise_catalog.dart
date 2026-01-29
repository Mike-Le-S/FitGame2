/// Static exercise catalog data for program creation
class ExerciseCatalog {
  ExerciseCatalog._();

  /// Available muscle groups
  static const List<String> muscleGroups = [
    'Pectoraux',
    'Dos',
    'Épaules',
    'Biceps',
    'Triceps',
    'Jambes',
    'Abdos',
  ];

  /// Default exercise catalog with training mode and warmup config
  static const List<Map<String, dynamic>> exercises = [
    {'name': 'Développé couché', 'muscle': 'Pectoraux', 'sets': 4, 'reps': 10, 'mode': 'classic', 'warmup': false},
    {'name': 'Développé incliné', 'muscle': 'Pectoraux', 'sets': 3, 'reps': 12, 'mode': 'classic', 'warmup': false},
    {'name': 'Écarté poulie', 'muscle': 'Pectoraux', 'sets': 3, 'reps': 15, 'mode': 'classic', 'warmup': false},
    {'name': 'Squat barre', 'muscle': 'Jambes', 'sets': 4, 'reps': 8, 'mode': 'classic', 'warmup': false},
    {'name': 'Presse jambes', 'muscle': 'Jambes', 'sets': 4, 'reps': 12, 'mode': 'classic', 'warmup': false},
    {'name': 'Leg curl', 'muscle': 'Jambes', 'sets': 3, 'reps': 12, 'mode': 'classic', 'warmup': false},
    {'name': 'Leg extension', 'muscle': 'Jambes', 'sets': 3, 'reps': 15, 'mode': 'classic', 'warmup': false},
    {'name': 'Soulevé de terre', 'muscle': 'Dos', 'sets': 4, 'reps': 6, 'mode': 'classic', 'warmup': false},
    {'name': 'Rowing barre', 'muscle': 'Dos', 'sets': 4, 'reps': 10, 'mode': 'classic', 'warmup': false},
    {'name': 'Tractions', 'muscle': 'Dos', 'sets': 4, 'reps': 8, 'mode': 'classic', 'warmup': false},
    {'name': 'Tirage vertical', 'muscle': 'Dos', 'sets': 3, 'reps': 12, 'mode': 'classic', 'warmup': false},
    {'name': 'Développé militaire', 'muscle': 'Épaules', 'sets': 3, 'reps': 12, 'mode': 'classic', 'warmup': false},
    {'name': 'Élévations latérales', 'muscle': 'Épaules', 'sets': 3, 'reps': 15, 'mode': 'classic', 'warmup': false},
    {'name': 'Oiseau', 'muscle': 'Épaules', 'sets': 3, 'reps': 15, 'mode': 'classic', 'warmup': false},
    {'name': 'Curl biceps', 'muscle': 'Biceps', 'sets': 3, 'reps': 12, 'mode': 'classic', 'warmup': false},
    {'name': 'Curl marteau', 'muscle': 'Biceps', 'sets': 3, 'reps': 12, 'mode': 'classic', 'warmup': false},
    {'name': 'Extension triceps', 'muscle': 'Triceps', 'sets': 3, 'reps': 12, 'mode': 'classic', 'warmup': false},
    {'name': 'Dips', 'muscle': 'Triceps', 'sets': 3, 'reps': 10, 'mode': 'classic', 'warmup': false},
    {'name': 'Crunch', 'muscle': 'Abdos', 'sets': 3, 'reps': 20, 'mode': 'classic', 'warmup': false},
    {'name': 'Planche', 'muscle': 'Abdos', 'sets': 3, 'reps': 60, 'mode': 'classic', 'warmup': false},
  ];

  /// Get exercises by muscle group
  static List<Map<String, dynamic>> getByMuscle(String muscle) {
    return exercises.where((e) => e['muscle'] == muscle).toList();
  }
}
