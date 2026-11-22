import 'package:flutter_test/flutter_test.dart';
import 'package:almaz_tj/main.dart';

void main() {
  testWidgets('Almaz TJ splash and five-tab home render', (tester) async {
    await tester.pumpWidget(const AlmazApp());
    expect(find.text('Almaz TJ'), findsOneWidget);

    // Advance past the splash timer and finish the route transition.
    // Do not use pumpAndSettle: the app contains an indeterminate loader
    // and other animations that are intentionally never fully idle.
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Дӯкон'), findsOneWidget);
    expect(find.text('Бозиҳо'), findsOneWidget);
    expect(find.text('Фармоиш'), findsOneWidget);
    expect(find.text('Ҳамён'), findsOneWidget);
    expect(find.text('Профил'), findsOneWidget);
  });
}
