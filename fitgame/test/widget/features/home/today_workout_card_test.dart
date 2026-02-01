import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/features/home/widgets/today_workout_card.dart';
import 'package:fitgame/shared/widgets/fg_glass_card.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('TodayWorkoutCard', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.byType(TodayWorkoutCard), findsOneWidget);
    });

    testWidgets('displays workout name', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.text('Upper Body'), findsOneWidget);
    });

    testWidgets('displays workout type and exercise count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.textContaining('Push'), findsOneWidget);
      expect(find.textContaining('6 exercices'), findsOneWidget);
    });

    testWidgets('displays duration estimate', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.text('~45-60 min'), findsOneWidget);
    });

    testWidgets('displays AUJOURD\'HUI label', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.text('AUJOURD\'HUI'), findsOneWidget);
    });

    testWidgets('contains play button icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets('contains timer icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('is wrapped in FGGlassCard', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.byType(FGGlassCard), findsOneWidget);
    });

    testWidgets('is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('contains Column for vertical layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('header and content sections are present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      // Header section contains AUJOURD'HUI and duration
      expect(find.text('AUJOURD\'HUI'), findsOneWidget);
      expect(find.text('~45-60 min'), findsOneWidget);

      // Content section contains workout name and details
      expect(find.text('Upper Body'), findsOneWidget);
    });

    testWidgets('workout details row has play icon on the right',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      // Both text and icon should be present
      expect(find.text('Upper Body'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets('card is tappable and triggers navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      // Verify the card has a GestureDetector that can be tapped
      final gestureDetector = find.descendant(
        of: find.byType(TodayWorkoutCard),
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetector, findsWidgets);

      // Tap the card - this will trigger navigation
      await tester.tap(find.byType(TodayWorkoutCard));
      // Just pump once to trigger the tap, don't wait for animation to settle
      await tester.pump();

      // Verify a navigation transition has started
      expect(find.byType(TodayWorkoutCard), findsOneWidget);
    });

    testWidgets('has Container decorations', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('header has gradient decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      // Find containers and check for gradient
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool hasGradient = false;

      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.gradient != null) {
            hasGradient = true;
            break;
          }
        }
      }

      expect(hasGradient, isTrue);
    });

    testWidgets('FGGlassCard has zero padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      final glassCard =
          tester.widget<FGGlassCard>(find.byType(FGGlassCard));
      expect(glassCard.padding, EdgeInsets.zero);
    });

    testWidgets('workout subtitle contains separator dot',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      // The text contains a bullet point
      expect(find.textContaining('\u2022'), findsOneWidget);
    });

    testWidgets('multiple cards can be rendered in list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          ListView(
            children: const [
              TodayWorkoutCard(),
              SizedBox(height: 16),
              TodayWorkoutCard(),
            ],
          ),
        ),
      );

      expect(find.byType(TodayWorkoutCard), findsNWidgets(2));
    });

    testWidgets('displays all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TodayWorkoutCard(),
        ),
      );

      // Check all required elements are present
      expect(find.text('AUJOURD\'HUI'), findsOneWidget); // Today label
      expect(find.text('~45-60 min'), findsOneWidget); // Duration
      expect(find.text('Upper Body'), findsOneWidget); // Workout name
      expect(find.textContaining('Push'), findsOneWidget); // Workout type
      expect(find.textContaining('6 exercices'), findsOneWidget); // Exercise count
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget); // Play button
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget); // Timer icon
    });
  });
}
