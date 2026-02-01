import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/shared/widgets/fg_glass_card.dart';
import 'package:fitgame/core/constants/spacing.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('FGGlassCard', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGGlassCard(
            child: Text('Test Content'),
          ),
        ),
      );

      expect(find.byType(FGGlassCard), findsOneWidget);
    });

    testWidgets('displays child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGGlassCard(
            child: Text('Test Content'),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('displays complex child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGGlassCard(
            child: Column(
              children: const [
                Text('Title'),
                Text('Subtitle'),
                Icon(Icons.star),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('applies custom padding', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(32.0);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGGlassCard(
            padding: customPadding,
            child: Text('Padded Content'),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(FGGlassCard),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.padding, customPadding);
    });

    testWidgets('uses default padding when not specified',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGGlassCard(
            child: Text('Default Padding'),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(FGGlassCard),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.padding, const EdgeInsets.all(Spacing.lg));
    });

    testWidgets('applies custom border radius', (WidgetTester tester) async {
      const customRadius = 12.0;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGGlassCard(
            borderRadius: customRadius,
            child: Text('Custom Radius'),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      expect(
        clipRRect.borderRadius,
        BorderRadius.circular(customRadius),
      );
    });

    testWidgets('onTap callback is triggered when tapped',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGGlassCard(
            onTap: () => tapped = true,
            child: const Text('Tappable Card'),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Card'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onTap callback is not triggered when null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGGlassCard(
            child: Text('Non-Tappable Card'),
          ),
        ),
      );

      // Should not throw any errors when tapped with null callback
      await tester.tap(find.text('Non-Tappable Card'));
      await tester.pump();

      expect(find.text('Non-Tappable Card'), findsOneWidget);
    });

    testWidgets('contains ClipRRect for rounded corners',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGGlassCard(
            child: Text('Test'),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('contains BackdropFilter for glass effect',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGGlassCard(
            child: Text('Glass Effect'),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('contains GestureDetector for tap handling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGGlassCard(
            onTap: () {},
            child: const Text('Tappable'),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('multiple cards can be rendered together',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Column(
            children: const [
              FGGlassCard(child: Text('Card 1')),
              FGGlassCard(child: Text('Card 2')),
              FGGlassCard(child: Text('Card 3')),
            ],
          ),
        ),
      );

      expect(find.byType(FGGlassCard), findsNWidgets(3));
      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
      expect(find.text('Card 3'), findsOneWidget);
    });

    testWidgets('zero padding is applied when specified',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGGlassCard(
            padding: EdgeInsets.zero,
            child: Text('No Padding'),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(FGGlassCard),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.padding, EdgeInsets.zero);
    });
  });
}
