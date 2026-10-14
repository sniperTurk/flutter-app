// Hava Durumu fetch buttons (owner, 2026-10-12): "Sıfırla" is always beside
// the button; after a fetch the button turns orange ("…alındı"); Sıfırla puts the
// starting values back and stays, orange, as "Veriler sıfırlandı"; typing
// into a filled field turns it back to gray.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';

import 'support/pro_sections.dart';
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
      const Scaffold(
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
        // Local 11:20: the done texts carry the fetch time (2026-10-14).
        clock: TestClock(DateTime(2026, 10, 12, 11, 20)),
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
    // "Sıfırla" is always there (owner, 2026-10-12).
    expect(find.byKey(reset), findsOneWidget);

    await _tap(tester, const Key('environment-fill-weather'));
    expect(find.text('Hava verisi alındı · 11:20'), findsOneWidget);
    expect(find.byKey(reset), findsOneWidget);
    expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');

    await _tap(tester, reset);
    // Sıfırla empties the boxes (owner, 2026-10-12).
    for (final k in [
      BallisticsFieldKeys.temperature,
      BallisticsFieldKeys.humidity,
      BallisticsFieldKeys.wind,
      BallisticsFieldKeys.altitude,
      BallisticsFieldKeys.pressure,
    ]) {
      expect(_text(tester, k), '', reason: '$k');
    }
    // The reset button stays, orange, as "Veriler sıfırlandı".
    expect(find.text('Veriler sıfırlandı'), findsOneWidget);
    expect(find.text('Tekrar canlı konum verisi al'), findsOneWidget);
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
    expect(find.textContaining('Hava verisi alındı'), findsNothing);
    expect(find.text('Konumdan canlı hava verisi al'), findsOneWidget);
    expect(_text(tester, BallisticsFieldKeys.temperature), '20');
  });

  testWidgets('pressure: orange with Sıfırla; Sıfırla empties the box', (
    tester,
  ) async {
    await _pump(tester);
    const reset = Key('environment-pressure-reset');
    expect(find.text('Basıncı telefondan al'), findsOneWidget);
    expect(find.byKey(reset), findsOneWidget);

    await _tap(tester, const Key('environment-phone-pressure'));
    expect(find.text('Basınç alındı · 11:20'), findsOneWidget);
    expect(_text(tester, BallisticsFieldKeys.pressure), '912.4');
    // İrtifa comes from the GPS on the same tap (owner, 2026-10-12).
    expect(_text(tester, BallisticsFieldKeys.altitude), '900');

    await _tap(tester, reset);
    expect(_text(tester, BallisticsFieldKeys.pressure), '');
    expect(_text(tester, BallisticsFieldKeys.altitude), '');
    expect(find.text('Basıncı telefondan al'), findsOneWidget);
    expect(find.text('Veriler sıfırlandı'), findsOneWidget);
  });

  testWidgets('Pro > Coriolis: Konumdan al → alındı; Sıfırla empties Enlem', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        const Scaffold(
          body: BallisticsScreen(profile: _profile, view: BallisticsView.pro),
        ),
        services: testServices(
          location: TestLocation(const LocationFix(38.07, 27.1)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openProFor(tester, const Key('pro-latitude'));
    expect(find.byKey(const Key('pro-latitude-reset')), findsOneWidget);
    await _tap(tester, const Key('pro-latitude-gps'));
    expect(_text(tester, const Key('pro-latitude')), '38.07');
    expect(find.text('Konumdan alındı'), findsOneWidget);
    await _tap(tester, const Key('pro-latitude-reset'));
    expect(_text(tester, const Key('pro-latitude')), '');
    expect(find.text('Konumdan al'), findsOneWidget);
    expect(find.text('Veriler sıfırlandı'), findsOneWidget);
  });
}
