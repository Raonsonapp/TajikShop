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
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (isOnlineNotifier.value != online) {
        isOnlineNotifier.value = online;
        debugPrint('[Network] \${online ? "Online" : "Offline"}');
      }
    });
  }
  void dispose() { _sub?.cancel(); }
}
