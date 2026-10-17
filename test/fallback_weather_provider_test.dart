// Google → MET Norway fallback (owner, 2026-10-17 20:37).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sniper_turk/tools/adapters/fallback_weather_provider.dart';
import 'package:sniper_turk/tools/adapters/google_weather_provider.dart';
import 'package:sniper_turk/tools/adapters/met_no_weather_provider.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';
import 'package:sniper_turk/tools/tools_services.dart';

import 'google_weather_provider_test.dart' show googleFixture;
import 'support/tool_fakes.dart';

const _ua = 'SniperTurk/1.0 test@example.invalid';
final _now = DateTime.utc(2026, 10, 17, 17, 10);

/// MET Norway compact body: one time step at 17:00 UTC.
String _metBody() => jsonEncode({
  'properties': {
    'timeseries': [
      {
        'time': '2026-10-17T17:00:00Z',
        'data': {
          'instant': {
            'details': {
              'air_temperature': 14.2,
              'relative_humidity': 61.0,
              'air_pressure_at_sea_level': 1016.4,
              'wind_from_direction': 225.0,
              'wind_speed': 3.4,
            },
          },
        },
      },
    ],
  },
});

class _Calls {
  int google = 0;
  int met = 0;
}

FallbackWeatherProvider _provider(
  _Calls calls, {
  String key = 'test-key-not-real',
  required Future<http.Response> Function() google,
  Future<http.Response> Function()? met,
  Duration googleTimeout = const Duration(seconds: 10),
}) => FallbackWeatherProvider(
  GoogleWeatherProvider(
    apiKey: key,
    clock: TestClock(_now),
    timeout: googleTimeout,
    client: MockClient((_) {
      calls.google++;
      return google();
    }),
  ),
  MetNoWeatherProvider(
    userAgent: _ua,
    clock: TestClock(_now),
    client: MockClient((_) {
      calls.met++;
      return (met ?? () async => http.Response(_metBody(), 200))();
    }),
  ),
);

void main() {
  test('Google answers → Google values, MET not asked', () async {
    final calls = _Calls();
    final o = await _provider(
      calls,
      google: () async =>
          http.Response.bytes(utf8.encode(jsonEncode(googleFixture())), 200),
    ).fetch(39.9, 32.8);
    expect(o.source, WeatherSource.google);
    expect(o.temperatureC, 13.7);
    expect(calls.google, 1);
    expect(calls.met, 0);
  });

  final googleFails = <String, Future<http.Response> Function()>{
    'HTTP 403': () async => http.Response('{}', 403),
    'HTTP 500': () async => http.Response('{}', 500),
    'HTTP 429': () async => http.Response('{}', 429),
    'network error': () async => throw http.ClientException('x'),
    'invalid data': () async => http.Response('{"temperature":{}}', 200),
  };
  for (final e in googleFails.entries) {
    test('Google ${e.key} → MET Norway values, source metNorway', () async {
      final calls = _Calls();
      final o = await _provider(calls, google: e.value).fetch(39.9, 32.8);
      expect(o.source, WeatherSource.metNorway);
      expect(o.sourceName, 'MET Norway (CC BY 4.0)');
      expect(o.temperatureC, 14.2);
      expect(o.windFromDeg, 225);
      expect(o.windSpeedMps, 3.4);
      expect(calls.google, 1);
      expect(calls.met, 1);
    });
  }

  test('Google timeout → MET Norway', () async {
    final calls = _Calls();
    final o = await _provider(
      calls,
      googleTimeout: const Duration(milliseconds: 10),
      google: () => Future<http.Response>.delayed(
        const Duration(seconds: 1),
        () => http.Response('{}', 200),
      ),
    ).fetch(39.9, 32.8);
    expect(o.source, WeatherSource.metNorway);
  });

  test('no Google key → no Google request, MET Norway', () async {
    final calls = _Calls();
    final o = await _provider(
      calls,
      key: '',
      google: () async => http.Response('{}', 200),
    ).fetch(39.9, 32.8);
    expect(o.source, WeatherSource.metNorway);
    expect(calls.google, 0);
    expect(calls.met, 1);
  });

  test('both fail → MET Norway failure as before', () async {
    final calls = _Calls();
    await expectLater(
      _provider(
        calls,
        google: () async => http.Response('{}', 500),
        met: () async => http.Response('', 503),
      ).fetch(39.9, 32.8),
      throwsA(
        isA<WeatherFailure>()
            .having((f) => f.kind, 'kind', WeatherFailureKind.server)
            .having((f) => f.message, 'message', 'Hava servisi hata verdi (503).'),
      ),
    );
  });

  test('production wiring: Google first, MET Norway second', () {
    final w = ToolsServices.production().weather;
    expect(w, isA<FallbackWeatherProvider>());
    final f = w as FallbackWeatherProvider;
    expect(f.primary, isA<GoogleWeatherProvider>());
    expect(f.secondary, isA<MetNoWeatherProvider>());
    expect(f.sourceName, 'Google ya da MET Norway (CC BY 4.0)');
  });
}
