import 'package:flutter_test/flutter_test.dart';
import 'package:utility_app/main.dart';

void main() {
  testWidgets('app starts and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const UtilityApp());
    await tester.pumpAndSettle();

    expect(find.text('Workspace'), findsOneWidget);
  });
}
