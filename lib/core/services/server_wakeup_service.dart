// FIX: ANR (Application Not Responding) ислоҳ шуд
// Сабаб: 10 retry × 10s = 100s блок → Android freeze → барнома мекушад
// Ислоҳ: wakeUp() дар isolate/compute нест — танҳо BACKGROUND fire-and-forget
//         Splash checkAuth() timeout 6s дорад — мунтазир намемонад
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ServerWakeupService {
  ServerWakeupService._();
  static final instance = ServerWakeupService._();

  static const _base   = 'https://tajikshop.onrender.com';
  static const _health = '/health';

  bool _awake = false;
  bool get isAwake => _awake;

  final _dio = Dio(BaseOptions(
    // FIX: 8s — агар дертар ҷавоб диҳад Splash timeout мезанад ва login га мебарад
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  // FIX: BACKGROUND — await НЕСТ, ANR намедиҳад!
  // Splash checkAuth() бо 6s timeout мунтазир мемонад
  // wakeUp() дар фон кор мекунад
  void wakeUp() {
    if (_awake) return;
    debugPrint('[Wakeup] 🔄 Background ping...');
    _pingOnce();
  }

  Future<void> _pingOnce() async {
    for (int i = 0; i < 3; i++) {
      try {
        final r = await _dio.get('$_base$_health');
        if ((r.statusCode ?? 0) < 500) {
          _awake = true;
          debugPrint('[Wakeup] ✅ Server awake (try ${i+1})');
          return;
        }
      } catch (e) {
        debugPrint('[Wakeup] ⏳ Try ${i+1}/3: $e');
        if (i < 2) await Future.delayed(const Duration(seconds: 3));
      }
    }
    debugPrint('[Wakeup] ⚠️ Server offline — app continues');
  }

  // Keep-alive: ҳар 12 дақиқа
  void startKeepAlive() {
    Timer.periodic(const Duration(minutes: 12), (_) async {
      try {
        await _dio.get('$_base$_health');
        _awake = true;
      } catch (_) { _awake = false; }
    });
  }
}
