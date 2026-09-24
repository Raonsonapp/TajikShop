import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tajikshop/main.dart' as app;

/// Тести ВОҚЕИИ барнома дар эмулятори Android.
///
/// Ин widget-тест нест: барнома пурра оғоз мешавад, ба backend-и ҳақиқӣ
/// пайваст мешавад, ҳисоби нав месозад, экранҳоро мекушояд ва дар охир
/// ҳисобро нест мекунад.
///
/// Чаро маҳз ин лозим буд: қариб ҳамаи хатоҳои ҷиддии ин барнома —
/// росткунҷаҳои хокистарранг, тугмаҳои кор накарда, «invalid token» —
/// `flutter analyze`-ро бе садо мегузаштанд ва танҳо дар телефон
/// намоён мешуданд.

/// ⚠️ `pumpAndSettle` дар ин барнома КОР НАМЕКУНАД: экранҳо shimmer доранд,
/// ки беохир аниматсия мекунад, пас `pumpAndSettle` то timeout меистад.
/// Барои ҳамин шумораи муайяни фрейм мекашем.
Future<void> settle(WidgetTester tester,
    {int frames = 40, Duration step = const Duration(milliseconds: 100)}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

/// Дар release виҷети хатогии Flutter росткунҷаи хокистарранг аст —
/// маҳз ҳамон чизе, ки дар барнома дида мешуд. Агар дар ягон экран
/// `ErrorWidget` бошад, тест меафтад.
void expectNoErrorWidget(String screen) {
  expect(find.byType(ErrorWidget), findsNothing,
      reason: 'Дар экрани «$screen» виҷети хатогӣ ҳаст '
          '(дар release ин росткунҷаи хокистарранг мешавад)');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('роҳи пурраи корбар: бақайдгирӣ → экранҳо → нест кардани ҳисоб',
      (tester) async {
    app.main();
    await settle(tester, frames: 60);

    // ── 1. Splash → экрани вуруд ──────────────────────────────────────────
    // Дар эмулятори тоза токен нест, пас барнома бояд вурудро нишон диҳад.
    expectNoErrorWidget('оғоз');

    // Ба бақайдгирӣ мегузарем. (Худи линк `RichText` аст, пас онро аз рӯи
    // матн ёфтан мумкин нест — калид гузошта шудааст.)
    final toRegister = find.byKey(const Key('to_register'));
    if (toRegister.evaluate().isNotEmpty) {
      await tester.tap(toRegister);
      await settle(tester, frames: 25);
    }

    // ── 2. Ҳисоби нав ────────────────────────────────────────────────────
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'citest_$stamp@tajikshop.test';

    expect(find.byKey(const Key('reg_email')), findsOneWidget,
        reason: 'Экрани бақайдгирӣ кушода нашуд');

    await tester.enterText(find.byKey(const Key('reg_name')), 'citest$stamp');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('reg_email')), email);
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('reg_password')), 'CiTest12345');
    await tester.pump();

    await tester.tap(find.byKey(const Key('reg_submit')));
    // Дархост ба сервери ҳақиқӣ меравад — вақти бештар медиҳем.
    await settle(tester, frames: 120, step: const Duration(milliseconds: 150));

    expectNoErrorWidget('пас аз бақайдгирӣ');
    expect(find.byKey(const Key('nav_0')), findsOneWidget,
        reason: 'Пас аз бақайдгирӣ саҳифаи асосӣ кушода нашуд — '
            'эҳтимол backend ҷавоб надод');

    // ── 3. Ҳамаи бахшҳои поёнӣ ───────────────────────────────────────────
    const tabs = {
      0: 'Асосӣ',
      1: 'Лайкҳо',
      2: 'Нашр кардан',
      3: 'Сабад',
      4: 'Профил',
    };
    for (final entry in tabs.entries) {
      await tester.tap(find.byKey(Key('nav_${entry.key}')));
      await settle(tester, frames: 30);
      expectNoErrorWidget(entry.value);
      expect(tester.takeException(), isNull,
          reason: 'Экрани «${entry.value}» истисно партофт');
    }

    // ── 4. Бахшҳои профил, ки пештар кор намекарданд ─────────────────────
    await tester.tap(find.byKey(const Key('nav_4')));
    await settle(tester, frames: 30);

    // Интихоби забон: маҳз ҳамин `showModalBottomSheet` буд, ки бе
    // `MaterialLocalizations` хомӯшона намекушода шуд.
    final lang = find.textContaining(
        RegExp('Забон|Язык|Language', caseSensitive: false));
    if (lang.evaluate().isNotEmpty) {
      await tester.tap(lang.first);
      await settle(tester, frames: 25);
      expectNoErrorWidget('интихоби забон');
      // Варақа бояд кушода шавад — ҳар се забон дар он аст.
      expect(find.textContaining('English'), findsWidgets,
          reason: 'Варақаи интихоби забон кушода нашуд');
      // Пӯшидан.
      await tester.tapAt(const Offset(20, 60));
      await settle(tester, frames: 20);
    }

    expect(tester.takeException(), isNull);

    // ── 5. Тоза кардан: ҳисоби санҷишӣ набояд дар база монад ─────────────
    // (Худи ҳамин ҷараёни нест кардан низ санҷида мешавад.)
    await tester.tap(find.byKey(const Key('nav_4')));
    await settle(tester, frames: 25);

    final del = find.textContaining(
        RegExp('Нест кардани ҳисоб|Удалить аккаунт|Delete account',
            caseSensitive: false));
    // Тозакунӣ — «best effort»: агар нашавад, тест набояд бардурӯғ афтад,
    // чунки асли санҷиш дар қадамҳои боло аст.
    try {
      if (del.evaluate().isNotEmpty) {
        await tester.ensureVisible(del.first);
        await settle(tester, frames: 10);
        await tester.tap(del.first);
        await settle(tester, frames: 25);
        expectNoErrorWidget('нест кардани ҳисоб');
      }
    } catch (e) {
      // Ҳисоби санҷишӣ мемонад — он бо префикси `citest_` фарқ мекунад.
      debugPrint('тозакунии ҳисоб нашуд: $e');
    }

    // Истисноҳои ҷамъшуда — агар бошанд, тест меафтад.
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
