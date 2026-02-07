import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class ExcelImportService {
  ExcelImportService._();

  /// Parse an Excel file and return a program structure
  static Map<String, dynamic> parseExcelFile(String filePath, {Uint8List? fileBytes}) {
    debugPrint('ExcelImport: START parseExcelFile, hasBytes=${fileBytes != null}');
    final bytes = fileBytes ?? File(filePath).readAsBytesSync();
    debugPrint('ExcelImport: bytes loaded, length=${bytes.length}');

    final decoder = SpreadsheetDecoder.decodeBytes(bytes);
    debugPrint('ExcelImport: decoded OK, sheets=${decoder.tables.keys.toList()}');

    final days = <Map<String, dynamic>>[];
    int dayIndex = 0;

    for (final sheetName in decoder.tables.keys) {
      final table = decoder.tables[sheetName];
      if (table == null || table.rows.isEmpty) {
        debugPrint('ExcelImport: sheet "$sheetName" is null or empty, skipping');
        continue;
      }
      debugPrint('ExcelImport: processing sheet "$sheetName" with ${table.rows.length} rows');

      final exercises = <Map<String, dynamic>>[];
      String? currentDayName;

      for (int r = 0; r < table.rows.length; r++) {
        try {
          final row = table.rows[r];
          if (row.isEmpty || row.every((c) => c == null)) continue;

          final firstCell = _cellStr(row, 0);
          if (_isDayHeader(firstCell)) {
            debugPrint('ExcelImport: row $r is day header: "$firstCell"');
            if (currentDayName != null && exercises.isNotEmpty) {
              days.add(_buildDay(dayIndex++, currentDayName, List.from(exercises)));
              exercises.clear();
            }
            currentDayName = firstCell;
            continue;
          }

          final exercise = _parseExerciseRow(row);
          if (exercise != null) {
            debugPrint('ExcelImport: row $r parsed exercise: ${exercise['name']}');
            exercises.add(exercise);
          }
        } catch (e, stack) {
          debugPrint('ExcelImport: ERROR row $r in $sheetName: $e');
          debugPrint('ExcelImport: stack: $stack');
        }
      }

      if (exercises.isNotEmpty) {
        final dayName = currentDayName ?? sheetName;
        days.add(_buildDay(dayIndex++, dayName, exercises));
      }
    }

    debugPrint('ExcelImport: DONE, parsed ${days.length} days');
    return {
      'name': 'Programme importé',
      'days': days,
    };
  }

  /// Safely extract string from a row cell by index
  static String _cellStr(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    final val = row[index];
    if (val == null) return '';
    return val.toString().trim();
  }

  static bool _isDayHeader(String text) {
    if (text.isEmpty) return false;
    final upper = text.toUpperCase();
    return upper.contains('LUNDI') ||
        upper.contains('MARDI') ||
        upper.contains('MERCREDI') ||
        upper.contains('JEUDI') ||
        upper.contains('VENDREDI') ||
        upper.contains('SAMEDI') ||
        upper.contains('DIMANCHE') ||
        (upper.contains('PUSH') && !upper.contains('PROGRAMME')) ||
        (upper.contains('PULL') && !upper.contains('PROGRAMME')) ||
        (upper.contains('LEGS') && !upper.contains('PROGRAMME')) ||
        upper.contains('JOUR ');
  }

  static Map<String, dynamic> _buildDay(
      int index, String name, List<Map<String, dynamic>> exercises) {
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
    return 1;
  }

  static Map<String, dynamic>? _parseExerciseRow(List<dynamic> row) {
    if (row.length < 2) return null;

    final firstVal = _cellStr(row, 0);
    // Skip empty rows, headers, summary rows, title rows
    final upperFirst = firstVal.toUpperCase();
    if (firstVal.isEmpty ||
        firstVal == '#' ||
        upperFirst == 'N°' ||
        firstVal.startsWith('≈') ||
        firstVal.startsWith('Muscles') ||
        firstVal.startsWith('Objectif') ||
        upperFirst.startsWith('PROGRAMME') ||
        upperFirst.startsWith('RAPPEL')) {
      return null;
    }

    // First cell should be a number (exercise index) or exercise name
    final isNumbered = int.tryParse(firstVal) != null;

    String? name;
    String? setsInfo;
    String? notes;
    String? progression;

    if (isNumbered) {
      // Numbered format: #, Name, Sets, Notes, Progression
      name = _cellStr(row, 1);
      setsInfo = _cellStr(row, 2);
      notes = _cellStr(row, 3);
      progression = _cellStr(row, 4);
    } else {
      // Name in first column
      name = firstVal;
      setsInfo = _cellStr(row, 1);
      notes = _cellStr(row, 2);
      progression = _cellStr(row, 3);
    }

    if (name.isEmpty) return null;

    final customSets = _parseSetsInfo(setsInfo);
    final muscle = _guessMuscleName(name);

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
      'reps': customSets.isNotEmpty
          ? (customSets.first['reps'] as int?) ?? 10
          : 10,
      'warmupEnabled': customSets.any((s) => s['isWarmup'] == true),
      'weightType': weightType,
    };

    if (customSets.isNotEmpty) {
      exercise['customSets'] = customSets;
    }

    if (notes.isNotEmpty) {
      exercise['notes'] = notes;
    }

    if (progression.isNotEmpty) {
      exercise['progressionRule'] = progression;
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
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        final set = _parseSingleSet(trimmed);
        if (set != null) sets.add(set);
      }
      if (sets.isNotEmpty) return sets;
    }

    // Pattern: "3×6-8 @30/20/10kg" (different weights per set)
    final slashWeightMatch =
        RegExp(r'(\d+)\s*[x×]\s*(\d+)(?:-(\d+))?\s*@?\s*([\d.]+(?:/[\d.]+)+)\s*kg')
            .firstMatch(text);
    if (slashWeightMatch != null) {
      final repsLow = int.tryParse(slashWeightMatch.group(2) ?? '') ?? 10;
      final weightsStr = slashWeightMatch.group(4) ?? '';
      final weights = weightsStr.split('/').map((w) => double.tryParse(w) ?? 0.0).toList();
      for (final w in weights) {
        sets.add({'reps': repsLow, 'weight': w, 'isWarmup': false});
      }
      if (sets.isNotEmpty) return sets;
    }

    // Pattern: "3x10 @80kg" or "3×10 80kg"
    final match = RegExp(r'(\d+)\s*[x×]\s*(\d+)').firstMatch(text);
    if (match != null) {
      final count = int.tryParse(match.group(1) ?? '') ?? 3;
      final reps = int.tryParse(match.group(2) ?? '') ?? 10;
      final weightMatch =
          RegExp(r'@?\s*(\d+(?:\.\d+)?)\s*kg').firstMatch(text);
      final weight = weightMatch != null
          ? (double.tryParse(weightMatch.group(1) ?? '') ?? 0.0)
          : 0.0;

      for (int i = 0; i < count; i++) {
        sets.add({'reps': reps, 'weight': weight, 'isWarmup': false});
      }
      return sets;
    }

    // Pattern: "N séries"
    final simpleMatch =
        RegExp(r'^(\d+)\s*s[eé]ries?').firstMatch(text.toLowerCase());
    if (simpleMatch != null) {
      final count = int.tryParse(simpleMatch.group(1) ?? '') ?? 3;
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

    final reps = int.tryParse(match.group(2) ?? '') ?? 10;
    final weightMatch =
        RegExp(r'@?\s*(\d+(?:\.\d+)?)\s*kg').firstMatch(text);
    final weight = weightMatch != null
        ? (double.tryParse(weightMatch.group(1) ?? '') ?? 0.0)
        : 0.0;

    final isWarmup = text.toLowerCase().contains('échauf') ||
        text.toLowerCase().contains('warmup');

    return {'reps': reps, 'weight': weight, 'isWarmup': isWarmup};
  }

  static String _guessMuscleName(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    if (lower.contains('pec') ||
        lower.contains('bench') ||
        lower.contains('développé couché') ||
        lower.contains('dip')) {
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
        lower.contains('latéral') ||
        lower.contains('développé') ||
        lower.contains('face pull') ||
        lower.contains('oiseau')) {
      return 'Épaules';
    }
    if (lower.contains('bicep') || lower.contains('curl')) {
      return 'Biceps';
    }
    if (lower.contains('tricep') || lower.contains('extension corde')) {
      return 'Triceps';
    }
    if (lower.contains('jambe') ||
        lower.contains('squat') ||
        lower.contains('leg') ||
        lower.contains('cuisse') ||
        lower.contains('presse') ||
        lower.contains('fente') ||
        lower.contains('ischios') ||
        lower.contains('ischio')) {
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
    final match = RegExp(
            r'(\d+)\s*reps?\s*@\s*(\d+(?:\.\d+)?)\s*kg.*?(\d+(?:\.\d+)?)\s*kg')
        .firstMatch(text.toLowerCase());
    if (match == null) return null;

    final g1 = match.group(1);
    final g2 = match.group(2);
    final g3 = match.group(3);
    if (g1 == null || g2 == null || g3 == null) return null;

    final repThreshold = int.tryParse(g1);
    final currentWeight = double.tryParse(g2);
    final nextWeight = double.tryParse(g3);
    if (repThreshold == null || currentWeight == null || nextWeight == null) {
      return null;
    }

    return {
      'type': 'threshold',
      'repThreshold': repThreshold,
      'weightIncrement': nextWeight - currentWeight,
    };
  }
}
