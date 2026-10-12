// Hava Durumu fetch buttons (owner, 2026-10-12): after a fetch the button
// turns orange ("…alındı") with "Sıfırla" beside it; Sıfırla puts the
// starting values back; typing into a filled field turns it back to gray.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';

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

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(_field(key)).controller!.text;

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      Scaffold(
        body: BallisticsScreen(
          profile: _profile,
          view: BallisticsView.environment,
        ),
      ),
      services: testServices(
        location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
        weather: TestWeather(
          observation(fetchedAt: DateTime.utc(2026, 10, 12)),
        ),
        pressure: TestPressure(const PressureRead(912.4)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('weather: gray → orange with Sıfırla → back to the start', (
    tester,
  ) async {
    await _pump(tester);
    const reset = Key('environment-weather-reset');
    expect(find.text('Konumdan canlı hava verisi al'), findsOneWidget);
    expect(find.byKey(reset), findsNothing);

    await _tap(tester, const Key('environment-fill-weather'));
    expect(find.text('Konumdan canlı hava verisi alındı'), findsOneWidget);
    expect(find.byKey(reset), findsOneWidget);
    expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');

    await _tap(tester, reset);
    expect(_text(tester, BallisticsFieldKeys.temperature), '15');
    expect(_text(tester, BallisticsFieldKeys.humidity), '50');
    expect(_text(tester, BallisticsFieldKeys.wind), '0');
    expect(_text(tester, BallisticsFieldKeys.altitude), '0');
    expect(_text(tester, BallisticsFieldKeys.pressure), '1013.25');
    expect(find.byKey(reset), findsNothing);
    expect(find.text('Konumdan canlı hava verisi al'), findsOneWidget);
  });

  testWidgets('weather: a typed value turns the button gray again', (
    tester,
  ) async {
    await _pump(tester);
    await _tap(tester, const Key('environment-fill-weather'));
    expect(find.byKey(const Key('environment-weather-reset')), findsOneWidget);
    await tester.ensureVisible(_field(BallisticsFieldKeys.temperature));
    await tester.enterText(_field(BallisticsFieldKeys.temperature), '20');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('environment-weather-reset')), findsNothing);
    expect(find.text('Konumdan canlı hava verisi al'), findsOneWidget);
    expect(_text(tester, BallisticsFieldKeys.temperature), '20');
  });

  testWidgets('pressure: orange with Sıfırla; Sıfırla puts 1013.25 back', (
    tester,
  ) async {
    await _pump(tester);
    const reset = Key('environment-pressure-reset');
    expect(find.text('Basıncı telefondan al'), findsOneWidget);
    expect(find.byKey(reset), findsNothing);

    await _tap(tester, const Key('environment-phone-pressure'));
    expect(find.text('Basınç telefondan alındı'), findsOneWidget);
    expect(_text(tester, BallisticsFieldKeys.pressure), '912.4');

    await _tap(tester, reset);
    expect(_text(tester, BallisticsFieldKeys.pressure), '1013.25');
    expect(find.text('Basıncı telefondan al'), findsOneWidget);
    expect(find.byKey(reset), findsNothing);
  });
}
