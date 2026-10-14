import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/theme/app_motion.dart';

/// Ҳаракат дар барнома.
///
/// Ду чизи ин файл воқеан муҳим аст:
///
///   1. Таъхири зинавӣ бояд МАҲДУД бошад — вагарна дар рӯйхати дароз
///      корбар экрани холиро чанд сония мебинад;
///   2. «Хомӯш кардани аниматсия»-и система бояд эҳтиром шавад — барои
///      одамоне, ки аз ҳаракат сарашон гаранг мешавад, ин масъалаи
///      тиббист, на завқ.
void main() {
  group('AppMotion.stagger', () {
    test('элементи аввал бе таъхир', () {
      expect(AppMotion.stagger(0), Duration.zero);
    });

    test('таъхир зинавӣ меафзояд', () {
      expect(AppMotion.stagger(1).inMilliseconds,
          lessThan(AppMotion.stagger(3).inMilliseconds));
    });

    /// ⚠️ Муҳимтарин санҷиши ин гурӯҳ.
    ///
    /// Бе маҳдудият `45 * index` дар рӯйхати 40-элемента ба 1.8 сония
    /// мерасид: корбар рӯйхати холиро медид ва фикр мекард, ки барнома
    /// шикастааст.
    test('таъхир аз ним сония зиёд намешавад', () {
      for (final i in [9, 20, 100, 5000]) {
        expect(AppMotion.stagger(i).inMilliseconds, lessThanOrEqualTo(500),
            reason: 'элементи №$i таъхири ${AppMotion.stagger(i)} гирифт — '
                'корбар экрани холиро мебинад');
      }
    });

    test('баъди зинаи 8 таъхир намеафзояд', () {
      expect(AppMotion.stagger(9), AppMotion.stagger(100));
    });
  });

  group('мӯҳлатҳо', () {
    test('зинаҳо аз якдигар фарқ мекунанд ва меафзоянд', () {
      expect(AppMotion.fast.inMilliseconds,
          lessThan(AppMotion.normal.inMilliseconds));
      expect(AppMotion.normal.inMilliseconds,
          lessThan(AppMotion.slow.inMilliseconds));
    });

    /// Аниматсияи дароз барномаро СУСТ менамояд.
    ///
    /// 400ms ҳудуди эҳсосшавандаи «интизорӣ» аст: аз он зиёд корбар
    /// таъхирро мебинад, на ҳаракатро.
    test('ҳеҷ мӯҳлат аз 400ms зиёд нест', () {
      for (final d in [AppMotion.fast, AppMotion.normal, AppMotion.slow]) {
        expect(d.inMilliseconds, lessThanOrEqualTo(400));
      }
    });
  });

  group('«Хомӯш кардани аниматсия»-и система', () {
    /// Виҷетро бо `disableAnimations` дода, натиҷаи гузаришро мегирад.
    Future<Widget> transitionUnder(
      WidgetTester tester,
      bool disabled,
      RouteTransitionsBuilder build,
    ) async {
      final marker = Container(key: const Key('page'));
      late Widget out;
      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(disableAnimations: disabled),
        child: Builder(builder: (ctx) {
          out = build(ctx, const AlwaysStoppedAnimation(0.5),
              const AlwaysStoppedAnimation(0), marker);
          return const SizedBox();
        }),
      ));
      return out;
    }

    // Се синфи гузариш — ҳар кадом бояд ҳамин қоидаро эҳтиром кунад.
    final builders = <String, RouteTransitionsBuilder>{
      'FadeThroughPage': FadeThroughPage.buildTransition,
      'DeepPage': DeepPage.buildTransition,
      'SheetPage': SheetPage.buildTransition,
    };

    builders.forEach((name, build) {
      testWidgets('$name: хомӯш → экран БЕ ивазкунӣ бармегардад',
          (tester) async {
        final out = await transitionUnder(tester, true, build);
        expect(out.key, const Key('page'),
            reason: '$name ҳангоми хомӯш будани аниматсия бояд худи '
                'экранро диҳад — вагарна одамоне, ки «Remove animations»-ро '
                'фаъол кардаанд, ҳамон ҳаракатро мегиранд');
      });

      testWidgets('$name: фаъол → экран печонда мешавад', (tester) async {
        final out = await transitionUnder(tester, false, build);
        expect(out.key, isNot(const Key('page')),
            reason: '$name ҳеҷ гузариш илова накард');
      });
    });
  });

  group('AppMotion.reduced', () {
    testWidgets('бе MediaQuery хато намедиҳад', (tester) async {
      // Виҷете, ки берун аз `MaterialApp` кашида мешавад, `MediaQuery`
      // надорад. `maybeOf` ҳатмист — `MediaQuery.of` ин ҷо истисно
      // мепартофт ва гузариш барномаро мешикаст.
      late bool got;
      await tester.pumpWidget(Builder(builder: (ctx) {
        got = AppMotion.reduced(ctx);
        return const SizedBox();
      }));
      expect(got, isFalse);
    });

    testWidgets('`disableAnimations: true`-ро мебинад', (tester) async {
      late bool got;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (ctx) {
          got = AppMotion.reduced(ctx);
          return const SizedBox();
        }),
      ));
      expect(got, isTrue);
    });
  });
}
