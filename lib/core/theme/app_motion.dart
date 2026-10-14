import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Ҳаракат дар тамоми барнома — ЯК ҷой.
///
/// ЧАРО МАРКАЗӢ: пештар ҳар экран мӯҳлати худро менавишт (110ms, 180,
/// 200, 220, 250, 380), ва барнома «ноҳамвор» менамуд — ҳамон амал дар
/// ду ҷо суръати гуногун дошт. Акнун мӯҳлат ва каҷӣ аз ҳамин файл
/// гирифта мешаванд.
///
/// ⚠️ ДАСТРАСӢ: системаи корбар метавонад «Хомӯш кардани аниматсия»-ро
/// фаъол кунад (Android: Settings → Accessibility → Remove animations;
/// iOS: Reduce Motion). Одамоне, ки ин корро мекунанд, аз ҳаракат сарашон
/// гаранг мешавад — ин масъалаи тиббист, на завқ. Ҳамаи гузаришҳои ин
/// файл инро эҳтиром мекунанд: бо `disableAnimations` экран ФАВРАН
/// иваз мешавад.
class AppMotion {
  const AppMotion._();

  // ── Мӯҳлатҳо ──
  //
  // Се зина, на даҳ. Зиёд шудани зинаҳо маънои онро дорад, ки касе
  // ҳангоми нависандагӣ интихоб мекунад — ва интихоб ноҳамворӣ медиҳад.

  /// Вокуниши фаврӣ: пахши тугма, иваз шудани нишона.
  static const Duration fast = Duration(milliseconds: 120);

  /// Ҳаракати оддӣ: кушодани варақа, пайдо шудани корт.
  static const Duration normal = Duration(milliseconds: 240);

  /// Гузариши экран ва рӯйхатҳои паси ҳам.
  static const Duration slow = Duration(milliseconds: 360);

  // ── Каҷиҳо ──

  /// Барои чизе, ки ПАЙДО мешавад ё меистад: суръати баланд → нарм.
  static const Curve enter = Curves.easeOutCubic;

  /// Барои чизе, ки НОПАДИД мешавад.
  static const Curve exit = Curves.easeInCubic;

  /// Барои ҳаракати «зинда» — тугма, нишонаи дӯстдошта.
  static const Curve spring = Curves.easeOutBack;

  /// Таъхири зинавӣ барои элементи рӯйхат.
  ///
  /// Маҳдудияти 8 ҳатмист: дар рӯйхати 40-элемента `45 * index` ба
  /// 1.8 сония таъхир мерасид, ва корбар экрани холиро медид.
  static Duration stagger(int index) =>
      Duration(milliseconds: 45 * (index > 8 ? 8 : index));

  /// Оё системаи корбар аниматсияро хомӯш кардааст?
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// Гузариши «fade through» — барои ВАРАҚАҲОИ БАРОБАР (панели поёнӣ).
///
/// ЧАРО МАҲЗ ҲАМИН НАМУД: панели поёнӣ пештар `NoTransitionPage`
/// истифода мебурд — экран ФАВРАН иваз мешуд, бе ҳеҷ ҳаракат. Маҳз
/// ҳаминро корбар ҳамчун «барнома бе аниматсия» мебинад.
///
/// Вале ҷои `NoTransitionPage` лағжиши паҳлуӣ (slide) ҲАМ нодуруст
/// мебуд: лағжиш «ақиб/пеш» мегӯяд, ҳол он ки «Асосӣ» ва «Профил»
/// зинаи баробар доранд — ҳеҷ яке аз дигаре «чуқуртар» нест. Барои
/// элементҳои баробар намуди дурусти Material «fade through» аст:
/// кӯҳна ғайб мезанад, нав бо каме калон шудан пайдо мешавад.
class FadeThroughPage<T> extends CustomTransitionPage<T> {
  FadeThroughPage({required super.child, super.key})
      : super(
          transitionDuration: AppMotion.normal,
          // Баромадан бояд ТЕЗТАР аз даромадан бошад, вагарна ду экран
          // якҷоя намоён мемонанд ва тасвир «лой» менамояд.
          reverseTransitionDuration: AppMotion.fast,
          transitionsBuilder: buildTransition,
        );

  /// Оммавӣ, то тест бевосита даъват карда тавонад.
  ///
  /// Бе ин даъвои «аниматсияи хомӯш эҳтиром мешавад» исботнашаванда
  /// мемонд: `CustomTransitionPage`-ро дар тест сохтан router мехоҳад.
  static Widget buildTransition(BuildContext context, Animation<double> animation,
      Animation<double> secondary, Widget child) {
    if (AppMotion.reduced(context)) return child;
    final fade = CurvedAnimation(
      parent: animation,
      // Матн то нимаи роҳ пайдо намешавад: ҳамин «ҷудоӣ» ҳисси
      // ивазшавиро медиҳад, на ҳисси шаффофият.
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1).animate(
            CurvedAnimation(parent: animation, curve: AppMotion.enter)),
        child: child,
      ),
    );
  }
}

/// Гузариши «shared axis» — барои экрани ЧУҚУРТАР (мол, фармоиш, чат).
///
/// Ин ҷо лағжиш маҳз дуруст аст: экрани нав воқеан «дохили» экрани
/// пешин аст, ва ҳаракати уфуқӣ ҳамин иерархияро мегӯяд.
class DeepPage<T> extends CustomTransitionPage<T> {
  DeepPage({required super.child, super.key})
      : super(
          transitionDuration: AppMotion.slow,
          reverseTransitionDuration: AppMotion.normal,
          transitionsBuilder: buildTransition,
        );

  /// Оммавӣ, то тест бевосита даъват карда тавонад.
  ///
  /// Бе ин даъвои «аниматсияи хомӯш эҳтиром мешавад» исботнашаванда
  /// мемонд: `CustomTransitionPage`-ро дар тест сохтан router мехоҳад.
  static Widget buildTransition(BuildContext context, Animation<double> animation,
      Animation<double> secondary, Widget child) {
    if (AppMotion.reduced(context)) return child;
    final enter = CurvedAnimation(parent: animation, curve: AppMotion.enter);
    return SlideTransition(
      // 0.25, на 1.0: экрани нав аз канор НАМЕОЯД, балки каме меғелад.
      // Лағжиши пурра дар экрани калон суст менамояд.
      position: Tween<Offset>(begin: const Offset(0.25, 0), end: Offset.zero)
          .animate(enter),
      child: FadeTransition(
        opacity: enter,
        // Экрани ПЕШИН каме ба чап меравад — ҳисси «қабат».
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.1, 0))
              .animate(CurvedAnimation(parent: secondary, curve: AppMotion.enter)),
          child: child,
        ),
      ),
    );
  }
}

/// Гузариши «аз поён» — барои варақаҳо ва шаклҳо (эълони нав, пардохт).
class SheetPage<T> extends CustomTransitionPage<T> {
  SheetPage({required super.child, super.key})
      : super(
          transitionDuration: AppMotion.slow,
          reverseTransitionDuration: AppMotion.normal,
          transitionsBuilder: buildTransition,
        );

  /// Оммавӣ, то тест бевосита даъват карда тавонад.
  ///
  /// Бе ин даъвои «аниматсияи хомӯш эҳтиром мешавад» исботнашаванда
  /// мемонд: `CustomTransitionPage`-ро дар тест сохтан router мехоҳад.
  static Widget buildTransition(BuildContext context, Animation<double> animation,
      Animation<double> secondary, Widget child) {
    if (AppMotion.reduced(context)) return child;
    final enter = CurvedAnimation(parent: animation, curve: AppMotion.enter);
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(enter),
      child: FadeTransition(opacity: enter, child: child),
    );
  }
}
