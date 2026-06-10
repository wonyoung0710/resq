import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // 웹/iOS 시뮬레이터: localhost  /  Android 에뮬레이터: 10.0.2.2  /  실기기: 컴퓨터 IP
  static const String baseUrl = 'https://resq-backend-production.up.railway.app';

  static const Duration _timeout = Duration(seconds: 10);

  // ── GET ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: queryParams);

    final res = await http.get(uri).timeout(_timeout);
    return _handle(res);
  }

  // ── POST ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(_timeout);
    return _handle(res);
  }

  // ── PUT ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http
        .put(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(_timeout);
    return _handle(res);
  }

  // ── 공통 응답 처리 ─────────────────────────────────────────
  static Map<String, dynamic> _handle(http.Response res) {
    final decoded = json.decode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }
    throw Exception('API 오류 ${res.statusCode}: $decoded');
  }
}
