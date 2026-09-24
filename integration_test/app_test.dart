import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tajikshop/main.dart' as app;

/// Тести ВОҚЕИИ барнома дар эмулятори Android.
///
/// Ин widget-тест нест: барномаи ҳақиқӣ дар дастгоҳ оғоз мешавад.
///
/// Чаро маҳз ин лозим буд: қариб ҳамаи хатоҳои ҷиддии ин барнома —
/// росткунҷаҳои хокистарранг, тугмаҳои кор накарда, «invalid token» —
/// `flutter analyze`-ро бе садо мегузаштанд ва танҳо дар телефон
/// намоён мешуданд.
///
/// Ҳоло заминаи УСТУВОР сохта мешавад: оғози барнома ва санҷиши он ки
/// ҳеҷ виҷети хатогӣ нест. Қадамҳои амиқтар (бақайдгирӣ, гардиш дар
/// бахшҳо) пас аз сабз шудани ҳамин замина илова мешаванд — вагарна
/// сабаби нокомӣ маълум намешавад.

/// ⚠️ `pumpAndSettle` дар ин барнома КОР НАМЕКУНАД: экранҳо shimmer
/// доранд, ки беохир аниматсия мекунад, пас он то timeout меистад.
/// Барои ҳамин шумораи муайяни фрейм мекашем.
Future<void> settle(WidgetTester tester,
    {int frames = 20, Duration step = const Duration(milliseconds: 100)}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('барнома оғоз мешавад ва виҷети хатогӣ надорад', (tester) async {
    // ⚠️ `main()`-и барнома `FlutterError.onError`-ро иваз мекунад.
    // Дар тест ин механизми гирифтани хатогиро мешиканад ва иҷро бо
    // «A test overrode FlutterError.onError…» меафтад. Пас онро нигоҳ
    // дошта, пас аз оғоз бармегардонем.
    final harnessOnError = FlutterError.onError;
    app.main();
    FlutterError.onError = harnessOnError;

    // Оғоз + splash + санҷиши сессия. Дар эмулятор ин суст аст.
    await settle(tester, frames: 40, step: const Duration(milliseconds: 250));

    // Барнома воқеан бор шуд?
    expect(find.byType(MaterialApp), findsOneWidget,
        reason: 'Барнома умуман оғоз нашуд');

    // Дар release виҷети хатогии Flutter росткунҷаи ХОКИСТАРРАНГ аст —
    // маҳз ҳамон нуқсони асосии барнома. Акнун худкор дошта мешавад.
    expect(find.byType(ErrorWidget), findsNothing,
        reason: 'Дар экрани аввал виҷети хатогӣ ҳаст '
            '(дар release ин росткунҷаи хокистарранг мешавад)');

    // Ягон экран воқеан кашида шуд (splash ё вуруд) — экрани холӣ не.
    expect(find.byType(Scaffold), findsWidgets,
        reason: 'Ҳеҷ экран кашида нашуд');

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
