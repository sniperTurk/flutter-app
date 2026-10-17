// Pre-TestFlight audit 2026-10-14b, area MUH: ammunition / BC / drag model.
//
// Covers #298 (typed firearm ammunition), #306 (BC modeli on PCP, G1
// default), #296 / #304 (factory BC back-solved from the makers' velocity
// tables; X651 and FA007) and #305 (BC ⓘ note for BC-less factory loads).
// Independent references: tools/test_denetim_2026_10_14b_muh.py (own
// 2-D point-mass back-solve, Army Standard Metro, BRL G1/G7 tables; never the
// repo's tools/research/bc_backsolve.py and never another ballistic app).
//
// Findings encoded here (skip: = expected to fail on 7eb1416):
//   MUH-1 (medium) a listed factory/library round's maker BC is kept when the
//          BC modeli is switched G1 <-> G7, silently re-read on the other
//          curve; no warning for X651 (i = 0.816 is inside both bands).
//   MUH-2 (medium) FA007 Aguila 22 LR Standard Velocity: weight fixed to
//          40 gr but muzzle velocity still 1095 fps (.22 Short); the maker
//          page the weight came from says 1130 fps.
//   MUH-3 (low, pre-existing) a stored BC with an unknown model string is
//          dropped silently; PCP then runs the estimate labelled "BC
//          girilmediği için".
//   MUH-4 (low) FA056 Aguila .308 150 gr FMJBT: app MV 2750 fps, the page
//          its BC was back-solved from says 2760 fps.
//   MUH-5 (low) BC-less factory load: the #305 ⓘ says "BC modelini de
//          seçin" but typing a BC selects G1 automatically.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/estimated_bc.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/core/units.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/rifle_form.dart';

const _fps = 0.3048;

Future<void> _openNew(WidgetTester tester, {MemoryProfileStore? store}) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store ?? MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
}

Finder _in(String key, Finder f) =>
    find.descendant(of: find.byKey(Key(key)), matching: f);

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(_in(key, find.byType(TextField))).controller!.text;

FactoryAmmo _factory(String brand, String name, String cartridge) =>
    FactoryAmmoLibrary.all.singleWhere(
      (a) => a.brand == brand && a.name == name && a.cartridge == cartridge,
    );

/// X651 as the app lists it.
FactoryAmmo get _x651 => _factory(
  'Winchester',
  'Super-X Power-Point 129 gr Power-Point',
  '6.5 Creedmoor',
);

Future<void> _pickX651(WidgetTester tester) async {
  await chooseInSelect(tester, 'rifle-caliber', '6.5 Creedmoor');
  await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
  await chooseInSelect(tester, 'ammo-brand-select', 'Winchester');
  await chooseInSelect(
    tester,
    'ammo-model-select',
    'Super-X Power-Point 129 gr Power-Point',
  );
}

BallisticInput _x651Input(BallisticModel m) => BallisticInput(
  muzzleVelocityMps: 2820 * _fps,
  grain: 129,
  zeroRangeM: 100,
  sightHeightMm: 38.1,
  rangesM: const [600, 800],
  environment: const EnvironmentData(
    temperatureC: 15,
    pressureHpa: 1013.25,
    humidityPercent: 0,
  ),
  ballisticCoefficient: 0.324,
  ballisticModel: m,
);

Map<String, dynamic> _pcpAmmo({Object? bc, Object? model, bool key = true}) => {
  'id': 'manual_ammo_old_pcp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': '',
  'model': '',
  'caliberMm': 6.35,
  'grain': 33.95,
  'ammoType': 'slug',
  'bc': bc,
  if (key) 'bcModel': model,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('guard: BC model -> drag table (#306)', () {
    test('every model maps to its own table; G1/G7 anchor Cd values', () {
      final tables = {
        for (final m in BallisticModel.values) StandardDragTables.forModel(m),
      };
      expect(tables.length, BallisticModel.values.length);
      // Published BRL values.
      final g1 = StandardDragTables.forModel(BallisticModel.g1);
      final g7 = StandardDragTables.forModel(BallisticModel.g7);
      expect(g1.coefficientAtMach(1.0), closeTo(0.4805, 1e-4));
      expect(g1.coefficientAtMach(2.0), closeTo(0.5934, 1e-4));
      expect(g7.coefficientAtMach(1.0), closeTo(0.3803, 1e-4));
      expect(g7.coefficientAtMach(2.0), closeTo(0.2980, 1e-4));
    });

    test('stored model strings: case and spaces tolerated', () {
      for (final (s, m) in const [
        ('g1', BallisticModel.g1),
        ('G7', BallisticModel.g7),
        (' ra4 ', BallisticModel.ra4),
        ('GS', BallisticModel.gs),
      ]) {
        final a = UserCatalog.fromManualEntries([
          _pcpAmmo(bc: 0.11, model: s),
        ]).ammunition.single;
        expect(a.ballisticModel, m, reason: s);
        expect(a.ballisticCoefficient, 0.11, reason: s);
      }
    });

    test('same BC on G1 vs G7: X651 differs by > 1.5 / 3.5 mrad', () {
      // Independent reference (tools/test_denetim_2026_10_14b_muh.py,
      // zero 100 m, Army Standard Metro): 600 m G1 6.17 vs G7 4.41 mrad,
      // 800 m 10.86 vs 6.78 mrad. ICAO air and sight height here, so only
      // the size of the gap is checked.
      final g1 = const BallisticEngine().solve(_x651Input(BallisticModel.g1));
      final g7 = const BallisticEngine().solve(_x651Input(BallisticModel.g7));
      expect(g1[0].correctionMrad - g7[0].correctionMrad, greaterThan(1.5));
      expect(g1[1].correctionMrad - g7[1].correctionMrad, greaterThan(3.5));
    });
  });

  group('guard: old PCP records default to G1, same as before #306', () {
    test('BC + g1 -> G1 0.11 (pre- and post-#306 identical)', () {
      final a = UserCatalog.fromManualEntries([
        _pcpAmmo(bc: 0.11, model: 'g1'),
      ]).ammunition.single;
      expect(a.ballisticCoefficient, 0.11);
      expect(a.ballisticModel, BallisticModel.g1);
      expect(a.modelWithoutBc, isNull);
      expect(identical(EstimatedBc.fill(a), a), isTrue);
    });

    test('no BC + g1 (pre-#306 save) -> estimated G1, no model note', () {
      final a = UserCatalog.fromManualEntries([
        _pcpAmmo(bc: null, model: 'g1'),
      ]).ammunition.single;
      expect(a.ballisticCoefficient, isNull);
      expect(a.modelWithoutBc, BallisticModel.g1);
      final f = EstimatedBc.fill(a);
      expect(f.ballisticModel, BallisticModel.g1);
      // SD = 33.95 / 7000 / 0.25² = 0.07760; / 0.825 = 0.0941.
      expect(f.ballisticCoefficient, closeTo(0.094, 0.0006));
    });
  });

  group('MUH-3: unknown stored model string', () {
    test(
      'a typed BC is kept or the record is reported, never silently dropped',
      () {
        final cat = UserCatalog.fromManualEntries([
          _pcpAmmo(bc: 0.11, model: 'ga'),
        ]);
        final kept = cat.ammunition.any((a) => a.ballisticCoefficient == 0.11);
        expect(kept || cat.blocked.isNotEmpty, isTrue);
      },
    );

    test(
      'old profile with "ga" loads with its BC as G1 (owner, 2026-10-15)',
      () {
        final a = UserCatalog.fromManualEntries([
          _pcpAmmo(bc: 0.11, model: 'ga'),
        ]).ammunition.single;
        expect(a.ballisticCoefficient, 0.11);
        expect(a.ballisticModel, BallisticModel.g1);
        expect(a.modelWithoutBc, isNull);
        // The rest of the saved record is unchanged.
        expect(a.grain, 33.95);
        expect(a.caliberMm, 6.35);
        // No estimate replaces the saved BC.
        expect(identical(EstimatedBc.fill(a), a), isTrue);
      },
    );
  });

  group('guard: factory BC rows re-checked (#296 / #304)', () {
    test('X651: 129 gr, BC 0.324 G1, 2820 fps, printed source', () {
      final a = _x651;
      expect(a.grain, 129);
      expect(a.bc, 0.324);
      expect(a.model, BallisticModel.g1);
      expect(a.muzzleVelocityFps, 2820);
      expect(a.bcSource, 'printed');
      // i = SD / BC = 0.2645 / 0.324 = 0.816: a G1 form factor.
      final dIn = a.diameterMm / 25.4;
      expect(a.grain / (7000 * dIn * dIn) / a.bc!, closeTo(0.816, 0.005));
    });

    test('FA007: 40 gr, no BC and no model', () {
      final a = _factory(
        'Aguila',
        '22 Long Rifle Standard Velocity Lead Solid Point',
        '.22 LR',
      );
      expect(a.grain, 40);
      expect(a.bc, isNull);
      expect(a.model, isNull);
    });

    test('back-solved rows = independent re-check (G1, within 1 %)', () {
      // Own back-solve of the makers' tables in
      // data/bc_gelistirme/velocity_tables.json (MUH python reference).
      const expected = <(String, String, String, double, double, double)>[
        // brand, name, cartridge, grain, mv fps, independent G1 BC
        (
          'Hornady',
          'Varmint Express Rimfire 17 gr V-MAX',
          '.17 HMR',
          17,
          2550,
          0.1250,
        ),
        (
          'Hornady',
          '30 gr V-MAX Varmint Express Rimfire',
          '.22 WMR',
          30,
          2200,
          0.0951,
        ),
        ('Hornady', '170 gr MonoFlex Black', '.338 ARC', 170, 2075, 0.3091),
        ('Hornady', '175 gr HP Match BLACK', '.338 ARC', 175, 2075, 0.3849),
        (
          'Hornady',
          '210 gr InterLock American Whitetail',
          '.400 Legend',
          210,
          2200,
          0.1983,
        ),
        (
          'Hornady',
          'American Gunner 123 gr HP Match',
          '7.62x39',
          123,
          2350,
          0.2721,
        ),
        (
          'Aguila',
          '30-06 SPRG 150 Grain Soft Point',
          '.30-06 Springfield',
          150,
          2900,
          0.3383,
        ),
        (
          'Aguila',
          '140 Grain Full Metal Jacket Boat Tail',
          '6.5 Creedmoor',
          140,
          2600,
          0.4996,
        ),
        (
          'Aguila',
          '5.56 x 45mm NATO 55 Grain FMJ',
          '5.56x45 NATO',
          55,
          3164,
          0.2521,
        ),
        (
          'Aguila',
          '22 Long Rifle Target Competition Lead Solid Point',
          '.22 LR',
          40,
          1080,
          0.1693,
        ),
      ];
      for (final (brand, name, cart, grain, mv, bc) in expected) {
        final a = _factory(brand, name, cart);
        expect(a.model, BallisticModel.g1, reason: name);
        expect(a.grain, grain, reason: name);
        expect(a.muzzleVelocityFps, mv, reason: name);
        expect(a.bc! / bc, closeTo(1, 0.01), reason: name);
        expect(a.bcSource, 'maker-table-backsolve', reason: name);
      }
    });
  });

  group('MUH-2: FA007 muzzle velocity', () {
    test('FA007 velocity is the maker page figure (1130 fps)', () {
      final a = _factory(
        'Aguila',
        '22 Long Rifle Standard Velocity Lead Solid Point',
        '.22 LR',
      );
      expect(a.muzzleVelocityFps, 1130);
    });
  });

  group('MUH-4: FA056 velocity vs its BC source', () {
    test('FA056 MV equals the table the BC was solved from (2760 fps)', () {
      final a = _factory(
        'Aguila',
        '308 WIN 150 Grain Full Metal Jacket Boat Tail',
        '.308 Win',
      );
      expect(a.muzzleVelocityFps, 2760);
    }, skip: 'MUH-4: 2750 fps (catalog) vs 2760 fps (product page)');
  });

  group('MUH-1: G1 <-> G7 switch on a listed round with a maker BC', () {
    testWidgets('guard: picking X651 fills 129 gr, BC 0,324, G1, 2820 fps', (
      tester,
    ) async {
      await _openNew(tester);
      await _pickX651(tester);
      expect(_text(tester, 'ammo-grain'), '129');
      expect(_text(tester, 'ammo-bc'), '0,324');
      expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g1');
      expect(_text(tester, 'profile-velocity-fps'), '2820');
      expect(find.byKey(const Key('ammo-bc-warning')), findsNothing);
    });

    testWidgets('switching to G7 does not keep the G1 number silently', (
      tester,
    ) async {
      await _openNew(tester);
      await _pickX651(tester);
      await chooseInSelect(tester, 'ammo-bc-model', 'G7');
      expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g7');
      final cleared = _text(tester, 'ammo-bc') != '0,324';
      final warned = find
          .byKey(const Key('ammo-bc-warning'))
          .evaluate()
          .isNotEmpty;
      expect(cleared || warned, isTrue);
      // X651 has no maker G7 BC: the box is emptied (owner, 2026-10-15).
      expect(_text(tester, 'ammo-bc'), '');
      // Back to G1: the maker's G1 BC again.
      await chooseInSelect(tester, 'ammo-bc-model', 'G1');
      expect(_text(tester, 'ammo-bc'), '0,324');
    });

    testWidgets('a maker G7 BC is used when the record has one (Lapua)', (
      tester,
    ) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '.223 Rem');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await chooseInSelect(tester, 'ammo-brand-select', 'Lapua');
      await chooseInSelect(
        tester,
        'ammo-model-select',
        'Lapua 4.5 g (69 gr) Scenar',
      );
      expect(_text(tester, 'ammo-bc'), '0,341');
      await chooseInSelect(tester, 'ammo-bc-model', 'G7');
      expect(_text(tester, 'ammo-bc'), '0,171');
      await chooseInSelect(tester, 'ammo-bc-model', 'G1');
      expect(_text(tester, 'ammo-bc'), '0,341');
    });

    testWidgets('guard: typed round G1 -> G7 with a G1-sized BC is warned', (
      tester,
    ) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      // Typed round: Marka "Diğer marka" since 2026-10-17.
      await chooseOtherAmmoBrand(tester);
      await enterRifleField(tester, 'ammo-grain', '168');
      await enterRifleField(tester, 'ammo-bc', '0,462');
      await chooseInSelect(tester, 'ammo-bc-model', 'G1');
      expect(find.byKey(const Key('ammo-bc-warning')), findsNothing);
      // i = 0.2531 / 0.462 = 0.548 < 0.63: too high for G7.
      await chooseInSelect(tester, 'ammo-bc-model', 'G7');
      expect(_text(tester, 'ammo-bc'), '0,462');
      expect(find.byKey(const Key('ammo-bc-warning')), findsOneWidget);
    });
  });

  group('guard: typed firearm round, decimal comma, gr -> solver mass', () {
    testWidgets('173,5 gr and BC 0,4625 reach the record and the energy', (
      tester,
    ) async {
      final store = MemoryProfileStore();
      await _openNew(tester, store: store);
      await fillRifleForm(tester, caliber: '.308 Win');
      await fillScopeForm(tester);
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      // Typed round: Marka "Diğer marka" since 2026-10-17.
      await chooseOtherAmmoBrand(tester);
      await enterRifleField(tester, 'ammo-grain', '173,5');
      // 173,5 gr = 11,24 g: the unit text shows grams.
      expect(_in('ammo-grain', find.text('gr = 11,2 g')), findsOneWidget);
      await enterRifleField(tester, 'ammo-bc', '0,4625');
      await chooseInSelect(tester, 'ammo-bc-model', 'G1');
      await fillShotValues(
        tester,
        velocityFps: '2650',
        zero: '100',
        sight: '45',
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      final a = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == saved.ammunitionId,
      );
      expect(a.grain, 173.5);
      expect(a.ballisticCoefficient, 0.4625);
      expect(a.ballisticModel, BallisticModel.g1);
      expect(saved.muzzleVelocityMps, closeTo(2650 * _fps, 1e-6));
      // Mass in the solver: 173,5 gr = 0.0112426 kg (1 gr = 64.79891 mg).
      expect(Units.grainToKg(a.grain), closeTo(0.0112426, 1e-7));
      final pts = const BallisticEngine().solve(
        BallisticInput(
          muzzleVelocityMps: saved.muzzleVelocityMps,
          grain: a.grain,
          zeroRangeM: 100,
          sightHeightMm: 45,
          rangesM: const [300],
          environment: const EnvironmentData(),
          ballisticCoefficient: a.ballisticCoefficient,
          ballisticModel: a.ballisticModel,
        ),
      );
      final p = pts.single;
      expect(
        p.energyJ,
        closeTo(0.5 * 0.0112426 * p.velocityMps * p.velocityMps, 0.5),
      );
    });
  });

  group('MUH-5: BC-less factory load, BC modeli after typing a BC', () {
    // Owner, 2026-10-15: the G1 rule (2026-10-13) stays; the ⓘ now says a
    // typed BC sets G1 and to choose G7 for a maker G7 value.
    testWidgets('typing a BC sets G1 and the ⓘ says so', (tester) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '.223 Rem');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await chooseInSelect(tester, 'ammo-brand-select', 'Black Hills');
      await chooseInSelect(
        tester,
        'ammo-model-select',
        'Black Hills 52 gr Match HP',
      );
      expect(selectedValue<String>(tester, 'ammo-bc-model'), isNull);
      final info = tester
          .widget<MenzilInput>(find.byKey(const Key('ammo-bc')))
          .info!;
      expect(info, contains('kendiliğinden G1'));
      expect(info, contains('G7'));
      expect(info, isNot(contains('BC modelini de seçin')));
      await enterRifleField(tester, 'ammo-bc', '0,25');
      expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g1');
    });
  });
}
