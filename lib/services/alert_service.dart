import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';

// ── 모델 ──────────────────────────────────────────────────────
class AlertModel {
  final int id;
  final String regionCode;
  final String regionName;
  final String categoryCode;
  final String categoryLabel;
  final String colorHex;
  final String severityCode;
  final String severityLabel;
  final String title;
  final String content;
  final String actionGuide;
  final String status;
  final String issuedAt;

  const AlertModel({
    required this.id,
    required this.regionCode,
    required this.regionName,
    required this.categoryCode,
    required this.categoryLabel,
    required this.colorHex,
    required this.severityCode,
    required this.severityLabel,
    required this.title,
    required this.content,
    required this.actionGuide,
    required this.status,
    required this.issuedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
        id:            j['id'],
        regionCode:    j['region_code']    ?? '',
        regionName:    j['region_name']    ?? '',
        categoryCode:  j['category_code']  ?? '',
        categoryLabel: j['category_label'] ?? '',
        colorHex:      j['color_hex']      ?? '#9AA5B4',
        severityCode:  j['severity_code']  ?? '',
        severityLabel: j['severity_label'] ?? '',
        title:         j['title']          ?? '',
        content:       j['content']        ?? '',
        actionGuide:   j['action_guide']   ?? '',
        status:        j['status']         ?? '',
        issuedAt:      j['issued_at']      ?? '',
      );

  bool get isActive => status == 'ACTIVE';

  String get timeAgo {
    try {
      final dt = DateTime.parse(issuedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (_) {
      return '';
    }
  }

  AlertModel copyWith({
    String? title,
    String? content,
    String? actionGuide,
  }) =>
      AlertModel(
        id: id,
        regionCode: regionCode,
        regionName: regionName,
        categoryCode: categoryCode,
        categoryLabel: categoryLabel,
        colorHex: colorHex,
        severityCode: severityCode,
        severityLabel: severityLabel,
        title: title ?? this.title,
        content: content ?? this.content,
        actionGuide: actionGuide ?? this.actionGuide,
        status: status,
        issuedAt: issuedAt,
      );
}

class AlertCategory {
  final String code;
  final String labelEn;
  final String colorHex;

  const AlertCategory({
    required this.code,
    required this.labelEn,
    required this.colorHex,
  });

  factory AlertCategory.fromJson(Map<String, dynamic> j) => AlertCategory(
        code:     j['code']      ?? '',
        labelEn:  j['label_en']  ?? '',
        colorHex: j['color_hex'] ?? '#9AA5B4',
      );
}

// ── 번역 캐시 ─────────────────────────────────────────────────
final Map<String, Map<int, AlertModel>> _translateCache = {};

// ── 서비스 ────────────────────────────────────────────────────
class AlertService {

  /// Google Translate API (한국어 → 목표언어)
  static Future<String> _translateText(String text, String targetLang) async {
    if (text.isEmpty) return text;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final uri = Uri.parse(
          'https://translate.googleapis.com/translate_a/single'
          '?client=gtx&sl=ko&tl=$targetLang&dt=t'
          '&q=${Uri.encodeComponent(text)}',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final buffer = StringBuffer();
          for (final item in data[0]) {
            if (item[0] != null) buffer.write(item[0]);
          }
          final result = buffer.toString();
          if (result.isNotEmpty) return result;
        }
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    return text;
  }

  /// 번역하면서 배치마다 콜백으로 즉시 업데이트
  /// → 화면에 번역되는 즉시 표시됨
  static Future<void> fetchAlertsWithCallback({
    String lang = 'en',
    String? regionCode,
    String? categoryCode,
    String? status,
    required void Function(List<AlertModel>) onUpdate,
  }) async {
    final params = <String, String>{'lang': lang};
    if (regionCode   != null) params['region_code']   = regionCode;
    if (categoryCode != null) params['category_code'] = categoryCode;
    if (status       != null) params['status']        = status;

    final res = await ApiClient.get('/alerts', queryParams: params);
    final list = res['alerts'] as List<dynamic>? ?? [];
    final alerts = list.map((e) => AlertModel.fromJson(e)).toList();

    // 원본(한국어) 먼저 즉시 전달
    final result = List<AlertModel>.from(alerts);
    onUpdate(List.from(result));

    // 캐시 확인
    final cached = _translateCache[lang];

    // 5개씩 병렬 번역
    const batchSize = 5;
    for (int i = 0; i < alerts.length; i += batchSize) {
      final batch = alerts.sublist(
        i, (i + batchSize).clamp(0, alerts.length),
      );

      final futures = batch.map((alert) async {
        // 캐시 있으면 즉시 반환
        if (cached != null && cached.containsKey(alert.id)) {
          return MapEntry(alert.id, cached[alert.id]!);
        }

        // 번역 API 호출
        try {
          final results = await Future.wait([
            _translateText(alert.title, lang),
            _translateText(alert.content, lang),
            _translateText(alert.actionGuide, lang),
          ]);
          final translated = alert.copyWith(
            title:       results[0],
            content:     results[1],
            actionGuide: results[2],
          );
          _translateCache[lang] ??= {};
          _translateCache[lang]![alert.id] = translated;
          return MapEntry(alert.id, translated);
        } catch (_) {
          return MapEntry(alert.id, alert);
        }
      });

      final batchResults = await Future.wait(futures);

      // 배치 완료마다 결과 반영 후 즉시 화면 업데이트
      for (final entry in batchResults) {
        final idx = result.indexWhere((a) => a.id == entry.key);
        if (idx != -1) result[idx] = entry.value;
      }
      onUpdate(List.from(result)); // ← 배치마다 화면 갱신
    }
  }

  /// 기존 호환용 (캐시된 것만 반환, 번역 없음)
  static Future<List<AlertModel>> fetchAlerts({
    String lang = 'en',
    String? regionCode,
    String? categoryCode,
    String? status,
  }) async {
    final params = <String, String>{'lang': lang};
    if (regionCode   != null) params['region_code']   = regionCode;
    if (categoryCode != null) params['category_code'] = categoryCode;
    if (status       != null) params['status']        = status;

    final res = await ApiClient.get('/alerts', queryParams: params);
    final list = res['alerts'] as List<dynamic>? ?? [];
    return list.map((e) => AlertModel.fromJson(e)).toList();
  }

  /// 캐시 확인
  static bool isCached(String lang, int alertId) {
    return _translateCache[lang]?.containsKey(alertId) ?? false;
  }

  /// 번역 캐시 초기화
  static void clearCache([String? lang]) {
    if (lang != null) {
      _translateCache.remove(lang);
    } else {
      _translateCache.clear();
    }
  }

  /// 알림 상세 조회
  static Future<AlertModel> fetchAlertDetail(int id, {String lang = 'en'}) async {
    final res = await ApiClient.get('/alerts/$id', queryParams: {'lang': lang});
    return AlertModel.fromJson(res);
  }

  /// 카테고리 목록 조회
  static Future<List<AlertCategory>> fetchCategories() async {
    final res = await ApiClient.get('/alerts/categories');
    final list = res['categories'] as List<dynamic>? ?? [];
    return list.map((e) => AlertCategory.fromJson(e)).toList();
  }
}
