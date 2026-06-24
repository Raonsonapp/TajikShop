import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api/api_client.dart';

// Background message handler — бояд top-level бошад
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Дар background танҳо log; намоиш аз ҷониби системаи Android анҷом мешавад
  debugPrint('📩 BG push: ${message.notification?.title}');
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _ready = false;

  /// Дар оғоз даъват мешавад. Дар web/desktop безарар бармегардад.
  Future<void> init() async {
    if (kIsWeb) return; // Web config-и алоҳида (VAPID) мехоҳад
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      _ready = true;

      // Token-и аввал
      await registerToken();
      // Token нав шавад → дубора фиристем
      messaging.onTokenRefresh.listen(_sendToken);
    } catch (e) {
      debugPrint('Push init skipped: $e');
    }
  }

  /// Баъди login даъват мешавад, то token ба ҳисоби корбар баста шавад.
  Future<void> registerToken() async {
    if (!_ready || kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) await _sendToken(token);
    } catch (_) {}
  }

  Future<void> _sendToken(String token) async {
    try {
      await ApiClient.instance.dio.post('/users/me/fcm-token', data: {'token': token});
    } catch (_) {
      // Корбар ҳанӯз ворид нашуда бошад — баъди login дубора кӯшиш мешавад
    }
  }
}
