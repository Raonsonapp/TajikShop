import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
// `MissingPluginException` дар `services.dart` аст, на дар `material.dart`.
import 'package:flutter/services.dart';
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
///
/// ⚠️ Муҳим: виҷет метавонад БЕРУН АЗ ЭКРАН бошад.
///
/// `find.textContaining` онро меёбад (он сохта шудааст, вале поёнтар аз
/// экран аст), ва `tester.tap` ба маркази он мезанад — яъне ба ҷои холӣ.
/// Бо `warnIfMissed: false` ин ХОМӮШОНА мегузашт, ва қадами тест
/// «гузашт» ҳисоб мешуд, ҳол он ки ҳеҷ чиз накарда буд.
///
/// Маҳз ҳамин тугмаи «Забон»-ро дар профил вайрон кард: он поёни экран
/// аст, зеркунӣ ба ҷои холӣ мерафт, варақа кушода намешуд.
Future<bool> tapIfPresent(WidgetTester tester, Finder f,
    {int frames = 20}) async {
  if (f.evaluate().isEmpty) return false;
  final target = f.first;
  try {
    // Виҷетро ба экран меорем — вагарна зеркунӣ ба ҷои холӣ меравад.
    await tester.ensureVisible(target);
    await settle(tester, frames: 6);
  } catch (_) {
    // Волиди ҷойивазшаванда нест (масалан тугмаи bottom bar) — ҳамон
    // тавре мезанем.
  }
  // `warnIfMissed: true` — акнун норасидан дар лог намоён мешавад.
  await tester.tap(target);
  await settle(tester, frames: frames);
  return true;
}

Finder byText(String pattern) =>
    find.textContaining(RegExp(pattern, caseSensitive: false));

/// Шумораи хатоҳои нодидагирифташуда.
///
/// Онҳо дар хулосаи охир чоп мешаванд. Ин муҳим аст: хатои хомӯшона
/// нодидагирифташуда тестро «сабз» мекунад, ҳол он ки барнома
/// метавонад ягон расм нишон надиҳад.
int _ignoredImages = 0;
int _ignoredPlugin = 0;


/// Ба экрани асосӣ бармегардад, ҳар чи дар рӯи он кушода бошад.
///
/// Чаро ин лозим шуд: тест пештар чунин мекард —
///
///     await tapIfPresent(tester, find.byType(BackButton));
///     await tester.tap(find.byKey(const Key('nav_0')));
///
/// Вале на ҳар экран виҷети `BackButton` дорад — баъзеҳо тугмаи худро бо
/// `IconButton` месозанд. Он гоҳ `tapIfPresent` хомӯшона `false`
/// бармегардонад, экран кушода мемонад, ва сатри навбатӣ хато медиҳад:
///
///     Found 0 widgets with key [<'nav_0'>]
///
/// Ҳоло худи `Navigator` баста мешавад — ба ягон виҷет вобаста нест.
///
/// `tester.binding.handlePopRoute()` (тугмаи «ақиб»-и Android) мувофиқтар
/// менамуд, вале он `@protected` аст — истифодаи он аз берун огоҳии
/// таҳлилгар медиҳад. API-и оммавии `NavigatorState` ҳамон кор мекунад.
Future<void> backToRoot(WidgetTester tester, {int max = 5}) async {
  for (var i = 0; i < max; i++) {
    if (find.byKey(const Key('nav_0')).evaluate().isNotEmpty) return;

    // Навигаторҳоро аз ДОХИЛӢ ба берунӣ мегардем: экрани кушода дар
    // навигатори дохилӣ аст (GoRouter shell), ва бастани навигатори
    // берунӣ онро намебандад.
    var popped = false;
    for (final el in find.byType(Navigator).evaluate().toList().reversed) {
      final state = (el as StatefulElement).state;
      if (state is NavigatorState && state.canPop()) {
        state.pop();
        popped = true;
        break;
      }
    }
    if (!popped) return; // дигар ҷое барои баргаштан нест
    await settle(tester, frames: 12);
  }
}

/// Бахши поёнӣ. Агар панел набошад — хатои ФАҲМО, на «Found 0 widgets».
Future<void> tapNav(WidgetTester tester, int index) async {
  await backToRoot(tester);
  final f = find.byKey(Key('nav_$index'));
  expect(f, findsOneWidget,
      reason: 'Панели поёнӣ нест — эҳтимол экрани дигар кушода мондааст');
  await tester.tap(f);
  await settle(tester, frames: 15);
}

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
      // ⚠️ Плагини `yandex_mobileads` дар дохили худаш
      // `_channel.invokeMethod('destroy')`-ро БЕ `await` даъват мекунад
      // (ad.dart:28). Агар реклама бор нашуда бошад, он
      // `MissingPluginException` мепартояд ва он аз дохили плагин мебарояд —
      // онро аз тарафи мо гирифтан мумкин нест. Ин хатои китобхонаи бегона
      // аст, на барнома, пас тестро намеафтонад. Ҳар хатои дигар мегузарад.
      FlutterError.onError = (details) {
        final text = details.exception.toString();
        if (details.exception is MissingPluginException &&
            text.contains('yandex_mobileads')) {
          debugPrint('⚠ нодида: хатои плагини Yandex — $text');
          _ignoredPlugin++;
          return;
        }
        // ⚠️ Хатои БОРКУНИИ РАСМ. Flutter ҳар расми борнашударо ба
        // `FlutterError` мефиристад (`library: 'image resource service'`),
        // ҳатто агар виҷет `errorWidget` дошта бошад.
        //
        // Дар телефони воқеӣ ин хато НЕСТ: харидор ба ҷои расм ишораи
        // холӣ мебинад ва экран кор мекунад. Вале дар эмулятори CI
        // интернет суст аст ва backend аз хоб мебедорад, пас чанд расм
        // ҳамеша бор намешавад — ва тамоми тестро меафтонад.
        //
        // Пас онҳо ҳисоб мешаванд, НА ПИНҲОН: агар ҳеҷ расм бор нашавад,
        // ин дар хулосаи охир намоён мешавад. Вагарна тест метавонист
        // «сабз» бошад, ҳол он ки барнома ягон расм нишон намедиҳад.
        //
        // Муқоисаи САТР истифода мешавад, на навъ. `NetworkImageLoadException`
        // гарчанде аз `material.dart` дастрас аст, маҳз ҳамин навъи
        // вобастагӣ — «ин ном аз куҷо меояд?» — билди release-ро як бор
        // шикаст (`MissingPluginException`). `details.library`-ро Flutter
        // ҳамеша барои хатои расм ба ҳамин сатр мегузорад.
        if (details.library == 'image resource service' ||
            text.contains('NetworkImageLoadException') ||
            text.contains('Invalid image data')) {
          _ignoredImages++;
          return;
        }
        harnessOnError?.call(details);
      };

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
        await tapNav(tester, e.key);
        await settle(tester, frames: 15, step: const Duration(milliseconds: 150));
        expectClean(tester, e.value);
      }
    });

    await step('интихоби забон (пештар кушода намешуд)', () async {
      await tapNav(tester, 4);

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
      await tapNav(tester, 4);
      if (await tapIfPresent(
          tester, byText('Галочка|галочка|Verified|Синяя'))) {
        expectClean(tester, 'галочкаи тасдиқ');
        await backToRoot(tester);
      }
    });

    await step('username, даъват, купонҳо', () async {
      await tapNav(tester, 4);

      for (final item in ['Username', 'Дӯстон|Пригласить|Invite', 'Купон']) {
        if (await tapIfPresent(tester, byText(item))) {
          expectClean(tester, item);
          // Варақа/диалогро мепӯшем.
          await tester.tapAt(const Offset(20, 60));
          await settle(tester, frames: 12);
          await backToRoot(tester);
          await tapNav(tester, 4);
        }
      }
    });

    await step('ҷустуҷӯ ва категорияҳо', () async {
      await tapNav(tester, 0);

      if (await tapIfPresent(tester, byText('Ҷустуҷӯ|Поиск|Search'))) {
        expectClean(tester, 'ҷустуҷӯ');
        await backToRoot(tester);
      }
      await tapNav(tester, 0);

      if (await tapIfPresent(tester, byText('Категория'))) {
        expectClean(tester, 'категорияҳо');
        await backToRoot(tester);
      }
    });

    await step('дӯконҳои наздик (харита)', () async {
      await tapNav(tester, 0);
      if (await tapIfPresent(tester, byText('Дӯконҳои наздик'), frames: 30)) {
        expectClean(tester, 'дӯконҳои наздик');
        await backToRoot(tester);
      }
    });

    await step('огоҳиҳо', () async {
      await tapNav(tester, 0);
      if (await tapIfPresent(tester, find.byIcon(FeatherIcons.bell))) {
        expectClean(tester, 'огоҳиҳо');
        await backToRoot(tester);
      }
    });


    await step('дархости нарх (RFQ): сохтан ва дидан', () async {
      await tapNav(tester, 4);

      if (!await tapIfPresent(
          tester, byText('Дархости нарх|Запрос цены|Request for quote'))) {
        debugPrint('   ⚠ тугмаи RFQ ёфт нашуд — қадам гузаронида шуд');
        await backToRoot(tester);
        return;
      }
      expectClean(tester, 'RFQ: рӯйхат');

      // Форма.
      if (!await tapIfPresent(
          tester, byText('Дархости нав|Новый запрос|New request'))) {
        debugPrint('   ⚠ тугмаи «Дархости нав» ёфт нашуд');
        await backToRoot(tester);
        return;
      }
      expectClean(tester, 'RFQ: форма');

      // Майдонҳо аз рӯи матни ишорашон пур карда мешаванд — калид нест,
      // чунки варақа майдонҳои зиёд дорад ва калид ба ҳар кадом гузоштан
      // кодро ифлос мекунад.
      final title = find.byType(TextField);
      if (title.evaluate().length < 3) {
        debugPrint('   ⚠ майдонҳои форма ёфт нашуданд');
        await backToRoot(tester);
        return;
      }
      await tester.enterText(title.at(0), 'CI: 500 кг орд');
      await tester.pump();
      // Майдони сеюм шумора аст (ном, тавзеҳ, шумора).
      await tester.enterText(title.at(2), '500');
      await tester.pump();
      await settle(tester, frames: 8);

      // Фиристодан — тугмаи поёни варақа.
      await tapIfPresent(
          tester, byText('Дархости нав|Новый запрос|New request'), frames: 30);
      await settle(tester, frames: 25);
      expectClean(tester, 'RFQ: пас аз сохтан');

      // Дархости сохташуда бояд дар рӯйхат бошад.
      expect(byText('CI: 500 кг орд'), findsWidgets,
          reason: 'Дархости сохташуда дар рӯйхат пайдо нашуд — '
              'эҳтимол сервер онро рад кард');

      // Ва кушода шавад.
      if (await tapIfPresent(tester, byText('CI: 500 кг орд'), frames: 25)) {
        expectClean(tester, 'RFQ: тафсилот');
      }
      await backToRoot(tester);
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

    // Хулоса. Хатоҳои нодидагирифташуда ЧОП мешаванд, то «сабз»-и тест
    // онҳоро напӯшонад.
    debugPrint('━━━ хулоса ━━━');
    debugPrint('   расмҳои борнашуда: $_ignoredImages');
    debugPrint('   хатоҳои плагини Yandex: $_ignoredPlugin');
    if (_ignoredImages > 0) {
      debugPrint('   ℹ️ дар эмулятори CI интернет суст аст; дар телефони '
          'воқеӣ расм бор мешавад ва ин хато нест');
    }

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
