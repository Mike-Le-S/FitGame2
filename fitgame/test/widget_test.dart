import 'package:flutter_test/flutter_test.dart';
import 'package:fitgame/main.dart';

void main() {
  testWidgets('FitGame app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FitGameApp());
    expect(find.text('FITGAME'), findsOneWidget);
  });
}
