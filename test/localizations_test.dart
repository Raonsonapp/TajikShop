import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/l10n/fallback_localizations.dart';
import 'package:tajikshop/providers/locale_provider.dart';

/// Муҳофиз аз хатои «тугма кор намекунад».
///
/// Тоҷикӣ дар `flutter_localizations` нест. Агар барои ягон забони дастгирӣ-
/// шаванда `MaterialLocalizations` бор нашавад, тугмаи бозгашт, ҳамаи bottom
/// sheet-ҳо (интихоби забон, даъват, купонҳо, username) ва RefreshIndicator
/// дар режими release ба росткунҷаи хокистарранг табдил меёбанд.
///
/// Ин тестҳо маҳз ҳамонро месанҷанд — барои ҲАР забони рӯйхати барнома.
void main() {
  const delegates = <LocalizationsDelegate<dynamic>>[
    fallbackMaterialDelegate,
    fallbackCupertinoDelegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  for (final locale in LocaleNotifier.supported) {
    testWidgets('«${locale.languageCode}» — Material ва Cupertino доранд',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: delegates,
        supportedLocales: LocaleNotifier.supported,
        home: Builder(builder: (c) {
          ctx = c;
          return const Scaffold(body: SizedBox());
        }),
      ));

      // Инҳо истисно мепартоянд, агар delegate ёфт нашавад.
      expect(MaterialLocalizations.of(ctx), isNotNull);
      expect(CupertinoLocalizations.of(ctx), isNotNull);
      expect(MaterialLocalizations.of(ctx).modalBarrierDismissLabel,
          isNotEmpty);
      expect(MaterialLocalizations.of(ctx).backButtonTooltip, isNotEmpty);
    });

    testWidgets('«${locale.languageCode}» — bottom sheet кушода мешавад',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: delegates,
        supportedLocales: LocaleNotifier.supported,
        home: Builder(builder: (c) {
          ctx = c;
          return const Scaffold(body: SizedBox());
        }),
      ));

      showModalBottomSheet<void>(
        context: ctx,
        builder: (_) => const Text('sheet-и санҷишӣ'),
      );
      await tester.pumpAndSettle();

      expect(find.text('sheet-и санҷишӣ'), findsOneWidget);
    });

    testWidgets('«${locale.languageCode}» — тугмаи бозгашт месозад',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: delegates,
        supportedLocales: LocaleNotifier.supported,
        home: Scaffold(
          appBar: AppBar(title: const Text('якум')),
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(
                builder: (_) => Scaffold(appBar: AppBar(title: const Text('дуюм'))),
              )),
              child: const Text('пеш'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('пеш'));
      await tester.pumpAndSettle();

      // Дар саҳифаи дуюм AppBar бояд тугмаи бозгашти воқеӣ дошта бошад.
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
