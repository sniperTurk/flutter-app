import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../ports/product_report_service.dart';

/// [ProductReportService] for the owner's Cloudflare product box (worker
/// `sniper-turk-urun-kutusu`, deployed by the owner; it writes each record to
/// the private repo sniperTurk/kullanici-urunleri). One HTTPS POST per
/// report, 10 s timeout, no retry. The body carries only the product kind,
/// the platform, the app version and the entered product values; the install
/// id is always null (no device or personal identifier is sent).
class CloudflareProductReportService implements ProductReportService {
  static final Uri endpoint = Uri.https(
    'sniper-turk-urun-kutusu.sekerbirol76.workers.dev',
    '/urun',
  );

  /// The worker's limits (owner, 2026-10-17): body ≤ 8 KB, ≤ 30 fields,
  /// keys `[A-Za-z0-9_]`, values ≤ 200 characters. A report outside them is
  /// not sent.
  static const maxBodyBytes = 8 * 1024;
  static const maxFields = 30;
  static const maxValueLength = 200;
  static final RegExp _key = RegExp(r'^[A-Za-z0-9_]+$');

  final http.Client _client;
  final String _appVersion;

  /// 10 s by default (owner, 2026-10-17).
  final Duration timeout;

  CloudflareProductReportService({
    required String appVersion,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _appVersion = appVersion;

  /// The JSON body for [report] (public for tests).
  static Map<String, Object?> bodyOf(ProductReport report, String appVersion) {
    if (report.fields.isEmpty || report.fields.length > maxFields) {
      throw const ProductReportFailure('Ürün alanları geçersiz.');
    }
    for (final e in report.fields.entries) {
      final v = e.value;
      if (!_key.hasMatch(e.key) ||
          (v is String && (v.isEmpty || v.length > maxValueLength)) ||
          (v is num && !v.isFinite) ||
          (v is! String && v is! num)) {
        throw const ProductReportFailure('Ürün alanları geçersiz.');
      }
    }
    return {
      'tur': report.kind.wireName,
      'platform': 'ios',
      'uygulamaSurumu': appVersion,
      'kurulumKimligi': null,
      'alanlar': report.fields,
    };
  }

  @override
  Future<String> send(ProductReport report) async {
    final body = utf8.encode(jsonEncode(bodyOf(report, _appVersion)));
    if (body.length > maxBodyBytes) {
      throw const ProductReportFailure('Ürün bilgisi çok uzun.');
    }
    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const ProductReportFailure('Zaman aşımı.');
    } catch (_) {
      // Offline, TLS (a Wi-Fi login page) or any other client error.
      throw const ProductReportFailure('Bağlantı yok.');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ProductReportFailure('Sunucu hatası (${response.statusCode}).');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ProductReportFailure('Yanıt okunamadı.');
    }
    if (decoded is Map && decoded['ok'] == true) {
      final id = decoded['id'];
      if (id is String && id.isNotEmpty && id.length <= 100) return id;
    }
    throw const ProductReportFailure('Yanıt okunamadı.');
  }
}
