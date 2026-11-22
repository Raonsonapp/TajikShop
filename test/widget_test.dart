import 'package:flutter_test/flutter_test.dart';
import 'package:tm_score/main.dart';

void main() {
  testWidgets('Almaz TJ | Алмаз ТҶ home screen renders', (tester) async {
    await tester.pumpWidget(const TmsApp());
    await tester.pump();
    expect(find.text('Almaz TJ | Алмаз ТҶ'), findsOneWidget);
    expect(find.text('Ахбор'), findsWidgets);
  });
}
