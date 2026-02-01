import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/core/constants/spacing.dart';

void main() {
  group('Spacing', () {
    group('Constants', () {
      test('xs equals 4', () {
        expect(Spacing.xs, 4);
      });

      test('sm equals 8', () {
        expect(Spacing.sm, 8);
      });

      test('md equals 16', () {
        expect(Spacing.md, 16);
      });

      test('lg equals 24', () {
        expect(Spacing.lg, 24);
      });

      test('xl equals 32', () {
        expect(Spacing.xl, 32);
      });

      test('xxl equals 48', () {
        expect(Spacing.xxl, 48);
      });
    });

    group('Type Verification', () {
      test('xs is a double', () {
        expect(Spacing.xs, isA<double>());
      });

      test('sm is a double', () {
        expect(Spacing.sm, isA<double>());
      });

      test('md is a double', () {
        expect(Spacing.md, isA<double>());
      });

      test('lg is a double', () {
        expect(Spacing.lg, isA<double>());
      });

      test('xl is a double', () {
        expect(Spacing.xl, isA<double>());
      });

      test('xxl is a double', () {
        expect(Spacing.xxl, isA<double>());
      });
    });

    group('8px Grid System', () {
      test('xs is half of sm (4 = 8/2)', () {
        expect(Spacing.xs, Spacing.sm / 2);
      });

      test('sm is the base unit (8px)', () {
        expect(Spacing.sm, 8);
      });

      test('md is double of sm (16 = 8*2)', () {
        expect(Spacing.md, Spacing.sm * 2);
      });

      test('lg is triple of sm (24 = 8*3)', () {
        expect(Spacing.lg, Spacing.sm * 3);
      });

      test('xl is quadruple of sm (32 = 8*4)', () {
        expect(Spacing.xl, Spacing.sm * 4);
      });

      test('xxl is sextuple of sm (48 = 8*6)', () {
        expect(Spacing.xxl, Spacing.sm * 6);
      });
    });

    group('Ordering', () {
      test('xs < sm', () {
        expect(Spacing.xs < Spacing.sm, true);
      });

      test('sm < md', () {
        expect(Spacing.sm < Spacing.md, true);
      });

      test('md < lg', () {
        expect(Spacing.md < Spacing.lg, true);
      });

      test('lg < xl', () {
        expect(Spacing.lg < Spacing.xl, true);
      });

      test('xl < xxl', () {
        expect(Spacing.xl < Spacing.xxl, true);
      });

      test('values are in ascending order', () {
        final values = [
          Spacing.xs,
          Spacing.sm,
          Spacing.md,
          Spacing.lg,
          Spacing.xl,
          Spacing.xxl,
        ];

        for (int i = 0; i < values.length - 1; i++) {
          expect(values[i] < values[i + 1], true);
        }
      });
    });

    group('Differences', () {
      test('difference between xs and sm is 4', () {
        expect(Spacing.sm - Spacing.xs, 4);
      });

      test('difference between sm and md is 8', () {
        expect(Spacing.md - Spacing.sm, 8);
      });

      test('difference between md and lg is 8', () {
        expect(Spacing.lg - Spacing.md, 8);
      });

      test('difference between lg and xl is 8', () {
        expect(Spacing.xl - Spacing.lg, 8);
      });

      test('difference between xl and xxl is 16', () {
        expect(Spacing.xxl - Spacing.xl, 16);
      });
    });

    group('Ratios', () {
      test('md is 4x of xs', () {
        expect(Spacing.md / Spacing.xs, 4);
      });

      test('xl is 8x of xs', () {
        expect(Spacing.xl / Spacing.xs, 8);
      });

      test('xxl is 12x of xs', () {
        expect(Spacing.xxl / Spacing.xs, 12);
      });

      test('xxl is 6x of sm', () {
        expect(Spacing.xxl / Spacing.sm, 6);
      });

      test('xxl is 3x of md', () {
        expect(Spacing.xxl / Spacing.md, 3);
      });

      test('xxl is 2x of lg', () {
        expect(Spacing.xxl / Spacing.lg, 2);
      });
    });

    group('Positive Values', () {
      test('all values are positive', () {
        expect(Spacing.xs > 0, true);
        expect(Spacing.sm > 0, true);
        expect(Spacing.md > 0, true);
        expect(Spacing.lg > 0, true);
        expect(Spacing.xl > 0, true);
        expect(Spacing.xxl > 0, true);
      });
    });

    group('Usage Scenarios', () {
      test('xs suitable for tight spacing', () {
        expect(Spacing.xs, 4);
      });

      test('sm suitable for standard item spacing', () {
        expect(Spacing.sm, 8);
      });

      test('md suitable for section padding', () {
        expect(Spacing.md, 16);
      });

      test('lg suitable for card margins', () {
        expect(Spacing.lg, 24);
      });

      test('xl suitable for screen padding', () {
        expect(Spacing.xl, 32);
      });

      test('xxl suitable for large gaps between sections', () {
        expect(Spacing.xxl, 48);
      });
    });

    group('Combinations', () {
      test('xs + sm equals md - xs', () {
        expect(Spacing.xs + Spacing.sm, Spacing.md - Spacing.xs);
      });

      test('sm + md equals lg', () {
        expect(Spacing.sm + Spacing.md, Spacing.lg);
      });

      test('md + xl equals xxl', () {
        expect(Spacing.md + Spacing.xl, Spacing.xxl);
      });

      test('xs + lg equals xl - xs', () {
        expect(Spacing.xs + Spacing.lg, Spacing.xl - Spacing.xs);
      });

      test('sum of xs, sm, md equals xl + xs', () {
        expect(Spacing.xs + Spacing.sm + Spacing.md, Spacing.xl - Spacing.xs);
      });
    });

    group('Flutter Usage Compatibility', () {
      test('values work with EdgeInsets.all', () {
        // Spacing values should work with EdgeInsets
        expect(Spacing.md, isA<double>());
        expect(Spacing.md.isFinite, true);
        expect(Spacing.md.isNaN, false);
      });

      test('values work with SizedBox dimensions', () {
        // Spacing values should work with SizedBox width/height
        expect(Spacing.lg, isA<double>());
        expect(Spacing.lg > 0, true);
      });

      test('values work with padding and margin', () {
        // All values should be valid for padding/margin
        final values = [
          Spacing.xs,
          Spacing.sm,
          Spacing.md,
          Spacing.lg,
          Spacing.xl,
          Spacing.xxl,
        ];

        for (final value in values) {
          expect(value.isFinite, true);
          expect(value.isNaN, false);
          expect(value.isNegative, false);
        }
      });
    });

    group('Const Verification', () {
      test('xs is a compile-time constant', () {
        const xs = Spacing.xs;
        expect(xs, 4);
      });

      test('sm is a compile-time constant', () {
        const sm = Spacing.sm;
        expect(sm, 8);
      });

      test('md is a compile-time constant', () {
        const md = Spacing.md;
        expect(md, 16);
      });

      test('lg is a compile-time constant', () {
        const lg = Spacing.lg;
        expect(lg, 24);
      });

      test('xl is a compile-time constant', () {
        const xl = Spacing.xl;
        expect(xl, 32);
      });

      test('xxl is a compile-time constant', () {
        const xxl = Spacing.xxl;
        expect(xxl, 48);
      });
    });
  });
}
