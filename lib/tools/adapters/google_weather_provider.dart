import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/weather_policy.dart';
import '../ports/clock.dart';
import '../ports/weather_provider.dart';

/// [WeatherProvider] for the Google Maps Platform Weather API,
/// `currentConditions:lookup` (owner, 2026-10-17 20:37: sıcaklık, nem,
/// basınç ve rüzgâr Google'dan; Google cevap vermezse MET Norway).
///
///  * The key is the Google Maps iOS key the TestFlight build passes as
///    `--dart-define=GOOGLE_MAPS_IOS_API_KEY=…`; it is never committed and
///    never written to a message or log. A build without it sends nothing
///    ([WeatherFailureKind.notConfigured]).
///  * The key is restricted to the iOS app, so every request carries the
///    `X-Ios-Bundle-Identifier` header.
///  * Only the position rounded to 2 decimals (~1 km) is sent, as for MET
///    Norway ([WeatherPolicy.roundCoordinate]).
///  * `unitsSystem=METRIC`: temperature °C, humidity %, pressure
///    `meanSeaLevelMillibars` (1 mb = 1 hPa, sea-level reduced, so
///    [PressureKind.seaLevel] as MET), wind speed km/h → m/s = km/h ÷ 3,6.
///    Any other unit, a missing value or an implausible one is rejected
///    ([WeatherFailureKind.invalidResponse]) so the caller can fall back.
class GoogleWeatherProvider implements WeatherProvider {
  static const keyFromBuild = String.fromEnvironment('GOOGLE_MAPS_IOS_API_KEY');
  static const bundleId = 'com.sniperturk.sniperTurk';
  static const name = 'Google';

  final http.Client? _client;
  final String _apiKey;
  final Clock _clock;
  final Duration _timeout;

  const GoogleWeatherProvider({
    http.Client? client,
    String apiKey = keyFromBuild,
    Clock clock = const SystemClock(),
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client,
       _apiKey = apiKey,
       _clock = clock,
       _timeout = timeout;

  @override
  String get sourceName => name;

  /// The request URL. Exposed for tests; never log it (it holds the key).
  static Uri requestUri(double latitude, double longitude, String key) =>
      Uri.https('weather.googleapis.com', '/v1/currentConditions:lookup', {
        'key': key,
        'location.latitude': WeatherPolicy.roundCoordinate(
          latitude,
        ).toStringAsFixed(2),
        'location.longitude': WeatherPolicy.roundCoordinate(
          longitude,
        ).toStringAsFixed(2),
        'unitsSystem': 'METRIC',
      });

  @override
  Future<WeatherObservation> fetch(double latitude, double longitude) async {
    final key = _apiKey.trim();
    if (key.isEmpty) {
      throw const WeatherFailure(
        WeatherFailureKind.notConfigured,
        'Google hava servisi bu derlemede yapılandırılmamış.',
      );
    }
    if (!latitude.isFinite || !longitude.isFinite) {
      throw const WeatherFailure(
        WeatherFailureKind.invalidResponse,
        'Konum okunamadı.',
      );
    }
    final client = _client ?? http.Client();
    final http.Response response;
    try {
      response = await client
          .get(
            requestUri(latitude, longitude, key),
            headers: const {
              'X-Ios-Bundle-Identifier': bundleId,
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);
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
      // Its text holds the URL (and so the key): never passed on.
      throw const WeatherFailure(
        WeatherFailureKind.offline,
        'İnternet bağlantısı yok.',
      );
    } on IOException {
      throw const WeatherFailure(
        WeatherFailureKind.offline,
        'İnternet bağlantısı yok.',
      );
    } finally {
      if (_client == null) client.close();
    }
    final code = response.statusCode;
    if (code == 429) {
      throw const WeatherFailure(
        WeatherFailureKind.rateLimited,
        'Hava servisi istek sınırına ulaştı.',
      );
    }
    if (code != 200) {
      throw WeatherFailure(
        WeatherFailureKind.server,
        'Hava servisi hata verdi ($code).',
      );
    }
    return parse(
      utf8.decode(response.bodyBytes, allowMalformed: true),
      fetchedAt: _clock.now().toUtc(),
    );
  }

  /// Reads a `currentConditions:lookup` body (METRIC). Exposed for tests.
  static WeatherObservation parse(String body, {required DateTime fetchedAt}) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) throw const FormatException('root');
      double need(Object? v, String what) {
        if (v is! num || !v.isFinite) throw FormatException(what);
        return v.toDouble();
      }

      Map obj(Object? v, String what) {
        if (v is! Map) throw FormatException(what);
        return v;
      }

      final temp = obj(json['temperature'], 'temperature');
      if (temp['unit'] != 'CELSIUS') throw const FormatException('unit');
      final t = need(temp['degrees'], 'temperature');
      // Coldest / hottest air ever measured near the ground, with margin.
      if (t < -90 || t > 60) throw const FormatException('temperature');

      final h = json['relativeHumidity'];
      final humidity = need(h, 'humidity');
      if (humidity < 0 || humidity > 100) throw const FormatException('rh');

      final p = need(
        obj(json['airPressure'], 'pressure')['meanSeaLevelMillibars'],
        'pressure',
      );
      // Sea-level records are about 870 and 1084 hPa.
      if (p < 850 || p > 1100) throw const FormatException('pressure');

      final wind = obj(json['wind'], 'wind');
      final speed = obj(wind['speed'], 'speed');
      if (speed['unit'] != 'KILOMETERS_PER_HOUR') {
        throw const FormatException('speed unit');
      }
      final kmh = need(speed['value'], 'speed');
      // Strongest measured gust ~408 km/h; a mean wind beyond is not data.
      if (kmh < 0 || kmh > 410) throw const FormatException('speed');
      final mps = kmh / 3.6;

      // Calm air may come without a direction; then 0° (it is not used).
      final dir = wind['direction'];
      final double from;
      if (dir == null && kmh == 0) {
        from = 0;
      } else {
        from = need(obj(dir, 'direction')['degrees'], 'direction');
        if (from < 0 || from > 360) throw const FormatException('direction');
      }

      final time = json['currentTime'];
      if (time is! String) throw const FormatException('time');
      final validAt = DateTime.parse(time).toUtc();

      return WeatherObservation(
        temperatureC: t,
        humidityPercent: humidity,
        pressureHpa: p,
        pressureKind: PressureKind.seaLevel,
        windSpeedMps: mps,
        windFromDeg: from % 360,
        validAt: validAt,
        fetchedAt: fetchedAt.toUtc(),
        sourceName: name,
        source: WeatherSource.google,
      );
    } catch (_) {
      throw const WeatherFailure(
        WeatherFailureKind.invalidResponse,
        'Hava servisi yanıtı okunamadı.',
      );
    }
  }
}
