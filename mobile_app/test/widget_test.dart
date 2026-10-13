import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('Product Management App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProductManagementApp());
    expect(find.byType(ProductManagementApp), findsOneWidget);
  });
}
