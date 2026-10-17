// Pre-TestFlight calculation audit 2026-10-14b, area KUL: turret travel
// with the zero angle (#295 F2), the regulator-less PCP zero velocity
// (#295 F3), the GA text (#295 F5), the cleanup (#291) and the rifle
// "Listede yok" link (#289).
//
// References are hand calculations, not another ballistic app:
// tools/test_denetim_2026_10_14b_kul.py (vacuum closed form of the zero
// condition; RK4 point mass with the BRL G1 table in ICAO dry air).
//
// Findings encoded here (expected behaviour; `skip:` while the audited code
// fails it):
//   KUL-1 zero angle larger than half of the turret travel: DOWN travel
//         longer than the whole turret, UP silently 0, no "cannot zero"
//         note (fixed 2026-10-15, un-skipped).
//   KUL-2 Doğrulama (truing) wrote Namlu çıkış hızı, which an
//         unregulated PCP with a usable Profil table no longer uses for
//         zero or shot after F3. Fixed 2026-10-15: not written there, the
//         page says the speed comes from the pressure table.
//   KUL-3 PRO_TUBE_PRESSURE on, Pro box empty: the Profil Tüp basıncı and
//         table are ignored (skip, hidden flag). Closed 2026-10-16: the
//         flag, the Pro box and the table are deleted (owner), so its
//         source-text test went with them.
// Owner, 2026-10-16: the "Basınca göre hız" table is deleted; the pressures
// are kept but not in the formula. Owner, 2026-10-17: a PCP calculates
// with its Namlu çıkış hızı; the optional En düşük / En yüksek namlu çıkış
// hızı are saved only. The F3 and KUL-2 guards below pin that rule.
// The other tests are passing guards.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/tools/truing_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/library_source.dart';
import '../support/tool_fakes.dart';

// ---- Manual ("Listede yok") records, as a typed rifle is stored ----------

const _pcpRifle = <String, dynamic>{
  'id': 'kul_rifle_pcp',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Kul',
  'model': 'PCP',
  'caliberMm': 5.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 18,
};
const _pcpAmmo = <String, dynamic>{
  'id': 'kul_ammo_pcp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Kul 18',
  'model': '',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.031,
  'bcModel': 'g1',
};
const _fxRifle = <String, dynamic>{
  'id': 'kul_rifle_fx',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Kul',
  'model': '308',
  'caliberMm': 7.82,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _fxAmmo = <String, dynamic>{
  'id': 'kul_ammo_fx',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Kul 168',
  'model': '',
  'caliberMm': 7.82,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};

/// .308 168 gr G1 0,462, 800 m/s, 45 mm, zero 100 m on the Gazi 6–36
/// (26 mrad travel). Hand calc: zero angle 1,2601 mrad.
RifleProfile _fx({AngularUnit unit = AngularUnit.mrad, double mount = 0}) =>
    RifleProfile(
      id: 'kul-fx',
      name: 'FX',
      rifleId: 'kul_rifle_fx',
      ammunitionId: 'kul_ammo_fx',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 800,
      zeroRangeM: 100,
      sightHeightMm: 45,
      angularUnit: unit,
      mountCantMoa: mount,
    );

/// Catalog PCP without BC (vacuum): 270 m/s, zero 25 m, 60 mm.
/// Hand calc: zero angle 4,0815 mrad = 41 clicks of 0,1 mrad.
RifleProfile _vacuumPcp(String scopeId, {double mount = 0}) => RifleProfile(
  id: 'kul-vac',
  name: 'Vakum',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: scopeId,
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  mountCantMoa: mount,
);

/// PCP pellet G1 0,031, 50 mm, Profil table 120 bar → 255 m/s, 200 bar →
/// 270 m/s (and 100 bar → 240 m/s when [withLowPoint]).
RifleProfile _pcp({
  required double profileMps,
  required double zeroM,
  double? tubeBar,
  double? regulatorBar,
  bool withLowPoint = false,
  bool onePoint = false,
  double? minMps,
  double? maxMps,
}) => RifleProfile(
  id: 'kul-pcp',
  name: 'PCP',
  rifleId: 'kul_rifle_pcp',
  ammunitionId: 'kul_ammo_pcp',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: profileMps,
  pcpMinVelocityMps: minMps,
  pcpMaxVelocityMps: maxMps,
  zeroRangeM: zeroM,
  sightHeightMm: 50,
  pressureBar: regulatorBar,
  tubePressureBar: tubeBar,
  pressureVelocityTable: onePoint
      ? const [PressureVelocityPoint(bar: 120, mps: 255)]
      : [
          if (withLowPoint) const PressureVelocityPoint(bar: 100, mps: 240),
          const PressureVelocityPoint(bar: 120, mps: 255),
          const PressureVelocityPoint(bar: 200, mps: 270),
        ],
);

Widget _app(RifleProfile profile, BallisticsView view) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: BallisticsScreen(profile: profile, view: view),
  ),
);

/// Hedef (Atış) at its default range (100 m), as in
/// test/audit_2026_10_14/findings_audit_test.dart.
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

BallisticInput _input({
  double v = 800,
  double? zeroV,
  double zero = 100,
  double sight = 45,
  double? bc,
  EnvironmentData environment = const EnvironmentData(),
  double incline = 0,
  double cant = 0,
}) => BallisticInput(
  muzzleVelocityMps: v,
  grain: 168,
  zeroRangeM: zero,
  sightHeightMm: sight,
  rangesM: [zero],
  environment: environment,
  ballisticCoefficient: bc,
  ballisticModel: bc == null ? null : BallisticModel.g1,
  zeroMuzzleVelocityMps: zeroV,
  inclineDeg: incline,
  cantDeg: cant,
);

double _angle(BallisticInput i) => const BallisticEngine().zeroAngleMrad(i);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_pcpRifle, _pcpAmmo, _fxRifle, _fxAmmo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('F2 zero angle: magnitude and sign vs hand calculation', () {
    test('vacuum PCP 270 m/s, 25 m, 60 mm: 4,0815 mrad, bore above sight', () {
      final a = _angle(_input(v: 270, zero: 25, sight: 60));
      expect(a, greaterThan(0));
      expect(a, closeTo(4.0815, 0.0005));
    });

    test('the zero-day velocity is used, not today\'s (vacuum and G1)', () {
      // Vacuum: (s + g·x²/2v²)/x at 780 m/s → 1,2559 mrad.
      expect(_angle(_input(zeroV: 780)), closeTo(1.2559, 0.0005));
      expect(
        _angle(_input(zeroV: 780, bc: 0.462)),
        closeTo(_angle(_input(v: 780, bc: 0.462)), 1e-6),
      );
    });

    test('G1 .308: 1,2601 mrad; G1 pellet 280 m/s 30 m 50 mm: 3,768 mrad', () {
      expect(_angle(_input(bc: 0.462)), closeTo(1.2601, 0.003));
      expect(
        _angle(_input(v: 280, zero: 30, sight: 50, bc: 0.031)),
        closeTo(3.768, 0.01),
      );
    });

    test(
      'ICAO zero air: today\'s weather, incline and cant do not move it',
      () {
        final base = _angle(_input(bc: 0.462));
        const hot = EnvironmentData(
          temperatureC: 35,
          pressureHpa: 845.56,
          humidityPercent: 80,
          altitudeM: 1500,
          windMps: 5,
          windDirectionDeg: 270,
        );
        expect(
          _angle(_input(bc: 0.462, environment: hot)),
          closeTo(base, 1e-9),
        );
        expect(
          _angle(_input(bc: 0.462, incline: 30, cant: 5)),
          closeTo(base, 1e-9),
        );
      },
    );
  });

  group('F2 turret travel = report formula', () {
    testWidgets('MRAD 0 / 20 MOA mount: 117/143 and 175/85, needs unchanged', (
      tester,
    ) async {
      final flat = await _shotView(tester, _fx());
      expect(flat.halfElevationClicks, 130);
      expect(flat.zeroAngleClicks, 13);
      expect(flat.maxElevationClicks, 117);
      expect(flat.maxElevationDownClicks, 143);
      final upFlat = flat.requiredUp!;
      final mounted = await _shotView(tester, _fx(mount: 20));
      expect(mounted.mountCantClicks, 58);
      expect(mounted.maxElevationClicks, 175);
      expect(mounted.maxElevationDownClicks, 85);
      // The required correction does not depend on the mount or the zero
      // angle (limits only).
      expect(mounted.requiredUp!, closeTo(upFlat, 1e-9));
    });

    testWidgets('MOA turret: same angle in the turret unit, nearest click', (
      tester,
    ) async {
      final v = await _shotView(tester, _fx(unit: AngularUnit.moa));
      final click = v.clickValue;
      final half = (AngularUnit.moa.fromMrad(13) / click).floor();
      final zero = (AngularUnit.moa.fromMrad(1.2601) / click).round();
      expect(v.halfElevationClicks, half);
      expect(v.zeroAngleClicks, zero);
      expect(v.maxElevationClicks, half - zero);
      expect(v.maxElevationDownClicks, half + zero);
    });

    testWidgets('vacuum PCP on the Gazi: 41 clicks, up 89, down 171', (
      tester,
    ) async {
      final v = await _shotView(tester, _vacuumPcp('gazi-6-36'));
      expect(v.zeroAngleClicks, 41);
      expect(v.maxElevationClicks, 130 - 41);
      expect(v.maxElevationDownClicks, 130 + 41);
    });
  });

  group('KUL-1 zero angle beyond half of the travel', () {
    testWidgets(
      'Steiner Ranger 4 (7,2 mrad) on a 25 m / 60 mm PCP: up + down never '
      'exceed the whole travel',
      (tester) async {
        final v = await _shotView(
          tester,
          _vacuumPcp('lib-steiner-ranger-4-4-16x56-4a-i'),
        );
        final half = v.halfElevationClicks!;
        expect(half, 36);
        expect(v.zeroAngleClicks, 41);
        // Before the fix: up 0, down 36 + 41 = 77 > 72 (the whole turret).
        expect(
          v.maxElevationClicks + v.maxElevationDownClicks!,
          lessThanOrEqualTo(2 * half),
        );
      },
    );

    testWidgets('repro Hatsan Hercules 635 + Steiner Ranger 4: up 0, down 72, '
        '"sıfırlanamaz" note, mount suggestion from the unclamped travel', (
      tester,
    ) async {
      final v = await _shotView(
        tester,
        _vacuumPcp('lib-steiner-ranger-4-4-16x56-4a-i'),
      );
      expect(v.maxElevationClicks, 0);
      expect(v.maxElevationDownClicks, 72);
      expect(v.zeroAngleBlocksZero, isTrue);
      expect(v.mountBlocksZero, isFalse);
      final note = tester.widget<MenzilNotice>(
        find.byKey(ScopeDialKeys.zeroAngleNote),
      );
      expect(note.message, contains('sıfırlanamaz'));
      // 41 − 0 clicks up are needed to zero, the UP half is 36 clicks.
      expect(note.message, contains('yaklaşık 41 klik'));
      expect(note.message, contains('yukarı yolu 36 klik'));
      expect(find.byKey(ScopeDialKeys.mountZeroNote), findsNothing);

      // The required clicks on Hedef are not limited by the travel.
      final need = (v.requiredUp! / 0.1).round();
      expect(need, greaterThan(0));
      // Hand calc: a mount of m clicks gives UP 36 + m − 41, so the
      // mount must cover need − 36 + 41 clicks; 1 mrad = 10,8/π MOA.
      final needMoa = (need - 36 + 41) * 0.1 * 10.8 / math.pi;
      final travel = tester.widget<MenzilNotice>(
        find.byKey(ScopeDialKeys.travelNote),
      );
      expect(travel.message, contains('${needMoa.ceil()} MOA'));
      // Before the fix the suggestion was 5 clicks (0,5 mrad) short.
      final oldMoa = need * 0.1 * 10.8 / math.pi;
      if (oldMoa.ceil() != needMoa.ceil()) {
        expect(travel.message, isNot(contains('${oldMoa.ceil()} MOA')));
      }
    });

    testWidgets(
      'normal: Ranger 4 with a 20 MOA mount: no note, up 53, down 19',
      (tester) async {
        final v = await _shotView(
          tester,
          _vacuumPcp('lib-steiner-ranger-4-4-16x56-4a-i', mount: 20),
        );
        // 20 MOA = 5,818 mrad → 58 clicks (rounded down).
        expect(v.mountCantClicks, 58);
        expect(v.maxElevationClicks, 36 + 58 - 41);
        expect(v.maxElevationDownClicks, 36 - 58 + 41);
        expect(
          v.maxElevationClicks + v.maxElevationDownClicks!,
          2 * v.halfElevationClicks!,
        );
        expect(v.zeroAngleBlocksZero, isFalse);
        expect(find.byKey(ScopeDialKeys.zeroAngleNote), findsNothing);
        expect(find.byKey(ScopeDialKeys.mountZeroNote), findsNothing);
      },
    );

    testWidgets('normal: Gazi 6-36, zero inside half: no note, full travel', (
      tester,
    ) async {
      final v = await _shotView(tester, _vacuumPcp('gazi-6-36'));
      expect(v.zeroAngleBlocksZero, isFalse);
      expect(find.byKey(ScopeDialKeys.zeroAngleNote), findsNothing);
      expect(
        v.maxElevationClicks + v.maxElevationDownClicks!,
        2 * v.halfElevationClicks!,
      );
    });

    testWidgets('required clicks do not depend on the travel clamp', (
      tester,
    ) async {
      final ranger = await _shotView(
        tester,
        _vacuumPcp('lib-steiner-ranger-4-4-16x56-4a-i'),
      );
      final upRanger = ranger.requiredUp!;
      final gazi = await _shotView(tester, _vacuumPcp('gazi-6-36'));
      // Same rifle, ammo, zero and range: same required angle in mrad.
      expect(upRanger, closeTo(gazi.requiredUp!, 1e-9));
    });
  });

  group('F3 regulator-less PCP zero velocity', () {
    testWidgets('unregulated, table at Profil tube pressure: on zero', (
      tester,
    ) async {
      final v = await _shotView(
        tester,
        _pcp(profileMps: 270, zeroM: 100, tubeBar: 120),
      );
      expect(v.requiredUp!.abs(), lessThan(0.05));
    });

    testWidgets('one-point table: profile velocity, on zero', (tester) async {
      final v = await _shotView(
        tester,
        _pcp(profileMps: 270, zeroM: 100, tubeBar: 120, onePoint: true),
      );
      expect(v.requiredUp!.abs(), lessThan(0.05));
    });

    testWidgets('regulated, tube above regulator: on zero', (tester) async {
      final v = await _shotView(
        tester,
        _pcp(profileMps: 270, zeroM: 100, tubeBar: 200, regulatorBar: 150),
      );
      expect(v.requiredUp!.abs(), lessThan(0.05));
    });

    testWidgets('regulated, stored tube below regulator: still on zero (the '
        'pressures are not in the formula since 2026-10-16)', (tester) async {
      // 120 bar < 150 bar regulator; table 100 → 240, 120 → 255 m/s.
      final v = await _shotView(
        tester,
        _pcp(
          profileMps: 270,
          zeroM: 100,
          tubeBar: 120,
          regulatorBar: 150,
          withLowPoint: true,
        ),
      );
      expect(v.requiredUp!.abs(), lessThan(0.05));
    });

    testWidgets('design guard: the Profil Namlu çıkış hızı enters the solve, '
        'a saved table does not', (tester) async {
      final a = await _shotView(
        tester,
        _pcp(profileMps: 270, zeroM: 30, tubeBar: 120),
      );
      final upA = a.requiredUp!;
      final b = await _shotView(
        tester,
        _pcp(profileMps: 240, zeroM: 30, tubeBar: 120),
      );
      // Slower pellet, zeroed at 30 m: more drop at 100 m.
      expect(b.requiredUp!, greaterThan(upA + 0.3));
    });

    testWidgets('design guard: with En düşük | En yüksek the Namlu çıkış '
        'hızı still enters the solve, their mean does not', (tester) async {
      final a = await _shotView(
        tester,
        _pcp(profileMps: 240, zeroM: 30, minMps: 260, maxMps: 280),
      );
      final b = await _shotView(
        tester,
        _pcp(profileMps: 240, zeroM: 30, onePoint: true),
      );
      expect(a.requiredUp!, closeTo(b.requiredUp!, 1e-9));
    });
  });

  group('KUL-2 Doğrulama and the PCP velocity', () {
    // Owner, 2026-10-16: the table is deleted. Owner, 2026-10-17: the Namlu
    // çıkış hızı is trued and applied as before, with or without En düşük |
    // En yüksek (saved only, kept as they were).
    Future<MemoryProfileStore> pumpTruing(
      WidgetTester tester,
      RifleProfile p,
    ) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final store = MemoryProfileStore();
      await store.save(p);
      final active = MemoryActiveProfileStore()..value = p.id;
      await tester.pumpWidget(
        host(TruingScreen(profileStore: store, activeProfileStore: active)),
      );
      await tester.pumpAndSettle();
      return store;
    }

    Future<void> computeAt100(WidgetTester tester) async {
      // Observation of a 240 m/s shot at 100 m (zero 30 m, 50 mm).
      final observed = const BallisticEngine()
          .solve(
            BallisticInput(
              muzzleVelocityMps: 240,
              grain: 18,
              zeroRangeM: 30,
              sightHeightMm: 50,
              rangesM: const [100],
              ballisticCoefficient: 0.031,
              ballisticModel: BallisticModel.g1,
            ),
          )
          .single
          .correctionMrad;
      await tester.enterText(find.byKey(const Key('truing-range')), '100');
      await tester.enterText(
        find.byKey(const Key('truing-observed')),
        observed.toStringAsFixed(4).replaceAll('.', ','),
      );
      await tester.ensureVisible(find.byKey(const Key('truing-compute')));
      await tester.tap(find.byKey(const Key('truing-compute')));
      await tester.pumpAndSettle();
    }

    testWidgets('with En düşük | En yüksek: the Namlu çıkış hızı is trued '
        'and applied; the pair is kept', (tester) async {
      final store = await pumpTruing(
        tester,
        _pcp(
          profileMps: 270,
          zeroM: 30,
          tubeBar: 120,
          minMps: 250,
          maxMps: 260,
        ),
      );
      expect(find.textContaining('ortalama'), findsNothing);
      expect(find.textContaining('Basınca göre hız'), findsNothing);
      await computeAt100(tester);
      expect(find.byKey(const Key('truing-result')), findsOneWidget);
      final apply = find.byKey(const Key('truing-apply'));
      await tester.ensureVisible(apply);
      expect(
        tester.widget<MenzilSecondaryButton>(apply).onPressed,
        isNotNull,
      );
      await tester.tap(apply);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('truing-confirm')));
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      expect(saved.muzzleVelocityMps, closeTo(240, 0.5));
      expect(saved.pcpMinVelocityMps, 250);
      expect(saved.pcpMaxVelocityMps, 260);
      expect(saved.pressureVelocityTable, hasLength(2));
    });

    for (final onePoint in [false, true]) {
      testWidgets('saved table (${onePoint ? 'one point' : 'usable'}), no En '
          'düşük | En yüksek: velocity is applied, the table ignored', (
        tester,
      ) async {
        final store = await pumpTruing(
          tester,
          _pcp(profileMps: 270, zeroM: 30, tubeBar: 120, onePoint: onePoint),
        );
        await computeAt100(tester);
        final apply = find.byKey(const Key('truing-apply'));
        await tester.ensureVisible(apply);
        expect(
          tester.widget<MenzilSecondaryButton>(apply).onPressed,
          isNotNull,
        );
        await tester.tap(apply);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('truing-confirm')));
        await tester.pumpAndSettle();
        final saved = (await store.all()).single;
        expect(saved.muzzleVelocityMps, closeTo(240, 0.5));
        // The saved table is carried, never erased.
        expect(saved.pressureVelocityTable, hasLength(onePoint ? 1 : 2));
      });
    }

    testWidgets('regulated PCP above the regulator: velocity is applied as '
        'before', (tester) async {
      await pumpTruing(
        tester,
        _pcp(profileMps: 270, zeroM: 30, tubeBar: 200, regulatorBar: 150),
      );
      await computeAt100(tester);
      final apply = find.byKey(const Key('truing-apply'));
      await tester.ensureVisible(apply);
      expect(tester.widget<MenzilSecondaryButton>(apply).onPressed, isNotNull);
    });
  });

  group('F5 GA text', () {
    test('no GA drag-model advice left in the two-velocity BC note', () {
      final src = File(
        'lib/features/tools/calculators_screen.dart',
      ).readAsStringSync();
      expect(src, isNot(contains('Diabolo saçmada GA')));
      expect(src, contains('BC\\\'leri G1\\\'e göre'));
    });
  });

  group('#289 rifle "Listede yok": a saved typed rifle still computes', () {
    testWidgets('typed .308 profile: on zero at 100 m, zero angle 13 clicks', (
      tester,
    ) async {
      final v = await _shotView(tester, _fx());
      expect(v.requiredUp!.abs(), lessThan(0.05));
      expect(v.zeroAngleClicks, 13);
    });

    test('the hidden item stays behind RIFLE_LISTEDE_YOK (default off)', () {
      final src = librarySource('lib/features/profiles/profiles_screen.dart');
      expect(src, contains("bool.fromEnvironment(\n    'RIFLE_LISTEDE_YOK',"));
      expect(src, contains('if (_showRifleListedeYok)'));
      expect(src, contains("Key('rifle-not-listed')"));
    });
  });
}
