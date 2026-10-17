// Hava/Rüzgâr notes (owner, 2026-10-17 20:40/20:44).
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/wind_source_note.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';

WeatherObservation _obs({
  WeatherSource source = WeatherSource.google,
  String name = 'Google',
  double deg = 315,
  double mps = 4.2,
}) => WeatherObservation(
  temperatureC: 15,
  humidityPercent: 50,
  pressureHpa: 1013,
  pressureKind: PressureKind.seaLevel,
  windSpeedMps: mps,
  windFromDeg: deg,
  // 20:00 local time on the test machine.
  validAt: DateTime(2026, 10, 17, 20).toUtc(),
  fetchedAt: DateTime(2026, 10, 17, 20, 5).toUtc(),
  sourceName: name,
  source: source,
);

void main() {
  test('owner example, Google', () {
    expect(
      windSourceNote(_obs()),
      'Google rüzgâr verisi (20:00): kuzeybatıdan, 315°, 4,2 m/s. '
      'Rüzgâr yönünü siz seçin.',
    );
  });

  test('MET Norway source', () {
    expect(
      windSourceNote(
        _obs(
          source: WeatherSource.metNorway,
          name: 'MET Norway (CC BY 4.0)',
          deg: 225,
          mps: 3.4,
        ),
      ),
      'MET Norway rüzgâr verisi (20:00): güneybatıdan, 225°, 3,4 m/s. '
      'Rüzgâr yönünü siz seçin.',
    );
  });

  test('all 8 directions with their suffix', () {
    const expected = {
      0: 'kuzeyden',
      45: 'kuzeydoğudan',
      90: 'doğudan',
      135: 'güneydoğudan',
      180: 'güneyden',
      225: 'güneybatıdan',
      270: 'batıdan',
      315: 'kuzeybatıdan',
    };
    for (final e in expected.entries) {
      expect(turkishWindFrom(e.key.toDouble()), e.value, reason: '${e.key}°');
      expect(
        windSourceNote(_obs(deg: e.key.toDouble())),
        contains(': ${e.value}, ${e.key}°,'),
      );
    }
  });

  test('sector edges', () {
    expect(turkishWindFrom(22.4), 'kuzeyden');
    expect(turkishWindFrom(22.5), 'kuzeydoğudan');
    expect(turkishWindFrom(337.4), 'kuzeybatıdan');
    expect(turkishWindFrom(337.5), 'kuzeyden');
  });

  test('0° and 360° are both north, written 0°', () {
    expect(windSourceNote(_obs(deg: 0)), contains('kuzeyden, 0°,'));
    expect(windSourceNote(_obs(deg: 360)), contains('kuzeyden, 0°,'));
    expect(windSourceNote(_obs(deg: 359.6)), contains('kuzeyden, 0°,'));
  });

  test('comma decimals, one digit', () {
    expect(windSourceNote(_obs(mps: 8 / 3.6)), contains(', 2,2 m/s.'));
    expect(windSourceNote(_obs(mps: 0)), contains(', 0,0 m/s.'));
    expect(windSourceNote(_obs(mps: 10)), contains(', 10,0 m/s.'));
  });

  test('an unnamed provider uses its own name', () {
    expect(
      windSourceNote(_obs(source: WeatherSource.other, name: 'Test servisi')),
      startsWith('Test servisi rüzgâr verisi (20:00): '),
    );
  });
}
