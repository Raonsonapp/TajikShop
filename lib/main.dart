import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/network_service.dart';
import 'core/services/server_wakeup_service.dart';
import 'core/services/user_session.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'shared/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Кэши корбарро бор кун — UI зудтар нишон медиҳад
  await UserSession.loadCachedData();

  // Шабакаро назорат кун
  NetworkService.instance.init();

  // Серверро бедор кун (Render free tier)
  ServerWakeupService.instance.wakeUp();
  ServerWakeupService.instance.startKeepAlive();

  runApp(const ProviderScope(child: TajikShopApp()));
}

class TajikShopApp extends ConsumerWidget {
  const TajikShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TajikShop',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // OfflineBanner ҳар вақт офлайн бошад нишон медиҳад
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox()),
    );
  }
}
