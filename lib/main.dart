import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TajikShop',
      theme: ThemeData.dark(),
      home: const SplashPage(),
    );
  }
}

// ═══════════════════════════════════════════
// SPLASH
// ═══════════════════════════════════════════
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_rounded,
                color: Color(0xFF00D084), size: 80),
            SizedBox(height: 16),
            Text('TajikShop',
                style: TextStyle(color: Color(0xFF00D084),
                    fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Бозори Тоҷикистон',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// LOGIN
// ═══════════════════════════════════════════
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: const SafeArea(
        child: Center(
          child: Text('Login Screen',
              style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
      ),
    );
  }
}
