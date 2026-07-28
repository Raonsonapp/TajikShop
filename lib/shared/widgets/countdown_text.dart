import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/extra_l10n.dart';

/// Таймери ҳисоби бозгашт (зинда, ҳар сония нав мешавад).
class CountdownText extends StatefulWidget {
  final DateTime endsAt;
  final TextStyle? style;
  const CountdownText({super.key, required this.endsAt, this.style});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final left = widget.endsAt.difference(DateTime.now());
    if (left.isNegative) {
      _timer?.cancel();
      if (mounted) setState(() => _left = Duration.zero);
      return;
    }
    if (mounted) setState(() => _left = left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_left == Duration.zero) {
      return Text(AppL10n.of(context).ended, style: widget.style);
    }
    final d = _left.inDays;
    final h = _left.inHours % 24;
    final m = _left.inMinutes % 60;
    final s = _left.inSeconds % 60;
    final text = d > 0
        ? '$dр ${_two(h)}:${_two(m)}:${_two(s)}'
        : '${_two(h)}:${_two(m)}:${_two(s)}';
    return Text(text, style: widget.style);
  }
}
