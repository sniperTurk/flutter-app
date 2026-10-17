// Google Weather API adapter (owner, 2026-10-17 20:37): the response shape
// below is built from Google's documented currentConditions:lookup example
// (developers.google.com/maps/documentation/weather/current-conditions).
// No live key: the key here is a placeholder and never reaches a network.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sniper_turk/tools/adapters/google_weather_provider.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';

import 'support/tool_fakes.dart';

const _key = 'test-key-not-real';

/// Google's documented METRIC example (Mountain View, 2025-01-28).
Map<String, dynamic> googleFixture() => {
  'currentTime': '2025-01-28T22:04:12.025273178Z',
  'timeZone': {'id': 'America/Los_Angeles'},
  'isDaytime': true,
  'weatherCondition': {
    'iconBaseUri': 'https://maps.gstatic.com/weather/v1/sunny',
    'description': {'text': 'Sunny', 'languageCode': 'en'},
    'type': 'CLEAR',
  },
  'temperature': {'degrees': 13.7, 'unit': 'CELSIUS'},
  'feelsLikeTemperature': {'degrees': 13.1, 'unit': 'CELSIUS'},
  'dewPoint': {'degrees': 1.1, 'unit': 'CELSIUS'},
  'relativeHumidity': 42,
  'uvIndex': 1,
  'precipitation': {
    'probability': {'percent': 0, 'type': 'RAIN'},
    'qpf': {'quantity': 0, 'unit': 'MILLIMETERS'},
  },
  'thunderstormProbability': 0,
  'airPressure': {'meanSeaLevelMillibars': 1019.16},
  'wind': {
    'direction': {'degrees': 335, 'cardinal': 'NORTH_NORTHWEST'},
    'speed': {'value': 8, 'unit': 'KILOMETERS_PER_HOUR'},
    'gust': {'value': 18, 'unit': 'KILOMETERS_PER_HOUR'},
  },
  'visibility': {'distance': 16, 'unit': 'KILOMETERS'},
  'cloudCover': 0,
};

final _fetchedAt = DateTime.utc(2025, 1, 28, 22, 5);

WeatherObservation _parse(Map<String, dynamic> json) =>
    GoogleWeatherProvider.parse(jsonEncode(json), fetchedAt: _fetchedAt);

Matcher _failure(WeatherFailureKind kind) =>
    throwsA(isA<WeatherFailure>().having((f) => f.kind, 'kind', kind));

void main() {
  group('GoogleWeatherProvider.parse', () {
    test('maps the documented fields', () {
      final o = _parse(googleFixture());
      expect(o.temperatureC, 13.7);
      expect(o.humidityPercent, 42);
      expect(o.pressureHpa, 1019.16); // 1 mb = 1 hPa
      expect(o.pressureKind, PressureKind.seaLevel);
      expect(o.windFromDeg, 335);
      expect(o.source, WeatherSource.google);
      expect(o.sourceName, 'Google');
      expect(o.fetchedAt, _fetchedAt);
      // Nanosecond fraction is accepted.
      expect(o.validAt, DateTime.utc(2025, 1, 28, 22, 4, 12, 25, 273));
    });

    test('wind speed km/h → m/s exactly (÷ 3,6)', () {
      expect(_parse(googleFixture()).windSpeedMps, 8 / 3.6);
      final j = googleFixture();
      (j['wind'] as Map)['speed'] = {
        'value': 36,
        'unit': 'KILOMETERS_PER_HOUR',
      };
      expect(_parse(j).windSpeedMps, 10.0);
      (j['wind'] as Map)['speed'] = {'value': 0, 'unit': 'KILOMETERS_PER_HOUR'};
      expect(_parse(j).windSpeedMps, 0.0);
    });

    test('360° is stored as 0°', () {
      final j = googleFixture();
      (j['wind'] as Map)['direction'] = {'degrees': 360, 'cardinal': 'NORTH'};
      expect(_parse(j).windFromDeg, 0);
    });

    test('calm wind without a direction reads as 0°', () {
      final j = googleFixture();
      (j['wind'] as Map).remove('direction');
      (j['wind'] as Map)['speed'] = {'value': 0, 'unit': 'KILOMETERS_PER_HOUR'};
      expect(_parse(j).windFromDeg, 0);
    });

    final bad = <String, void Function(Map<String, dynamic>)>{
      'missing temperature': (j) => j.remove('temperature'),
      'Fahrenheit temperature': (j) =>
          j['temperature'] = {'degrees': 56.6, 'unit': 'FAHRENHEIT'},
      'temperature 75 °C': (j) =>
          j['temperature'] = {'degrees': 75, 'unit': 'CELSIUS'},
      'temperature −95 °C': (j) =>
          j['temperature'] = {'degrees': -95, 'unit': 'CELSIUS'},
      'humidity 101': (j) => j['relativeHumidity'] = 101,
      'humidity −1': (j) => j['relativeHumidity'] = -1,
      'humidity text': (j) => j['relativeHumidity'] = '42',
      'missing pressure': (j) => j.remove('airPressure'),
      'pressure 500 hPa': (j) =>
          j['airPressure'] = {'meanSeaLevelMillibars': 500},
      'pressure 1200 hPa': (j) =>
          j['airPressure'] = {'meanSeaLevelMillibars': 1200},
      'mph wind': (j) =>
          (j['wind'] as Map)['speed'] = {'value': 5, 'unit': 'MILES_PER_HOUR'},
      'negative wind': (j) => (j['wind'] as Map)['speed'] = {
        'value': -1,
        'unit': 'KILOMETERS_PER_HOUR',
      },
      'wind 500 km/h': (j) => (j['wind'] as Map)['speed'] = {
        'value': 500,
        'unit': 'KILOMETERS_PER_HOUR',
      },
      'missing wind': (j) => j.remove('wind'),
      'direction 400°': (j) =>
          (j['wind'] as Map)['direction'] = {'degrees': 400},
      'direction −5°': (j) => (j['wind'] as Map)['direction'] = {'degrees': -5},
      'missing direction with wind': (j) =>
          (j['wind'] as Map).remove('direction'),
      'missing currentTime': (j) => j.remove('currentTime'),
      'bad currentTime': (j) => j['currentTime'] = 'yesterday',
    };
    for (final e in bad.entries) {
      test('rejects ${e.key}', () {
        final j = googleFixture();
        e.value(j);
        expect(() => _parse(j), _failure(WeatherFailureKind.invalidResponse));
      });
    }

    test('rejects a non-JSON body', () {
      expect(
        () => GoogleWeatherProvider.parse('<html>', fetchedAt: _fetchedAt),
        _failure(WeatherFailureKind.invalidResponse),
      );
    });
  });

  group('GoogleWeatherProvider.fetch', () {
    test('no key → no request, notConfigured', () async {
      var calls = 0;
      final p = GoogleWeatherProvider(
        apiKey: '  ',
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        p.fetch(39.9, 32.8),
        _failure(WeatherFailureKind.notConfigured),
      );
      expect(calls, 0);
    });

    test(
      'request: endpoint, rounded location, METRIC, bundle header',
      () async {
        late http.Request seen;
        final p = GoogleWeatherProvider(
          apiKey: _key,
          clock: TestClock(_fetchedAt),
          client: MockClient((r) async {
            seen = r;
            return http.Response.bytes(
              utf8.encode(jsonEncode(googleFixture())),
              200,
            );
          }),
        );
        final o = await p.fetch(39.91234, 32.85678);
        expect(o.source, WeatherSource.google);
        expect(o.fetchedAt, _fetchedAt);
        expect(seen.method, 'GET');
        expect(seen.url.scheme, 'https');
        expect(seen.url.host, 'weather.googleapis.com');
        expect(seen.url.path, '/v1/currentConditions:lookup');
        expect(seen.url.queryParameters['location.latitude'], '39.91');
        expect(seen.url.queryParameters['location.longitude'], '32.86');
        expect(seen.url.queryParameters['unitsSystem'], 'METRIC');
        expect(seen.url.queryParameters['key'], _key);
        expect(
          seen.headers['X-Ios-Bundle-Identifier'],
          'com.sniperturk.sniperTurk',
        );
      },
    );

    final codes = <int, WeatherFailureKind>{
      400: WeatherFailureKind.server,
      403: WeatherFailureKind.server,
      404: WeatherFailureKind.server,
      429: WeatherFailureKind.rateLimited,
      500: WeatherFailureKind.server,
      503: WeatherFailureKind.server,
    };
    for (final e in codes.entries) {
      test('HTTP ${e.key} → ${e.value.name}, key not in message', () async {
        final p = GoogleWeatherProvider(
          apiKey: _key,
          client: MockClient((_) async => http.Response('{}', e.key)),
        );
        await expectLater(
          p.fetch(39.9, 32.8),
          throwsA(
            isA<WeatherFailure>()
                .having((f) => f.kind, 'kind', e.value)
                .having((f) => f.message, 'message', isNot(contains(_key))),
          ),
        );
      });
    }

    test('socket error → offline', () async {
      final p = GoogleWeatherProvider(
        apiKey: _key,
        client: MockClient((_) async => throw const SocketException('x')),
      );
      await expectLater(
        p.fetch(39.9, 32.8),
        _failure(WeatherFailureKind.offline),
      );
    });

    test(
      'client error carrying the URL → offline, key not in message',
      () async {
        final p = GoogleWeatherProvider(
          apiKey: _key,
          client: MockClient(
            (r) async => throw http.ClientException('failed', r.url),
          ),
        );
        await expectLater(
          p.fetch(39.9, 32.8),
          throwsA(
            isA<WeatherFailure>()
                .having((f) => f.kind, 'kind', WeatherFailureKind.offline)
                .having((f) => f.toString(), 'text', isNot(contains(_key))),
          ),
        );
      },
    );

    test('a hanging connection → timeout', () async {
      final p = GoogleWeatherProvider(
        apiKey: _key,
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) => Completer<http.Response>().future),
      );
      await expectLater(
        p.fetch(39.9, 32.8),
        _failure(WeatherFailureKind.timeout),
      );
    });

    test('non-finite coordinates → no request', () async {
      var calls = 0;
      final p = GoogleWeatherProvider(
        apiKey: _key,
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        p.fetch(double.nan, 32.8),
        _failure(WeatherFailureKind.invalidResponse),
      );
      expect(calls, 0);
    });
  });
}
