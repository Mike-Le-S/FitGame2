import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/features/home/widgets/quick_stats_row.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('QuickStatsRow', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.byType(QuickStatsRow), findsOneWidget);
    });

    testWidgets('displays sessions stat with correct format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('séances'), findsOneWidget);
    });

    testWidgets('displays time stat', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.text('2h15'), findsOneWidget);
      expect(find.text('cette sem.'), findsOneWidget);
    });

    testWidgets('displays calories stat', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.text('1500'), findsOneWidget);
      expect(find.text('kcal'), findsOneWidget);
    });

    testWidgets('displays all three stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 4,
            weekTarget: 6,
            totalTime: '3h30',
            calories: 2500,
          ),
        ),
      );

      // All three stats should be visible
      expect(find.text('4/6'), findsOneWidget);
      expect(find.text('3h30'), findsOneWidget);
      expect(find.text('2500'), findsOneWidget);
    });

    testWidgets('uses Row as main layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      // Main widget should be a Row
      final rowFinder = find.descendant(
        of: find.byType(QuickStatsRow),
        matching: find.byType(Row),
      );
      expect(rowFinder, findsWidgets);
    });

    testWidgets('contains three Expanded widgets for equal spacing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.byType(Expanded), findsNWidgets(3));
    });

    testWidgets('handles zero values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 0,
            weekTarget: 5,
            totalTime: '0h00',
            calories: 0,
          ),
        ),
      );

      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('0h00'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('handles large values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 10,
            weekTarget: 10,
            totalTime: '15h45',
            calories: 12500,
          ),
        ),
      );

      expect(find.text('10/10'), findsOneWidget);
      expect(find.text('15h45'), findsOneWidget);
      expect(find.text('12500'), findsOneWidget);
    });

    testWidgets('each stat pill contains Column for vertical layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('stats have Container decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('multiple QuickStatsRow can be rendered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Column(
            children: const [
              QuickStatsRow(
                weekSessions: 3,
                weekTarget: 5,
                totalTime: '2h15',
                calories: 1500,
              ),
              QuickStatsRow(
                weekSessions: 4,
                weekTarget: 6,
                totalTime: '3h30',
                calories: 2000,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(QuickStatsRow), findsNWidgets(2));
    });

    testWidgets('different time formats are displayed correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '45min',
            calories: 500,
          ),
        ),
      );

      expect(find.text('45min'), findsOneWidget);
    });

    testWidgets('sessions label is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.text('séances'), findsOneWidget);
    });

    testWidgets('time label is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.text('cette sem.'), findsOneWidget);
    });

    testWidgets('calories label is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const QuickStatsRow(
            weekSessions: 3,
            weekTarget: 5,
            totalTime: '2h15',
            calories: 1500,
          ),
        ),
      );

      expect(find.text('kcal'), findsOneWidget);
    });
  });
}
