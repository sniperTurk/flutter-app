import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../tools/ports/product_report_service.dart';

/// A record the product box accepted: kept on the device for a later task
/// ("Ürününüz fabrika değerleriyle uygulamaya eklenmiştir" + "Profilime
/// uygula"; not shown anywhere yet).
class SentProductReport {
  final String id;
  final String tur;
  final DateTime createdAt;
  const SentProductReport(this.id, this.tur, this.createdAt);

  Map<String, Object> toJson() => {
    'id': id,
    'tur': tur,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  static SentProductReport? fromJson(Object? e) {
    if (e is! Map) return null;
    final id = e['id'], tur = e['tur'], at = e['createdAt'];
    if (id is! String || tur is! String || at is! String) return null;
    final t = DateTime.tryParse(at);
    return t == null ? null : SentProductReport(id, tur, t);
  }
}

/// Sends a typed product to the product box once per profile and remembers
/// what was sent (owner, 2026-10-17): a hash of the last sent values per
/// profile, so an unchanged product is not sent again, and the ids the box
/// returned. Fire-and-forget: [reportOnce] never throws and nothing is shown
/// to the user.
class ProductReportLedger {
  static const hashesKey = 'sniper_turk.product_reports.sent_hashes.v1';
  static const idsKey = 'sniper_turk.product_reports.ids.v1';

  /// Reports being sent right now (same key + hash): a second save while
  /// the first request is in flight does not send twice.
  static final Set<String> _inFlight = {};

  final ProductReportService service;
  final DateTime Function() now;

  ProductReportLedger(this.service, {DateTime Function()? now})
    : now = now ?? DateTime.now;

  /// FNV-1a (32 bit) of the values as canonical JSON (keys sorted). Only a
  /// change detector, not a security measure.
  static String hashOf(ProductReport report) {
    final keys = report.fields.keys.toList()..sort();
    final canonical = jsonEncode([
      report.kind.wireName,
      for (final k in keys) [k, report.fields[k]],
    ]);
    var h = 0x811c9dc5;
    for (final b in utf8.encode(canonical)) {
      h ^= b;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  /// The hash key of one profile's product of [kind].
  static String keyOf(String profileId, ProductReportKind kind) =>
      '${kind.wireName}:$profileId';

  /// Sends [report] unless the same values were already sent for
  /// [profileId]. On success the hash and the returned id are stored; on
  /// failure nothing is stored (a later save of that profile tries again).
  Future<void> reportOnce(String profileId, ProductReport report) async {
    final key = keyOf(profileId, report.kind);
    final hash = hashOf(report);
    final flight = '$key#$hash';
    if (_inFlight.contains(flight)) return;
    _inFlight.add(flight);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_hashes(prefs)[key] == hash) return;
      final id = await service.send(report);
      // Read again: another report may have been stored meanwhile.
      final hashes = _hashes(prefs)..[key] = hash;
      await prefs.setString(hashesKey, jsonEncode(hashes));
      final ids = sentReports(prefs)
        ..add(SentProductReport(id, report.kind.wireName, now()));
      await prefs.setString(
        idsKey,
        jsonEncode([for (final r in ids) r.toJson()]),
      );
    } catch (_) {
      // Offline, timeout, server error or storage error: saving the profile
      // never depends on this request, and the user sees nothing.
    } finally {
      _inFlight.remove(flight);
    }
  }

  static Map<String, String> _hashes(SharedPreferences prefs) {
    try {
      final d = jsonDecode(prefs.getString(hashesKey) ?? '{}');
      if (d is Map) {
        return {
          for (final e in d.entries)
            if (e.key is String && e.value is String)
              e.key as String: e.value as String,
        };
      }
    } on FormatException {
      // Unreadable: start over (the worst case is one more report).
    }
    return {};
  }

  /// The records the product box accepted, oldest first.
  static List<SentProductReport> sentReports(SharedPreferences prefs) {
    try {
      final d = jsonDecode(prefs.getString(idsKey) ?? '[]');
      if (d is List) {
        return [
          for (final e in d) SentProductReport.fromJson(e),
        ].whereType<SentProductReport>().toList();
      }
    } on FormatException {
      // Unreadable: keep what can be read from now on.
    }
    return [];
  }
}
