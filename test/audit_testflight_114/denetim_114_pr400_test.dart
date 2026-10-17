// Denetim TestFlight 114, second target: PR #400 (feat/google-hava-verisi).
// Report: docs/reports/denetim-testflight-114.md (on audit/testflight-114).
//
// Independent references:
//  * Google Maps Platform Weather API, currentConditions (METRIC):
//    temperature °C, relativeHumidity %, airPressure.meanSeaLevelMillibars
//    (1 mbar = 1 hPa, sea-level reduced), wind.speed km/h. 1 m/s = 3,6 km/h
//    (SI definition), so 15 km/h = 4,1667 m/s.
//  * Owner 2026-10-17 20:14: "Rüzgâr ve basınç da buradan alınacaktı!"
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/tools/adapters/google_weather_provider.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';

String _body({double kmh = 15, double hpa = 1012.3}) => jsonEncode({
  'currentTime': '2026-10-17T17:00:00.123456789Z',
  'temperature': {'degrees': 18.5, 'unit': 'CELSIUS'},
  'relativeHumidity': 55,
  'airPressure': {'meanSeaLevelMillibars': hpa},
  'wind': {
    'direction': {'degrees': 315, 'cardinal': 'NORTHWEST'},
    'speed': {'value': kmh, 'unit': 'KILOMETERS_PER_HOUR'},
  },
});

void main() {
  final fetched = DateTime.utc(2026, 10, 17, 17, 1);

  test('units: km/h ÷ 3,6, hPa sea level, °C, %', () {
    final o = GoogleWeatherProvider.parse(_body(), fetchedAt: fetched);
    expect(o.windSpeedMps, closeTo(15 / 3.6, 1e-12));
    expect(o.pressureHpa, 1012.3);
    expect(o.pressureKind, PressureKind.seaLevel);
    expect(o.temperatureC, 18.5);
    expect(o.humidityPercent, 55);
    expect(o.windFromDeg, 315);
    expect(o.validAt, DateTime.utc(2026, 10, 17, 17, 0, 0, 123, 456));
    expect(o.source, WeatherSource.google);
  });

  test('wind 360° → 0°; implausible pressure (sea level 700) refused', () {
    final body = jsonDecode(_body()) as Map<String, dynamic>;
    (body['wind'] as Map)['direction'] = {'degrees': 360};
    expect(
      GoogleWeatherProvider.parse(
        jsonEncode(body),
        fetchedAt: fetched,
      ).windFromDeg,
      0,
    );
    expect(
      () => GoogleWeatherProvider.parse(_body(hpa: 700), fetchedAt: fetched),
      throwsA(isA<WeatherFailure>()),
    );
  });

  test('the sea-level pressure is never written to İstasyon basıncı (no '
      'sea-level → station double correction)', () {
    final src = File(
      'lib/features/ballistics/ballistics_screen.dart',
    ).readAsStringSync();
    final start = src.indexOf('Future<void> _fillWeather(');
    final end = src.indexOf('// ---- Phone barometer', start);
    final fill = src.substring(start, end);
    expect(fill.contains('put(pressure'), isFalse);
    expect(fill.contains('pressure.text'), isFalse);
  });

  test(
    'D114-1: Google pressure is offered to the page (owner 20:14)',
    () {
      final src = File(
        'lib/features/ballistics/ballistics_screen.dart',
      ).readAsStringSync();
      final start = src.indexOf('Future<void> _fillWeather(');
      final end = src.indexOf('// ---- Phone barometer', start);
      expect(src.substring(start, end), contains('obs.pressureHpa'));
    },
    skip:
        'D114-1 (ORTA): Google basıncı okunuyor ama sayfaya hiç '
        'yazılmıyor; sahip kararı gerekli (deniz seviyesi → istasyon için '
        'irtifa gerekir).',
  );
}
