// lib/core/services/server_wakeup_service.dart
// Render.com free tier: сервер ҳар 15 дақиқа "хобида" мемонад.
// Ин сервис барномаро кушодан пеш серверро бедор мекунад.
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

  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));

  /// Серверро бедор кун — вақти Splash
  Future<void> wakeUp() async {
    if (_isAwake) return;
    debugPrint('[ServerWakeup] Pinging server...');
    try {
      final res = await _dio.get('$_serverUrl$_healthPath');
      if ((res.statusCode ?? 500) < 500) {
        _isAwake = true;
        debugPrint('[ServerWakeup] ✅ Server is awake!');
        return;
      }
    } catch (_) {}
    _wakeUpInBackground();
  }

  void _wakeUpInBackground() {
    Future(() async {
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(seconds: 5));
        try {
          final res = await _dio.get('$_serverUrl$_healthPath');
          if ((res.statusCode ?? 500) < 500) {
            _isAwake = true;
            debugPrint('[ServerWakeup] ✅ Woke up after ${i + 1} tries');
            return;
          }
        } catch (_) {}
      }
    });
  }

  /// Keep-alive: ҳар 10 дақиқа ping — сервер нахобад
  void startKeepAlive() {
    Timer.periodic(const Duration(minutes: 10), (_) async {
      try { await _dio.get('$_serverUrl$_healthPath'); } catch (_) {}
    });
  }
}
