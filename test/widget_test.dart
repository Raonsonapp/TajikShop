import 'package:flutter_test/flutter_test.dart';
import 'package:football_live_tj/main.dart';

void main() {
  testWidgets('Football Live home screen renders', (tester) async {
    await tester.pumpWidget(const FootballApp());
    await tester.pump();
    expect(find.text('Бозиҳои зинда'), findsOneWidget);
    expect(find.text('Бозиҳо'), findsWidgets);
  });
}
