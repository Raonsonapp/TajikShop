import 'package:flutter/material.dart';

// Raonson App ID: 19230220
// To activate: replace stub with real yandex_mobileads calls
// after confirming exact API version with: flutter pub deps

class AdsService {
  static Future<void> init() async {}
  static Future<void> showInterstitial() async {}
}

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
