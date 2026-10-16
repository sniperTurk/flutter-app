// Formül denetimi 2026-10-14: the "?" and "✗" rows of
// docs/reports/formul_denetimi_2026_10_14.md, each as a minimal repro.
//
// Tests that describe the EXPECTED behaviour and failed on the audited code
// were `skip:`ped with the finding number. F1, F2, F3 and F5 are fixed
// (fix/denetim-f1-f2-f3-f5, report docs/reports/denetim_duzeltmeleri_
// f1_f2_f3_f5.md) and run; F4 stays skipped until the main session decides
// it. The other tests are controls that pin the part that was right.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

// ---- F1: altitude with an empty pressure box -----------------------------

const _catalogPcp = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

double _readDensity(WidgetTester tester) {
  final text = tester
      .widget<Text>(find.textContaining('Hava yoğunluğu:'))
      .data!;
  final match = RegExp(r'Hava yoğunluğu: ([\d,]+)').firstMatch(text)!;
  return double.parse(match.group(1)!.replaceAll(',', '.'));
}

Future<double> _densityAt(
  WidgetTester tester, {
  required String pressure,
  required String altitude,
}) async {
  await tester.pumpWidget(
    const MaterialApp(home: BallisticsScreen(profile: _catalogPcp)),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(BallisticsFieldKeys.temperature), '15');
  await tester.enterText(find.byKey(BallisticsFieldKeys.humidity), '0');
  await tester.enterText(find.byKey(BallisticsFieldKeys.pressure), pressure);
  await tester.enterText(find.byKey(BallisticsFieldKeys.altitude), altitude);
  await tester.ensureVisible(find.text('DOPE oluştur'));
  await tester.tap(find.text('DOPE oluştur'));
  await tester.pumpAndSettle();
  return _readDensity(tester);
}

// ICAO Doc 7488/3: 1500 m → 845.56 hPa; dry air at 15 °C → 1.0223 kg/m³.
const _isa1500Density = 1.0223;

// ---- F2 / F3: manual PCP and firearm records ------------------------------

const _pcpRifle = <String, dynamic>{
  'id': 'audit_rifle_pcp',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Audit',
  'model': 'PCP',
  'caliberMm': 5.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 18,
};
const _pcpAmmo = <String, dynamic>{
  'id': 'audit_ammo_pcp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Audit 18',
  'model': '',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.031,
  'bcModel': 'g1',
};
const _fxRifle = <String, dynamic>{
  'id': 'audit_rifle_fx',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Audit',
  'model': '308',
  'caliberMm': 7.82,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _fxAmmo = <String, dynamic>{
  'id': 'audit_ammo_fx',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Audit 168',
  'model': '',
  'caliberMm': 7.82,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};

/// Unregulated PCP zeroed at 100 m (the Atış default range), profile
/// velocity 270 m/s; the Profil table says 255 m/s at 120 bar and 270 m/s
/// at 200 bar.
RifleProfile _unregulated(double tubeBar) => RifleProfile(
  id: 'audit-pcp',
  name: 'PCP',
  rifleId: 'audit_rifle_pcp',
  ammunitionId: 'audit_ammo_pcp',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 100,
  sightHeightMm: 50,
  tubePressureBar: tubeBar,
  pressureVelocityTable: const [
    PressureVelocityPoint(bar: 120, mps: 255),
    PressureVelocityPoint(bar: 200, mps: 270),
  ],
);

/// .308 168 gr, 800 m/s, zero 100 m, 0 MOA mount; Gazi 6–36: 26 mrad
/// travel, 0.1 mrad click → 130 clicks each way from mid-travel.
const _fx = RifleProfile(
  id: 'audit-fx',
  name: 'FX',
  rifleId: 'audit_rifle_fx',
  ammunitionId: 'audit_ammo_fx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

Widget _app(RifleProfile profile, BallisticsView view) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: BallisticsScreen(profile: profile, view: view),
  ),
);

Future<ScopeDialView> _shotView(
  WidgetTester tester,
  RifleProfile profile,
) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(_app(profile, BallisticsView.pro));
  await tester.pumpAndSettle();
  await tester.pumpWidget(_app(profile, BallisticsView.shot));
  await tester.pumpAndSettle();
  return tester.widget<ScopeDialView>(find.byType(ScopeDialView));
}

void main() {
  group('F1 altitude with an empty İstasyon basıncı', () {
    testWidgets('control: a typed station pressure is used as is', (
      tester,
    ) async {
      final rho = await _densityAt(
        tester,
        pressure: '845.56',
        altitude: '1500',
      );
      expect(rho, closeTo(_isa1500Density, 0.0005));
    });

    testWidgets(
      'expected: empty pressure at 1500 m solves with ISA station pressure, '
      'not 1013.25 hPa',
      (tester) async {
        final rho = await _densityAt(tester, pressure: '', altitude: '1500');
        // Before the fix: 1.2250 (sea level), 20 % too dense.
        expect(rho, closeTo(_isa1500Density, 0.0005));
      },
    );
  });

  group('F2 / F3 Atış on the scope view', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_pcpRifle, _pcpAmmo, _fxRifle, _fxAmmo]),
      );
    });
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    testWidgets('control F3: table velocity = profile velocity → on zero', (
      tester,
    ) async {
      final v = await _shotView(tester, _unregulated(200));
      // 0.05 mrad: the shot uses the Hava default (%50 nem), the zero ICAO
      // dry air (0.016 mrad here); a click is 0.1 mrad.
      expect(v.requiredUp!.abs(), lessThan(0.05));
    });

    testWidgets('expected F3: at its own zero range the profile shoots on zero '
        '(same velocity for zero and shot)', (tester) async {
      final v = await _shotView(tester, _unregulated(120));
      // Before the fix: zero solved at 270 m/s, shot at 255 m/s → ≈ +1.0
      // mrad at the zero range itself.
      expect(v.requiredUp!.abs(), lessThan(0.05));
    });

    testWidgets('control F2: 0 MOA mount, travel taken from mid-travel', (
      tester,
    ) async {
      final v = await _shotView(tester, _fx);
      expect(v.halfElevationClicks, 130);
      expect(v.mountCantClicks, 0);
    });

    testWidgets(
      'expected F2: the zero itself uses ~1.26 mrad (≈13 clicks) of UP travel',
      (tester) async {
        final v = await _shotView(tester, _fx);
        // Before the fix: 130 (zero assumed at mid-travel).
        expect(v.maxElevationClicks, lessThanOrEqualTo(130 - 10));
      },
    );
  });

  group('F4 SFP calibration magnification', () {
    test('control: the SFP rule itself (calibration / magnification)', () {
      // A reticle calibrated at 10× read at 16×: one mark = 0.625 units.
      expect(
        ScopeDialMath.reticleSubtension(
          firstFocalPlane: false,
          magnification: 16,
          calibrationMagnification: 10,
        ),
        closeTo(0.625, 1e-12),
      );
    });

    test('expected: the calibration magnification comes from the scope, not '
        'its maximum magnification', () {
      final src = File(
        'lib/features/ballistics/scope_dial_view.dart',
      ).readAsStringSync();
      expect(src, isNot(contains('calibrationMag => maxMagnification')));
    }, skip: 'F4: SFP assumed calibrated at max magnification');
  });

  group('F5 leftover GA text (#195)', () {
    test('expected: no GA advice in the BC-from-two-velocities note', () {
      final src = File(
        'lib/features/tools/calculators_screen.dart',
      ).readAsStringSync();
      expect(src, isNot(contains('Diabolo saçmada GA')));
    });
  });
}
