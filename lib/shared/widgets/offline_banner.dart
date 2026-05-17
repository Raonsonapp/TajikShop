import 'package:flutter/material.dart';

// MVP: NetworkService удалит шудааст — OfflineBanner танҳо child return мекунад
class OfflineBanner extends StatelessWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
