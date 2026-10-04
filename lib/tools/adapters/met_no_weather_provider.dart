import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/tools_config.dart';
import '../domain/weather_policy.dart';
import '../ports/clock.dart';
import '../ports/weather_provider.dart';

/// [WeatherProvider] for the MET Norway Locationforecast 2.0 API
/// (CC BY 4.0). Rules honoured here (from the service terms):
///  * identifying User-Agent with contact information is mandatory;
///  * coordinates are sent with at most 4 decimals;
///  * data is cached and `Expires` / `If-Modified-Since` are respected;
///  * no request is made while the app does not ask for data.
class MetNoWeatherProvider implements WeatherProvider {
  final http.Client _client;
  final Clock _clock;
  final String _userAgent;
  final Duration _timeout;
  final Map<String, _CacheEntry> _cache = {};

  MetNoWeatherProvider({
    http.Client? client,
    Clock clock = const SystemClock(),
    String userAgent = ToolsConfig.metNoUserAgent,
    Duration timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       _clock = clock,
       _userAgent = userAgent,
       _timeout = timeout;

  @override
  String get sourceName => 'MET Norway (CC BY 4.0)';

  @override
  Future<WeatherObservation> fetch(double latitude, double longitude) async {
    if (_userAgent.contains(ToolsConfig.metNoPlaceholderMarker)) {
      throw const WeatherFailure(
        WeatherFailureKind.notConfigured,
        'Hava servisi yapılandırılmadı: iletişim bilgisi eksik.',
      );
    }
    final lat = _round4(latitude), lon = _round4(longitude);
    final key =
        '${WeatherPolicy.roundCoordinate(latitude)},${WeatherPolicy.roundCoordinate(longitude)}';
    final cached = _cache[key];
    final now = _clock.now().toUtc();
    if (cached != null &&
        cached.expires != null &&
        now.isBefore(cached.expires!)) {
      return cached.observation;
    }

    final uri = Uri.https(
      'api.met.no',
      '/weatherapi/locationforecast/2.0/compact',
      {'lat': lat.toStringAsFixed(4), 'lon': lon.toStringAsFixed(4)},
    );
    final headers = <String, String>{
      'User-Agent': _userAgent,
      'Accept': 'application/json',
    };
    final lastModified = cached?.lastModified;
    if (lastModified != null) headers['If-Modified-Since'] = lastModified;

    final http.Response response;
    try {
      response = await _client.get(uri, headers: headers).timeout(_timeout);
    } on TimeoutException {
      throw const WeatherFailure(
        WeatherFailureKind.timeout,
        'Hava servisi zaman aşımına uğradı.',
      );
    } on SocketException {
      throw const WeatherFailure(
        WeatherFailureKind.offline,
        'İnternet bağlantısı yok.',
      );
    } on http.ClientException {
      throw const WeatherFailure(
        WeatherFailureKind.offline,
        'İnternet bağlantısı yok.',
      );
    }

    if (response.statusCode == 304 && cached != null) {
      final refreshed = _CacheEntry(
        cached.observation,
        _parseExpires(response.headers['expires']) ?? cached.expires,
        cached.lastModified,
      );
      _cache[key] = refreshed;
      return refreshed.observation;
    }
    if (response.statusCode == 429) {
      throw const WeatherFailure(
        WeatherFailureKind.rateLimited,
        'Hava servisi istek sınırına ulaştı.',
      );
    }
    if (response.statusCode != 200) {
      throw WeatherFailure(
        WeatherFailureKind.server,
        'Hava servisi hata verdi (${response.statusCode}).',
      );
    }
    final observation = parse(utf8.decode(response.bodyBytes), fetchedAt: now);
    _cache[key] = _CacheEntry(
      observation,
      _parseExpires(response.headers['expires']),
      response.headers['last-modified'],
    );
    return observation;
  }

  /// Parses a Locationforecast "compact" JSON body. Exposed for tests.
  static WeatherObservation parse(String body, {required DateTime fetchedAt}) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final series =
          (json['properties'] as Map<String, dynamic>)['timeseries']
              as List<dynamic>;
      if (series.isEmpty) throw const FormatException('empty timeseries');
      final now = fetchedAt.toUtc();
      Map<String, dynamic> pick = series.first as Map<String, dynamic>;
      for (final raw in series) {
        final entry = raw as Map<String, dynamic>;
        final t = DateTime.parse(entry['time'] as String).toUtc();
        if (t.isAfter(now)) break;
        pick = entry;
      }
      final data = pick['data'] as Map<String, dynamic>;
      final details =
          (data['instant'] as Map<String, dynamic>)['details']
              as Map<String, dynamic>;
      double need(String k) {
        final v = details[k];
        if (v is! num || !v.toDouble().isFinite) {
          throw FormatException('missing $k');
        }
        return v.toDouble();
      }

      final humidity = need('relative_humidity');
      final windFrom = need('wind_from_direction');
      final speed = need('wind_speed');
      if (humidity < 0 ||
          humidity > 100 ||
          speed < 0 ||
          windFrom < 0 ||
          windFrom > 360) {
        throw const FormatException('value out of range');
      }
      String? symbol;
      final next = data['next_1_hours'];
      if (next is Map<String, dynamic>) {
        final summary = next['summary'];
        if (summary is Map<String, dynamic>) {
          symbol = summary['symbol_code'] as String?;
        }
      }
      return WeatherObservation(
        temperatureC: need('air_temperature'),
        humidityPercent: humidity,
        pressureHpa: need('air_pressure_at_sea_level'),
        pressureKind: PressureKind.seaLevel,
        windSpeedMps: speed,
        windFromDeg: windFrom % 360,
        conditionCode: symbol,
        validAt: DateTime.parse(pick['time'] as String).toUtc(),
        fetchedAt: now,
        sourceName: 'MET Norway (CC BY 4.0)',
      );
    } on WeatherFailure {
      rethrow;
    } catch (_) {
      throw const WeatherFailure(
        WeatherFailureKind.invalidResponse,
        'Hava servisi yanıtı okunamadı.',
      );
    }
  }

  static double _round4(double v) => (v * 10000).round() / 10000;

  static DateTime? _parseExpires(String? header) {
    if (header == null) return null;
    try {
      return HttpDate.parse(header).toUtc();
    } catch (_) {
      return null;
    }
  }
}

class _CacheEntry {
  final WeatherObservation observation;
  final DateTime? expires;
  final String? lastModified;
  const _CacheEntry(this.observation, this.expires, this.lastModified);
}
