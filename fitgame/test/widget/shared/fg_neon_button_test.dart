import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/shared/widgets/fg_neon_button.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('FGNeonButton', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Test Button',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(FGNeonButton), findsOneWidget);
    });

    testWidgets('displays label text in uppercase', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Click Me',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('CLICK ME'), findsOneWidget);
    });

    testWidgets('onPressed callback is triggered when tapped',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Press Me',
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(FGNeonButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('button is disabled when onPressed is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const FGNeonButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
      );

      // Find the InkWell and check it can be tapped without error
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets('shows loading indicator when isLoading is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label should not be visible when loading
      expect(find.text('LOADING'), findsNothing);
    });

    testWidgets('hides label text when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Submit',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.text('SUBMIT'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not trigger onPressed when loading',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Loading Button',
            onPressed: () => pressed = true,
            isLoading: true,
          ),
        ),
      );

      await tester.tap(find.byType(FGNeonButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('expands to full width when isExpanded is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Expanded',
            onPressed: () {},
            isExpanded: true,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('does not expand when isExpanded is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Center(
            child: FGNeonButton(
              label: 'Not Expanded',
              onPressed: () {},
              isExpanded: false,
            ),
          ),
        ),
      );

      // Check that there's no SizedBox with infinite width wrapping the button
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      for (final sizedBox in sizedBoxes) {
        if (sizedBox.width == double.infinity) {
          // This would fail if button incorrectly expands
          fail('Button should not have infinite width when isExpanded is false');
        }
      }
    });

    testWidgets('contains Material widget for ink effects',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Material',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('contains InkWell for tap feedback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'InkWell',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('label transforms to uppercase correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'mIxEd CaSe',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('MIXED CASE'), findsOneWidget);
    });

    testWidgets('handles empty label', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: '',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(FGNeonButton), findsOneWidget);
    });

    testWidgets('loading indicator has correct size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, 20);
      expect(sizedBox.height, 20);
    });

    testWidgets('multiple buttons can be rendered together',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Column(
            children: [
              FGNeonButton(label: 'Button 1', onPressed: () {}),
              FGNeonButton(label: 'Button 2', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.byType(FGNeonButton), findsNWidgets(2));
      expect(find.text('BUTTON 1'), findsOneWidget);
      expect(find.text('BUTTON 2'), findsOneWidget);
    });

    testWidgets('transitions from loading to normal state',
        (WidgetTester tester) async {
      bool isLoading = true;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return FGNeonButton(
                label: 'Submit',
                onPressed: () => setState(() => isLoading = false),
                isLoading: isLoading,
              );
            },
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('SUBMIT'), findsNothing);

      // Simulate state change
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FGNeonButton(
            label: 'Submit',
            onPressed: () {},
            isLoading: false,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('SUBMIT'), findsOneWidget);
    });
  });
}
