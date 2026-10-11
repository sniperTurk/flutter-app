// Pro Ayarlar: Enlem, Atış yönü and Yerçekimi are filled ONLY when the user
// taps "Konumdan al", "Pusuladan al" or "Konumdan hesapla" (owner,
// 2026-10-11: "tuşlarına basmadan veriler otomatik doluyor, bunu
// istemiyorum").
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/features/ballistics/pro_section_info.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/tools/ports/heading_provider.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/tools_services.dart';

import 'support/pro_sections.dart';
import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-noauto',
  name: 'Elle',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _lat = Key('pro-latitude');
const _az = Key('pro-azimuth');
const _g = Key('pro-gravity');

String _text(WidgetTester tester, Key key) => tester
    .widget<TextField>(
      find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
    )
    .controller!
    .text;

Future<void> _sized(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget _app(ToolsServices services, BallisticsView view) => host(
  Scaffold(
    body: BallisticsScreen(profile: _profile, view: view, autoWeather: true),
  ),
  services: services,
);

Future<void> _tap(WidgetTester tester, Key key) async {
  await openProFor(tester, key);
  final f = find.byKey(key);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

/// Reads all three Pro fields (their boxes open one at a time).
Future<({String lat, String az, String g})> _proValues(
  WidgetTester tester,
) async {
  await openProFor(tester, _lat);
  final lat = _text(tester, _lat);
  final az = _text(tester, _az);
  await openProFor(tester, _g);
  final g = _text(tester, _g);
  return (lat: lat, az: az, g: g);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('opening Pro reads neither the location nor the compass', (
    tester,
  ) async {
    await _sized(tester);
    final location = TestLocation(
      const LocationFix(39.9, 32.8, altitudeM: 900),
    );
    final heading = TestHeading();
    final services = testServices(location: location, heading: heading);
    await tester.pumpWidget(_app(services, BallisticsView.pro));
    await tester.pumpAndSettle();
    // A compass reading arriving on its own must not be picked up.
    heading.controller.add(const HeadingAvailable(HeadingReading(135)));
    await tester.pumpAndSettle();

    final v = await _proValues(tester);
    expect(v.lat, isEmpty);
    expect(v.az, isEmpty);
    expect(v.g, isEmpty);
    expect(location.calls, 0);
    expect(heading.controller.hasListener, isFalse);
    expect(find.text('Enlem konumdan alındı.'), findsNothing);
    expect(find.textContaining('Konumdan hesaplandı'), findsNothing);
  });

  testWidgets('the live weather fill on Hava Durumu leaves Pro alone', (
    tester,
  ) async {
    await _sized(tester);
    final location = TestLocation(
      const LocationFix(39.9, 32.8, altitudeM: 900),
    );
    final services = testServices(
      location: location,
      weather: TestWeather(observation(fetchedAt: DateTime.utc(2026, 10, 11))),
    );
    await tester.pumpWidget(_app(services, BallisticsView.environment));
    await tester.pumpAndSettle();
    // Hava Durumu did read the location for its own weather fields…
    expect(location.calls, 1);
    expect(
      find.textContaining('Hava verisi otomatik dolduruldu'),
      findsOneWidget,
    );

    await tester.pumpWidget(_app(services, BallisticsView.pro));
    await tester.pumpAndSettle();
    // …but Enlem, Atış yönü and Yerçekimi stay empty.
    final v = await _proValues(tester);
    expect(v.lat, isEmpty);
    expect(v.az, isEmpty);
    expect(v.g, isEmpty);
    expect(location.calls, 1);
  });

  testWidgets('each button fills its value when tapped', (tester) async {
    await _sized(tester);
    final location = TestLocation(const LocationFix(39.9, 32.8));
    final heading = TestHeading();
    final services = testServices(location: location, heading: heading);
    await tester.pumpWidget(_app(services, BallisticsView.pro));
    await tester.pumpAndSettle();

    await _tap(tester, const Key('pro-latitude-gps'));
    await tester.pumpAndSettle();
    expect(location.calls, 1);
    expect(_text(tester, _lat), '39.90');
    expect(find.text('Enlem konumdan alındı.'), findsOneWidget);
    expect(_text(tester, _az), isEmpty);

    await _tap(tester, const Key('pro-azimuth-compass'));
    await tester.pump();
    expect(heading.controller.hasListener, isTrue);
    heading.controller.add(const HeadingAvailable(HeadingReading(135.4)));
    await tester.pumpAndSettle();
    expect(_text(tester, _az), '135');
    expect(find.text('Atış yönü pusuladan alındı.'), findsOneWidget);

    await openProFor(tester, _g);
    expect(_text(tester, _g), isEmpty);
    await _tap(tester, const Key('pro-gravity-gps'));
    await tester.pumpAndSettle();
    expect(location.calls, 2);
    expect(_text(tester, _g), matches(RegExp(r'^9\.8\d{3}$')));
    expect(find.textContaining('Konumdan hesaplandı'), findsOneWidget);
  });

  testWidgets('values saved behind an old OFF switch do not come back', (
    tester,
  ) async {
    await _sized(tester);
    // Before 2026-10-11 Coriolis and Yerçekimi had on/off switches; a value
    // kept behind a switch that was off was never used. Showing it now
    // would fill the fields without a tap.
    SharedPreferences.setMockInitialValues({
      ShotSettingsStore.keyFor('p-noauto'): jsonEncode(
        const ShotSettings(
          coriolisOn: false,
          latitudeText: '39.90',
          azimuthText: '135',
          gravityOn: false,
          gravityText: '9.7988',
        ).toJson(),
      ),
    });
    final location = TestLocation(const LocationFix(39.9, 32.8));
    await tester.pumpWidget(
      _app(testServices(location: location), BallisticsView.pro),
    );
    await tester.pumpAndSettle();
    final v = await _proValues(tester);
    expect(v.lat, isEmpty);
    expect(v.az, isEmpty);
    expect(v.g, isEmpty);
    expect(location.calls, 0);
  });

  testWidgets('values the user obtained earlier are kept', (tester) async {
    await _sized(tester);
    SharedPreferences.setMockInitialValues({
      ShotSettingsStore.keyFor('p-noauto'): jsonEncode(
        const ShotSettings(
          coriolisOn: true,
          latitudeText: '41.0',
          azimuthText: '90',
          gravityOn: true,
          gravityText: '9.8030',
        ).toJson(),
      ),
    });
    final location = TestLocation(const LocationFix(39.9, 32.8));
    await tester.pumpWidget(
      _app(testServices(location: location), BallisticsView.pro),
    );
    await tester.pumpAndSettle();
    final v = await _proValues(tester);
    expect(v.lat, '41.0');
    expect(v.az, '90');
    expect(v.g, '9.8030');
    expect(location.calls, 0);
  });

  test('ⓘ texts say the values fill only on a tap', () {
    final texts = [
      EnvironmentFieldInfo.latitude,
      EnvironmentFieldInfo.azimuth,
      EnvironmentFieldInfo.gravity,
      ProSectionInfo.coriolis.how,
      ProSectionInfo.gravity.how,
    ];
    for (final t in texts) {
      expect(t, contains('dokununca'), reason: t);
      expect(t, isNot(contains('kendiliğinden hesaplanır')), reason: t);
      expect(t, isNot(contains('Düğmeyi aç')), reason: t);
    }
    expect(EnvironmentFieldInfo.gravity, isNot(contains('Kapalıyken')));
    expect(EnvironmentFieldInfo.coriolis, isNot(contains('Açıkken')));
    expect(EnvironmentFieldInfo.coriolisFirearm, isNot(contains('Açıkken')));
  });
}
