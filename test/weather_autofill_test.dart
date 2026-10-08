// Hava Durumu fills itself from the location's live weather when it opens
// (owner, 2026-10-08); values the user typed are kept; sea-level pressure is
// only used after converting it with a known altitude.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/field_calc.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

String _text(WidgetTester tester, Key key) => tester
    .widget<TextField>(
      find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
    )
    .controller!
    .text;

Future<void> _pump(
  WidgetTester tester, {
  required LocationResult location,
  Object? weather,
  bool auto = true,
}) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      Scaffold(
        body: BallisticsScreen(
          profile: _profile,
          view: BallisticsView.environment,
          autoWeather: auto,
        ),
      ),
      services: testServices(
        location: TestLocation(location),
        weather: TestWeather(
          weather ?? observation(fetchedAt: DateTime.utc(2026, 10, 8, 17)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fills temperature, humidity, wind, altitude, station pressure', (
    tester,
  ) async {
    await _pump(
      tester,
      location: const LocationFix(39.9, 32.8, altitudeM: 900),
    );
    expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');
    expect(_text(tester, BallisticsFieldKeys.humidity), '55');
    expect(_text(tester, BallisticsFieldKeys.wind), '5.0');
    expect(_text(tester, BallisticsFieldKeys.altitude), '900');
    // 1012.3 hPa at sea level → station pressure at 900 m.
    expect(
      _text(tester, BallisticsFieldKeys.pressure),
      FieldCalc.stationPressureHpa(1012.3, 900).toStringAsFixed(1),
    );
    expect(find.textContaining('otomatik dolduruldu'), findsOneWidget);
    expect(find.textContaining('900 m irtifaya göre'), findsOneWidget);
  });

  testWidgets('without altitude the sea-level pressure is NOT used', (
    tester,
  ) async {
    await _pump(tester, location: const LocationFix(39.9, 32.8));
    expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');
    expect(_text(tester, BallisticsFieldKeys.pressure), '1013.25');
    expect(find.textContaining('basınç doldurulmadı'), findsOneWidget);
  });

  testWidgets('typed values are kept; "yeniden doldur" replaces them', (
    tester,
  ) async {
    await _pump(
      tester,
      location: const LocationFix(39.9, 32.8, altitudeM: 900),
      auto: false,
    );
    // Nothing is fetched without autoWeather.
    expect(_text(tester, BallisticsFieldKeys.temperature), '15');
    await tester.enterText(
      find.descendant(
        of: find.byKey(BallisticsFieldKeys.temperature),
        matching: find.byType(TextField),
      ),
      '25',
    );
    await tester.pump();
    final button = find.byKey(const Key('environment-fill-weather'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    // The explicit button takes the service values for every field.
    expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');
  });

  testWidgets('location refused: fields stay, the user is told', (
    tester,
  ) async {
    await _pump(
      tester,
      location: const LocationDenied(permanent: false),
    );
    expect(_text(tester, BallisticsFieldKeys.temperature), '15');
    expect(find.textContaining('Konum izni yok'), findsOneWidget);
  });

  testWidgets('service down: fields stay, the user is told', (tester) async {
    await _pump(
      tester,
      location: const LocationFix(39.9, 32.8, altitudeM: 900),
      weather: const WeatherFailure(WeatherFailureKind.offline, 'x'),
    );
    expect(_text(tester, BallisticsFieldKeys.temperature), '15');
    expect(find.textContaining('ulaşılamadı'), findsOneWidget);
  });
}
