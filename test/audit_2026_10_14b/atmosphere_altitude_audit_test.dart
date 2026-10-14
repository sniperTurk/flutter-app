// Pre-TestFlight calculation audit 2026-10-14b — ATMOSPHERE / ALTITUDE /
// PRESSURE (#295 Denetim F1 and #307 İrtifa card).
//
// Chains checked (passing guards, no skip):
//  * F1: empty İstasyon basıncı → ISA station pressure from the EFFECTIVE
//    İrtifa (Telefondan irtifa, else Haritadan irtifa); a typed or phone
//    ("Basınç al") pressure wins and is never combined with the altitude.
//  * "Basınç irtifadan tahmin edildi." on Hedef for phone AND map-only
//    altitude; gone after İrtifa Sıfırla.
//  * Sıfırla on the İrtifa card (back to 1013,25 hPa) and on the Basınç
//    Ölçer card (back to the altitude estimate).
//  * Pressure plausibility warning with the effective altitude.
//  * Pro → Yerçekimi → Konumdan hesapla with the effective altitude.
//  * Saved data: older single 'altitude' → Telefondan irtifa, saved
//    'mapAltitude' → Haritadan irtifa, both used by the calculation.
//
// Findings (skip: until fixed):
//  * ATM-1 (high, suspected; pre-existing): the saved Hava Durumu is put
//    back AFTER the first automatic solve and nothing solves again, so a
//    workspace that opens on Hedef (the shell's default view) shows the
//    standard-atmosphere solution next to the restored boxes.
//  * ATM-2 (low): no visible ⓘ says that İrtifa is used only when
//    İstasyon basıncı is empty (EnvironmentFieldInfo.altitude is unused).
//  * ATM-3 (low): EnvironmentFieldInfo.pressure still names the button
//    "Basıncı telefondan al", renamed "Basınç al" by #307.
//
// Independent references (tools/test_denetim_2026_10_14b_atm.py):
// ICAO/US-1976 standard atmosphere from its base constants, dry-air ideal
// gas R = R*/M = 287.053 J/(kg·K), GRS80 series normal gravity with the
// free-air gradient 3.086e-6 s⁻². No ballistic app is used.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/tools/tools_services.dart';

import '../support/pro_sections.dart';
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

// ---- Independent references (dry air, 15 °C) ------------------------------
// ISA P(h) = 1013,25·(1 − 0,0065·h/288,15)^(g0·M/(R*·L)); ρ = P/(R·T).
const _rho0 = 1.2250; // 0 m, 1013,25 hPa
const _rho1500 = 1.0223; // 1500 m, 845,56 hPa
const _rho300 = 1.1821; // 300 m, 977,73 hPa
const _rho900hPa = 1.0881; // typed 900 hPa
const _rho998hPa = 1.2071; // phone barometer 998,4 hPa
const _rhoTol = 0.0008;

// GRS80 normal gravity at 39,9° N with the free-air gradient.
const _g1500 = 9.79698;
const _g300 = 9.80068;
const _g900 = 9.79883; // the fake GPS fix height
const _gTol = 1.5e-4;

const _note = Key('shot-pressure-from-altitude');
const _warning = Key('environment-pressure-warning');
const _altReset = Key('environment-altitude-reset');
const _pressureReset = Key('environment-pressure-reset');
const _pressureBtn = Key('environment-phone-pressure');
const _gravity = Key('pro-gravity');
const _gravityBtn = Key('pro-gravity-gps');

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

Future<void> _type(WidgetTester tester, Key key, String v) async {
  await tester.ensureVisible(_field(key));
  await tester.pumpAndSettle();
  await tester.enterText(_field(key), v);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Widget _screen(BallisticsView view) => Scaffold(
  body: BallisticsScreen(profile: _profile, view: view),
);

/// A fresh workspace on [view] (the old one is dropped first).
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

Future<void> _dope(WidgetTester tester) async {
  await tester.ensureVisible(find.text('DOPE oluştur'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('DOPE oluştur'));
  await tester.pumpAndSettle();
}

/// Balistik / DOPE page (Hava Durumu boxes + "Hava yoğunluğu"): 15 °C,
/// 0 % RH, then the given boxes, then DOPE oluştur.
Future<double> _densityWith(
  WidgetTester tester, {
  String pressure = '',
  String phone = '',
  String map = '',
}) async {
  final rig = _Rig();
  await _open(tester, rig, BallisticsView.all);
  await _type(tester, BallisticsFieldKeys.temperature, '15');
  await _type(tester, BallisticsFieldKeys.humidity, '0');
  await _type(tester, BallisticsFieldKeys.pressure, pressure);
  await _type(tester, BallisticsFieldKeys.altitude, phone);
  await _type(tester, BallisticsFieldKeys.mapAltitude, map);
  await _dope(tester);
  return _density(tester);
}

void _seed(Map<String, dynamic> json) {
  SharedPreferences.setMockInitialValues({
    ShotSettingsStore.keyFor(_profile.id): jsonEncode(json),
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('chain: F1 pressure from the effective İrtifa', () {
    testWidgets('neither box: 1013,25 hPa', (tester) async {
      expect(await _densityWith(tester), closeTo(_rho0, _rhoTol));
    });

    testWidgets('empty pressure + Telefondan irtifa 1500 m: ISA 845,6 hPa', (
      tester,
    ) async {
      expect(
        await _densityWith(tester, phone: '1500'),
        closeTo(_rho1500, _rhoTol),
      );
    });

    testWidgets('empty pressure + Haritadan irtifa only (300 m): ISA', (
      tester,
    ) async {
      expect(await _densityWith(tester, map: '300'), closeTo(_rho300, _rhoTol));
    });

    testWidgets('both filled, different: Telefondan wins', (tester) async {
      expect(
        await _densityWith(tester, phone: '1500', map: '300'),
        closeTo(_rho1500, _rhoTol),
      );
    });

    testWidgets('a typed pressure wins; the altitude is not applied again', (
      tester,
    ) async {
      expect(
        await _densityWith(tester, pressure: '900', phone: '1500', map: '300'),
        closeTo(_rho900hPa, _rhoTol),
      );
    });
  });

  group('chain: "Basınç al" + İrtifa never double counts', () {
    testWidgets('phone barometer 998,4 hPa with İrtifa 1500 m', (
      tester,
    ) async {
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.all);
      await _type(tester, BallisticsFieldKeys.temperature, '15');
      await _type(tester, BallisticsFieldKeys.humidity, '0');
      await _type(tester, BallisticsFieldKeys.altitude, '1500');
      await _tap(tester, _pressureBtn);
      expect(rig.pressure.reads, 1);
      expect(_text(tester, BallisticsFieldKeys.pressure), '998.4');
      // "Basınç al" leaves both İrtifa boxes alone (#307).
      expect(_text(tester, BallisticsFieldKeys.altitude), '1500');
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '');
      await _dope(tester);
      // The measured station pressure is used as is.
      expect(_density(tester), closeTo(_rho998hPa, _rhoTol));
      // 998 hPa cannot be the station pressure at 1500 m: warned.
      expect(find.byKey(_warning), findsOneWidget);
      expect(find.textContaining('1500 m irtifada'), findsOneWidget);
    });
  });

  group('chain: Sıfırla', () {
    testWidgets('İrtifa Sıfırla: both boxes empty, back to 1013,25 hPa', (
      tester,
    ) async {
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.all);
      await _type(tester, BallisticsFieldKeys.temperature, '15');
      await _type(tester, BallisticsFieldKeys.humidity, '0');
      await _type(tester, BallisticsFieldKeys.altitude, '1500');
      await _type(tester, BallisticsFieldKeys.mapAltitude, '300');
      await _dope(tester);
      expect(_density(tester), closeTo(_rho1500, _rhoTol));
      await _tap(tester, _altReset);
      expect(_text(tester, BallisticsFieldKeys.altitude), '');
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '');
      // Re-solved by the reset itself.
      expect(_density(tester), closeTo(_rho0, _rhoTol));
    });

    testWidgets('Basınç Sıfırla: the pressure is estimated from İrtifa', (
      tester,
    ) async {
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.all);
      await _type(tester, BallisticsFieldKeys.temperature, '15');
      await _type(tester, BallisticsFieldKeys.humidity, '0');
      await _type(tester, BallisticsFieldKeys.pressure, '900');
      await _type(tester, BallisticsFieldKeys.mapAltitude, '1500');
      await _dope(tester);
      expect(_density(tester), closeTo(_rho900hPa, _rhoTol));
      await _tap(tester, _pressureReset);
      expect(_text(tester, BallisticsFieldKeys.pressure), '');
      // İrtifa is untouched by the Basınç Ölçer Sıfırla.
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '1500');
      expect(_density(tester), closeTo(_rho1500, _rhoTol));
    });
  });

  group('chain: Hedef note "Basınç irtifadan tahmin edildi."', () {
    testWidgets('map-only altitude shows it; İrtifa Sıfırla removes it', (
      tester,
    ) async {
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.environment);
      await _type(tester, BallisticsFieldKeys.mapAltitude, '1500');
      await _view(tester, rig, BallisticsView.shot);
      expect(find.byKey(_note), findsOneWidget);

      await _view(tester, rig, BallisticsView.environment);
      await _tap(tester, _altReset);
      await _view(tester, rig, BallisticsView.shot);
      expect(find.byKey(_note), findsNothing);
    });

    testWidgets('a phone pressure ("Basınç al") hides it', (tester) async {
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.environment);
      await _type(tester, BallisticsFieldKeys.altitude, '1500');
      await _tap(tester, _pressureBtn);
      await _view(tester, rig, BallisticsView.shot);
      expect(find.byKey(_note), findsNothing);
    });
  });

  group('chain: pressure warning with the effective İrtifa', () {
    testWidgets('map only is checked; Telefondan wins over it', (
      tester,
    ) async {
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.environment);
      await _type(tester, BallisticsFieldKeys.pressure, '1013');
      await _type(tester, BallisticsFieldKeys.mapAltitude, '1500');
      expect(find.byKey(_warning), findsOneWidget);
      expect(find.textContaining('1500 m irtifada'), findsOneWidget);
      await _type(tester, BallisticsFieldKeys.altitude, '0');
      expect(find.byKey(_warning), findsNothing);
    });
  });

  group('chain: Yerçekimi → Konumdan hesapla uses the İrtifa card', () {
    Future<double> gravityAfter(
      WidgetTester tester, {
      required String phone,
      required String map,
    }) async {
      final rig = _Rig();
      await _open(tester, rig, BallisticsView.environment);
      await _type(tester, BallisticsFieldKeys.altitude, phone);
      await _type(tester, BallisticsFieldKeys.mapAltitude, map);
      await _view(tester, rig, BallisticsView.pro);
      await openProFor(tester, _gravityBtn);
      await _tap(tester, _gravityBtn);
      return double.parse(_text(tester, _gravity).replaceAll(',', '.'));
    }

    testWidgets('Telefondan irtifa (1500 m) over Haritadan (300 m)', (
      tester,
    ) async {
      expect(
        await gravityAfter(tester, phone: '1500', map: '300'),
        closeTo(_g1500, _gTol),
      );
      expect(find.textContaining('1500 m'), findsWidgets);
    });

    testWidgets('Haritadan irtifa when Telefondan is empty', (tester) async {
      expect(
        await gravityAfter(tester, phone: '', map: '300'),
        closeTo(_g300, _gTol),
      );
    });

    testWidgets('both empty: the GPS fix height (900 m)', (tester) async {
      expect(
        await gravityAfter(tester, phone: '', map: ''),
        closeTo(_g900, _gTol),
      );
    });
  });

  group('chain: saved İrtifa comes back and is calculated', () {
    testWidgets('older single İrtifa → Telefondan irtifa, used by F1', (
      tester,
    ) async {
      _seed({
        'weather': {'temperature': 15, 'humidity': 0, 'altitude': 1500},
      });
      await _open(tester, _Rig(), BallisticsView.all);
      expect(_text(tester, BallisticsFieldKeys.altitude), '1500');
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '');
      // A plain value (no fetch time): the button is not orange.
      expect(find.text('Telefondan'), findsOneWidget);
      await _dope(tester);
      expect(_density(tester), closeTo(_rho1500, _rhoTol));
    });

    testWidgets('saved Haritadan irtifa reopens orange and is used', (
      tester,
    ) async {
      _seed({
        'weather': {'temperature': 15, 'humidity': 0, 'mapAltitude': 1500},
        'altMapAt': DateTime(2026, 10, 14, 9).millisecondsSinceEpoch,
      });
      await _open(tester, _Rig(), BallisticsView.all);
      expect(_text(tester, BallisticsFieldKeys.altitude), '');
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '1500');
      expect(find.text('Haritadan alındı'), findsOneWidget);
      await _dope(tester);
      expect(_density(tester), closeTo(_rho1500, _rhoTol));
    });
  });

  group('ATM-1 restored Hava Durumu is solved without a tab switch', () {
    // The shell builds the workspace on BallisticsView.shot (IndexedStack,
    // Hedef default); the first automatic solve runs in a post-frame
    // callback, the saved settings arrive after it and are never solved.
    void seedAltitude() => _seed({
      'weather': {'temperature': 15, 'humidity': 0, 'altitude': 1500},
    });

    testWidgets(
      'Hava yoğunluğu after a restart matches the restored boxes',
      (tester) async {
        seedAltitude();
        await _open(tester, _Rig(), BallisticsView.all);
        expect(_text(tester, BallisticsFieldKeys.altitude), '1500');
        // No DOPE oluştur: the automatic solve must already use 1500 m.
        expect(_density(tester), closeTo(_rho1500, _rhoTol));
      },
      skip: false, // ATM-1: shows 1,2211 (standard atmosphere) until re-solved
    );

    testWidgets(
      'Hedef opened directly shows the F1 note for the restored İrtifa',
      (tester) async {
        seedAltitude();
        await _open(tester, _Rig(), BallisticsView.shot);
        expect(find.byKey(_note), findsOneWidget);
      },
      skip: false, // ATM-1: the first solve ran before the İrtifa was restored
    );

    testWidgets(
      'Hedef elevation is the same before and after a tab round trip',
      (tester) async {
        seedAltitude();
        final rig = _Rig();
        await _open(tester, rig, BallisticsView.shot);
        final first = tester
            .widget<ScopeDialView>(find.byType(ScopeDialView))
            .requiredUp;
        await _view(tester, rig, BallisticsView.environment);
        await _view(tester, rig, BallisticsView.shot);
        final after = tester
            .widget<ScopeDialView>(find.byType(ScopeDialView))
            .requiredUp;
        expect(after, isNotNull);
        expect(first, isNotNull);
        expect(first!, closeTo(after!, 1e-9));
      },
      skip: false, // ATM-1: first = standard atmosphere, after = 1500 m
    );
  });

  group('ATM-2 the İrtifa ⓘ says when İrtifa is used', () {
    test(
      'the İrtifa ⓘ mentions the empty-pressure rule',
      () {
        final t = EnvironmentFieldInfo.altitudeCard.toLowerCase();
        expect(t, contains('basınç'));
        expect(t, contains('boş'));
      },
      skip: false, // ATM-2: owner text dropped the F1 rule; .altitude unused
    );
  });

  group('ATM-3 pressure ⓘ names an existing button', () {
    test(
      'no "Basıncı telefondan al" after the #307 rename',
      () {
        expect(
          EnvironmentFieldInfo.pressure,
          isNot(contains('Basıncı telefondan al')),
        );
      },
      skip: false, // ATM-3: still the old name; phone_pressure_test locks it
    );
  });
}
