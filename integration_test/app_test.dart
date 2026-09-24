import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tajikshop/core/api/api_client.dart';
import 'package:tajikshop/main.dart' as app;

/// Тести ПУРРАИ барнома дар эмулятори воқеии Android.
///
/// Ин widget-тест нест: барномаи ҳақиқӣ дар дастгоҳ оғоз мешавад, ба
/// backend-и ҳақиқӣ пайваст мешавад, ҳисоби нав месозад, ҳамаи бахшҳо ва
/// экранҳоро мекушояд ва дар охир ҳисобро нест мекунад.
///
/// Чаро маҳз ин лозим буд: қариб ҳамаи хатоҳои ҷиддии ин барнома —
/// росткунҷаҳои хокистарранг, тугмаҳои кор накарда, «invalid token» —
/// `flutter analyze`-ро бе садо мегузаштанд ва танҳо дар телефон намоён
/// мешуданд.

/// ⚠️ `pumpAndSettle` дар ин барнома КОР НАМЕКУНАД: экранҳо shimmer доранд,
/// ки беохир аниматсия мекунад, пас он то timeout меистад. Барои ҳамин
/// шумораи муайяни фрейм мекашем.
Future<void> settle(WidgetTester tester,
    {int frames = 20, Duration step = const Duration(milliseconds: 100)}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

/// Номи қадам дар лог — ҳангоми нокомӣ фавран маълум мешавад, ки кадом
/// бахш айбдор аст. Бе ин ҳар нокомӣ як девори стек буд, бе ишора ба ҷой.
int _stepNo = 0;
Future<void> step(String name, Future<void> Function() body) async {
  _stepNo++;
  debugPrint('◆ ҚАДАМИ $_stepNo: $name');
  await body();
  debugPrint('✓ ҚАДАМИ $_stepNo тамом: $name');
}

/// Дар release виҷети хатогии Flutter росткунҷаи ХОКИСТАРРАНГ аст — маҳз
/// ҳамон нуқсони асосии барнома. Пас аз ҳар экран санҷида мешавад.
void expectClean(WidgetTester tester, String screen) {
  expect(find.byType(ErrorWidget), findsNothing,
      reason: 'Дар экрани «$screen» виҷети хатогӣ ҳаст '
          '(дар release ин росткунҷаи хокистарранг мешавад)');
  expect(tester.takeException(), isNull,
      reason: 'Экрани «$screen» истисно партофт');
}

/// Тугмаро мезанад, агар он бошад. Баъзе бахшҳо танҳо барои фурӯшанда ё
/// танҳо ҳангоми мавҷудияти маълумот пайдо мешаванд.
Future<bool> tapIfPresent(WidgetTester tester, Finder f,
    {int frames = 20}) async {
  if (f.evaluate().isEmpty) return false;
  await tester.tap(f.first, warnIfMissed: false);
  await settle(tester, frames: frames);
  return true;
}

Finder byText(String pattern) =>
    find.textContaining(RegExp(pattern, caseSensitive: false));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('роҳи пурраи корбар: бақайдгирӣ → ҳамаи экранҳо → нест кардан',
      (tester) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'citest_$stamp@tajikshop.test';

    await step('оғози барнома', () async {
      // ⚠️ `main()`-и барнома `FlutterError.onError`-ро иваз мекунад ва ин
      // механизми гирифтани хатогии тестро мешиканад — онро бармегардонем.
      final harnessOnError = FlutterError.onError;
      app.main();
      FlutterError.onError = harnessOnError;

      await settle(tester, frames: 40, step: const Duration(milliseconds: 250));
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Барнома умуман оғоз нашуд');
      expectClean(tester, 'оғоз');
    });

    await step('гузариш ба бақайдгирӣ', () async {
      // Линки «Бақайдгирӣ» `RichText` аст — аз рӯи матн ёфта намешавад,
      // барои ҳамин калид гузошта шудааст.
      await tapIfPresent(tester, find.byKey(const Key('to_register')));
      expect(find.byKey(const Key('reg_email')), findsOneWidget,
          reason: 'Экрани бақайдгирӣ кушода нашуд');
      expectClean(tester, 'бақайдгирӣ');
    });

    await step('сохтани ҳисоби нав дар backend-и ҳақиқӣ', () async {
      await tester.enterText(find.byKey(const Key('reg_name')), 'citest$stamp');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('reg_email')), email);
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('reg_password')), 'CiTest12345');
      await tester.pump();

      await tester.tap(find.byKey(const Key('reg_submit')));
      // Дархост ба сервери ҳақиқӣ меравад — вақти бештар.
      await settle(tester, frames: 60, step: const Duration(milliseconds: 300));

      expect(find.byKey(const Key('nav_0')), findsOneWidget,
          reason: 'Пас аз бақайдгирӣ саҳифаи асосӣ кушода нашуд — '
              'эҳтимол backend ҷавоб надод ё бақайдгирӣ рад шуд');
      expectClean(tester, 'пас аз бақайдгирӣ');
    });

    await step('ҳамаи панҷ бахши поёнӣ', () async {
      const tabs = {
        0: 'Асосӣ',
        1: 'Лайкҳо',
        2: 'Нашр кардан',
        3: 'Сабад',
        4: 'Профил',
      };
      for (final e in tabs.entries) {
        debugPrint('   → бахши «${e.value}»');
        await tester.tap(find.byKey(Key('nav_${e.key}')));
        await settle(tester, frames: 25, step: const Duration(milliseconds: 150));
        expectClean(tester, e.value);
      }
    });

    await step('интихоби забон (пештар кушода намешуд)', () async {
      await tester.tap(find.byKey(const Key('nav_4')));
      await settle(tester, frames: 25);

      // Маҳз ин `showModalBottomSheet` буд, ки бе `MaterialLocalizations`
      // хомӯшона намекушода шуд ва тугма «кор намекард».
      if (await tapIfPresent(tester, byText('Забон|Язык|Language'))) {
        expectClean(tester, 'интихоби забон');
        expect(byText('English'), findsWidgets,
            reason: 'Варақаи интихоби забон кушода нашуд');
        await tester.tapAt(const Offset(20, 60)); // пӯшидан
        await settle(tester, frames: 15);
      }
      expectClean(tester, 'профил пас аз забон');
    });

    await step('галочкаи тасдиқ', () async {
      await tester.tap(find.byKey(const Key('nav_4')));
      await settle(tester, frames: 20);
      if (await tapIfPresent(
          tester, byText('Галочка|галочка|Verified|Синяя'))) {
        expectClean(tester, 'галочкаи тасдиқ');
        await tapIfPresent(tester, find.byType(BackButton));
      }
    });

    await step('username, даъват, купонҳо', () async {
      await tester.tap(find.byKey(const Key('nav_4')));
      await settle(tester, frames: 20);

      for (final item in ['Username', 'Дӯстон|Пригласить|Invite', 'Купон']) {
        if (await tapIfPresent(tester, byText(item))) {
          expectClean(tester, item);
          // Варақа/диалогро мепӯшем.
          await tester.tapAt(const Offset(20, 60));
          await settle(tester, frames: 12);
          await tapIfPresent(tester, find.byType(BackButton), frames: 12);
          await tester.tap(find.byKey(const Key('nav_4')));
          await settle(tester, frames: 15);
        }
      }
    });

    await step('ҷустуҷӯ ва категорияҳо', () async {
      await tester.tap(find.byKey(const Key('nav_0')));
      await settle(tester, frames: 20);

      if (await tapIfPresent(tester, byText('Ҷустуҷӯ|Поиск|Search'))) {
        expectClean(tester, 'ҷустуҷӯ');
        await tapIfPresent(tester, find.byType(BackButton));
      }
      await tester.tap(find.byKey(const Key('nav_0')));
      await settle(tester, frames: 15);

      if (await tapIfPresent(tester, byText('Категория'))) {
        expectClean(tester, 'категорияҳо');
        await tapIfPresent(tester, find.byType(BackButton));
      }
    });

    await step('дӯконҳои наздик (харита)', () async {
      await tester.tap(find.byKey(const Key('nav_0')));
      await settle(tester, frames: 15);
      if (await tapIfPresent(tester, byText('Дӯконҳои наздик'), frames: 30)) {
        expectClean(tester, 'дӯконҳои наздик');
        await tapIfPresent(tester, find.byType(BackButton));
      }
    });

    await step('огоҳиҳо', () async {
      await tester.tap(find.byKey(const Key('nav_0')));
      await settle(tester, frames: 15);
      if (await tapIfPresent(tester, find.byIcon(FeatherIcons.bell))) {
        expectClean(tester, 'огоҳиҳо');
        await tapIfPresent(tester, find.byType(BackButton));
      }
    });

    await step('тозакунӣ: нест кардани ҳисоби санҷишӣ', () async {
      // Тавассути API — боэътимодтар аз гардиш дар меню, ва худи ҳамин
      // роҳро низ месанҷад. Ҳисоби санҷишӣ набояд дар база монад.
      try {
        await ApiClient.instance.dio.delete('/users/me');
        debugPrint('   → ҳисоби $email нест карда шуд');
      } catch (e) {
        // Нашудани тозакунӣ тестро намеафтонад — ҳисобҳои санҷишӣ
        // префикси `citest_` доранд ва фарқ мекунанд.
        debugPrint('   ⚠ тозакунӣ нашуд: $e');
      }
    });

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
