// Pre-TestFlight audit 2026-10-15b, area PROFIL SPLIT + TÜR ZORUNLU.
//
// #318 (2188ec9): profiles_screen.dart split into part files
// (profile_editor*.dart, profile_summary.dart), "Seçiniz" for Tür on a new
// profile, MenzilSelect's own list under the box, Ek mühimmat bilgileri as
// its own card. #323 (d3fdf29): a new profile cannot be saved while Tür is
// "Seçiniz"; Profili Düzenle unchanged.
//
// Question: user input -> stored value -> solver input stays the same. Each
// round trip snapshots what Balistik / Hedef reads from the stored profile
// (profile + resolved rifle / ammunition / scope via
// ProfileCatalogIntegrity), opens Profili Düzenle, presses Güncelle without
// touching anything and compares. Tolerances are the editor's display
// rounding only (tools/denetim_2026_10_15b_profil.py derives them by hand:
// fps with one decimal <= 0.01524 m/s, band thresholds whole fps <= 0.1524
// m/s, zero to 0.1 yd <= 0.04572 m, turret travel as whole clicks).
//
// Findings (see the audit report):
//   PRF-9 (medium, pre-existing since #262, made reachable by every new
//         profile's "Seçiniz" boxes): a zero typed while Mesafe birimi is
//         still "Seçiniz" is converted as if it were metres when Yard is
//         picked (100 -> 109.4 yd, stored 100 m instead of 91.44 m).
//                                                             [skipped test]
//   PRF-10 (low, #318/#323; same bug as PRF-7 in profil_tur_audit_test.dart,
//         fixed by #327): picking Tür after Kalibre reset the chosen
//         cartridge to the first one of the same diameter (".300 Win Mag"
//         -> ".308 Win"); diameter, and so the calculation, unchanged.
//                                                     [test runs, no skip]
// Passing guards: listed factory round with saved BC bands in the moved Ek
// mühimmat card, yard + MOA + travel; typed SMOA scope + decimal twist;
// unresolved (missing) rifle record: Tür filled from the ammunition,
// never listed missing; Kopyala of an old profile then Güncelle; new profile
// with Tür picked last keeps every typed value (Ek mühimmat, yard zero).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/cartridges.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/rifle_form.dart';

// ---- Saved records (ManualCatalogStore JSON, as the app stores them) -------

const _typedRifle = <String, dynamic>{
  'id': 'manual_rifle_a15b',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Atölyem',
  'model': 'Özel Yapım',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 10,
};

/// The first listed .308 Win factory round with a maker BC and model, saved
/// with two BC bands the user typed in Ek mühimmat bilgileri (a listed
/// round shows the Hıza göre BC rows there).
final FactoryAmmo _factory308 = FactoryAmmoLibrary.all.firstWhere(
  (a) => a.cartridge == '.308 Win' && a.bc != null && a.model != null,
);

Map<String, dynamic> _factoryAmmo() => <String, dynamic>{
  'id': 'manual_ammo_a15b_fab',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': _factory308.brand,
  'model': _factory308.name,
  'caliberMm': 7.82,
  'grain': _factory308.grain,
  'ammoType': 'bullet',
  'bc': _factory308.bc,
  'bcModel': _factory308.model!.name,
  'bcBands': [
    {'mps': 700.0, 'bc': _factory308.bc},
    {'mps': 500.0, 'bc': 0.45},
    {'mps': 0.0, 'bc': 0.42},
  ],
};

/// 100 MOA total travel (400 clicks of 1/4 MOA) in mrad: 100 * pi / 10.8.
const double _hundredMoaInMrad = 29.08882086657216;

const _typedScopeMoa = <String, dynamic>{
  'id': 'manual_scope_a15b_moa',
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

/// Typed rifle with a decimal twist (1:9.5 in) and a typed G7 round.
const _typedRifleDecimal = <String, dynamic>{
  'id': 'manual_rifle_a15b_dec',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Atölyem',
  'model': 'Kısa Namlu',
  'caliberMm': 7.82,
  'twistDirection': 'left',
  'twistRateIn': 9.5,
};

const _typedAmmoG7 = <String, dynamic>{
  'id': 'manual_ammo_a15b_g7',
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

/// 120 SMOA total travel (480 clicks of 1/4 SMOA) in mrad: 120 * 1000/3600
/// (1 SMOA = 1 in at 100 yd = 0.0254 / 91.44 rad).
const double _smoaTravelMrad = 33.333333333333336;

const _typedScopeSmoa = <String, dynamic>{
  'id': 'manual_scope_a15b_smoa',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Atölyem Optik',
  'model': '5-25x56 FFP',
  'objectiveMm': 56,
  'click': 0.25,
  'clickUnit': 'smoa',
  'focal': 'ffp',
  'minMag': 5,
  'maxMag': 25,
  'magnification': '5-25x',
  'elevationRangeMrad': _smoaTravelMrad,
};

/// The rifle id of an old profile whose rifle record is gone (unresolved):
/// the editor takes the Tür from the ammunition. A record without a Tür
/// (platform) cannot be in the personal store at all: ManualCatalogStore
/// rejects it on write and on read (_validateEntry), so the unresolved rifle
/// is modelled by a missing record.
const _missingRifleId = 'manual_rifle_a15b_np';

const _oldFireAmmo = <String, dynamic>{
  'id': 'manual_ammo_a15b_old',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Eski Marka',
  'model': 'Eski Fişek',
  'caliberMm': 7.82,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.475,
  'bcModel': 'g1',
};

const _oldFireScope = <String, dynamic>{
  'id': 'manual_scope_a15b_old',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Atölyem Optik',
  'model': '4-16x44 SFP',
  'objectiveMm': 44,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'sfp',
  'minMag': 4,
  'maxMag': 16,
  'magnification': '4-16x',
};

const _oldFireRifle = <String, dynamic>{
  'id': 'manual_rifle_a15b_old',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Atölyem',
  'model': 'Eski Tüfek',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 11,
};

Map<String, dynamic> _profileJson({
  required String id,
  required String name,
  required String rifleId,
  required String ammoId,
  required String scopeId,
  double velocityMps = 822.96, // 2700 fps
  double zeroM = 91.44, // 100 yd
  double sightMm = 50.8, // 2 in
  String angularUnit = 'moa',
  String distanceUnit = 'yard',
  double cantMoa = 30,
  double? powderCoef = 1.25,
  double? powderRef = 15,
}) => {
  'id': id,
  'name': name,
  'rifleId': rifleId,
  'ammunitionId': ammoId,
  'scopeId': scopeId,
  'muzzleVelocityMps': velocityMps,
  'zeroRangeM': zeroM,
  'sightHeightMm': sightMm,
  'pressureBar': null,
  'tubePressureBar': null,
  'pressureVelocity': const <Map<String, double>>[],
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

// ---- Solver inputs (as test/audit_2026_10_14b/profile_match_audit_test) ---

Map<String, Object?> _solverInputs(RifleProfile p) {
  final r = const ProfileCatalogIntegrity().resolve(p);
  expect(r, isNotNull, reason: 'profile ${p.id} no longer resolves');
  final rifle = r!.rifle, a = r.ammunition, s = r.scope;
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
    'effectiveClick': effClick,
    'clickUnit': s.clickUnit,
    'elevationRangeMrad': s.elevationRangeMrad,
    'firstFocalPlane': s.firstFocalPlane,
    'minMag': s.minMagnification,
    'maxMag': s.maxMagnification,
    'objectiveMm': s.objectiveDiameterMm,
  };
}

/// Editor display rounding only (tools/denetim_2026_10_15b_profil.py).
const Map<String, double> _tolerance = {
  'muzzleVelocityMps': 0.02,
  'zeroRangeM': 0.05,
  'band0Mps': 0.2,
  'band1Mps': 0.2,
  'band2Mps': 0.2,
  'elevationRangeMrad': 0.05,
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
  WidgetTester tester, [
  List<RifleProfile> profiles = const [],
]) async {
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

Future<void> _openNew(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
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

/// The names listed under "Tüfek:" in "Kaydetmek için eksik".
List<String> _rifleMissing(WidgetTester tester) {
  final text = _missingText(tester);
  if (text.isEmpty) return const [];
  final body = text.substring('Kaydetmek için eksik: '.length);
  for (final part in body.split(' · ')) {
    if (part.startsWith('Tüfek: ')) {
      return part.substring('Tüfek: '.length).split(', ');
    }
  }
  return const [];
}

VoidCallback? _action(WidgetTester tester, String label) => tester
    .widget<MenzilPrimaryButton>(
      find.widgetWithText(MenzilPrimaryButton, label),
    )
    .onPressed;

/// Presses Kaydet / Güncelle and expects the editor to close.
Future<void> _press(WidgetTester tester, String label) async {
  expect(_action(tester, label), isNotNull, reason: _missingText(tester));
  final button = find.widgetWithText(MenzilPrimaryButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  // A save error notice (store write / read back) names the cause.
  for (final t in ['kaydedilemedi', 'okunamadı', 'eksik veya hatalı']) {
    expect(find.textContaining(t), findsNothing, reason: t);
  }
  expect(find.text('Profili Düzenle'), findsNothing);
  expect(find.text('Profil Oluştur'), findsNothing);
}

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

/// The ⋯ menu of the row of profile [id].
Future<void> _rowMenu(WidgetTester tester, String id, String item) async {
  final menu = find.descendant(
    of: find.byKey(ValueKey(id)),
    matching: find.byTooltip('Profil işlemleri'),
  );
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<Map<String, dynamic>> _record(String id) async =>
    (await ManualCatalogStore().all()).singleWhere((e) => e['id'] == id);

/// Every box of a new firearm profile except Tür (left on "Seçiniz"), the
/// zero in yards (as test/tur_zorunlu_test.dart, Mesafe birimi = Yard).
Future<void> _fillAllButTur(WidgetTester tester) async {
  await openRifleManual(tester);
  await enterRifleField(tester, 'rifle-brand', 'Test Marka');
  await enterRifleField(tester, 'rifle-model', 'Test Model');
  await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
  await enterRifleField(tester, 'rifle-twist-rate', '11');
  await chooseTwistDirection(tester, 'Sağ');
  await fillScopeForm(tester);
  await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
  // Typed round: Marka "Diğer marka" since 2026-10-17.
  await chooseOtherAmmoBrand(tester);
  await enterRifleField(tester, 'ammo-grain', '173');
  await enterRifleField(tester, 'ammo-bc', '0,5');
  await chooseInSelect(tester, 'ammo-bc-model', 'G7');
  await chooseInSelect(tester, 'profile-powder-coef', '1,5');
  await chooseInSelect(tester, 'profile-powder-temp', '21');
  await enterRifleField(tester, 'profile-velocity-fps', '2650');
  await chooseInSelect(tester, 'profile-distance-unit', 'Yard');
  await enterRifleField(tester, 'profile-zero', '100');
  await enterRifleField(tester, 'scope-sight-height', '45');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('Profili Düzenle after the split: Güncelle keeps every value', () {
    testWidgets('listed factory round with saved BC bands (Ek mühimmat card), '
        'yard zero, MOA scope with travel, 30 MOA mount, Barut 1,25 / 15', (
      tester,
    ) async {
      final ammo = _factoryAmmo();
      _seed([_typedRifle, ammo, _typedScopeMoa]);
      final p = _decode(
        _profileJson(
          id: 'a15b-fab',
          name: 'Fabrika Profil',
          rifleId: 'manual_rifle_a15b',
          ammoId: 'manual_ammo_a15b_fab',
          scopeId: 'manual_scope_a15b_moa',
        ),
      );
      final before = _solverInputs(p);
      expect(before['bandRows'], 3);
      final store = await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);

      // The bands are in the moved Ek mühimmat card, prefilled.
      final card = find.byKey(const Key('profile-ammo-extra-form'));
      expect(card, findsOneWidget);
      const bandKeys = ['ammo-band-fps-0', 'ammo-band-bc-0', 'ammo-band-fps-1'];
      for (final k in bandKeys) {
        expect(
          find.descendant(of: card, matching: find.byKey(Key(k))),
          findsOneWidget,
          reason: k,
        );
      }
      expect(_text(tester, 'ammo-band-fps-0'), '2297'); // 700 m/s
      expect(_text(tester, 'ammo-band-bc-0'), '0.45');
      expect(_text(tester, 'ammo-band-fps-1'), '1640'); // 500 m/s
      expect(_text(tester, 'ammo-band-bc-1'), '0.42');
      expect(selectedValue<String>(tester, 'profile-powder-coef'), '1,25');
      expect(selectedValue<String>(tester, 'profile-powder-temp'), '15');
      // Every saved choice is filled in: no "Seçiniz" default blocks it.
      expect(
        selectedValue<WeaponPlatform>(tester, 'profile-platform'),
        WeaponPlatform.firearm,
      );
      expect(
        selectedValue<DistanceUnit>(tester, 'profile-distance-unit'),
        DistanceUnit.yard,
      );
      expect(selectedValue<double>(tester, 'scope-mount'), 30);
      expect(_text(tester, 'profile-zero'), '100');
      expect(_text(tester, 'profile-velocity-fps'), '2700');
      expect(_text(tester, 'scope-travel-elevation'), '400');
      expect(_missingText(tester), isEmpty);

      await _press(tester, 'Güncelle');
      final saved = (await store.all()).single;
      _expectSameInputs(before, _solverInputs(saved));
      // The personal record only this profile uses is updated in place and
      // keeps its identity and calculation fields.
      expect(saved.ammunitionId, 'manual_ammo_a15b_fab');
      final rec = await _record('manual_ammo_a15b_fab');
      const fields = ['brand', 'model', 'grain', 'bc', 'bcModel', 'caliberMm'];
      for (final k in fields) {
        expect(rec[k], ammo[k], reason: k);
      }
      expect((rec['bcBands'] as List).length, 3);
    });

    testWidgets('typed SMOA scope with travel, decimal twist 1:9,5, left '
        'twist, metres, 20 MOA mount, typed G7 round', (tester) async {
      _seed([_typedRifleDecimal, _typedAmmoG7, _typedScopeSmoa]);
      final p = _decode(
        _profileJson(
          id: 'a15b-smoa',
          name: 'SMOA Profil',
          rifleId: 'manual_rifle_a15b_dec',
          ammoId: 'manual_ammo_a15b_g7',
          scopeId: 'manual_scope_a15b_smoa',
          velocityMps: 850,
          zeroM: 100,
          sightMm: 38.1, // 1.5 in
          angularUnit: 'smoa',
          distanceUnit: 'meter',
          cantMoa: 20,
          powderCoef: null,
          powderRef: null,
        ),
      );
      final before = _solverInputs(p);
      final store = await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      expect(_text(tester, 'rifle-twist-rate'), '9.5');
      expect(_text(tester, 'scope-sight-height'), '38.1');
      expect(_text(tester, 'scope-travel-elevation'), '480');
      // No Barut values: the Ek mühimmat lists stay on "Seçiniz" and
      // nothing is written for them.
      expect(selectedValue<String>(tester, 'profile-powder-coef'), isNull);
      await _press(tester, 'Güncelle');
      final saved = (await store.all()).single;
      _expectSameInputs(before, _solverInputs(saved));
      expect(saved.powderTempCoefPercentPer15C, isNull);
      expect(saved.powderTempReferenceC, isNull);
      expect(_solverInputs(saved)['effectiveClick'], 0.25);
      expect(_solverInputs(saved)['clickUnit'], AngularUnit.smoa);
    });
  });

  group('#323 Tür zorunlu: old profiles are never blocked by Tür', () {
    testWidgets('rifle record missing (unresolved): Tür comes from the '
        'ammunition, is never listed missing; after typing the rifle '
        'Güncelle saves and keeps the other values', (tester) async {
      _seed([_oldFireAmmo, _oldFireScope]);
      expect(
        CatalogRepository.allRifles.any((r) => r.id == _missingRifleId),
        isFalse,
      );
      final p = _decode(
        _profileJson(
          id: 'a15b-np',
          name: 'Türsüz Profil',
          rifleId: _missingRifleId,
          ammoId: 'manual_ammo_a15b_old',
          scopeId: 'manual_scope_a15b_old',
          velocityMps: 800,
          zeroM: 100,
          sightMm: 45,
          angularUnit: 'mrad',
          distanceUnit: 'meter',
          cantMoa: 0,
          powderCoef: null,
          powderRef: null,
        ),
      );
      final store = await _pumpList(tester, [p]);
      await _openEdit(tester, p.name);
      expect(find.textContaining('tüfek'), findsWidgets);
      expect(
        selectedValue<WeaponPlatform>(tester, 'profile-platform'),
        WeaponPlatform.firearm,
      );
      expect(_rifleMissing(tester), isNot(contains('Tür')));
      // Fail-closed (unchanged): the unresolved rifle's boxes are asked.
      expect(_rifleMissing(tester), contains('Marka'));

      await fillRifleForm(tester, caliber: '.308 Win', twist: '11');
      expect(_rifleMissing(tester), isEmpty, reason: _missingText(tester));
      await _press(tester, 'Güncelle');
      final saved = (await store.all()).single;
      final after = _solverInputs(saved);
      expect(after['platform'], WeaponPlatform.firearm);
      expect(after['muzzleVelocityMps'], closeTo(800, 0.02));
      expect(after['zeroRangeM'], closeTo(100, 1e-9));
      expect(after['sightHeightMm'], 45);
      expect(after['bc'], 0.475);
      expect(after['bcModel'], BallisticModel.g1);
      expect(after['grain'], 175);
      expect(after['caliberMm'], 7.82);
      expect(after['twistRateIn'], 11);
      expect(saved.ammunitionId, 'manual_ammo_a15b_old');
    });

    testWidgets('Kopyala of an old profile, then Profili Düzenle on the copy: '
        'Tür filled, Güncelle works, the copy solves like the original', (
      tester,
    ) async {
      _seed([_oldFireRifle, _oldFireAmmo, _oldFireScope]);
      final p = _decode(
        _profileJson(
          id: 'a15b-orig',
          name: 'Eski Ateşli',
          rifleId: 'manual_rifle_a15b_old',
          ammoId: 'manual_ammo_a15b_old',
          scopeId: 'manual_scope_a15b_old',
          velocityMps: 800,
          zeroM: 100,
          sightMm: 45,
          angularUnit: 'mrad',
          distanceUnit: 'meter',
          cantMoa: 0,
        ),
      );
      final before = _solverInputs(p);
      final store = await _pumpList(tester, [p]);
      await _rowMenu(tester, p.id, 'Kopyala');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final copy = (await store.all()).singleWhere((x) => x.id != p.id);
      _expectSameInputs(before, _solverInputs(copy));

      await _openEdit(tester, copy.name);
      expect(
        selectedValue<WeaponPlatform>(tester, 'profile-platform'),
        WeaponPlatform.firearm,
      );
      expect(_rifleMissing(tester), isNot(contains('Tür')));
      await _press(tester, 'Güncelle');
      final all = await store.all();
      _expectSameInputs(
        before,
        _solverInputs(all.singleWhere((x) => x.id == copy.id)),
      );
      // The original is untouched.
      expect(
        const ProfileCodec().encode(all.singleWhere((x) => x.id == p.id)),
        const ProfileCodec().encode(p),
      );
    });
  });

  group('Profil Oluştur: Tür picked last keeps every typed value', () {
    testWidgets('Ek mühimmat (Barut 1,5 / 21), yard zero, fps velocity and '
        'the typed round are stored as typed', (tester) async {
      final store = await _pumpList(tester);
      await _openNew(tester);
      await _fillAllButTur(tester);
      expect(_missingText(tester), 'Kaydetmek için eksik: Tüfek: Tür');
      await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
      expect(_missingText(tester), isEmpty);
      // Same Tür as the form already had: nothing was cleared.
      expect(_text(tester, 'ammo-bc'), '0,5');
      expect(_text(tester, 'profile-zero'), '100');
      expect(selectedValue<String>(tester, 'profile-powder-coef'), '1,5');
      await _press(tester, 'Kaydet');

      final saved = (await store.all()).single;
      // 2650 fps * 0.3048 = 807.72 m/s; 100 yd * 0.9144 = 91.44 m.
      expect(saved.muzzleVelocityMps, closeTo(807.72, 1e-9));
      expect(saved.zeroRangeM, closeTo(91.44, 1e-9));
      expect(saved.distanceUnit, DistanceUnit.yard);
      expect(saved.sightHeightMm, 45);
      expect(saved.powderTempCoefPercentPer15C, 1.5);
      expect(saved.powderTempReferenceC, 21);
      final inputs = _solverInputs(saved);
      expect(inputs['platform'], WeaponPlatform.firearm);
      expect(inputs['caliberMm'], 7.82);
      expect(inputs['twistRateIn'], 11);
      expect(inputs['grain'], 173);
      expect(inputs['bc'], 0.5);
      expect(inputs['bcModel'], BallisticModel.g7);
      expect(inputs['bandRows'], 0);
    });

    testWidgets('PRF-9: a zero typed while Mesafe birimi is "Seçiniz" is not '
        'converted as metres when Yard is picked', (tester) async {
      await _pumpList(tester);
      await _openNew(tester);
      expect(
        selectedValue<DistanceUnit>(tester, 'profile-distance-unit'),
        isNull,
      );
      await enterRifleField(tester, 'profile-zero', '100');
      await chooseInSelect(tester, 'profile-distance-unit', 'Yard');
      // Today: "109.4" (100 m in yards); the user typed 100 yd.
      expect(_text(tester, 'profile-zero'), '100');
    }, skip: true); // PRF-9: unset unit converts the typed zero from metres

    testWidgets('PRF-10 guard: picking Tür after Kalibre keeps the bullet '
        'diameter (the calculation input)', (tester) async {
      await _pumpList(tester);
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '.300 Win Mag');
      await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
      final key = selectedValue<String>(tester, 'rifle-caliber');
      final mm = Cartridges.firearm.where((e) => e.$1 == key).single.$2;
      expect(mm, 7.82);
    });

    testWidgets('PRF-10: picking Tür after Kalibre keeps the cartridge', (
      tester,
    ) async {
      await _pumpList(tester);
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '.300 Win Mag');
      expect(selectedValue<String>(tester, 'rifle-caliber'), '.300 Win Mag');
      await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
      // Before #327: ".308 Win" (first cartridge of 7.82 mm).
      expect(selectedValue<String>(tester, 'rifle-caliber'), '.300 Win Mag');
    }); // PRF-10: fixed by #327
  });
}
