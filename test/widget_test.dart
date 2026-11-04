import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_business_app/main.dart';

void main() {
  testWidgets('App starts and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GroceryBusinessApp());

    expect(find.text('Grocery Business App'), findsWidgets);
    expect(find.byIcon(Icons.storefront), findsOneWidget);
  });
}
