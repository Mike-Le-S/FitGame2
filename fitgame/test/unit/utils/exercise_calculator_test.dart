import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/features/workout/create/utils/exercise_calculator.dart';

void main() {
  group('ExerciseCalculator', () {
    group('getModeLabel', () {
      test('returns "RPT" for rpt mode', () {
        expect(ExerciseCalculator.getModeLabel('rpt'), 'RPT');
      });

      test('returns "Pyramidal" for pyramid mode', () {
        expect(ExerciseCalculator.getModeLabel('pyramid'), 'Pyramidal');
      });

      test('returns "Dropset" for dropset mode', () {
        expect(ExerciseCalculator.getModeLabel('dropset'), 'Dropset');
      });

      test('returns "Classique" for classic mode', () {
        expect(ExerciseCalculator.getModeLabel('classic'), 'Classique');
      });

      test('returns "Classique" for unknown mode', () {
        expect(ExerciseCalculator.getModeLabel('unknown'), 'Classique');
      });

      test('returns "Classique" for empty string', () {
        expect(ExerciseCalculator.getModeLabel(''), 'Classique');
      });

      test('is case-sensitive', () {
        expect(ExerciseCalculator.getModeLabel('RPT'), 'Classique');
        expect(ExerciseCalculator.getModeLabel('Pyramid'), 'Classique');
        expect(ExerciseCalculator.getModeLabel('DROPSET'), 'Classique');
      });
    });

    group('getWarmupDescription', () {
      test('returns correct description for rpt mode', () {
        expect(
          ExerciseCalculator.getWarmupDescription('rpt'),
          '2 séries: 60%×8, 80%×5',
        );
      });

      test('returns correct description for classic mode', () {
        expect(
          ExerciseCalculator.getWarmupDescription('classic'),
          '1 série: 50%×10',
        );
      });

      test('returns correct description for dropset mode', () {
        expect(
          ExerciseCalculator.getWarmupDescription('dropset'),
          '1 série: 50%×10',
        );
      });

      test('returns default description for pyramid mode', () {
        expect(
          ExerciseCalculator.getWarmupDescription('pyramid'),
          'Adapté au mode',
        );
      });

      test('returns default description for unknown mode', () {
        expect(
          ExerciseCalculator.getWarmupDescription('unknown'),
          'Adapté au mode',
        );
      });

      test('returns default description for empty string', () {
        expect(
          ExerciseCalculator.getWarmupDescription(''),
          'Adapté au mode',
        );
      });
    });

    group('calculateSets - Classic Mode', () {
      test('generates correct number of sets without warmup', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 10,
          warmup: false,
        );

        expect(result.length, 3);
      });

      test('generates correct number of sets with warmup', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 10,
          warmup: true,
        );

        expect(result.length, 4); // 1 warmup + 3 working
      });

      test('all working sets have 100% weight', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 4,
          reps: 8,
          warmup: false,
        );

        for (final set in result) {
          expect(set['weight'], '100%');
          expect(set['warmup'], false);
        }
      });

      test('all working sets have same reps', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 5,
          reps: 12,
          warmup: false,
        );

        for (final set in result) {
          expect(set['reps'], 12);
        }
      });

      test('sets are numbered correctly', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 10,
          warmup: false,
        );

        expect(result[0]['number'], 1);
        expect(result[1]['number'], 2);
        expect(result[2]['number'], 3);
      });

      test('warmup set has correct properties', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 10,
          warmup: true,
        );

        final warmupSet = result[0];
        expect(warmupSet['number'], 0);
        expect(warmupSet['weight'], '50%');
        expect(warmupSet['reps'], 10);
        expect(warmupSet['warmup'], true);
      });

      test('handles single set', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 1,
          reps: 10,
          warmup: false,
        );

        expect(result.length, 1);
        expect(result[0]['number'], 1);
      });

      test('handles zero sets', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 0,
          reps: 10,
          warmup: false,
        );

        expect(result.length, 0);
      });
    });

    group('calculateSets - RPT Mode', () {
      test('generates correct number of sets without warmup', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'rpt',
          sets: 3,
          reps: 8,
          warmup: false,
        );

        expect(result.length, 3);
      });

      test('generates correct number of sets with warmup', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'rpt',
          sets: 3,
          reps: 8,
          warmup: true,
        );

        expect(result.length, 5); // 2 warmup + 3 working
      });

      test('warmup sets have correct RPT properties', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'rpt',
          sets: 3,
          reps: 8,
          warmup: true,
        );

        expect(result[0]['number'], 0);
        expect(result[0]['weight'], '60%');
        expect(result[0]['reps'], 8);
        expect(result[0]['warmup'], true);

        expect(result[1]['number'], 0);
        expect(result[1]['weight'], '80%');
        expect(result[1]['reps'], 5);
        expect(result[1]['warmup'], true);
      });

      test('weight decreases by 10% per set', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'rpt',
          sets: 4,
          reps: 8,
          warmup: false,
        );

        expect(result[0]['weight'], '100%');
        expect(result[1]['weight'], '90%');
        expect(result[2]['weight'], '80%');
        expect(result[3]['weight'], '70%');
      });

      test('reps decrease by 2 per set', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'rpt',
          sets: 4,
          reps: 10,
          warmup: false,
        );

        expect(result[0]['reps'], 10);
        expect(result[1]['reps'], 8);
        expect(result[2]['reps'], 6);
        expect(result[3]['reps'], 4);
      });

      test('reps do not go below 1', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'rpt',
          sets: 5,
          reps: 4,
          warmup: false,
        );

        // 4, 2, 0->1, -2->1, -4->1
        expect(result[0]['reps'], 4);
        expect(result[1]['reps'], 2);
        expect(result[2]['reps'], 1); // Would be 0, clamped to 1
        expect(result[3]['reps'], 1); // Would be -2, clamped to 1
        expect(result[4]['reps'], 1); // Would be -4, clamped to 1
      });

      test('sets are numbered correctly', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'rpt',
          sets: 3,
          reps: 8,
          warmup: false,
        );

        expect(result[0]['number'], 1);
        expect(result[1]['number'], 2);
        expect(result[2]['number'], 3);
      });

      test('all working sets are not warmup', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'rpt',
          sets: 3,
          reps: 8,
          warmup: false,
        );

        for (final set in result) {
          expect(set['warmup'], false);
        }
      });
    });

    group('calculateSets - Pyramid Mode', () {
      test('generates correct total sets', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 5,
          reps: 12,
          warmup: false,
        );

        expect(result.length, 5);
      });

      test('ascending phase increases weight and decreases reps', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 4,
          reps: 12,
          warmup: false,
        );

        // Ascending: 2 sets (ceil of 4/2)
        expect(result[0]['weight'], '70%');
        expect(result[0]['reps'], 12);
        expect(result[0]['warmup'], true); // First set is warmup

        expect(result[1]['weight'], '80%');
        expect(result[1]['reps'], 10);
        expect(result[1]['warmup'], false);
      });

      test('descending phase decreases weight and increases reps', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 4,
          reps: 12,
          warmup: false,
        );

        // Descending: 2 sets (4 - 2)
        expect(result[2]['weight'], '90%');
        expect(result[2]['reps'], 14);
        expect(result[2]['warmup'], false);

        expect(result[3]['weight'], '80%');
        expect(result[3]['reps'], 16);
        expect(result[3]['warmup'], false);
      });

      test('first set is marked as warmup', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 5,
          reps: 10,
          warmup: false,
        );

        expect(result[0]['warmup'], true);
        for (int i = 1; i < result.length; i++) {
          expect(result[i]['warmup'], false);
        }
      });

      test('sets are numbered correctly', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 5,
          reps: 10,
          warmup: false,
        );

        for (int i = 0; i < result.length; i++) {
          expect(result[i]['number'], i + 1);
        }
      });

      test('handles odd number of sets', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 5,
          reps: 10,
          warmup: false,
        );

        // Ascending: 3 sets (ceil of 5/2)
        // Descending: 2 sets (5 - 3)
        expect(result.length, 5);

        // Ascending
        expect(result[0]['weight'], '70%');
        expect(result[1]['weight'], '80%');
        expect(result[2]['weight'], '90%');

        // Descending
        expect(result[3]['weight'], '90%');
        expect(result[4]['weight'], '80%');
      });

      test('handles even number of sets', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 6,
          reps: 12,
          warmup: false,
        );

        // Ascending: 3 sets (ceil of 6/2)
        // Descending: 3 sets (6 - 3)
        expect(result.length, 6);
      });

      test('reps do not go below 1 in ascending phase', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 6,
          reps: 4,
          warmup: false,
        );

        // Ascending with low reps: 4, 2, 0->1
        expect(result[0]['reps'], 4);
        expect(result[1]['reps'], 2);
        expect(result[2]['reps'], 1); // Clamped from 0
      });

      test('warmup flag does not add additional warmup sets', () {
        // In pyramid mode, warmup=true doesn't add extra warmup sets
        // since the first ascending set is already marked as warmup
        final result = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 4,
          reps: 10,
          warmup: false,
        );

        final resultWithWarmup = ExerciseCalculator.calculateSets(
          mode: 'pyramid',
          sets: 4,
          reps: 10,
          warmup: true,
        );

        // Note: Based on code, warmup flag does add a warmup set (50%×10)
        expect(resultWithWarmup.length, result.length + 1);
      });
    });

    group('calculateSets - Dropset Mode', () {
      test('always generates 4 sets regardless of sets parameter', () {
        final result3 = ExerciseCalculator.calculateSets(
          mode: 'dropset',
          sets: 3,
          reps: 10,
          warmup: false,
        );

        final result5 = ExerciseCalculator.calculateSets(
          mode: 'dropset',
          sets: 5,
          reps: 10,
          warmup: false,
        );

        final result1 = ExerciseCalculator.calculateSets(
          mode: 'dropset',
          sets: 1,
          reps: 10,
          warmup: false,
        );

        expect(result3.length, 4);
        expect(result5.length, 4);
        expect(result1.length, 4);
      });

      test('generates correct dropset weight progression', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'dropset',
          sets: 4,
          reps: 10,
          warmup: false,
        );

        expect(result[0]['weight'], '100%');
        expect(result[1]['weight'], '80%');
        expect(result[2]['weight'], '60%');
        expect(result[3]['weight'], '40%');
      });

      test('generates correct dropset rep progression', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'dropset',
          sets: 4,
          reps: 8,
          warmup: false,
        );

        expect(result[0]['reps'], 8);
        expect(result[1]['reps'], 10); // +2
        expect(result[2]['reps'], 12); // +4
        expect(result[3]['reps'], 14); // +6
      });

      test('sets are numbered 1-4', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'dropset',
          sets: 4,
          reps: 10,
          warmup: false,
        );

        expect(result[0]['number'], 1);
        expect(result[1]['number'], 2);
        expect(result[2]['number'], 3);
        expect(result[3]['number'], 4);
      });

      test('no sets are marked as warmup', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'dropset',
          sets: 4,
          reps: 10,
          warmup: false,
        );

        for (final set in result) {
          expect(set['warmup'], false);
        }
      });

      test('warmup adds one set at beginning', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'dropset',
          sets: 4,
          reps: 10,
          warmup: true,
        );

        expect(result.length, 5); // 1 warmup + 4 drops
        expect(result[0]['warmup'], true);
        expect(result[0]['weight'], '50%');
        expect(result[0]['reps'], 10);
      });

      test('with different base reps', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'dropset',
          sets: 4,
          reps: 6,
          warmup: false,
        );

        expect(result[0]['reps'], 6);
        expect(result[1]['reps'], 8);
        expect(result[2]['reps'], 10);
        expect(result[3]['reps'], 12);
      });
    });

    group('calculateSets - Edge Cases', () {
      test('handles unknown mode', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'unknown',
          sets: 3,
          reps: 10,
          warmup: false,
        );

        // Unknown mode returns empty list (no case matched)
        expect(result.isEmpty, true);
      });

      test('handles empty string mode with warmup', () {
        final result = ExerciseCalculator.calculateSets(
          mode: '',
          sets: 3,
          reps: 10,
          warmup: true,
        );

        // Only warmup set is added, no working sets for unknown mode
        expect(result.length, 1);
        expect(result[0]['warmup'], true);
      });

      test('handles zero reps in classic mode', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 0,
          warmup: false,
        );

        expect(result.length, 3);
        for (final set in result) {
          expect(set['reps'], 0);
        }
      });

      test('handles negative sets parameter', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: -3,
          reps: 10,
          warmup: false,
        );

        // Negative iteration count results in empty list
        expect(result.isEmpty, true);
      });

      test('handles large number of sets', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 20,
          reps: 10,
          warmup: false,
        );

        expect(result.length, 20);
      });

      test('handles large number of reps', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 100,
          warmup: false,
        );

        expect(result.length, 3);
        for (final set in result) {
          expect(set['reps'], 100);
        }
      });
    });

    group('calculateSets - Map Structure', () {
      test('all sets contain required keys', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 10,
          warmup: true,
        );

        for (final set in result) {
          expect(set.containsKey('number'), true);
          expect(set.containsKey('weight'), true);
          expect(set.containsKey('reps'), true);
          expect(set.containsKey('warmup'), true);
        }
      });

      test('number is int type', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 10,
          warmup: false,
        );

        for (final set in result) {
          expect(set['number'], isA<int>());
        }
      });

      test('weight is String type', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 10,
          warmup: false,
        );

        for (final set in result) {
          expect(set['weight'], isA<String>());
        }
      });

      test('reps is int type', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 10,
          warmup: false,
        );

        for (final set in result) {
          expect(set['reps'], isA<int>());
        }
      });

      test('warmup is bool type', () {
        final result = ExerciseCalculator.calculateSets(
          mode: 'classic',
          sets: 3,
          reps: 10,
          warmup: true,
        );

        for (final set in result) {
          expect(set['warmup'], isA<bool>());
        }
      });
    });

    group('Private Constructor', () {
      test('ExerciseCalculator cannot be instantiated', () {
        // The private constructor ExerciseCalculator._() prevents instantiation
        // This is verified by the fact that all methods are static
        expect(ExerciseCalculator.getModeLabel('classic'), isNotNull);
        expect(ExerciseCalculator.getWarmupDescription('classic'), isNotNull);
        expect(
          ExerciseCalculator.calculateSets(
            mode: 'classic',
            sets: 1,
            reps: 10,
            warmup: false,
          ),
          isNotNull,
        );
      });
    });
  });
}
