import 'package:flutter_test/flutter_test.dart';
import 'package:tm_score/main.dart';

void main() {
  testWidgets('TM SCORE home screen renders', (tester) async {
    await tester.pumpWidget(const TmsApp());
    await tester.pump();
    expect(find.text('TM SCORE'), findsOneWidget);
    expect(find.text('Ахбор'), findsWidgets);
  });
}
