import 'package:flutter_test/flutter_test.dart';
import 'package:almaz_tj/main.dart';

void main() {
  testWidgets('TAJ DONATE splash and five-tab navigation render', (tester) async {
    await tester.pumpWidget(const AlmazApp());

    // The splash screen was rebranded from Almaz TJ to TAJ DONATE.
    expect(find.text('TAJ DONATE'), findsOneWidget);

    // Advance past the splash timer and finish the route transition.
    // Do not use pumpAndSettle: the app contains animations that may remain active.
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 400));

    // Keep these labels aligned with the current five-tab navigation.
    expect(find.text('Дӯкон'), findsOneWidget);
    expect(find.text('Баланс'), findsOneWidget);
    expect(find.text('Мағоза'), findsOneWidget);
    expect(find.text('Фармоишҳо'), findsOneWidget);
    expect(find.text('Профил'), findsOneWidget);
  });
}
