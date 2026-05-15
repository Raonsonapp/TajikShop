// lib/core/services/server_wakeup_service.dart
// FIX: Render.com free tier — cold start то 50 сония тӯл мекашад.
// Timeout аз 8s то 55s зиёд шуд + retry 10 маротиба.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ServerWakeupService {
  ServerWakeupService._();
  static final instance = ServerWakeupService._();

  static const _serverUrl  = 'https://tajikshop.onrender.com';
  static const _healthPath = '/health';

  bool _isAwake = false;
  bool get isAwake => _isAwake;

  final _dio = Dio(BaseOptions(
    // FIX: timeout аз 8s то 55s — cold start-ро пӯшад
    connectTimeout: const Duration(seconds: 55),
    receiveTimeout: const Duration(seconds: 55),
  ));

  /// Серверро бедор кун — SplashScreen-ро block мекунад то ки сервер ҷавоб диҳад.
  /// FIX: Дигар background-га намеравад — Splash мунтазир мемонад.
  Future<void> wakeUp() async {
    if (_isAwake) return;
    debugPrint('[ServerWakeup] 🔄 Pinging server (cold start possible ~30-50s)...');
    
    // FIX: 10 маротиба кӯшиш, ҳар 5 сония
    for (int i = 0; i < 10; i++) {
      try {
        final res = await _dio
            .get('$_serverUrl$_healthPath')
            .timeout(const Duration(seconds: 10));
        if ((res.statusCode ?? 500) < 500) {
          _isAwake = true;
          debugPrint('[ServerWakeup] ✅ Server awake after ${i + 1} ping(s)');
          return;
        }
      } catch (e) {
        debugPrint('[ServerWakeup] ⏳ Try ${i + 1}/10 failed: $e');
        if (i < 9) await Future.delayed(const Duration(seconds: 4));
      }
    }
    // 10 retry баъд ҳам нашуд — бигузор ба login равад
    debugPrint('[ServerWakeup] ⚠️ Server not reachable after 10 tries — continuing offline');
  }

  /// Keep-alive: ҳар 10 дақиқа ping — сервер нахобад
  void startKeepAlive() {
    Timer.periodic(const Duration(minutes: 10), (_) async {
      try {
        await _dio.get('$_serverUrl$_healthPath');
        _isAwake = true;
      } catch (_) {
        _isAwake = false;
      }
    });
  }
}
