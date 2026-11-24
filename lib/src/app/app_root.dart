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
          ? ColorScheme.fromSeed(seedColor: const Color(0xFF087A3B), brightness: Brightness.light)
          : const ColorScheme.dark(primary: green, surface: surface),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AlmazSplash(),
      ),
    ),
  );
}
