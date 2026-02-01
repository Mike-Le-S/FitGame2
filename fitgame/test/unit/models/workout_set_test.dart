import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/core/models/workout_set.dart';

void main() {
  group('WorkoutSet', () {
    group('Constructor', () {
      test('creates WorkoutSet with required parameters', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        expect(set.targetReps, 10);
        expect(set.targetWeight, 50.0);
        expect(set.isWarmup, false);
      });

      test('creates WorkoutSet with isWarmup true', () {
        final set = WorkoutSet(
          targetReps: 15,
          targetWeight: 20.0,
          isWarmup: true,
        );

        expect(set.isWarmup, true);
      });

      test('creates WorkoutSet with isWarmup false explicitly', () {
        final set = WorkoutSet(
          targetReps: 8,
          targetWeight: 60.0,
          isWarmup: false,
        );

        expect(set.isWarmup, false);
      });
    });

    group('Default Values', () {
      test('actualReps defaults to targetReps', () {
        final set = WorkoutSet(
          targetReps: 12,
          targetWeight: 40.0,
        );

        expect(set.actualReps, 12);
        expect(set.actualReps, set.targetReps);
      });

      test('actualWeight defaults to targetWeight', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 55.5,
        );

        expect(set.actualWeight, 55.5);
        expect(set.actualWeight, set.targetWeight);
      });

      test('isCompleted defaults to false', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        expect(set.isCompleted, false);
      });

      test('isWarmup defaults to false', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        expect(set.isWarmup, false);
      });
    });

    group('Mutable Properties', () {
      test('actualReps can be modified', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        set.actualReps = 12;
        expect(set.actualReps, 12);

        set.actualReps = 8;
        expect(set.actualReps, 8);
      });

      test('actualWeight can be modified', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        set.actualWeight = 55.0;
        expect(set.actualWeight, 55.0);

        set.actualWeight = 45.5;
        expect(set.actualWeight, 45.5);
      });

      test('isCompleted can be modified', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        expect(set.isCompleted, false);

        set.isCompleted = true;
        expect(set.isCompleted, true);

        set.isCompleted = false;
        expect(set.isCompleted, false);
      });
    });

    group('Immutable Properties', () {
      test('targetReps is final', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        expect(set.targetReps, 10);
        // Cannot reassign - compile error if attempted
      });

      test('targetWeight is final', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        expect(set.targetWeight, 50.0);
        // Cannot reassign - compile error if attempted
      });

      test('isWarmup is final', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
          isWarmup: true,
        );

        expect(set.isWarmup, true);
        // Cannot reassign - compile error if attempted
      });
    });

    group('Edge Cases', () {
      test('handles zero targetReps', () {
        final set = WorkoutSet(
          targetReps: 0,
          targetWeight: 50.0,
        );

        expect(set.targetReps, 0);
        expect(set.actualReps, 0);
      });

      test('handles zero targetWeight (bodyweight)', () {
        final set = WorkoutSet(
          targetReps: 20,
          targetWeight: 0.0,
        );

        expect(set.targetWeight, 0.0);
        expect(set.actualWeight, 0.0);
      });

      test('handles decimal targetWeight', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 32.5,
        );

        expect(set.targetWeight, 32.5);
      });

      test('handles large targetReps', () {
        final set = WorkoutSet(
          targetReps: 100,
          targetWeight: 10.0,
        );

        expect(set.targetReps, 100);
      });

      test('handles large targetWeight', () {
        final set = WorkoutSet(
          targetReps: 1,
          targetWeight: 500.0,
        );

        expect(set.targetWeight, 500.0);
      });

      test('handles very small decimal weight', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 0.25,
        );

        expect(set.targetWeight, 0.25);
      });

      test('handles negative reps (edge case)', () {
        final set = WorkoutSet(
          targetReps: -5,
          targetWeight: 50.0,
        );

        expect(set.targetReps, -5);
        expect(set.actualReps, -5);
      });

      test('handles negative weight (edge case)', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: -10.0,
        );

        expect(set.targetWeight, -10.0);
        expect(set.actualWeight, -10.0);
      });
    });

    group('Workout Tracking Scenarios', () {
      test('tracks completed set with same values', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        set.isCompleted = true;

        expect(set.targetReps, 10);
        expect(set.actualReps, 10);
        expect(set.targetWeight, 50.0);
        expect(set.actualWeight, 50.0);
        expect(set.isCompleted, true);
      });

      test('tracks set with higher actual reps (PR)', () {
        final set = WorkoutSet(
          targetReps: 8,
          targetWeight: 60.0,
        );

        set.actualReps = 10;
        set.isCompleted = true;

        expect(set.actualReps, 10);
        expect(set.actualReps > set.targetReps, true);
      });

      test('tracks set with lower actual reps (failed)', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 60.0,
        );

        set.actualReps = 7;
        set.isCompleted = true;

        expect(set.actualReps, 7);
        expect(set.actualReps < set.targetReps, true);
      });

      test('tracks set with higher actual weight', () {
        final set = WorkoutSet(
          targetReps: 8,
          targetWeight: 60.0,
        );

        set.actualWeight = 65.0;
        set.isCompleted = true;

        expect(set.actualWeight, 65.0);
        expect(set.actualWeight > set.targetWeight, true);
      });

      test('tracks set with lower actual weight', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 60.0,
        );

        set.actualWeight = 55.0;
        set.isCompleted = true;

        expect(set.actualWeight, 55.0);
        expect(set.actualWeight < set.targetWeight, true);
      });

      test('tracks warmup set completion', () {
        final set = WorkoutSet(
          targetReps: 15,
          targetWeight: 20.0,
          isWarmup: true,
        );

        set.isCompleted = true;

        expect(set.isWarmup, true);
        expect(set.isCompleted, true);
      });

      test('tracks partial completion then full', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        // First attempt - failed
        set.actualReps = 6;
        set.isCompleted = false;

        expect(set.actualReps, 6);
        expect(set.isCompleted, false);

        // Retry - completed
        set.actualReps = 10;
        set.isCompleted = true;

        expect(set.actualReps, 10);
        expect(set.isCompleted, true);
      });
    });

    group('Weight and Rep Calculations', () {
      test('volume calculation for single set', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        set.isCompleted = true;

        final targetVolume = set.targetReps * set.targetWeight;
        final actualVolume = set.actualReps * set.actualWeight;

        expect(targetVolume, 500.0);
        expect(actualVolume, 500.0);
      });

      test('volume calculation with different actual values', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 50.0,
        );

        set.actualReps = 8;
        set.actualWeight = 55.0;
        set.isCompleted = true;

        final targetVolume = set.targetReps * set.targetWeight;
        final actualVolume = set.actualReps * set.actualWeight;

        expect(targetVolume, 500.0);
        expect(actualVolume, 440.0);
      });

      test('comparing target vs actual performance', () {
        final set = WorkoutSet(
          targetReps: 10,
          targetWeight: 60.0,
        );

        set.actualReps = 12;
        set.actualWeight = 60.0;
        set.isCompleted = true;

        final targetVolume = set.targetReps * set.targetWeight;
        final actualVolume = set.actualReps * set.actualWeight;

        expect(actualVolume > targetVolume, true);
        expect(actualVolume - targetVolume, 120.0);
      });
    });

    group('Multiple Sets', () {
      test('creates list of sets with progressive weight', () {
        final sets = [
          WorkoutSet(targetReps: 12, targetWeight: 40.0),
          WorkoutSet(targetReps: 10, targetWeight: 45.0),
          WorkoutSet(targetReps: 8, targetWeight: 50.0),
          WorkoutSet(targetReps: 6, targetWeight: 55.0),
        ];

        expect(sets.length, 4);
        expect(sets[0].targetWeight, 40.0);
        expect(sets[3].targetWeight, 55.0);
      });

      test('creates warmup and working sets', () {
        final warmup = WorkoutSet(
          targetReps: 15,
          targetWeight: 20.0,
          isWarmup: true,
        );

        final workingSets = List.generate(
          3,
          (_) => WorkoutSet(targetReps: 10, targetWeight: 50.0),
        );

        final allSets = [warmup, ...workingSets];

        expect(allSets.length, 4);
        expect(allSets.where((s) => s.isWarmup).length, 1);
        expect(allSets.where((s) => !s.isWarmup).length, 3);
      });

      test('tracks completion of all sets', () {
        final sets = List.generate(
          5,
          (_) => WorkoutSet(targetReps: 10, targetWeight: 50.0),
        );

        // Complete all sets
        for (final set in sets) {
          set.isCompleted = true;
        }

        expect(sets.every((s) => s.isCompleted), true);
      });

      test('counts incomplete sets', () {
        final sets = List.generate(
          5,
          (_) => WorkoutSet(targetReps: 10, targetWeight: 50.0),
        );

        // Complete only first 3
        for (int i = 0; i < 3; i++) {
          sets[i].isCompleted = true;
        }

        final completedCount = sets.where((s) => s.isCompleted).length;
        final remainingCount = sets.where((s) => !s.isCompleted).length;

        expect(completedCount, 3);
        expect(remainingCount, 2);
      });
    });
  });
}
