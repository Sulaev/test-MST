import 'package:flutter_test/flutter_test.dart';
import 'package:time_management/main.dart';

void main() {
  testWidgets('app starts and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const TimeManagementApp());
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Time Management'), findsOneWidget);
  });
}
