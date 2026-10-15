// Pre-TestFlight audit 2026-10-14b, area PROFILES / CATALOG RE-MATCHING /
// PROFILE FLAGS (#308, commit 7eb1416; report docs/reports/profil_duzen.md).
//
// Question: an old saved profile that Profili Düzenle now re-matches to a
// list record (lib/features/profiles/profile_catalog_match.dart) must keep
// EVERY value the calculation reads. Each round-trip test below snapshots the
// solver inputs of the stored profile (profile + resolved rifle / ammunition
// / scope, exactly what ProfileCatalogIntegrity hands to Balistik), opens
// Profili Düzenle, presses Güncelle without touching anything, and compares
// the new snapshot. Tolerances are the display rounding of the editor only
// (fps shown with one decimal, band thresholds as whole fps, zero to 0.1 of
// the distance unit, turret travel as whole clicks).
//
// Findings (see the audit report). PRF-1, PRF-3, PRF-4 and PRF-5 were fixed
// in fix/prf-durbun-eslestirme; their tests are un-skipped and must pass.
//   PRF-1 (medium) catalog scope -> Güncelle drops windageRangeMrad (and the
//         turret travel lower-bound flags): the Hedef windage drum limit
//         and "Kule yetmez" for windage disappear.            [skipped test]
//   PRF-2 (high, pre-existing) Kopyala shares the rifle / ammo / scope
//         records; editing the copy rewrites the original's BC. [skipped test]
//   PRF-3 (medium) profile unit MOA on an old MRAD scope that is now
//         tolerant-matched: Güncelle rewrites the scope as MOA 0.25 and the
//         next opening matches the scope's MOA variant (another list model,
//         Retikül "Seçiniz"). Hedef click size unchanged.     [skipped test]
//   PRF-4 (medium) rifle tolerant match prefers the saved caliber over the
//         exact model name: "HATSAN / Hercules Bully" .25 is renamed to
//         "Hercules" (saved identity changed).                [skipped test]
//   PRF-5 (low) Turkish dotless ı: "SARSILMAZ" is not matched to
//         "Sarsılmaz" (opens typed; no value changes).        [skipped test]
// Passing guards: re-match keeps all solver inputs (tolerant firearm, typed
// firearm with MOA scope, PCP with pressures and a hidden saved length),
// "İptal" writes nothing, a deleted catalog id is never substituted,
// ambiguous matches give no match, Barut katsayısı semantics (%/15 °C).
//
// Python reference: tools/test_denetim_2026_10_14b_prf.py.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/powder_temperature.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/data/rifle_library.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profile_catalog_match.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/rifle_form.dart';

// ---- Saved records (ManualCatalogStore JSON) ------------------------------

/// Tikka saved with an older spelling: tolerant match to "Tikka / T3x TACT
/// A1" (same record as test/profil_duzen_koruma_test.dart).
const _oldRifle = <String, dynamic>{
  'id': 'manual_rifle_old',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'TIKKA',
  'model': 'T3X Tact A1',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 11,
};

/// Typed firearm round with three saved BC bands (hidden behind
/// AMMO_BC_BANDS_TYPED, kept and used).
const _oldAmmo = <String, dynamic>{
  'id': 'manual_ammo_old',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Eski Marka',
  'model': 'Eski Fişek',
  'caliberMm': 7.82,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.475,
  'bcModel': 'g1',
  'bcBands': [
    {'mps': 800.0, 'bc': 0.475},
    {'mps': 600.0, 'bc': 0.46},
    {'mps': 0.0, 'bc': 0.44},
  ],
};

/// Arken saved under the older series name (tolerant scope match).
const _oldScope = <String, dynamic>{
  'id': 'manual_scope_old',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Arken SH-4 Gen II',
  'model': '4-16x50 FFP',
  'objectiveMm': 50,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'ffp',
  'minMag': 4,
  'maxMag': 16,
  'magnification': '4-16x',
  'reticle': 'VPR-MIL',
};

/// Typed (Listede yok) rifle, G7 round and a MOA scope with a known travel.
const _typedRifle = <String, dynamic>{
  'id': 'manual_rifle_typed',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Atölyem',
  'model': 'Özel Yapım',
  'caliberMm': 7.82,
  'twistDirection': 'left',
  'twistRateIn': 12,
};

const _typedAmmo = <String, dynamic>{
  'id': 'manual_ammo_typed',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Eski Marka',
  'model': 'G7 Fişek',
  'caliberMm': 7.82,
  'grain': 177,
  'ammoType': 'bullet',
  'bc': 0.243,
  'bcModel': 'g7',
};

/// 100 MOA total travel (400 clicks of 1/4 MOA) expressed in mrad.
const double _hundredMoaInMrad = 29.08882086657216;

const _typedScopeMoa = <String, dynamic>{
  'id': 'manual_scope_typed',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Atölyem Optik',
  'model': '4-16x44 SFP',
  'objectiveMm': 44,
  'click': 0.25,
  'clickUnit': 'moa',
  'focal': 'sfp',
  'minMag': 4,
  'maxMag': 16,
  'magnification': '4-16x',
  'elevationRangeMrad': _hundredMoaInMrad,
};

/// PCP typed set (as test/uzunluk_sadece_pro_test.dart) with a length saved
/// before PROFILE_AMMO_LENGTH hid the box.
const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_pcp',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Atölye',
  'model': 'Slug',
  'caliberMm': 6.35,
  'twistDirection': 'right',
  'twistRateIn': 17,
  'sourceName': 'Kullanıcı girdisi',
};

const _pcpAmmo = <String, dynamic>{
  'id': 'manual_ammo_pcp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Kendi',
  'model': '',
  'caliberMm': 6.35,
  'grain': 33.95,
  'ammoType': 'slug',
  'bc': 0.1,
  'bcModel': 'g1',
  'lengthMm': 10.5,
  'sourceName': 'Kullanıcı girdisi',
};

const _pcpScope = <String, dynamic>{
  'id': 'manual_scope_pcp',
  'kind': 'scope',
  'platform': 'pcp',
  'brand': 'Optik',
  'model': '4-16x44',
  'objectiveMm': 44,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'sfp',
  'minMag': 4,
  'maxMag': 16,
};

const _arkenCatalogId = 'lib-arken-optics-sh-4-genii-4-16x50-ffp';

Map<String, dynamic> _profileJson({
  String id = 'old',
  String name = 'Eski Profil',
  String rifleId = 'manual_rifle_old',
  String ammoId = 'manual_ammo_old',
  String scopeId = 'manual_scope_old',
  double velocityMps = 807.72, // 2650 fps
  double zeroM = 91.44, // 100 yd
  double sightMm = 50.8,
  String angularUnit = 'mrad',
  String distanceUnit = 'yard',
  double cantMoa = 20,
  double? powderCoef = 0.8,
  double? powderRef = 21,
  double? pressureBar,
  double? tubePressureBar,
  List<Map<String, double>> table = const [],
}) => {
  'id': id,
  'name': name,
  'rifleId': rifleId,
  'ammunitionId': ammoId,
  'scopeId': scopeId,
  'muzzleVelocityMps': velocityMps,
  'zeroRangeM': zeroM,
  'sightHeightMm': sightMm,
  'pressureBar': pressureBar,
  'tubePressureBar': tubePressureBar,
  'pressureVelocity': table,
  'angularUnit': angularUnit,
  'distanceUnit': distanceUnit,
  'mountCantMoa': cantMoa,
  'powderTempCoef': powderCoef,
  'powderTempRefC': powderRef,
};

RifleProfile _decode(Map<String, dynamic> j) => const ProfileCodec().decode(j);

/// Records in the store the editor writes to AND in the live catalog.
void _seed(List<Map<String, dynamic>> entries) {
  SharedPreferences.setMockInitialValues({
    ManualCatalogStore.key: jsonEncode(entries),
  });
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries([
      for (final e in entries) {...e},
    ]),
  );
}

// ---- Solver inputs ---------------------------------------------------------

/// Everything Balistik / Hedef reads from a stored profile, flattened.
Map<String, Object?> _solverInputs(RifleProfile p) {
  final r = const ProfileCatalogIntegrity().resolve(p);
  expect(r, isNotNull, reason: 'profile ${p.id} no longer resolves');
  final rifle = r!.rifle, a = r.ammunition, s = r.scope;
  // Click size the Hedef turret uses (ballistics_screen _scopeClickValue):
  // the scope's own click when its unit is the profile's, else the
  // standard click of the profile unit.
  final effClick = s.clickUnit == p.angularUnit
      ? s.clickValue
      : p.angularUnit.standardClick;
  return {
    'platform': rifle.platform,
    'muzzleVelocityMps': p.muzzleVelocityMps,
    'zeroRangeM': p.zeroRangeM,
    'sightHeightMm': p.sightHeightMm,
    'angularUnit': p.angularUnit,
    'distanceUnit': p.distanceUnit,
    'mountCantMoa': p.mountCantMoa,
    'powderCoef': p.powderTempCoefPercentPer15C,
    'powderRef': p.powderTempReferenceC,
    'regulatorBar': p.pressureBar,
    'tubeBar': p.tubePressureBar,
    'pvRows': p.pressureVelocityTable.length,
    for (final (i, pt) in p.pressureVelocityTable.indexed) ...{
      'pv${i}Bar': pt.bar,
      'pv${i}Mps': pt.mps,
    },
    'caliberMm': rifle.caliberMm,
    'twistRateIn': rifle.twistRateIn,
    'twistDirection': rifle.twistDirection,
    'grain': a.grain,
    'ammoType': a.type,
    'bc': a.ballisticCoefficient,
    'bcModel': a.ballisticModel,
    'dragCurve': a.dragCurve?.length,
    'bandRows': a.bcBands.length,
    for (final (i, b) in a.bcBands.indexed) ...{
      'band${i}Mps': b.minVelocityMps,
      'band${i}Bc': b.bc,
    },
    'ammoLengthMm': a.lengthMm,
    'effectiveClick': effClick,
    'elevationRangeMrad': s.elevationRangeMrad,
    'windageRangeMrad': s.windageRangeMrad,
    'firstFocalPlane': s.firstFocalPlane,
    'minMag': s.minMagnification,
    'maxMag': s.maxMagnification,
    'objectiveMm': s.objectiveDiameterMm,
    'reticle': s.reticle,
  };
}

/// Editor display rounding only (see header).
const Map<String, double> _tolerance = {
  'muzzleVelocityMps': 0.02, // fps with one decimal: <= 0.05 fps
  'zeroRangeM': 0.05, // 0.1 yd
  'pv0Mps': 0.02,
  'pv1Mps': 0.02,
  'band0Mps': 0.2, // whole fps: <= 0.5 fps = 0.15 m/s
  'band1Mps': 0.2,
  'band2Mps': 0.2,
  'elevationRangeMrad': 0.05, // whole clicks
};

void _expectSameInputs(
  Map<String, Object?> before,
  Map<String, Object?> after,
) {
  expect(after.keys.toSet(), before.keys.toSet());
  for (final k in before.keys) {
    final b = before[k], a = after[k];
    if (b is num && a is num) {
      expect(
        a.toDouble(),
        closeTo(b.toDouble(), _tolerance[k] ?? 1e-9),
        reason: '$k changed: $b -> $a',
      );
    } else {
      expect(a, b, reason: '$k changed: $b -> $a');
    }
  }
}

// ---- Pumping ---------------------------------------------------------------

Future<MemoryProfileStore> _pumpList(
  WidgetTester tester,
  List<RifleProfile> profiles,
) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _openEdit(WidgetTester tester, String name) async {
  final row = find.text(name).first;
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsOneWidget);
}

String _missingText(WidgetTester tester) {
  final f = find.byKey(const Key('profile-missing'));
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data!;
}

VoidCallback? _updateAction(WidgetTester tester) => tester
    .widget<MenzilPrimaryButton>(
      find.widgetWithText(MenzilPrimaryButton, 'Güncelle'),
    )
    .onPressed;

Future<void> _update(WidgetTester tester) async {
  expect(_updateAction(tester), isNotNull, reason: _missingText(tester));
  final button = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.text('Profili Düzenle'), findsNothing);
}

/// Opens [p] (stored alone), presses Güncelle, returns the inputs before
/// and after and the stored profile.
Future<
  ({
    Map<String, Object?> before,
    Map<String, Object?> after,
    RifleProfile saved,
    MemoryProfileStore store,
  })
>
_roundTrip(WidgetTester tester, RifleProfile p) async {
  final before = _solverInputs(p);
  final store = await _pumpList(tester, [p]);
  await _openEdit(tester, p.name);
  await _update(tester);
  final saved = (await store.all()).singleWhere((x) => x.id == p.id);
  return (
    before: before,
    after: _solverInputs(saved),
    saved: saved,
    store: store,
  );
}

List<LibraryRifle> _rifles(WeaponPlatform platform) => [
  for (final r in RifleLibrary.all)
    if (r.platform == platform) r,
];

ScopeOptic _scope(
  String id,
  String brand,
  String model, {
  AngularUnit unit = AngularUnit.mrad,
  bool userEntered = false,
}) => ScopeOptic(
  id: id,
  brand: brand,
  model: model,
  objectiveDiameterMm: 56,
  clickValue: unit == AngularUnit.mrad ? 0.1 : 0.25,
  clickUnit: unit,
  minMagnification: 5,
  maxMagnification: 25,
  firstFocalPlane: true,
  userEntered: userEntered,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('PRF re-match: Güncelle keeps every calculation value', () {
    testWidgets('old firearm profile (tolerant Tikka + Arken, typed round '
        'with hidden bands, Barut 0,8 / 21 °C, 20 MOA mount, yard)', (
      tester,
    ) async {
      _seed([_oldRifle, _oldAmmo, _oldScope]);
      final p = _decode(_profileJson());
      final before = _solverInputs(p);
      final store = await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      // The re-match path is the one under test: both open in the lists.
      expect(
        selectedValue<String>(tester, 'rifle-model-select'),
        'T3x TACT A1',
      );
      expect(
        selectedValue<String>(tester, 'scope-model-select'),
        'SH-4 GENII 4-16x50 FFP',
      );
      // Hidden flags (default off): typed bands and their title are not on
      // screen, the saved bands still reach the calculation (checked below).
      expect(find.byKey(const Key('ammo-bands-title')), findsNothing);
      // Barut katsayısı: off-list value kept and shown; no unit beside it.
      expect(selectedValue<String>(tester, 'profile-powder-coef'), '0,8');
      expect(find.text('%/15 °C'), findsNothing);
      await _update(tester);
      final saved = (await store.all()).single;
      _expectSameInputs(before, _solverInputs(saved));
    });

    testWidgets('"İptal" after opening writes nothing', (tester) async {
      _seed([_oldRifle, _oldAmmo, _oldScope]);
      final p = _decode(_profileJson());
      final store = await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      final cancel = find.widgetWithText(MenzilSecondaryButton, 'İptal');
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      final stored = (await store.all()).single;
      expect(
        const ProfileCodec().encode(stored),
        const ProfileCodec().encode(p),
      );
      final records = await ManualCatalogStore().all();
      expect(records.map((e) => e['id']).toSet(), {
        'manual_rifle_old',
        'manual_ammo_old',
        'manual_scope_old',
      });
      final rifle = records.singleWhere((e) => e['id'] == 'manual_rifle_old');
      expect(rifle['brand'], 'TIKKA');
      expect(rifle['model'], 'T3X Tact A1');
    });

    testWidgets('typed (Listede yok) rifle, G7 round, MOA scope with travel', (
      tester,
    ) async {
      _seed([_typedRifle, _typedAmmo, _typedScopeMoa]);
      final p = _decode(
        _profileJson(
          rifleId: 'manual_rifle_typed',
          ammoId: 'manual_ammo_typed',
          scopeId: 'manual_scope_typed',
          velocityMps: 850,
          zeroM: 100,
          sightMm: 45,
          angularUnit: 'moa',
          distanceUnit: 'meter',
          cantMoa: 0,
          powderCoef: 1.5,
          powderRef: 15,
        ),
      );
      final r = await _roundTrip(tester, p);
      _expectSameInputs(r.before, r.after);
      expect(r.after['effectiveClick'], 0.25);
    });

    testWidgets('PCP with regulator, tube, pressure table and a length saved '
        'before PROFILE_AMMO_LENGTH hid its box', (tester) async {
      _seed([_pcpRifle, _pcpAmmo, _pcpScope]);
      final p = _decode(
        _profileJson(
          rifleId: 'manual_rifle_pcp',
          ammoId: 'manual_ammo_pcp',
          scopeId: 'manual_scope_pcp',
          name: 'Eski Slug',
          velocityMps: 285,
          zeroM: 30,
          sightMm: 55,
          distanceUnit: 'meter',
          cantMoa: 0,
          powderCoef: null,
          powderRef: null,
          pressureBar: 150,
          tubePressureBar: 250,
          table: const [
            {'bar': 200.0, 'mps': 280.0},
            {'bar': 250.0, 'mps': 285.0},
          ],
        ),
      );
      final r = await _roundTrip(tester, p);
      _expectSameInputs(r.before, r.after);
      expect(r.after['ammoLengthMm'], 10.5);
      expect(r.after['tubeBar'], 250);
    });

    testWidgets(
      'MOA profile on an old MRAD scope: the Hedef click size is unchanged',
      (tester) async {
        _seed([_oldRifle, _oldAmmo, _oldScope]);
        final p = _decode(_profileJson(angularUnit: 'moa'));
        final r = await _roundTrip(tester, p);
        // Profile unit wins on Hedef: 1/4 MOA before and after.
        expect(r.before['effectiveClick'], 0.25);
        expect(r.after['effectiveClick'], 0.25);
      },
    );
  });

  group('PRF-1: catalog scope turret travel survives Güncelle', () {
    testWidgets('Arken SH-4 GENII (36 / 10 mrad) keeps its windage travel', (
      tester,
    ) async {
      _seed([_oldRifle, _oldAmmo]);
      final p = _decode(_profileJson(scopeId: _arkenCatalogId));
      final r = await _roundTrip(tester, p);
      expect(r.before['windageRangeMrad'], 10.0);
      expect(r.after['elevationRangeMrad'], closeTo(36, 0.05));
      // Expected: the manufacturer's 10 mrad windage travel still limits
      // the Hedef windage drum (ballistics_screen maxWindage). Today the
      // manual copy written by _scopeEntry has no windageRangeMrad, so the
      // limit becomes "unknown" (100000 clicks).
      expect(r.after['windageRangeMrad'], 10.0);
    }); // PRF-1 fixed (fix/prf-durbun-eslestirme): un-skipped (CLAUDE.md).

    testWidgets('catalog scope keeps its manufacturer source after Güncelle', (
      tester,
    ) async {
      _seed([_oldRifle, _oldAmmo]);
      final p = _decode(_profileJson(scopeId: _arkenCatalogId));
      final catalog = CatalogRepository.allScopes.singleWhere(
        (s) => s.id == _arkenCatalogId,
      );
      final r = await _roundTrip(tester, p);
      final scope = CatalogRepository.allScopes.singleWhere(
        (s) => s.id == r.saved.scopeId,
      );
      // The reticle is looked up with the scope's source document.
      expect(scope.sourceDocument, catalog.sourceDocument);
      expect(scope.sourceDocument, isNot(userCatalogSourceDocument));
      // Saved again: still the manufacturer's source and travel.
      await _openEdit(tester, p.name);
      await _update(tester);
      final savedAgain = (await r.store.all()).single;
      final again = CatalogRepository.allScopes.singleWhere(
        (s) => s.id == savedAgain.scopeId,
      );
      expect(again.sourceDocument, catalog.sourceDocument);
      expect(again.windageRangeMrad, 10.0);
    });

    testWidgets('a typed (personal) scope keeps the personal source', (
      tester,
    ) async {
      _seed([_typedRifle, _typedAmmo, _typedScopeMoa]);
      final p = _decode(
        _profileJson(
          rifleId: 'manual_rifle_typed',
          ammoId: 'manual_ammo_typed',
          scopeId: 'manual_scope_typed',
          angularUnit: 'moa',
          distanceUnit: 'meter',
        ),
      );
      final r = await _roundTrip(tester, p);
      final scope = CatalogRepository.allScopes.singleWhere(
        (s) => s.id == r.saved.scopeId,
      );
      expect(scope.sourceDocument, userCatalogSourceDocument);
      expect(scope.windageRangeMrad, isNull);
    });
  });

  group('PRF-2: Kopyala is an independent copy', () {
    testWidgets('editing the copy\'s BC leaves the original profile alone', (
      tester,
    ) async {
      _seed([_pcpRifle, _pcpAmmo, _pcpScope]);
      final original = _decode(
        _profileJson(
          id: 'orig',
          name: 'Eski Slug',
          rifleId: 'manual_rifle_pcp',
          ammoId: 'manual_ammo_pcp',
          scopeId: 'manual_scope_pcp',
          velocityMps: 285,
          zeroM: 30,
          sightMm: 55,
          distanceUnit: 'meter',
          cantMoa: 0,
          powderCoef: null,
          powderRef: null,
        ),
      );
      // What _duplicate stores: new id and name, the SAME record ids.
      final copy = _decode({
        ...const ProfileCodec().encode(original),
        'id': 'copy',
        'name': 'Eski Slug (kopya)',
      });
      final store = await _pumpList(tester, [original, copy]);
      await _openEdit(tester, 'Eski Slug (kopya)');
      await enterRifleField(tester, 'ammo-bc', '0,12');
      await _update(tester);
      final all = await store.all();
      final savedCopy = all.singleWhere((x) => x.id == 'copy');
      final savedOriginal = all.singleWhere((x) => x.id == 'orig');
      expect(
        _solverInputs(savedCopy)['bc'],
        closeTo(0.12, 1e-9),
        reason: 'the edit itself was saved',
      );
      // Expected: the original still flies with its own BC 0,1.
      expect(_solverInputs(savedOriginal)['bc'], closeTo(0.1, 1e-9));
    }); // PRF-2 fixed in #313: un-skipped (CLAUDE.md).
  });

  group('PRF-3: profile unit differs from the old scope unit', () {
    testWidgets('Güncelle keeps the MRAD 0,1 scope and reopens in the lists', (
      tester,
    ) async {
      _seed([_oldRifle, _oldAmmo, _oldScope]);
      final p = _decode(_profileJson(angularUnit: 'moa'));
      final r = await _roundTrip(tester, p);
      final scope = CatalogRepository.allScopes.singleWhere(
        (s) => s.id == r.saved.scopeId,
      );
      // Saved values are never replaced (report: "Veri korunur").
      expect(scope.clickUnit, AngularUnit.mrad);
      expect(scope.clickValue, 0.1);
      await _openEdit(tester, p.name);
      expect(
        selectedValue<String>(tester, 'scope-model-select'),
        'SH-4 GENII 4-16x50 FFP',
      );
    }); // PRF-3 fixed (fix/prf-durbun-eslestirme): un-skipped (CLAUDE.md).

    testWidgets('MOA profile on the MRAD catalog scope: scope stays MRAD 0,1', (
      tester,
    ) async {
      _seed([_oldRifle, _oldAmmo]);
      final p = _decode(
        _profileJson(scopeId: _arkenCatalogId, angularUnit: 'moa'),
      );
      final r = await _roundTrip(tester, p);
      final scope = CatalogRepository.allScopes.singleWhere(
        (s) => s.id == r.saved.scopeId,
      );
      expect(scope.clickUnit, AngularUnit.mrad);
      expect(scope.clickValue, 0.1);
      expect(scope.windageRangeMrad, 10.0);
      // The profile keeps its own unit; the Hedef click is unchanged.
      expect(r.saved.angularUnit, AngularUnit.moa);
      expect(r.after['effectiveClick'], r.before['effectiveClick']);
    });
  });

  group('deleted catalog id is never substituted', () {
    testWidgets('scope id gone: warning, Güncelle off, nothing written', (
      tester,
    ) async {
      _seed([_oldRifle, _oldAmmo]);
      final p = _decode(_profileJson(scopeId: 'silinmis-durbun'));
      final store = await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      expect(
        find.textContaining('dürbün bilgisi katalogda bulunamadı'),
        findsOneWidget,
      );
      expect(_updateAction(tester), isNull);
      expect(_missingText(tester), contains('Dürbün'));
      final stored = (await store.all()).single;
      expect(stored.scopeId, 'silinmis-durbun');
    });
  });

  group('matching rules (pure)', () {
    test('Tikka "T3x" alone fits several models: no match', () {
      expect(
        ProfileCatalogMatch.rifle(
          'Tikka',
          'T3x',
          7.82,
          _rifles(WeaponPlatform.firearm),
        ),
        isNull,
      );
    });

    test('old Tikka spelling finds the list model', () {
      final hit = ProfileCatalogMatch.rifle(
        'TIKKA',
        'T3X Tact A1',
        7.82,
        _rifles(WeaponPlatform.firearm),
      );
      expect(hit?.brand, 'Tikka');
      expect(hit?.model, 'T3x TACT A1');
    });

    test('two scope models that fit equally: no match', () {
      final saved = _scope(
        's',
        'Testoptik Alfa',
        '5-25x56 FFP',
        userEntered: true,
      );
      final lib = [
        _scope('a', 'Testoptik', 'Alfa X 5-25x56 FFP'),
        _scope('b', 'Testoptik', 'Alfa Y 5-25x56 FFP'),
      ];
      expect(ProfileCatalogMatch.scope(saved, lib, (s) => s.model), isNull);
      // Only one of them: matched.
      expect(
        ProfileCatalogMatch.scope(saved, lib.sublist(0, 1), (s) => s.model)?.id,
        'a',
      );
    });

    test('another click unit is never matched', () {
      final saved = _scope(
        's',
        'Testoptik Alfa',
        '5-25x56 FFP',
        unit: AngularUnit.moa,
        userEntered: true,
      );
      expect(
        ProfileCatalogMatch.scope(saved, [
          _scope('a', 'Testoptik', 'Alfa X 5-25x56 FFP'),
        ], (s) => s.model),
        isNull,
      );
    });

    test('PRF-4: "HATSAN / Hercules Bully" .25 is not renamed "Hercules"', () {
      final hit = ProfileCatalogMatch.rifle(
        'HATSAN',
        'Hercules Bully',
        6.35,
        _rifles(WeaponPlatform.pcp),
      );
      // Expected: the exact model name (or no match), never another model.
      expect(
        hit == null || hit.model == 'Hercules Bully',
        isTrue,
        reason: 'matched ${hit?.brand} / ${hit?.model}',
      );
    }); // PRF-4 fixed (fix/prf-durbun-eslestirme): un-skipped (CLAUDE.md).

    test('PRF-4: the exact name wins over the caliber; none, no match', () {
      final pcp = _rifles(WeaponPlatform.pcp);
      // Exact name, caliber not in the list: still that model.
      final bully = ProfileCatalogMatch.rifle(
        'HATSAN',
        'Hercules Bully',
        7.62,
        pcp,
      );
      expect(bully?.model, 'Hercules Bully');
      // No exact name: no match (opens typed, values kept).
      expect(
        ProfileCatalogMatch.rifle('Hatsan', 'Hercules Bully X', 6.35, pcp),
        isNull,
      );
    });

    test('PRF-5: upper-case Turkish brand "SARSILMAZ" is "Sarsılmaz"', () {
      final hit = ProfileCatalogMatch.rifle(
        'SARSILMAZ',
        'SAR 308 Versiyon 2',
        7.82,
        _rifles(WeaponPlatform.firearm),
      );
      expect(hit?.brand, 'Sarsılmaz');
      expect(hit?.model, 'SAR 308 Versiyon 2');
    }); // PRF-5 fixed (fix/prf-durbun-eslestirme): un-skipped (CLAUDE.md).

    test('PRF-5: Turkish case folding (İ/i, I/ı) in the matcher', () {
      expect(
        ProfileCatalogMatch.squash('SARSILMAZ'),
        ProfileCatalogMatch.squash('Sarsılmaz'),
      );
      expect(
        ProfileCatalogMatch.squash('İSTANBUL SİLAH'),
        ProfileCatalogMatch.squash('istanbul silah'),
      );
      expect(ProfileCatalogMatch.brandMatches('TIKKA', 'Tikka'), isTrue);
      expect(ProfileCatalogMatch.brandMatches('sarsilmaz', 'Sarsılmaz'), isTrue);
      expect(ProfileCatalogMatch.brandMatches('Hatsan', 'Sarsılmaz'), isFalse);
    });
  });

  group('Barut katsayısı semantics (%/15 °C, unchanged by #308)', () {
    test('ⓘ example: 2600 fps at 10 °C, 1,5 -> 2639 fps at 25 °C', () {
      final f = PowderTemperature.factor(
        coefPercentPer15C: 1.5,
        referenceTempC: 10,
        todayTempC: 25,
      );
      expect(2600 * f, closeTo(2639, 0.5));
      expect(ProfileFieldInfo.powderCoef, contains('15 °C'));
      expect(ProfileFieldInfo.powderCoef, contains('yüzde'));
      expect(ProfileFieldInfo.powderCoef, contains('1,5'));
    });

    test('an old saved 0,8 / 21 °C is read the same way', () {
      final p = _decode(_profileJson());
      expect(p.powderTempCoefPercentPer15C, 0.8);
      expect(p.powderTempReferenceC, 21);
      // 0,8 %/15 °C, 21 -> 6 °C: 1 - 0.008 = 0.992.
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: p.powderTempCoefPercentPer15C,
          referenceTempC: p.powderTempReferenceC,
          todayTempC: 6,
        ),
        closeTo(0.992, 1e-12),
      );
    });
  });
}
