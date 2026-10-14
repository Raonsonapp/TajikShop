import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/shared/widgets/app_button.dart';
import 'package:tajikshop/shared/widgets/fade_slide_in.dart';

/// Вокуниши пахш дар тугмаи асосии барнома.
///
/// Бе он «Ба сабад», «Харидан», «Фармоиш додан» «мурда» эҳсос мешуданд:
/// ҳангоми интернети суст корбар намедонист, оё зерашро барнома гирифт,
/// ва боз як бор мезад — ва дубора фармоиш медод.
void main() {
  /// `scale`-и ҳозираи `AnimatedScale`-и дохили тугма.
  double scaleOf(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  Future<void> pumpButton(
    WidgetTester tester, {
    VoidCallback? onTap,
    bool loading = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppButton(text: 'Харидан', onTap: onTap, isLoading: loading),
        ),
      ),
    ));
  }

  testWidgets('тугма ҳангоми пахш хурд мешавад ва баъд бармегардад',
      (tester) async {
    var taps = 0;
    await pumpButton(tester, onTap: () => taps++);
    expect(scaleOf(tester), 1, reason: 'тугма дар ҳолати ором хурд аст');

    final g = await tester.startGesture(tester.getCenter(find.text('Харидан')));
    await tester.pump();
    expect(scaleOf(tester), lessThan(1),
        reason: 'ҳангоми нигоҳ доштани ангушт тугма бояд хурд шавад');

    await g.up();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1, reason: 'баъди сар додан бояд баргардад');
    expect(taps, 1, reason: 'вокуниши пахш худи зеркуниро нашиканад');
  });

  /// ⚠️ Вокуниши пахш дар тугмаи ХОМӮШ дурӯғ мегӯяд.
  ///
  /// Корбар ҳаракатро мебинад, фикр мекунад, ки зерашро барнома гирифт,
  /// ва интизор мешавад — вале ҳеҷ чиз рӯй намедиҳад.
  testWidgets('тугмаи хомӯш вокуниш надорад', (tester) async {
    await pumpButton(tester, onTap: null);
    final g = await tester.startGesture(tester.getCenter(find.text('Харидан')));
    await tester.pump();
    expect(scaleOf(tester), 1,
        reason: 'тугмаи бе `onTap` набояд ҳаракат кунад — ин дурӯғ аст');
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('тугмаи дар ҳолати боркунӣ вокуниш надорад', (tester) async {
    var taps = 0;
    await pumpButton(tester, onTap: () => taps++, loading: true);
    // Дар ҳолати боркунӣ матн нест — доира аст.
    final g = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)));
    await tester.pump();
    expect(scaleOf(tester), 1);
    await g.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 0, reason: 'зеркунии такрорӣ ҳангоми боркунӣ фармоиши '
        'дучанд медод');
  });

  group('PressableScale', () {
    testWidgets('бекор кардани пахш ҳолатро бармегардонад', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: PressableScale(
              onTap: () {},
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ));
      final g = await tester.startGesture(const Offset(400, 300));
      await tester.pump();
      // Ангушт берун аз виҷет мелағжад → `onTapCancel`.
      await g.moveTo(const Offset(10, 10));
      await g.up();
      await tester.pumpAndSettle();
      expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1,
          reason: 'баъди бекоршавии пахш виҷет бояд ба андозаи аслӣ '
              'баргардад — вагарна он хурд МЕМОНАД');
    });
  });
}
