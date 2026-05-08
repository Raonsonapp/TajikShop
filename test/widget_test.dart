import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tajikshop/main.dart';

void main() {
  testWidgets('TajikShop app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TajikShopApp()),
    );
    expect(find.byType(TajikShopApp), findsOneWidget);
  });
}
