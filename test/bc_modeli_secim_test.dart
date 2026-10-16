// BC modeli seçimi (owner, 2026-10-14 11:35 / 11:38;
// docs/reports/bc_modeli_secim.md).
//
// * PCP: the BC modeli box is shown with every standard table, G1 selected
//   by default, and the chosen model is saved and reaches the solver.
// * Ateşli: items, default and custom curve unchanged; only the ⓘ text.
// * Every model reaches the formula: the same shot with the same BC is
//   compared, model by model, with an independent world-frame point-mass
//   reference (tools/bc_modeli_referans.py, built on
//   tools/formul_denetimi_2026_10_14.py) that reads only that model's
//   table. Tolerance as in test/audit_2026_10_14/solver_3d_audit_test.dart:
//   0.005 mrad and 0.5 ms. The closest two models differ by 0.022 mrad, so
//   a silent fallback to another table cannot pass.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/drag_band_truing.dart';
import 'package:sniper_turk/core/estimated_bc.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

const _fps = 0.3048;
const _mph = 0.44704;

/// ICAO Doc 7488/3 sea level, dry air, with a crosswind.
EnvironmentData _icao(double windMps, double windDeg) => EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 0,
  windMps: windMps,
  windDirectionDeg: windDeg,
);

BallisticInput _pcp(BallisticModel m) => BallisticInput(
  muzzleVelocityMps: 290,
  grain: 33.95,
  zeroRangeM: 50,
  sightHeightMm: 50,
  rangesM: const [100, 150],
  environment: _icao(3, 90),
  ballisticCoefficient: 0.110,
  ballisticModel: m,
);

BallisticInput _firearm(BallisticModel m) => BallisticInput(
  muzzleVelocityMps: 2650 * _fps,
  grain: 168,
  zeroRangeM: 100,
  sightHeightMm: 38.1,
  rangesM: const [300, 600],
  environment: _icao(10 * _mph, 270),
  ballisticCoefficient: 0.462,
  ballisticModel: m,
);

// (case, model, [(range m, elevation mrad, windage mrad, TOF s)]) from
// `python3 tools/bc_modeli_referans.py --dart`.
// dart format off
const _reference = <(String, BallisticModel, List<(double, double, double, double)>)>[
  ('pcp', BallisticModel.g1, [
    (100, 2.9419, -0.8865, 0.37438),
    (150, 6.5783, -1.3132, 0.58290),
  ]),
  ('pcp', BallisticModel.g2, [
    (100, 2.7409, -0.5619, 0.36356),
    (150, 6.0513, -0.8551, 0.56000),
  ]),
  ('pcp', BallisticModel.g5, [
    (100, 2.7114, -0.5110, 0.36186),
    (150, 5.9642, -0.7703, 0.55576),
  ]),
  ('pcp', BallisticModel.g6, [
    (100, 2.8417, -0.7299, 0.36916),
    (150, 6.3342, -1.1153, 0.57301),
  ]),
  ('pcp', BallisticModel.g7, [
    (100, 2.6585, -0.4219, 0.35889),
    (150, 5.8200, -0.6356, 0.54903),
  ]),
  ('pcp', BallisticModel.g8, [
    (100, 2.8277, -0.7076, 0.36842),
    (150, 6.2987, -1.0853, 0.57151),
  ]),
  ('pcp', BallisticModel.gi, [
    (100, 2.9420, -0.8899, 0.37449),
    (150, 6.5949, -1.3356, 0.58403),
  ]),
  ('pcp', BallisticModel.gs, [
    (100, 3.8728, -2.2966, 0.42139),
    (150, 9.2747, -3.5011, 0.69230),
  ]),
  ('pcp', BallisticModel.ra4, [
    (100, 2.8808, -0.7944, 0.37131),
    (150, 6.4441, -1.2146, 0.57798),
  ]),
  ('firearm', BallisticModel.g1, [
    (300, 1.6372, 0.7660, 0.42282),
    (600, 5.4711, 1.7590, 0.97892),
  ]),
  ('firearm', BallisticModel.g2, [
    (300, 1.4203, 0.3471, 0.39471),
    (600, 4.2541, 0.7444, 0.84275),
  ]),
  ('firearm', BallisticModel.g5, [
    (300, 1.4796, 0.4644, 0.40258),
    (600, 4.5725, 1.0239, 0.88025),
  ]),
  ('firearm', BallisticModel.g6, [
    (300, 1.4506, 0.4082, 0.39881),
    (600, 4.4250, 0.8998, 0.86359),
  ]),
  ('firearm', BallisticModel.g7, [
    (300, 1.4279, 0.3617, 0.39569),
    (600, 4.2878, 0.7713, 0.84635),
  ]),
  ('firearm', BallisticModel.g8, [
    (300, 1.4405, 0.3875, 0.39742),
    (600, 4.3636, 0.8426, 0.85592),
  ]),
  ('firearm', BallisticModel.gi, [
    (300, 1.6506, 0.7892, 0.42437),
    (600, 5.5239, 1.7903, 0.98312),
  ]),
  ('firearm', BallisticModel.gs, [
    (300, 2.0131, 1.4310, 0.46745),
    (600, 7.7918, 3.3525, 1.19279),
  ]),
  ('firearm', BallisticModel.ra4, [
    (300, 1.6051, 0.7015, 0.41849),
    (600, 5.2224, 1.5407, 0.94963),
  ]),
];
// dart format on

const _pcpItems = ['g1', 'g7', 'g2', 'g5', 'g6', 'g8', 'gi', 'gs', 'ra4'];

Future<void> _openNew(
  WidgetTester tester, {
  bool firearm = false,
  MemoryProfileStore? store,
}) async {
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
  await chooseInSelect(
    tester,
    'profile-platform',
    firearm ? 'Ateşli Tüfek' : 'PCP Tüfek',
  );
}

Finder _in(String key, Finder f) =>
    find.descendant(of: find.byKey(Key(key)), matching: f);

List<String?> _values(WidgetTester tester, String key) => [
  for (final i
      in tester
          .widget<MenzilSelect<String>>(
            _in(key, find.byType(MenzilSelect<String>)),
          )
          .items)
    i.value,
];

String _info(WidgetTester tester, String key) => tester
    .widget<MenzilSelect<String>>(_in(key, find.byType(MenzilSelect<String>)))
    .info!;

/// A full typed PCP profile (slug, 33,95 gr) with [bc] and [model].
Future<void> _savePcp(
  WidgetTester tester,
  MemoryProfileStore store, {
  required String bc,
  required String model,
}) async {
  await _openNew(tester, store: store);
  await fillRifleForm(tester);
  await fillScopeForm(tester);
  await enterRifleField(tester, 'scope-travel-elevation', '170');
  await fillAmmoForm(tester, bc: bc, bcModel: model);
  await fillShotValues(tester);
  await tester.tap(find.text('Kaydet'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('every BC modeli reaches the solver with its own table', () {
    for (final (name, model, expected) in _reference) {
      test('$name ${model.label} = independent reference', () {
        final input = name == 'pcp' ? _pcp(model) : _firearm(model);
        final pts = const BallisticEngine().solve(input);
        for (final (i, (r, up, wind, tof)) in expected.indexed) {
          expect(pts[i].rangeM, r);
          expect(pts[i].correctionMrad, closeTo(up, 0.005), reason: '$r m up');
          expect(pts[i].windMrad, closeTo(wind, 0.005), reason: '$r m wind');
          expect(pts[i].timeOfFlightS, closeTo(tof, 0.0005), reason: '$r m');
        }
      });
    }

    test('changing the model changes the result (no silent G1/G7)', () {
      for (final build in [_pcp, _firearm]) {
        final far = {
          for (final m in BallisticModel.values)
            m: const BallisticEngine().solve(build(m)).last,
        };
        for (final a in BallisticModel.values) {
          for (final b in BallisticModel.values) {
            if (a.index >= b.index) continue;
            final d = [
              (far[a]!.correctionMrad - far[b]!.correctionMrad).abs(),
              (far[a]!.windMrad - far[b]!.windMrad).abs(),
            ].reduce((x, y) => x > y ? x : y);
            expect(d, greaterThan(0.015), reason: '${a.label} vs ${b.label}');
          }
        }
      }
    });

    test('every model has its own table', () {
      final tables = {
        for (final m in BallisticModel.values) StandardDragTables.forModel(m),
      };
      expect(tables.length, BallisticModel.values.length);
    });

    test('re-solve copies keep the model (ranges, velocity, BC)', () {
      for (final m in BallisticModel.values) {
        final base = _firearm(m);
        expect(base.withRanges([200]).ballisticModel, m);
        expect(base.withMuzzleVelocity(700).ballisticModel, m);
        expect(base.withBallisticCoefficient(0.3).ballisticModel, m);
      }
    });

    test('Cd eğrisi düzeltmesi starts from the chosen model', () {
      for (final m in BallisticModel.values) {
        final own = DragBandTruing.ownCurve(
          base: _firearm(m),
          sectionalDensity: 0.253,
        );
        final t = StandardDragTables.forModel(m);
        for (final s in own) {
          expect(
            s.coefficient,
            closeTo(t.coefficientAtMach(s.mach) * 0.253 / 0.462, 1e-12),
          );
        }
      }
    });
  });

  group('PCP BC modeli box', () {
    // Owner, 2026-10-16 (approved PCP card): Tip | Marka, Model, …,
    // Ağırlık | BC, then BC modeli on its own row.
    testWidgets('shown, G1 selected, every table listed, Ağırlık | BC, '
        'BC modeli below', (tester) async {
      await _openNew(tester);
      expect(find.byKey(const Key('ammo-bc-model')), findsOneWidget);
      expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g1');
      expect(_values(tester, 'ammo-bc-model'), _pcpItems);
      // No custom curve on PCP.
      expect(_values(tester, 'ammo-bc-model'), isNot(contains('custom')));
      Rect r(String k) => tester.getRect(find.byKey(Key(k)));
      expect((r('ammo-grain').top - r('ammo-bc').top).abs(), lessThan(1));
      expect(r('ammo-grain').right, lessThan(r('ammo-bc').left));
      expect(
        r('ammo-bc-model').top,
        greaterThanOrEqualTo(r('ammo-bc').bottom - 0.5),
      );
      // Tip | Marka on the first row.
      expect(
        (r('ammo-type').top - r('ammo-brand-select').top).abs(),
        lessThan(1),
      );
      expect(r('ammo-type').bottom, lessThanOrEqualTo(r('ammo-grain').top));
      expect(_info(tester, 'ammo-bc-model'), ProfileFieldInfo.bcModel);
    });

    testWidgets('ⓘ opens a centred popup, one line per model, warning last', (
      tester,
    ) async {
      await _openNew(tester);
      final button = _in('ammo-bc-model', find.byType(MenzilInfoButton));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('G1: Düz dipli'),
        ),
      );
      expect(text.textAlign, TextAlign.start);
      final lines = text.data!.split('\n');
      expect(lines, [
        "G1: Düz dipli, klasik mermi. Saçma ve slug BC'leri de çoğunlukla "
            'buna göre verilir.',
        'G7: Uzun, sivri ve konik dipli (boat-tail) mermi.',
        'G2, G5, G6, G8, GI: Başka mermi şekilleri; az kullanılır.',
        'GS: Küre şekli (yuvarlak bilye).',
        'RA4: .22 LR rimfire.',
        '',
        'Uyarı: Yanlış eğri seçmek, hiç seçmemekten daha fazla hata '
            "yaratır. Üretici BC'yi hangi modele göre veriyorsa onu seçin; "
            "bilmiyorsanız G1'de bırakın.",
      ]);
      final dialog = tester.getRect(find.byType(AlertDialog));
      final screen = tester.getRect(find.byType(MaterialApp));
      expect((dialog.center.dx - screen.center.dx).abs(), lessThan(1));
    });

    testWidgets('G7 is saved, reopened and used by the solver', (tester) async {
      final store = MemoryProfileStore();
      await _savePcp(tester, store, bc: '0,110', model: 'G7');
      final saved = (await store.all()).single;
      final a = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == saved.ammunitionId,
      );
      expect(a.ballisticCoefficient, 0.110);
      expect(a.ballisticModel, BallisticModel.g7);
      await tester.tap(find.text(saved.name).first);
      await tester.pumpAndSettle();
      expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g7');
    });

    testWidgets('untouched box saves G1', (tester) async {
      final store = MemoryProfileStore();
      await _savePcp(tester, store, bc: '0,110', model: 'G1');
      final saved = (await store.all()).single;
      final a = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == saved.ammunitionId,
      );
      expect(a.ballisticModel, BallisticModel.g1);
    });

    testWidgets('empty BC + G7: the pick is kept, the estimate is G1', (
      tester,
    ) async {
      final store = MemoryProfileStore();
      await _savePcp(tester, store, bc: '', model: 'G7');
      final saved = (await store.all()).single;
      final a = CatalogRepository.allAmmunition.singleWhere(
        (x) => x.id == saved.ammunitionId,
      );
      expect(a.ballisticCoefficient, isNull);
      expect(a.ballisticModel, isNull);
      expect(a.modelWithoutBc, BallisticModel.g7);
      final filled = EstimatedBc.fill(a);
      expect(filled.ballisticModel, BallisticModel.g1);
      expect(filled.ballisticCoefficient, isNotNull);
      expect(filled.modelWithoutBc, BallisticModel.g7);
      // Reopened, the box still shows the pick.
      await tester.tap(find.text(saved.name).first);
      await tester.pumpAndSettle();
      expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g7');
    });

    testWidgets('an older PCP profile (G1) stays G1', (tester) async {
      final store = MemoryProfileStore();
      await _savePcp(tester, store, bc: '0,110', model: 'G1');
      final saved = (await store.all()).single;
      await tester.tap(find.text(saved.name).first);
      await tester.pumpAndSettle();
      expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g1');
    });
  });

  group('Ateşli BC modeli unchanged, only the ⓘ', () {
    testWidgets('items, default and custom curve as before', (tester) async {
      await _openNew(tester, firearm: true);
      await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      expect(selectedValue<String>(tester, 'ammo-bc-model'), isNull);
      expect(_values(tester, 'ammo-bc-model'), [
        'g1',
        'g2',
        'g5',
        'g6',
        'g7',
        'g8',
        'gi',
        'ra4',
        'custom',
      ]);
      expect(
        _info(tester, 'ammo-bc-model'),
        ProfileFieldInfo.bcModelWithCustom,
      );
      expect(
        ProfileFieldInfo.bcModelWithCustom,
        endsWith('\n\n${ProfileFieldInfo.bcModelWarning}'),
      );
      expect(
        ProfileFieldInfo.bcModelWithCustom,
        contains(ProfileFieldInfo.bcModelCustom),
      );
    });
  });

  group('Balistik with the PCP model', () {
    const profile = RifleProfile(
      id: 'p-model',
      name: 'Model',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'c-model',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 270,
      zeroRangeM: 25,
      sightHeightMm: 60,
      pressureBar: 200,
    );
    Map<String, dynamic> ammo(String model, double? bc) => {
      'id': 'c-model',
      'kind': 'custom_ammunition',
      'platform': 'pcp',
      'brand': 'Deneme',
      'model': '.25 slug',
      'caliberMm': 6.35,
      'grain': 33.95,
      'ammoType': 'slug',
      'bc': bc,
      'bcModel': model,
    };
    Future<List<String>> dope(WidgetTester tester, String model) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([ammo(model, 0.11)]),
      );
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: const BallisticsScreen(profile: profile),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Sürtünmeli hesap: ${model.toUpperCase()} BC 0,11'),
        findsOneWidget,
      );
      await tester.tap(find.text('DOPE oluştur'));
      await tester.pumpAndSettle();
      return [
        for (final t in tester.widgetList<Text>(
          find.descendant(
            of: find.byType(DataTable),
            matching: find.byType(Text),
          ),
        ))
          t.data ?? '',
      ];
    }

    testWidgets('G7 and G1 give different DOPE', (tester) async {
      final g1 = await dope(tester, 'g1');
      final g7 = await dope(tester, 'g7');
      expect(g1, isNotEmpty);
      expect(g7, isNot(equals(g1)));
    });

    testWidgets('empty BC with G7: the note says G1 was used', (tester) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([ammo('g7', null)]),
      );
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: BallisticsScreen(profile: profile)),
      );
      await tester.pumpAndSettle();
      final note = tester.widget<MenzilNotice>(
        find.byKey(const Key('ballistics-bc-estimated')),
      );
      expect(
        note.message,
        endsWith(
          'Seçtiğiniz G7 modeli BC olmadan kullanılamaz; tahmin G1 ile '
          'yapıldı.',
        ),
      );
    });

    testWidgets('empty BC with G1: the note is as before', (tester) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([ammo('g1', null)]),
      );
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: BallisticsScreen(profile: profile)),
      );
      await tester.pumpAndSettle();
      final note = tester.widget<MenzilNotice>(
        find.byKey(const Key('ballistics-bc-estimated')),
      );
      expect(note.message, endsWith("BC'yi biliyorsanız Profil'de girin."));
    });
  });
}
