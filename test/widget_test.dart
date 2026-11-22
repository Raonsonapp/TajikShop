import 'package:flutter_test/flutter_test.dart';
import 'package:tm_score/main.dart';

void main() {
  testWidgets('Almaz TJ five-tab home screen renders', (tester) async {
    await tester.pumpWidget(const AlmazApp());
    await tester.pump();
    expect(find.text('Almaz TJ'), findsWidgets);
    expect(find.text('Асосӣ'), findsOneWidget);
    expect(find.text('Бозиҳо'), findsOneWidget);
    expect(find.text('Фармоиш'), findsOneWidget);
    expect(find.text('Ҳамён'), findsOneWidget);
    expect(find.text('Профил'), findsOneWidget);
  });
}
