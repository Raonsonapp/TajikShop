import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/almaz_api.dart';

part 'src/app/app_root.dart';
part 'src/app/splash.dart';
part 'src/app/navigation.dart';
part 'src/widgets/brand_header.dart';
part 'src/widgets/page_shell.dart';
part 'src/screens/home_screen.dart';
part 'src/models/game.dart';
part 'src/widgets/game_assets.dart';
part 'src/screens/games_screen.dart';
part 'src/screens/game_detail_screen.dart';
part 'src/screens/orders_screen.dart';
part 'src/screens/wallet_screen.dart';
part 'src/screens/profile_screen.dart';
part 'src/widgets/profile_row.dart';
part 'src/widgets/empty_state.dart';
part 'src/widgets/api_status_card.dart';
part 'src/state/cart_store.dart';
part 'src/screens/cart_screen.dart';
part 'src/widgets/live_products_section.dart';
part 'src/screens/auth_screen.dart';

const bg=Color(0xFF111315), surface=Color(0xFF191C1F), green=Color(0xFF39FF72), lime=Color(0xFFB8FFCB), muted=Color(0xFFA1A1AA), gold=Color(0xFF39FF72);
final ValueNotifier<bool> almazLightMode = ValueNotifier<bool>(false);
final ValueNotifier<String> almazLanguage = ValueNotifier<String>('tg');
Color get card => almazLightMode.value ? const Color(0xFFFFFFFF) : const Color(0xFF1B1E21);
String tr(String key) {
  const words = <String, Map<String, String>>{
    'Дӯкон': {'ru':'Магазин','uz':'Do‘kon'},
    'Бозиҳо': {'ru':'Игры','uz':'O‘yinlar'},
    'Мағоза': {'ru':'Магазин','uz':'Do‘kon'},
    'Сабад': {'ru':'Корзина','uz':'Savat'},
    'Фармоиш': {'ru':'Заказы','uz':'Buyurtmalar'},
    'Фармоишҳо': {'ru':'Заказы','uz':'Buyurtmalar'},
    'Ҳамён': {'ru':'Кошелёк','uz':'Hamyon'},
    'Профил': {'ru':'Профиль','uz':'Profil'},
    'Баланс': {'ru':'Баланс','uz':'Balans'},
    'Забон': {'ru':'Язык','uz':'Til'},
    'Мавзӯи равшан': {'ru':'Светлая тема','uz':'Yorug‘ mavzu'},
    'Мавзӯи торик': {'ru':'Тёмная тема','uz':'Qorong‘i mavzu'},
    'Огоҳиномаҳо': {'ru':'Уведомления','uz':'Bildirishnomalar'},
  };
  if (almazLanguage.value == 'tg') return key;
  return words[key]?[almazLanguage.value] ?? key;
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  almazLightMode.value = preferences.getBool('almaz_light_mode') ?? false;
  almazLanguage.value = preferences.getString('almaz_language') ?? 'tg';
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: almazLightMode.value ? const Color(0xFFF3F7F4) : bg,
    statusBarIconBrightness: almazLightMode.value ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: almazLightMode.value ? const Color(0xFFF3F7F4) : bg,
    systemNavigationBarIconBrightness: almazLightMode.value ? Brightness.dark : Brightness.light,
  ));
  runApp(const AlmazApp());
}
