import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ports/product_report.dart';

/// [ProductReportSender] for our Cloudflare worker (owner, 2026-10-17). The
/// worker stores each report in a private repository; the URL is not a
/// secret. One HTTPS POST per tap on Gönder, nothing in the background.
class CloudflareProductReport implements ProductReportSender {
  static const String endpoint =
      'https://sniper-turk-urun-kutusu.sekerbirol76.workers.dev/urun';
  static const Duration defaultTimeout = Duration(seconds: 10);

  final http.Client? _client;
  final Duration _timeout;

  const CloudflareProductReport({
    http.Client? client,
    Duration timeout = defaultTimeout,
  }) : _client = client,
       _timeout = timeout;

  @override
  Future<void> send(Map<String, Object?> body) async {
    final client = _client ?? http.Client();
    final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const ProductReportFailure(
        ProductReportFailureKind.timeout,
        'Zaman aşımı.',
      );
    } on SocketException {
      throw const ProductReportFailure(
        ProductReportFailureKind.offline,
        'İnternet bağlantısı yok.',
      );
    } on http.ClientException {
      throw const ProductReportFailure(
        ProductReportFailureKind.offline,
        'Bağlantı kurulamadı.',
      );
    } finally {
      if (_client == null) client.close();
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ProductReportFailure(
        ProductReportFailureKind.server,
        'Sunucu ${response.statusCode} döndü.',
      );
    }
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }
    if (decoded is! Map || decoded['ok'] != true) {
      throw const ProductReportFailure(
        ProductReportFailureKind.server,
        'Sunucu kaydı onaylamadı.',
      );
    }
  }
}
