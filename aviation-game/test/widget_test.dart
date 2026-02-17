import 'package:flutter_test/flutter_test.dart';
import 'package:aviation_game/main.dart';

void main() {
  testWidgets('app starts and shows home title', (WidgetTester tester) async {
    await tester.pumpWidget(const AviationGameApp());
    await tester.pumpAndSettle();

    expect(find.text('Flight Run'), findsOneWidget);
  });
}
