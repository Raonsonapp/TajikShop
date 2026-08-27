import 'package:flutter/material.dart';
// `CupertinoLocalizations` аз `material.dart` намеояд — танҳо ҳамин як номро
// мегирем, то бо номҳои Material бархӯрд нашавад.
import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart';

/// Тарҷумаҳои дохилии Flutter барои забони тоҷикӣ.
///
/// ⚠️ ХАТОИ АСЛӢ, ки бисёр «тугмаҳои кор накарда»-ро ба вуҷуд меовард:
///
/// `flutter_localizations` тақрибан 115 забон дорад, вале **тоҷикӣ (`tg`) дар
/// он НЕСТ**. Забони пешфарзи барнома бошад маҳз `tg` аст. Дар натиҷа ҳеҷ як
/// delegate `MaterialLocalizations`-ро таъмин намекард ва ҳар виҷете, ки ба он
/// муроҷиат мекунад, истисно мепартофт:
///
///   • `BackButton` → `backButtonTooltip` → тугмаи «бозгашт» намесохт,
///     ба ҷояш дар кунҷи чапи боло росткунҷаи ХОКИСТАРРАНГ пайдо мешуд
///     (дар режими release виҷети хатогӣ маҳз хокистарранг аст — 0xF0C0C0C0);
///   • `showModalBottomSheet` / `showDialog` → `modalBarrierDismissLabel` →
///     интихоби забон, «Дӯстонро даъват кунед», купонҳо, username, «Бизнеси
///     ман» — ҳама тугмаро зер мекардӣ ва ҲЕҶ ЧИЗ намешуд;
///   • `RefreshIndicator` → `refreshIndicatorSemanticLabel` → ҳангоми
///     кашидани экрани home тамоми экран хокистарранг мешуд;
///   • `showTimePicker` (вақти расонидан дар checkout) — ҳамин тавр.
///
/// Ҳалли он: барои `tg` тарҷумаҳои дохилии **русиро** бор мекунем. Ин сатрҳо
/// танҳо сатрҳои системавии Flutter-анд (tooltip-и бозгашт, «Отмена/ОК» дар
/// интихобкунандаи вақт, менюи нусхабардорӣ) — ҳамаи матни худи барнома аз
/// `AppL10n` меояд ва тоҷикӣ мемонад. Русӣ гирифта шуд, чунки кириллист ва
/// формати сана/рақами ба Тоҷикистон наздик дорад.
///
/// Delegate-ҳо умумӣ навишта шудаанд: ҳар забоне, ки Flutter намедонад, ба
/// ҷои шикастани барнома ба забони заминавӣ мегузарад — пас ҳангоми илова
/// кардани забони нав ин хато такрор намешавад.

const LocalizationsDelegate<MaterialLocalizations> fallbackMaterialDelegate =
    _FallbackMaterialDelegate();

const LocalizationsDelegate<CupertinoLocalizations> fallbackCupertinoDelegate =
    _FallbackCupertinoDelegate();

/// Забони заминавӣ барои забоне, ки Flutter надорад.
Locale _baseFor(Locale locale) =>
    locale.languageCode == 'tg' ? const Locale('ru') : const Locale('en');

class _FallbackMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialDelegate();

  // Танҳо он ҷое кор мекунад, ки Flutter худаш забонро надорад.
  @override
  bool isSupported(Locale locale) =>
      !GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_baseFor(locale));

  @override
  bool shouldReload(_FallbackMaterialDelegate old) => false;
}

class _FallbackCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoDelegate();

  @override
  bool isSupported(Locale locale) =>
      !GlobalCupertinoLocalizations.delegate.isSupported(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_baseFor(locale));

  @override
  bool shouldReload(_FallbackCupertinoDelegate old) => false;
}
