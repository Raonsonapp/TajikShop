import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/l10n/fallback_localizations.dart';
import 'package:tajikshop/modules/profile/profile_screen.dart';

/// Муҳофизат аз камбудии ВОҚЕӢ, ки дар CI афтод.
///
/// Ман ба корти амалҳои профил ду тугма илова кардам (дархости нарх ва
/// таъминкунандагон) — 4 шуд 6, ва сатр нағунҷид:
///
///     A RenderFlex overflowed by 194 pixels on the right
///     Экрани «Профил» истисно партофт
///
/// Инро танҳо тести ЭМУЛЯТОР дошт — 8 дақиқа барои хатое, ки ин ҷо дар
/// як сония маълум мешавад. `flutter analyze` ва ҳамаи тестҳои дигар
/// онро умуман намебинанд: overflow танҳо ҳангоми расмкашии воқеӣ
/// пайдо мешавад.
void main() {
  /// Виҷетро дар паҳнии муайян мекашад ва мегӯяд, оё overflow буд.
  Future<Object?> renderAt(WidgetTester tester, double width,
      {required int buttons, required String label}) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      // Тоҷикӣ дар `flutter_localizations` нест — бе ин delegate
      // виҷетҳои Material умуман бор намешаванд.
      locale: const Locale('tg'),
      localizationsDelegates: const [
        fallbackMaterialDelegate,
        fallbackCupertinoDelegate,
      ],
      supportedLocales: const [Locale('tg')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: QuickActionsCard(
            children: [
              for (var i = 0; i < buttons; i++)
                QuickAction(
                  icon: FeatherIcons.creditCard,
                  color: Colors.green,
                  label: label,
                  onTap: () {},
                ),
            ],
          ),
        ),
      ),
    ));
    return tester.takeException();
  }

  // Маҳз ҳамин ҳолат дар CI афтод: 6 тугма бо матни дароз.
  testWidgets('6 тугма бо матни дароз дар экрани танг overflow намедиҳад',
      (tester) async {
    final e = await renderAt(tester, 320,
        buttons: 6, label: 'Таъминкунандагон');
    expect(e, isNull,
        reason: 'Корти амалҳо дар паҳнии 320 нағунҷид — '
            'маҳз ҳамин камбудӣ дар CI афтод');
  });

  // Ҳар шумораи тугма бояд ғунҷад, аз ҷумла онҳое, ки фардо илова
  // мешаванд.
  for (final n in [1, 2, 3, 4, 5, 6, 7, 8, 9, 12]) {
    testWidgets('$n тугма overflow намедиҳад', (tester) async {
      final e = await renderAt(tester, 320,
          buttons: n, label: 'Матни хеле дарози тугма');
      expect(e, isNull, reason: '$n тугма нағунҷид');
    });
  }

  // Экрани хеле танг (телефони кӯҳна).
  testWidgets('дар паҳнии 280 ҳам ғунҷад', (tester) async {
    final e = await renderAt(tester, 280,
        buttons: 6, label: 'Таъминкунандагон');
    expect(e, isNull, reason: 'дар экрани 280 нағунҷид');
  });

  // Виҷет бояд ВОҚЕАН расм кашад, на танҳо хато надиҳад.
  testWidgets('тугмаҳо воқеан кашида мешаванд', (tester) async {
    await renderAt(tester, 360, buttons: 6, label: 'Ҳамён');
    expect(find.text('Ҳамён'), findsNWidgets(6));
    expect(find.byType(QuickAction), findsNWidgets(6));
  });

  // Рӯйхати холӣ набояд барномаро шиканад.
  testWidgets('рӯйхати холӣ', (tester) async {
    final e = await renderAt(tester, 320, buttons: 0, label: 'х');
    expect(e, isNull);
  });
}
