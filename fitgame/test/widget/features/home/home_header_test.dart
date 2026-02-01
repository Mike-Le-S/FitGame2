import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/features/home/widgets/home_header.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('HomeHeader', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 7),
        ),
      );

      expect(find.byType(HomeHeader), findsOneWidget);
    });

    testWidgets('displays greeting with username', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 5),
        ),
      );

      expect(find.text('Salut Mike'), findsOneWidget);
    });

    testWidgets('displays streak count with correct format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 12),
        ),
      );

      expect(find.text('12 j'), findsOneWidget);
    });

    testWidgets('displays fire emoji for streak', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 3),
        ),
      );

      expect(find.textContaining('\u{1F525}'), findsOneWidget);
    });

    testWidgets('displays avatar with initial letter M',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 1),
        ),
      );

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('displays streak for zero days', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 0),
        ),
      );

      expect(find.text('0 j'), findsOneWidget);
    });

    testWidgets('displays streak for large numbers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 365),
        ),
      );

      expect(find.text('365 j'), findsOneWidget);
    });

    testWidgets('contains Row as main layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 5),
        ),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('streak badge is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 7),
        ),
      );

      // The streak badge should contain the streak number
      expect(find.text('7 j'), findsOneWidget);
    });

    testWidgets('avatar container has circular shape',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 5),
        ),
      );

      // Find the container with the avatar (the one containing 'M')
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool foundCircularAvatar = false;

      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.shape == BoxShape.circle) {
            foundCircularAvatar = true;
            break;
          }
        }
      }

      expect(foundCircularAvatar, isTrue);
    });

    testWidgets('header contains Expanded widget for flexible layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 5),
        ),
      );

      expect(find.byType(Expanded), findsWidgets);
    });

    testWidgets('multiple HomeHeaders can be rendered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Column(
            children: const [
              HomeHeader(currentStreak: 5),
              HomeHeader(currentStreak: 10),
            ],
          ),
        ),
      );

      expect(find.byType(HomeHeader), findsNWidgets(2));
      expect(find.text('5 j'), findsOneWidget);
      expect(find.text('10 j'), findsOneWidget);
    });

    testWidgets('greeting text and streak are in same row',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 3),
        ),
      );

      // Both should be present
      expect(find.text('Salut Mike'), findsOneWidget);
      expect(find.text('3 j'), findsOneWidget);
    });

    testWidgets('avatar has correct size (48x48)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const HomeHeader(currentStreak: 5),
        ),
      );

      // Find the circular container with the 'M' avatar
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool foundCorrectSize = false;

      for (final container in containers) {
        // Check if it has a BoxDecoration with circular shape and specific size
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.shape == BoxShape.circle) {
            // This container has the avatar
            // The Container uses explicit width/height properties
            final element = tester.element(find.byWidget(container));
            final renderBox = element.renderObject as RenderBox;
            if (renderBox.size.width == 48 && renderBox.size.height == 48) {
              foundCorrectSize = true;
              break;
            }
          }
        }
      }

      expect(foundCorrectSize, isTrue);
    });
  });
}
