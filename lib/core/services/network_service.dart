// FIX: DNS lookup (InternetAddress.lookup) хориҷ шуд — ANR сабаб буд
// Акнун танҳо connectivity_plus истифода мешавад — блок намекунад
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier(true);
  bool get isOnline => isOnlineNotifier.value;

  StreamSubscription? _sub;

  void init() {
    // FIX: танҳо connectivity — DNS lookup нест, ANR нест
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      _setOnline(online);
    });
  }

  void _setOnline(bool online) {
    if (isOnlineNotifier.value != online) {
      isOnlineNotifier.value = online;
      debugPrint('[Network] ${online ? "🟢 Online" : "🔴 Offline"}');
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
