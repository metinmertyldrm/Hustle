import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/analysis.dart';

class AnalysisException implements Exception {
  const AnalysisException(this.message);
  final String message;
  @override String toString() => message;
}

class AnalysisRepository {
  AnalysisRepository({required this.baseUrl, http.Client? client, this.timeout = const Duration(seconds: 12)})
      : client = client ?? http.Client();
  final String baseUrl;
  final http.Client client;
  final Duration timeout;
  static const cacheKey = 'last_analysis';

  Future<Analysis> fetch(String symbol, String interval) async {
    final uri = Uri.parse('$baseUrl/api/v1/analysis/$symbol').replace(
      queryParameters: {'interval': interval, 'limit': '200'});
    try {
      final response = await client.get(uri).timeout(timeout);
      if (response.statusCode == 400 || response.statusCode == 422) {
        throw const AnalysisException('Sembol veya zaman aralığı geçersiz.');
      }
      if (response.statusCode == 502) throw const AnalysisException('Piyasa veri sağlayıcısına ulaşılamıyor.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AnalysisException('Analiz servisi isteği tamamlayamadı.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      final analysis = Analysis.fromJson(decoded);
      if (analysis.symbol == '—') throw const FormatException();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(cacheKey, jsonEncode(analysis.toJson()));
      return analysis;
    } on TimeoutException { throw const AnalysisException('İstek zaman aşımına uğradı. Lütfen yeniden deneyin.');
    } on FormatException { throw const AnalysisException('Sunucudan geçersiz veri alındı.');
    } on http.ClientException { throw const AnalysisException('İnternet bağlantınızı kontrol edin.'); }
  }

  Future<Analysis?> cached() async {
    final raw = (await SharedPreferences.getInstance()).getString(cacheKey);
    if (raw == null) return null;
    try { final value = jsonDecode(raw); return value is Map<String, dynamic> ? Analysis.fromJson(value) : null; }
    on FormatException { return null; }
  }
}
