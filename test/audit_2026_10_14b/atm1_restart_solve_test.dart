// ATM-1 (pre-TestFlight audit 2026-10-14b, high): the saved Hava Durumu is
// put back after the first automatic solve. Fixed by solving again once the
// restore is written (fix/atm1-acilis-hesabi).
//
// The two ATM-1 tests are copied from audit/testflight-2026-10-14b
// (test/audit_2026_10_14b/atmosphere_altitude_audit_test.dart) with their
// `skip:` removed; the rest are the fix's own edge cases.
//
// Independent references (dry air, 15 °C; tools/test_denetim_2026_10_14b_atm.py):
// ISA P(h) = 1013,25·(1 − 0,0065·h/288,15)^(g0·M/(R*·L)); ρ = P/(R·T),
// R = 287,053 J/(kg·K). No ballistic app is used.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/tools/tools_services.dart';

import '../support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-atm',
  name: 'Atm',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _rho0 = 1.2250; // 0 m, 1013,25 hPa
const _rho1500 = 1.0223; // 1500 m, 845,56 hPa
const _rho900hPa = 1.0881; // typed 900 hPa
const _rhoTol = 0.0008;

const _note = Key('shot-pressure-from-altitude');
const _altReset = Key('environment-altitude-reset');

class _Rig {
  final TestClock clock = TestClock(DateTime(2026, 10, 14, 11, 20));
  final TestPressure pressure = TestPressure(const PressureRead(998.4));
  final TestLocation location = TestLocation(
    const LocationFix(39.9, 32.8, altitudeM: 900),
  );

  late final ToolsServices services = testServices(
    location: location,
    pressure: pressure,
    clock: clock,
  );
}

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

Widget _screen(BallisticsView view) => Scaffold(
  body: BallisticsScreen(profile: _profile, view: view),
);

/// A fresh workspace on [view] (the old one is dropped first) = a restart.
Future<void> _open(WidgetTester tester, _Rig rig, BallisticsView view) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(host(_screen(view), services: rig.services));
  await tester.pumpAndSettle();
}

/// Same workspace, another view (as the shell does between tabs).
Future<void> _view(WidgetTester tester, _Rig rig, BallisticsView view) async {
  await tester.pumpWidget(host(_screen(view), services: rig.services));
  await tester.pumpAndSettle();
}

double _density(WidgetTester tester) {
  final text = tester
      .widget<Text>(find.textContaining('Hava yoğunluğu:'))
      .data!;
  final m = RegExp(r'Hava yoğunluğu: ([\d,]+)').firstMatch(text)!;
  return double.parse(m.group(1)!.replaceAll(',', '.'));
}

void _seed(Map<String, dynamic> json) {
  SharedPreferences.setMockInitialValues({
    ShotSettingsStore.keyFor(_profile.id): jsonEncode(json),
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ATM-1 restored Hava Durumu is solved without a tab switch', () {
    // The shell builds the workspace on BallisticsView.shot (IndexedStack,
    // Hedef default); the first automatic solve runs in a post-frame
    // callback, the saved settings arrive after it.
    void seedAltitude() => _seed({
      'weather': {'temperature': 15, 'humidity': 0, 'altitude': 1500},
    });

    testWidgets('Hava yoğunluğu after a restart matches the restored boxes', (
      tester,
    ) async {
      seedAltitude();
      await _open(tester, _Rig(), BallisticsView.all);
      expect(_text(tester, BallisticsFieldKeys.altitude), '1500');
      // No DOPE oluştur: the automatic solve must already use 1500 m.
      expect(_density(tester), closeTo(_rho1500, _rhoTol));
    });

    testWidgets(
      'Hedef opened directly shows the F1 note for the restored İrtifa',
      (tester) async {
        seedAltitude();
        await _open(tester, _Rig(), BallisticsView.shot);
        expect(find.byKey(_note), findsOneWidget);
      },
    );

    testWidgets('opened on Profil, then Hedef (shot → shot): note shown', (
      tester,
    ) async {
      // The shell keeps the workspace on .shot while Profil is in front;
      // going to Hedef rebuilds it with the same view.
      seedAltitude();
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.shot);
      await _view(tester, rig, BallisticsView.shot);
      expect(find.byKey(_note), findsOneWidget);
    });

    testWidgets('tab switch Hava Durumu → Hedef keeps the restored solve', (
      tester,
    ) async {
      seedAltitude();
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.shot);
      await _view(tester, rig, BallisticsView.environment);
      await _view(tester, rig, BallisticsView.shot);
      expect(find.byKey(_note), findsOneWidget);
    });

    testWidgets('saved pressure only: typed 900 hPa is used, no F1 note', (
      tester,
    ) async {
      _seed({
        'weather': {'temperature': 15, 'humidity': 0, 'pressure': 900},
      });
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.all);
      expect(_text(tester, BallisticsFieldKeys.pressure), '900');
      expect(_density(tester), closeTo(_rho900hPa, _rhoTol));
      await _open(tester, rig, BallisticsView.shot);
      expect(find.byKey(_note), findsNothing);
    });

    testWidgets('saved pressure and İrtifa: altitude is not applied again', (
      tester,
    ) async {
      _seed({
        'weather': {
          'temperature': 15,
          'humidity': 0,
          'pressure': 900,
          'altitude': 1500,
        },
      });
      await _open(tester, _Rig(), BallisticsView.all);
      expect(_density(tester), closeTo(_rho900hPa, _rhoTol));
    });

    testWidgets('nothing saved: sea level, unchanged', (tester) async {
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.all);
      expect(_text(tester, BallisticsFieldKeys.altitude), '');
      expect(_text(tester, BallisticsFieldKeys.pressure), '');
      // Empty boxes = the standard atmosphere (as before the fix).
      expect(_density(tester), closeTo(1.2211, 0.0002));
      await _open(tester, rig, BallisticsView.shot);
      expect(find.byKey(_note), findsNothing);
    });

    testWidgets('İrtifa Sıfırla before the restart: back to sea level', (
      tester,
    ) async {
      seedAltitude();
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.all);
      expect(_density(tester), closeTo(_rho1500, _rhoTol));
      await _tap(tester, _altReset);
      expect(_text(tester, BallisticsFieldKeys.altitude), '');

      // Restart.
      await _open(tester, rig, BallisticsView.all);
      expect(_text(tester, BallisticsFieldKeys.altitude), '');
      expect(_text(tester, BallisticsFieldKeys.temperature), '15');
      expect(_density(tester), closeTo(_rho0, _rhoTol));
      await _open(tester, rig, BallisticsView.shot);
      expect(find.byKey(_note), findsNothing);
    });

    testWidgets('closed before the restore arrives: no error, no timer', (
      tester,
    ) async {
      seedAltitude();
      final rig = _Rig();
      await tester.pumpWidget(
        host(_screen(BallisticsView.shot), services: rig.services),
      );
      // Dropped before the saved settings are read back.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // flutter_test fails the test by itself if a Timer is still pending.
    });

    testWidgets('restored on Hedef, then closed: no pending timers', (
      tester,
    ) async {
      seedAltitude();
      await _open(tester, _Rig(), BallisticsView.shot);
      expect(find.byKey(_note), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
