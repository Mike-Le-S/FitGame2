import 'dart:io';
import 'package:excel/excel.dart';

class ExcelImportService {
  ExcelImportService._();

  /// Parse an Excel file and return a program structure
  static Map<String, dynamic> parseExcelFile(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final days = <Map<String, dynamic>>[];
    int dayIndex = 0;

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      if (sheet.rows.isEmpty) continue;

      // Try to detect if this sheet is a training day
      final exercises = <Map<String, dynamic>>[];
      String? currentDayName;

      for (int r = 0; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        // Check for day header (bold or pattern like "LUNDI — PUSH 1")
        final firstCell = row[0]?.value?.toString() ?? '';
        if (_isDayHeader(firstCell)) {
          // Save previous day if it had exercises
          if (currentDayName != null && exercises.isNotEmpty) {
            days.add(
                _buildDay(dayIndex++, currentDayName, List.from(exercises)));
            exercises.clear();
          }
          currentDayName = firstCell;
          continue;
        }

        // Try to parse as exercise row
        final exercise = _parseExerciseRow(row);
        if (exercise != null) {
          exercises.add(exercise);
        }
      }

      // Save last day from sheet
      if (exercises.isNotEmpty) {
        final dayName = currentDayName ?? sheetName;
        days.add(_buildDay(dayIndex++, dayName, exercises));
      }
    }

    return {
      'name': 'Programme importé',
      'days': days,
    };
  }

  static bool _isDayHeader(String text) {
    final upper = text.toUpperCase();
    return upper.contains('LUNDI') ||
        upper.contains('MARDI') ||
        upper.contains('MERCREDI') ||
        upper.contains('JEUDI') ||
        upper.contains('VENDREDI') ||
        upper.contains('SAMEDI') ||
        upper.contains('DIMANCHE') ||
        upper.contains('PUSH') ||
        upper.contains('PULL') ||
        upper.contains('LEGS') ||
        upper.contains('JOUR ');
  }

  static Map<String, dynamic> _buildDay(
      int index, String name, List<Map<String, dynamic>> exercises) {
    // Detect day of week from name
    final dayOfWeek = _detectDayOfWeek(name);
    return {
      'id': 'day-$index',
      'name': name.trim(),
      'dayOfWeek': dayOfWeek,
      'isRestDay': false,
      'exercises': exercises.asMap().entries.map((e) {
        final ex = e.value;
        ex['id'] = 'ex-import-$index-${e.key}';
        return ex;
      }).toList(),
      'supersets': <List<int>>[],
    };
  }

  static int _detectDayOfWeek(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('LUNDI')) return 1;
    if (upper.contains('MARDI')) return 2;
    if (upper.contains('MERCREDI')) return 3;
    if (upper.contains('JEUDI')) return 4;
    if (upper.contains('VENDREDI')) return 5;
    if (upper.contains('SAMEDI')) return 6;
    if (upper.contains('DIMANCHE')) return 7;
    return 1; // Default
  }

  static Map<String, dynamic>? _parseExerciseRow(List<Data?> row) {
    if (row.length < 2) return null;

    // Skip header rows
    final firstVal = row[0]?.value?.toString() ?? '';
    if (firstVal.isEmpty ||
        firstVal == '#' ||
        firstVal.toUpperCase() == 'N°') {
      return null;
    }

    // Try to get exercise name from column 1 or 2
    String? name;
    String? setsInfo;
    String? notes;
    String? progression;

    if (row.length >= 2) name = row[1]?.value?.toString();
    if (row.length >= 3) setsInfo = row[2]?.value?.toString();
    if (row.length >= 4) notes = row[3]?.value?.toString();
    if (row.length >= 5) progression = row[4]?.value?.toString();

    if (name == null || name.trim().isEmpty) return null;

    // Parse sets info
    final customSets = _parseSetsInfo(setsInfo ?? '');
    final muscle = _guessMuscleName(name);

    // Detect weight type
    final nameLower = name.toLowerCase();
    String weightType = 'kg';
    if (nameLower.contains('pdc') ||
        nameLower.contains('poids du corps') ||
        nameLower.contains('bodyweight')) {
      weightType = 'bodyweight';
    }

    final exercise = <String, dynamic>{
      'name': name.trim(),
      'muscle': muscle,
      'mode': customSets.length > 1 ? 'custom' : 'classic',
      'sets': customSets.length,
      'reps': customSets.isNotEmpty ? customSets.first['reps'] ?? 10 : 10,
      'warmupEnabled': customSets.any((s) => s['isWarmup'] == true),
      'weightType': weightType,
    };

    if (customSets.isNotEmpty) {
      exercise['customSets'] = customSets;
    }

    if (notes != null && notes.trim().isNotEmpty) {
      exercise['notes'] = notes.trim();
    }

    if (progression != null && progression.trim().isNotEmpty) {
      exercise['progressionRule'] = progression.trim();
      // Try to parse structured progression
      final prog = _parseProgressionRule(progression);
      if (prog != null) exercise['progression'] = prog;
    }

    return exercise;
  }

  static List<Map<String, dynamic>> _parseSetsInfo(String text) {
    if (text.isEmpty) {
      return [
        {'reps': 10, 'weight': 0.0, 'isWarmup': false}
      ];
    }

    final sets = <Map<String, dynamic>>[];

    // Pattern: "1×15 @40kg → 1×8 @65kg → ..."
    final arrowParts = text.split('→');
    if (arrowParts.length > 1) {
      for (final part in arrowParts) {
        final set = _parseSingleSet(part.trim());
        if (set != null) sets.add(set);
      }
      if (sets.isNotEmpty) return sets;
    }

    // Pattern: "3x10 @80kg" or "3×10 80kg"
    final match = RegExp(r'(\d+)\s*[x×]\s*(\d+)').firstMatch(text);
    if (match != null) {
      final count = int.parse(match.group(1)!);
      final reps = int.parse(match.group(2)!);
      final weightMatch =
          RegExp(r'@?\s*(\d+(?:\.\d+)?)\s*kg').firstMatch(text);
      final weight =
          weightMatch != null ? double.parse(weightMatch.group(1)!) : 0.0;

      for (int i = 0; i < count; i++) {
        sets.add({'reps': reps, 'weight': weight, 'isWarmup': false});
      }
      return sets;
    }

    // Just a number = number of sets
    final simpleMatch =
        RegExp(r'^(\d+)\s*séries?').firstMatch(text.toLowerCase());
    if (simpleMatch != null) {
      final count = int.parse(simpleMatch.group(1)!);
      for (int i = 0; i < count; i++) {
        sets.add({'reps': 10, 'weight': 0.0, 'isWarmup': false});
      }
      return sets;
    }

    return [
      {'reps': 10, 'weight': 0.0, 'isWarmup': false}
    ];
  }

  static Map<String, dynamic>? _parseSingleSet(String text) {
    // Pattern: "1×15 @40kg"
    final match = RegExp(r'(\d+)\s*[x×]\s*(\d+)').firstMatch(text);
    if (match == null) return null;

    final reps = int.parse(match.group(2)!);
    final weightMatch =
        RegExp(r'@?\s*(\d+(?:\.\d+)?)\s*kg').firstMatch(text);
    final weight =
        weightMatch != null ? double.parse(weightMatch.group(1)!) : 0.0;

    // Detect warmup (first set with low weight or "échauffement")
    final isWarmup = text.toLowerCase().contains('échauf') ||
        text.toLowerCase().contains('warmup');

    return {'reps': reps, 'weight': weight, 'isWarmup': isWarmup};
  }

  static String _guessMuscleName(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    if (lower.contains('pec') ||
        lower.contains('bench') ||
        lower.contains('développé') ||
        lower.contains('couché')) {
      return 'Pectoraux';
    }
    if (lower.contains('dos') ||
        lower.contains('tirage') ||
        lower.contains('rowing') ||
        lower.contains('traction')) {
      return 'Dos';
    }
    if (lower.contains('épaule') ||
        lower.contains('delto') ||
        lower.contains('latéral')) {
      return 'Épaules';
    }
    if (lower.contains('bicep') || lower.contains('curl')) {
      return 'Biceps';
    }
    if (lower.contains('tricep') ||
        lower.contains('extension') ||
        lower.contains('dip')) {
      return 'Triceps';
    }
    if (lower.contains('jambe') ||
        lower.contains('squat') ||
        lower.contains('leg') ||
        lower.contains('cuisse')) {
      return 'Jambes';
    }
    if (lower.contains('mollet') || lower.contains('calf')) {
      return 'Mollets';
    }
    if (lower.contains('abdo') ||
        lower.contains('crunch') ||
        lower.contains('gainage')) {
      return 'Abdos';
    }
    if (lower.contains('fessier') ||
        lower.contains('hip thrust') ||
        lower.contains('glute')) {
      return 'Fessiers';
    }
    return 'Autre';
  }

  static Map<String, dynamic>? _parseProgressionRule(String text) {
    // Try to match "quand X reps @Ykg → passe à Zkg"
    final match = RegExp(
            r'(\d+)\s*reps?\s*@\s*(\d+(?:\.\d+)?)\s*kg.*?(\d+(?:\.\d+)?)\s*kg')
        .firstMatch(text.toLowerCase());
    if (match != null) {
      final repThreshold = int.parse(match.group(1)!);
      final currentWeight = double.parse(match.group(2)!);
      final nextWeight = double.parse(match.group(3)!);
      return {
        'type': 'threshold',
        'repThreshold': repThreshold,
        'weightIncrement': nextWeight - currentWeight,
      };
    }
    return null;
  }
}
