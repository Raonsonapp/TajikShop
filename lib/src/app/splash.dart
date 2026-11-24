part of '../../main.dart';

class AlmazSplash extends StatefulWidget {
  const AlmazSplash({super.key});
  @override
  State<AlmazSplash> createState() => _AlmazSplashState();
}

class _AlmazSplashState extends State<AlmazSplash> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AlmazHome(),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            Positioned(
              top: -110,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: green.withOpacity(.12), blurRadius: 90, spreadRadius: 25)],
                ),
              ),
            ),
            Positioned(
              bottom: -130,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: green.withOpacity(.10), blurRadius: 100, spreadRadius: 25)],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AlmazMark(size: 174),
                  const SizedBox(height: 27),
                  const Text(
                    'TAJ DONATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 38),
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(green.withOpacity(.9)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
