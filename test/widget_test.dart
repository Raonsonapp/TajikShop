import 'package:flutter_test/flutter_test.dart';
import 'package:aurix_editor/main.dart';

void main() {
  testWidgets('AURIX home screen renders its identity', (tester) async {
    await tester.pumpWidget(const AurixApp());
    expect(find.text('AURIX'), findsOneWidget);
    expect(find.text('Start a new project'), findsOneWidget);
  });
}
