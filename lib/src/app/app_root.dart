part of '../../main.dart';

class AlmazApp extends StatelessWidget {
  const AlmazApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: almazLightMode,
    builder: (context, light, _) => ValueListenableBuilder<String>(
      valueListenable: almazLanguage,
      builder: (context, language, __) => MaterialApp(
      title: 'TAJ DONATE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: light ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: light ? const Color(0xFFF3F7F4) : bg,
        colorScheme: light
          ? ColorScheme.fromSeed(seedColor: surface, brightness: Brightness.light)
          : const ColorScheme.dark(primary: green, secondary: green, surface: surface),
        useMaterial3: true,
        primaryColor: surface,
        iconTheme: const IconThemeData(color: green),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: surface, foregroundColor: Colors.white)),
        fontFamily: 'Roboto',
      ),
      home: const AlmazSplash(),
      ),
    ),
  );
}
