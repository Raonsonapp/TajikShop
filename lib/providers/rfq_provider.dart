import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';

/// Дархостҳои нарх (RFQ).
///
/// Моделҳои ҷудо сохта намешаванд: ҷавоби сервер майдонҳои зиёд ва
/// гуногун дорад (вобаста ба он, ки харидор мепурсад ё фурӯшанда), ва
/// модели қатъӣ ҳар илова кардани майдонро ба тағйири ду ҷой табдил
/// медиҳад. `Map` ин ҷо хонданитар аст.

List<Map<String, dynamic>> _asList(dynamic raw) {
  final data = raw is Map ? raw['data'] : raw;
  if (data is! List) return const [];
  return data
      .whereType<Map>()
      .map((m) => m.cast<String, dynamic>())
      .toList();
}

Map<String, dynamic> _asMap(dynamic raw) {
  final data = raw is Map ? (raw['data'] is Map ? raw['data'] : raw) : null;
  return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
}

/// Дархостҳои худи корбар (ҳамчун харидор).
final myRFQsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/rfqs/my');
  return _asList(res.data);
});

/// Дархостҳои кушода — барои фурӯшанда.
final openRFQsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get('/rfqs/open');
  return _asList(res.data);
});

/// Як дархост бо пешниҳодҳо.
///
/// Муҳим: ҳамон як масир ба харидор ва фурӯшанда ҷавоби ГУНОГУН медиҳад.
/// Харидор ҳамаи пешниҳодҳоро мебинад, фурӯшанда танҳо пешниҳоди
/// худашро — ва ин дар сервер муайян мешавад, на ин ҷо.
final rfqDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
  final res = await ApiClient.instance.dio.get('/rfqs/$id');
  return _asMap(res.data);
});

/// Чанд рӯз то пӯшидани дархост (манфӣ = мӯҳлат гузашт).
int rfqDaysLeft(Map<String, dynamic> rfq) {
  final raw = rfq['closes_at']?.toString();
  if (raw == null || raw.isEmpty) return 0;
  final t = DateTime.tryParse(raw);
  if (t == null) return 0;
  // Фарқи РӮЗҲОИ тақвимӣ, на соатҳо: агар мӯҳлат фардо соати 9 бошад,
  // корбар бояд «1 рӯз» бинад, на «0».
  final now = DateTime.now();
  final a = DateTime(t.year, t.month, t.day);
  final b = DateTime(now.year, now.month, now.day);
  return a.difference(b).inDays;
}
