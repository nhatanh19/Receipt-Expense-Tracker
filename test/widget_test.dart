import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/main.dart';

void main() {
  testWidgets('App renders MainNavigationScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpenseTrackerApp(),
      ),
    );

    // Verify app bar title
    expect(find.text('VKU Expense OCR'), findsOneWidget);
    // Verify navigation bar labels
    expect(find.text('Hóa đơn'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
  });
}
