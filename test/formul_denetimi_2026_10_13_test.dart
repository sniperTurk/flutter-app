// Formül denetimi 2026-10-13 (docs/research/formul_denetimi.md).
//
// 1. The production solver against an independent point-mass reference
//    (tools/formul_denetimi_2026_10_13.py: range-stepped RK4, form-factor
//    drag, ICAO dry air, secant zero) for the four loads the owner named.
// 2. Miller Sg below the speed of sound (Courtney & Miller 2012).
// 3. Spin drift: never for a diabolo pellet; the bullet length comes from
//    Profil > Mühimmat (owner, 2026-10-17 11:34, reversing 2026-10-13
//    23:32), an old Pro value only without one
//    (docs/reports/pro_barut_not.md).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/stability.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';


const _fps = 0.3048;
const _tenMph = 10 * 0.44704;

/// ICAO sea level, dry air (ICAO Doc 7488/3).
EnvironmentData _icao({double windMps = 0}) => EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 0,
  windMps: windMps,
  windDirectionDeg: 90, // saat 9: from the left, drift to the right
);

class _Load {
  final String id;
  final BallisticModel model;
  final double bc, grain, mvFps, zeroM, sightMm;

  /// (range m, elevation mrad, windage mrad for 10 mph, v m/s, TOF s),
  /// printed by `python3 tools/formul_denetimi_2026_10_13.py --dart`.
  final List<(double, double, double, double, double)> expected;
  const _Load(
    this.id,
    this.model,
    this.bc,
    this.grain,
    this.mvFps,
    this.zeroM,
    this.sightMm,
    this.expected,
  );
}

// dart format off
const _loads = [
  _Load('.308 168 gr G1 0.462 2650 fps', BallisticModel.g1, 0.462, 168, 2650,
      100, 38.1, [
    (100.0, -0.00000, -0.23464, 743.4172, 0.129054),
    (300.0, 1.63722, -0.76597, 623.6632, 0.422818),
    (500.0, 4.00890, -1.39862, 516.3174, 0.775457),
  ]),
  _Load('6.5 CM 140 gr G7 0.315 2710 fps', BallisticModel.g7, 0.315, 140,
      2710, 100, 38.1, [
    (100.0, -0.00000, -0.16572, 777.6705, 0.124771),
    (300.0, 1.44154, -0.52849, 685.8119, 0.398658),
    (500.0, 3.40908, -0.93876, 600.6240, 0.710317),
  ]),
  _Load('PCP 6.35 mm 50 gr slug G1 0.139 985 fps', BallisticModel.g1, 0.139,
      50, 985, 50, 50, [
    (50.0, -0.00000, -0.56460, 279.4235, 0.172854),
    (100.0, 2.63979, -1.09576, 262.5705, 0.357585),
    (200.0, 9.51088, -2.11592, 235.0537, 0.760800),
    (300.0, 17.73611, -3.13236, 212.0229, 1.209395),
  ]),
  _Load('PCP .22 18 gr pellet G1 0.03 900 fps', BallisticModel.g1, 0.03, 18,
      900, 30, 50, [
    (50.0, 1.06968, -2.34047, 212.7266, 0.208440),
    (100.0, 6.07199, -4.84911, 168.7727, 0.472985),
    (200.0, 24.39577, -11.24666, 104.4216, 1.232143),
    (300.0, 63.50888, -20.84566, 63.0753, 2.492372),
  ]),
];
// dart format on

BallisticInput _input(_Load l, {double windMps = 0}) => BallisticInput(
  muzzleVelocityMps: l.mvFps * _fps,
  grain: l.grain,
  zeroRangeM: l.zeroM,
  sightHeightMm: l.sightMm,
  rangesM: [for (final e in l.expected) e.$1],
  environment: _icao(windMps: windMps),
  ballisticCoefficient: l.bc,
  ballisticModel: l.model,
);

// --- widget fixtures -------------------------------------------------------

const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_pcp635',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Test',
  'model': 'PCP 6.35',
  'caliberMm': 6.35,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 17,
};
const _slug = <String, dynamic>{
  'id': 'manual_ammo_slug',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Test slug',
  'model': '',
  'caliberMm': 6.35,
  'grain': 50,
  'ammoType': 'slug',
  'bc': 0.139,
  'bcModel': 'g1',
  'lengthMm': 10,
};

/// The same slug saved without a length.
const _slugNoLength = <String, dynamic>{
  'id': 'manual_ammo_slug_nolen',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Test slug',
  'model': '',
  'caliberMm': 6.35,
  'grain': 50,
  'ammoType': 'slug',
  'bc': 0.139,
  'bcModel': 'g1',
};
const _pellet = <String, dynamic>{
  'id': 'manual_ammo_pellet',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Test pellet',
  'model': '',
  'caliberMm': 6.35,
  'grain': 25,
  'ammoType': 'pellet',
  'bc': 0.03,
  'bcModel': 'g1',
  'lengthMm': 8,
};

RifleProfile _pcpProfile(String ammoId) => RifleProfile(
  id: 'p-$ammoId',
  name: 'PCP',
  rifleId: 'manual_rifle_pcp635',
  ammunitionId: ammoId,
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 300,
  zeroRangeM: 50,
  sightHeightMm: 50,
);

void main() {
  group('solver vs independent point-mass reference (ICAO, 10 mph)', () {
    const engine = BallisticEngine();
    for (final l in _loads) {
      test(l.id, () {
        final calm = engine.solve(_input(l));
        final windy = engine.solve(_input(l, windMps: _tenMph));
        for (var i = 0; i < l.expected.length; i++) {
          final (r, elev, wind, v, tof) = l.expected[i];
          final reason = '${l.id} @ $r m';
          expect(calm[i].rangeM, r);
          // Both integrate the same equations; the app's 0.5 ms time step
          // and the reference's 0.02 m range step agree to ~1e-5 mrad in
          // a faithful Python port. 0.005 mrad = 1/20 of a 0.1 mrad click.
          expect(calm[i].correctionMrad, closeTo(elev, 0.005), reason: reason);
          expect(windy[i].windMrad, closeTo(wind, 0.005), reason: reason);
          expect(calm[i].velocityMps, closeTo(v, 0.02), reason: reason);
          expect(calm[i].timeOfFlightS, closeTo(tof, 1e-4), reason: reason);
        }
      });
    }
  });

  group('Miller Sg below the speed of sound (Courtney & Miller 2012)', () {
    double sg(double v, {double t = 15, double p = 1013.25}) =>
        Stability.millerSg(
          grain: 50,
          caliberMm: 6.35,
          twistIn: 17,
          lengthMm: 10,
          velocityMps: v,
          temperatureC: t,
          pressureHpa: p,
        );

    test('dry-air speed of sound: ICAO 340.29 m/s at 15 °C', () {
      expect(Stability.speedOfSoundMps(15), closeTo(340.29, 0.01));
    });

    test('subsonic uses the factor at the speed of sound', () {
      // Python reference (tools/formul_denetimi_2026_10_13.py miller_sg):
      // 2.78819 with the floor; 2.67417 with the slug's own 985 fps.
      expect(sg(985 * _fps), closeTo(2.788188, 1e-5));
      expect(sg(200), closeTo(sg(985 * _fps), 1e-12));
      expect(sg(Stability.speedOfSoundMps(15)), closeTo(sg(250), 1e-12));
      // Colder air: lower speed of sound, still the floor for 300 m/s.
      expect(sg(985 * _fps, t: -10, p: 1020), closeTo(2.491611, 1e-5));
    });

    test('supersonic is unchanged and still grows with velocity', () {
      expect(sg(400), greaterThan(sg(360)));
      expect(sg(360), greaterThan(sg(300)));
    });
  });

  // Owner, 2026-10-17 11:34: Mermi uzunluğu is a property of the bullet and
  // is entered on Profil > Mühimmat again (reverses 2026-10-13 23:32). The
  // profile length is used; without one, a length an older version saved in
  // Pro > Mermi uzunluğu (shot settings 'bulletLength') still is.
  group('spin drift: pellets excluded, the Profil length used', () {
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    Future<void> pump(
      WidgetTester tester,
      String ammoId, {
      String? legacyProLength,
    }) async {
      tester.view.physicalSize = const Size(430, 3000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        if (legacyProLength != null)
          ShotSettingsStore.keyFor('p-$ammoId'): jsonEncode(
            ShotSettings(bulletLengthText: legacyProLength).toJson(),
          ),
      });
      // A fresh screen, so the profile and its saved settings load again.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: Scaffold(
            body: BallisticsScreen(
              profile: _pcpProfile(ammoId),
              view: BallisticsView.shot,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    String? spinNote(WidgetTester tester) {
      final f = find.byKey(const Key('shot-spin-drift'));
      return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
    }

    testWidgets('slug: the saved Profil length gives spin drift', (
      tester,
    ) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_pcpRifle, _slug]),
      );
      await pump(tester, 'manual_ammo_slug');
      expect(spinNote(tester), contains('sağa'));
    });

    testWidgets('slug: the Profil length wins; an old Pro length is used '
        'only without one', (tester) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_pcpRifle, _slug, _slugNoLength]),
      );
      // Profil 10 mm, no Pro value.
      await pump(tester, 'manual_ammo_slug');
      final profile10 = spinNote(tester);
      expect(profile10, contains('sağa'));
      // Profil 10 mm and an old Pro 12 mm: the Profil length.
      await pump(tester, 'manual_ammo_slug', legacyProLength: '12');
      expect(spinNote(tester), profile10);
      // No Profil length, old Pro 10 mm: the same result as Profil 10 mm.
      await pump(tester, 'manual_ammo_slug_nolen', legacyProLength: '10');
      expect(spinNote(tester), profile10);
      // No Profil length, old Pro 12 mm: a different result, so the lines
      // above did not ignore the length.
      await pump(tester, 'manual_ammo_slug_nolen', legacyProLength: '12');
      final legacy12 = spinNote(tester);
      expect(legacy12, contains('sağa'));
      expect(legacy12, isNot(profile10));
      // Neither: no spin drift.
      await pump(tester, 'manual_ammo_slug_nolen');
      expect(spinNote(tester), isNull);
    });

    testWidgets('pellet: no spin drift even with a length', (tester) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_pcpRifle, _pellet]),
      );
      await pump(tester, 'manual_ammo_pellet', legacyProLength: '8');
      expect(find.byKey(const Key('shot-spin-drift')), findsNothing);
    });
  });
}
