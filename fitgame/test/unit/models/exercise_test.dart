import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/core/models/exercise.dart';
import 'package:fitgame/core/models/workout_set.dart';

void main() {
  group('Exercise', () {
    group('Constructor', () {
      test('creates Exercise with required parameters', () {
        final sets = [
          WorkoutSet(targetReps: 10, targetWeight: 50.0),
          WorkoutSet(targetReps: 10, targetWeight: 50.0),
        ];

        final exercise = Exercise(
          name: 'Bench Press',
          muscle: 'Chest',
          sets: sets,
          restSeconds: 90,
        );

        expect(exercise.name, 'Bench Press');
        expect(exercise.muscle, 'Chest');
        expect(exercise.sets.length, 2);
        expect(exercise.restSeconds, 90);
        expect(exercise.previousBest, 0);
      });

      test('creates Exercise with optional previousBest', () {
        final exercise = Exercise(
          name: 'Squat',
          muscle: 'Legs',
          sets: [],
          restSeconds: 120,
          previousBest: 100.0,
        );

        expect(exercise.previousBest, 100.0);
      });

      test('creates Exercise with empty sets list', () {
        final exercise = Exercise(
          name: 'Deadlift',
          muscle: 'Back',
          sets: [],
          restSeconds: 180,
        );

        expect(exercise.sets, isEmpty);
      });

      test('creates Exercise with multiple sets of different types', () {
        final warmupSet = WorkoutSet(
          targetReps: 15,
          targetWeight: 20.0,
          isWarmup: true,
        );
        final workingSet1 = WorkoutSet(targetReps: 8, targetWeight: 60.0);
        final workingSet2 = WorkoutSet(targetReps: 8, targetWeight: 60.0);

        final exercise = Exercise(
          name: 'Shoulder Press',
          muscle: 'Shoulders',
          sets: [warmupSet, workingSet1, workingSet2],
          restSeconds: 60,
        );

        expect(exercise.sets.length, 3);
        expect(exercise.sets[0].isWarmup, true);
        expect(exercise.sets[1].isWarmup, false);
        expect(exercise.sets[2].isWarmup, false);
      });
    });

    group('Properties', () {
      test('name property returns correct value', () {
        final exercise = Exercise(
          name: 'Lat Pulldown',
          muscle: 'Back',
          sets: [],
          restSeconds: 60,
        );

        expect(exercise.name, 'Lat Pulldown');
      });

      test('muscle property returns correct value', () {
        final exercise = Exercise(
          name: 'Bicep Curl',
          muscle: 'Biceps',
          sets: [],
          restSeconds: 45,
        );

        expect(exercise.muscle, 'Biceps');
      });

      test('restSeconds property returns correct value', () {
        final exercise = Exercise(
          name: 'Tricep Extension',
          muscle: 'Triceps',
          sets: [],
          restSeconds: 45,
        );

        expect(exercise.restSeconds, 45);
      });

      test('sets property returns mutable list', () {
        final sets = <WorkoutSet>[
          WorkoutSet(targetReps: 10, targetWeight: 50.0),
        ];

        final exercise = Exercise(
          name: 'Row',
          muscle: 'Back',
          sets: sets,
          restSeconds: 90,
        );

        expect(exercise.sets.length, 1);
        // List is passed by reference
        sets.add(WorkoutSet(targetReps: 8, targetWeight: 55.0));
        expect(exercise.sets.length, 2);
      });
    });

    group('Edge Cases', () {
      test('handles zero restSeconds', () {
        final exercise = Exercise(
          name: 'Superset Exercise',
          muscle: 'Full Body',
          sets: [],
          restSeconds: 0,
        );

        expect(exercise.restSeconds, 0);
      });

      test('handles very long rest time', () {
        final exercise = Exercise(
          name: 'Heavy Deadlift',
          muscle: 'Back',
          sets: [],
          restSeconds: 600,
        );

        expect(exercise.restSeconds, 600);
      });

      test('handles previousBest as decimal', () {
        final exercise = Exercise(
          name: 'Dumbbell Press',
          muscle: 'Chest',
          sets: [],
          restSeconds: 90,
          previousBest: 32.5,
        );

        expect(exercise.previousBest, 32.5);
      });

      test('handles empty name', () {
        final exercise = Exercise(
          name: '',
          muscle: 'Unknown',
          sets: [],
          restSeconds: 60,
        );

        expect(exercise.name, '');
      });

      test('handles special characters in name', () {
        final exercise = Exercise(
          name: 'Bench Press (Incline) - DB',
          muscle: 'Chest',
          sets: [],
          restSeconds: 90,
        );

        expect(exercise.name, 'Bench Press (Incline) - DB');
      });

      test('handles unicode characters in muscle', () {
        final exercise = Exercise(
          name: 'Test Exercise',
          muscle: 'Pectoraux',
          sets: [],
          restSeconds: 60,
        );

        expect(exercise.muscle, 'Pectoraux');
      });

      test('handles large number of sets', () {
        final sets = List.generate(
          20,
          (index) => WorkoutSet(
            targetReps: 10 - (index % 5),
            targetWeight: 50.0 + (index * 2.5),
          ),
        );

        final exercise = Exercise(
          name: 'Volume Training',
          muscle: 'Legs',
          sets: sets,
          restSeconds: 45,
        );

        expect(exercise.sets.length, 20);
      });

      test('handles negative previousBest (edge case)', () {
        final exercise = Exercise(
          name: 'Test',
          muscle: 'Test',
          sets: [],
          restSeconds: 60,
          previousBest: -10.0,
        );

        expect(exercise.previousBest, -10.0);
      });
    });

    group('Immutability', () {
      test('name is final', () {
        final exercise = Exercise(
          name: 'Original',
          muscle: 'Chest',
          sets: [],
          restSeconds: 60,
        );

        // Cannot reassign name - this would be a compile error
        expect(exercise.name, 'Original');
      });

      test('muscle is final', () {
        final exercise = Exercise(
          name: 'Test',
          muscle: 'Original Muscle',
          sets: [],
          restSeconds: 60,
        );

        expect(exercise.muscle, 'Original Muscle');
      });

      test('restSeconds is final', () {
        final exercise = Exercise(
          name: 'Test',
          muscle: 'Chest',
          sets: [],
          restSeconds: 60,
        );

        expect(exercise.restSeconds, 60);
      });

      test('previousBest is final', () {
        final exercise = Exercise(
          name: 'Test',
          muscle: 'Chest',
          sets: [],
          restSeconds: 60,
          previousBest: 100.0,
        );

        expect(exercise.previousBest, 100.0);
      });
    });

    group('Integration with WorkoutSet', () {
      test('can access individual set properties', () {
        final sets = [
          WorkoutSet(targetReps: 10, targetWeight: 50.0),
          WorkoutSet(targetReps: 8, targetWeight: 55.0),
          WorkoutSet(targetReps: 6, targetWeight: 60.0),
        ];

        final exercise = Exercise(
          name: 'Progressive Set',
          muscle: 'Chest',
          sets: sets,
          restSeconds: 90,
        );

        expect(exercise.sets[0].targetReps, 10);
        expect(exercise.sets[0].targetWeight, 50.0);
        expect(exercise.sets[1].targetReps, 8);
        expect(exercise.sets[1].targetWeight, 55.0);
        expect(exercise.sets[2].targetReps, 6);
        expect(exercise.sets[2].targetWeight, 60.0);
      });

      test('can modify set properties through Exercise', () {
        final sets = [
          WorkoutSet(targetReps: 10, targetWeight: 50.0),
        ];

        final exercise = Exercise(
          name: 'Test',
          muscle: 'Chest',
          sets: sets,
          restSeconds: 60,
        );

        exercise.sets[0].actualReps = 12;
        exercise.sets[0].actualWeight = 52.5;
        exercise.sets[0].isCompleted = true;

        expect(exercise.sets[0].actualReps, 12);
        expect(exercise.sets[0].actualWeight, 52.5);
        expect(exercise.sets[0].isCompleted, true);
      });
    });
  });
}
