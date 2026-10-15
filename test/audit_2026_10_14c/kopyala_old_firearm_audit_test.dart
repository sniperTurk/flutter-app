// Pre-TestFlight audit 2026-10-14c — interaction guards, all expected to pass.
//
// #309 (⋯ menu, Ek mühimmat bilgileri) × #313 (PRF-2 Kopyala) × #307/#308
// (old profiles) × hidden AMMO_BC_BANDS_TYPED (default off):
// an old typed firearm profile with Barut katsayısı, Hız ölçüm sıcaklığı
// and saved Hıza göre BC bands (hidden for a typed round, kept in the record)
// is copied with the row's ⋯ → Kopyala; the copy flies like the original;
// editing the copy's BC changes only the copy and keeps its powder values and
// bands; the original's record and solver inputs are untouched.
//
// Record shapes follow test/atesli_elle_muhimmat_test.dart; helpers follow
// test/audit_2026_10_14b/prf2_kopyala_test.dart.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import '../support/rifle_form.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_old',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Atölye',
  'model': 'Özel',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 10,
};

const _ammo = <String, dynamic>{
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
    {'mps': 700.0, 'bc': 0.475},
    {'mps': 550.0, 'bc': 0.46},
    {'mps': 0.0, 'bc': 0.44},
  ],
};

const _scope = <String, dynamic>{
  'id': 'manual_scope_old',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Optik',
  'model': '5-25x56',
  'objectiveMm': 56,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'ffp',
  'minMag': 5,
  'maxMag': 25,
};

const _original = RifleProfile(
  id: 'old',
  name: 'Eski Profil',
  rifleId: 'manual_rifle_old',
  ammunitionId: 'manual_ammo_old',
  scopeId: 'manual_scope_old',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: 0.8,
  powderTempReferenceC: 20,
);

void _seed(List<Map<String, dynamic>> entries) {
  SharedPreferences.setMockInitialValues({
    ManualCatalogStore.key: jsonEncode(entries),
  });
  CatalogRepository.installUserCatalog(UserCatalog.fromManualEntries(entries));
}

/// Everything Hedef reads from a stored profile, flattened.
Map<String, Object?> _solverInputs(RifleProfile p) {
  final r = const ProfileCatalogIntegrity().resolve(p);
  expect(r, isNotNull, reason: 'profile ${p.id} no longer resolves');
  final rifle = r!.rifle, a = r.ammunition, s = r.scope;
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
    'caliberMm': rifle.caliberMm,
    'twistRateIn': rifle.twistRateIn,
    'twistDirection': rifle.twistDirection,
    'grain': a.grain,
    'bc': a.ballisticCoefficient,
    'bcModel': a.ballisticModel,
    'dragCurve': a.dragCurve?.length,
    'bandRows': a.bcBands.length,
    for (final (i, b) in a.bcBands.indexed) ...{
      'band${i}Mps': b.minVelocityMps,
      'band${i}Bc': b.bc,
    },
    'click': s.clickValue,
    'clickUnit': s.clickUnit,
    'firstFocalPlane': s.firstFocalPlane,
  };
}

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

/// The row's ⋯ menu (#309), then [item].
Future<void> _rowMenu(WidgetTester tester, String id, String item) async {
  final menu = find.byKey(Key('profile-menu-$id'));
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('old typed firearm profile: ⋯ Kopyala → edit copy BC → '
      'original unchanged, powder and bands kept', (tester) async {
    _seed([_rifle, _ammo, _scope]);
    final before = _solverInputs(_original);
    expect(before['bandRows'], 3);
    final store = await _pumpList(tester, [_original]);

    await _rowMenu(tester, 'old', 'Kopyala');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final copy = (await store.all()).singleWhere((p) => p.id != 'old');
    expect(copy.name, 'Eski Profil (kopya)');
    expect(copy.ammunitionId, isNot('manual_ammo_old'));
    expect(_solverInputs(copy), before, reason: 'copy flies like original');

    // Edit the copy (row tap opens the editor without onActivate).
    final row = find.text('Eski Profil (kopya)').first;
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsOneWidget);
    // Ek mühimmat bilgileri is there for a firearm (#309).
    expect(find.byKey(const Key('ammo-extra-header')), findsOneWidget);
    await enterRifleField(tester, 'ammo-bc', '0,5');
    final update = find.text('Güncelle');
    await tester.ensureVisible(update);
    await tester.tap(update);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Profili Düzenle'), findsNothing);

    final saved = await store.all();
    final savedOriginal = saved.singleWhere((p) => p.id == 'old');
    final savedCopy = saved.singleWhere((p) => p.id == copy.id);
    // Original: same record id, same record, same solver inputs.
    expect(savedOriginal.ammunitionId, 'manual_ammo_old');
    expect(_solverInputs(savedOriginal), before);
    final records = await ManualCatalogStore().all();
    expect(records.singleWhere((e) => e['id'] == 'manual_ammo_old'), _ammo);
    // Copy: new BC, powder values and the three bands kept (the first band
    // follows the main BC, as the editor writes it).
    final c = _solverInputs(savedCopy);
    expect(c['bc'], closeTo(0.5, 1e-9));
    expect(c['powderCoef'], 0.8);
    expect(c['powderRef'], 20);
    expect(c['bandRows'], 3);
    expect(c['band1Bc'], closeTo(0.46, 1e-9));
    expect(c['band2Bc'], closeTo(0.44, 1e-9));
    expect(c['band1Mps'] as double, closeTo(550, 0.2));
  });

  testWidgets('⋯ Kopyala works on a row that is not the active profile', (
    tester,
  ) async {
    _seed([_rifle, _ammo, _scope]);
    const other = RifleProfile(
      id: 'other',
      name: 'Diğer',
      rifleId: 'manual_rifle_old',
      ammunitionId: 'manual_ammo_old',
      scopeId: 'manual_scope_old',
      muzzleVelocityMps: 790,
      zeroRangeM: 100,
      sightHeightMm: 45,
    );
    // Shared records (old Kopyala): copying one of them still gives the copy
    // its own records and leaves both originals as they were.
    final beforeOld = _solverInputs(_original);
    final beforeOther = _solverInputs(other);
    final store = await _pumpList(tester, [_original, other]);
    await _rowMenu(tester, 'other', 'Kopyala');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final all = await store.all();
    expect(all, hasLength(3));
    final copy = all.singleWhere((p) => p.name == 'Diğer (kopya)');
    expect(copy.rifleId, isNot('manual_rifle_old'));
    expect(copy.ammunitionId, isNot('manual_ammo_old'));
    expect(copy.scopeId, isNot('manual_scope_old'));
    expect(_solverInputs(copy), beforeOther);
    expect(_solverInputs(all.singleWhere((p) => p.id == 'old')), beforeOld);
    expect(_solverInputs(all.singleWhere((p) => p.id == 'other')), beforeOther);
  });
}
