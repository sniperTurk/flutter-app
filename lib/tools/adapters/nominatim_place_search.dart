import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/tools_config.dart';
import '../ports/place_search.dart';

/// [PlaceSearch] for the OpenStreetMap Nominatim service (data © OpenStreetMap
/// contributors, ODbL). Usage-policy rules honoured here:
///  * identifying User-Agent with contact information;
///  * at most one request per second;
///  * search only on an explicit submit (never while typing);
///  * results are cached for the session.
class NominatimPlaceSearch implements PlaceSearch {
  final http.Client _client;
  final String _userAgent;
  final Duration _timeout;
  final Map<String, List<PlaceResult>> _cache = {};
  DateTime? _lastRequest;

  NominatimPlaceSearch({
    http.Client? client,
    String userAgent = ToolsConfig.metNoUserAgent,
    Duration timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       _userAgent = userAgent,
       _timeout = timeout;

  @override
  String get sourceName => 'OpenStreetMap Nominatim';

  @override
  Future<List<PlaceResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    if (_userAgent.contains(ToolsConfig.metNoPlaceholderMarker)) {
      throw const PlaceSearchFailure(
        PlaceSearchFailureKind.notConfigured,
        'Yer arama yapılandırılmadı: iletişim bilgisi eksik.',
      );
    }
    final key = q.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    final last = _lastRequest;
    if (last != null) {
      final wait = const Duration(milliseconds: 1100) -
          DateTime.now().difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastRequest = DateTime.now();

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q.length > 120 ? q.substring(0, 120) : q,
      'format': 'jsonv2',
      'limit': '6',
      'accept-language': 'tr',
    });
    final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const PlaceSearchFailure(
        PlaceSearchFailureKind.timeout,
        'Yer arama zaman aşımına uğradı.',
      );
    } on SocketException {
      throw const PlaceSearchFailure(
        PlaceSearchFailureKind.offline,
        'İnternet bağlantısı yok.',
      );
    } on http.ClientException {
      throw const PlaceSearchFailure(
        PlaceSearchFailureKind.offline,
        'İnternet bağlantısı yok.',
      );
    }
    if (response.statusCode != 200) {
      throw PlaceSearchFailure(
        PlaceSearchFailureKind.server,
        'Yer arama servisi hata verdi (${response.statusCode}).',
      );
    }
    final results = parse(utf8.decode(response.bodyBytes));
    _cache[key] = results;
    return results;
  }

  /// Parses a Nominatim `jsonv2` search response. Entries without valid
  /// coordinates are skipped.
  static List<PlaceResult> parse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const PlaceSearchFailure(
        PlaceSearchFailureKind.server,
        'Yer arama yanıtı okunamadı.',
      );
    }
    if (decoded is! List) {
      throw const PlaceSearchFailure(
        PlaceSearchFailureKind.server,
        'Yer arama yanıtı okunamadı.',
      );
    }
    final out = <PlaceResult>[];
    for (final e in decoded) {
      if (e is! Map) continue;
      final lat = double.tryParse('${e['lat']}');
      final lon = double.tryParse('${e['lon']}');
      final name = e['display_name'];
      if (lat == null ||
          lon == null ||
          name is! String ||
          lat < -90 ||
          lat > 90 ||
          lon < -180 ||
          lon > 180) {
        continue;
      }
      out.add(PlaceResult(name, lat, lon));
    }
    return out;
  }
}
