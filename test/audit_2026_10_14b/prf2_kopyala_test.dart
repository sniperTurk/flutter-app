// PRF-2 (pre-TestFlight audit 2026-10-14b, high): Kopyala must make an
// independent copy, and the editor must never overwrite a personal
// (user-entered) record another profile also points at.
//
// The first test is the audit's PRF-2 test (branch
// audit/testflight-2026-10-14b, test/audit_2026_10_14b/
// profile_match_audit_test.dart), copied un-skipped. Record constants and
// helpers are copied from the same file.
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
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/rifle_form.dart';

// ---- Saved records (ManualCatalogStore JSON) ------------------------------

/// Typed (Listede yok) firearm rifle and G7 round.
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


// ---- PRF-2 helpers -----------------------------------------------------------

RifleProfile _pcpProfile({String id = 'orig', String name = 'Eski Slug'}) =>
    _decode(
      _profileJson(
        id: id,
        name: name,
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

Future<List<Map<String, dynamic>>> _records() => ManualCatalogStore().all();

Map<String, dynamic> _record(List<Map<String, dynamic>> all, String id) =>
    all.singleWhere((e) => e['id'] == id);

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

/// Kopyala on [id]; returns the stored copy.
Future<RifleProfile> _copy(
  WidgetTester tester,
  MemoryProfileStore store,
  String id,
) async {
  final before = {for (final p in await store.all()) p.id};
  await _rowMenu(tester, id, 'Kopyala');
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return (await store.all()).singleWhere((p) => !before.contains(p.id));
}

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)),
    )
    .controller!
    .text;

/// Leaves the editor without saving.
Future<void> _close(WidgetTester tester) async {
  Navigator.of(tester.element(find.text('Profili Düzenle'))).pop();
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsNothing);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('PRF-2: Kopyala is an independent copy', () {
    // Audit test, un-skipped: a copy made before this fix shares the
    // records; editing it must not change the original.
    testWidgets('editing the copy\'s BC leaves the original profile alone', (
      tester,
    ) async {
      _seed([_pcpRifle, _pcpAmmo, _pcpScope]);
      final original = _pcpProfile();
      // What _duplicate stored before the fix: new id and name, the SAME
      // record ids.
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
    });

    testWidgets('Kopyala copies typed records under new ids; BC edit in '
        'the copy leaves the original alone', (tester) async {
      _seed([_pcpRifle, _pcpAmmo, _pcpScope]);
      final original = _pcpProfile();
      final before = _solverInputs(original);
      final store = await _pumpList(tester, [original]);
      final copy = await _copy(tester, store, 'orig');
      expect(copy.name, 'Eski Slug (kopya)');
      for (final (o, c) in [
        (original.rifleId, copy.rifleId),
        (original.ammunitionId, copy.ammunitionId),
        (original.scopeId, copy.scopeId),
      ]) {
        expect(c, isNot(o));
        expect(c, startsWith(o.substring(0, o.lastIndexOf('_') + 1)));
      }
      // The copy flies exactly like the original.
      expect(_solverInputs(copy), before);
      // The copied records carry every saved field (incl. the hidden
      // length) apart from the id.
      final all = await _records();
      expect({..._record(all, copy.ammunitionId), 'id': 'x'}, {
        ..._pcpAmmo,
        'id': 'x',
      });

      await _openEdit(tester, 'Eski Slug (kopya)');
      await enterRifleField(tester, 'ammo-bc', '0,12');
      await _update(tester);
      final saved = await store.all();
      final savedCopy = saved.singleWhere((x) => x.id == copy.id);
      final savedOriginal = saved.singleWhere((x) => x.id == 'orig');
      expect(_solverInputs(savedCopy)['bc'], closeTo(0.12, 1e-9));
      expect(_solverInputs(savedOriginal), before);
      expect(_record(await _records(), 'manual_ammo_pcp'), _pcpAmmo);
    });

    testWidgets('copy then edit typed rifle and scope fields: original '
        'unchanged', (tester) async {
      _seed([_pcpRifle, _pcpAmmo, _pcpScope]);
      final original = _pcpProfile();
      final before = _solverInputs(original);
      final store = await _pumpList(tester, [original]);
      final copy = await _copy(tester, store, 'orig');
      await _openEdit(tester, 'Eski Slug (kopya)');
      await enterRifleField(tester, 'rifle-model', 'Slug Yeni');
      await enterRifleField(tester, 'scope-brand', 'Optik Yeni');
      await _update(tester);
      final saved = await store.all();
      final savedCopy = saved.singleWhere((x) => x.id == copy.id);
      final savedOriginal = saved.singleWhere((x) => x.id == 'orig');
      final rc = const ProfileCatalogIntegrity().resolve(savedCopy)!;
      expect(rc.rifle.model, 'Slug Yeni');
      expect(rc.scope.brand, 'Optik Yeni');
      final ro = const ProfileCatalogIntegrity().resolve(savedOriginal)!;
      expect(ro.rifle.model, 'Slug');
      expect(ro.scope.brand, 'Optik');
      expect(savedOriginal.rifleId, 'manual_rifle_pcp');
      expect(savedOriginal.scopeId, 'manual_scope_pcp');
      expect(_solverInputs(savedOriginal), before);
      final all = await _records();
      expect(_record(all, 'manual_rifle_pcp'), _pcpRifle);
      expect(_record(all, 'manual_scope_pcp'), _pcpScope);
    });

    testWidgets('catalog records keep their catalog ids', (tester) async {
      _seed([_typedRifle, _typedAmmo]);
      final original = _decode(
        _profileJson(
          id: 'orig',
          name: 'Karışık',
          rifleId: 'manual_rifle_typed',
          ammoId: 'manual_ammo_typed',
          scopeId: _arkenCatalogId,
        ),
      );
      final before = _solverInputs(original);
      final store = await _pumpList(tester, [original]);
      final copy = await _copy(tester, store, 'orig');
      expect(copy.scopeId, _arkenCatalogId);
      expect(copy.rifleId, isNot('manual_rifle_typed'));
      expect(copy.ammunitionId, isNot('manual_ammo_typed'));
      expect(_solverInputs(copy), before);
      // Only the two typed records were copied; no record for the catalog
      // scope was written.
      final all = await _records();
      expect(all, hasLength(4));
      expect(all.where((e) => e['kind'] == 'scope'), isEmpty);
    });

    testWidgets('two old profiles sharing one typed record: editing one '
        'leaves the other unchanged', (tester) async {
      _seed([_pcpRifle, _pcpAmmo, _pcpScope]);
      final a = _pcpProfile(id: 'a', name: 'Profil A');
      final b = _pcpProfile(id: 'b', name: 'Profil B');
      final beforeB = _solverInputs(b);
      final store = await _pumpList(tester, [a, b]);
      await _openEdit(tester, 'Profil A');
      await enterRifleField(tester, 'ammo-bc', '0,13');
      await _update(tester);
      final saved = await store.all();
      final savedA = saved.singleWhere((x) => x.id == 'a');
      final savedB = saved.singleWhere((x) => x.id == 'b');
      expect(_solverInputs(savedA)['bc'], closeTo(0.13, 1e-9));
      expect(savedA.ammunitionId, isNot('manual_ammo_pcp'));
      expect(savedB.ammunitionId, 'manual_ammo_pcp');
      expect(_solverInputs(savedB), beforeB);
      expect(_record(await _records(), 'manual_ammo_pcp'), _pcpAmmo);

      // After the split A owns its record: the next edit updates it in
      // place and B still stays the same.
      final splitId = savedA.ammunitionId;
      await _openEdit(tester, 'Profil A');
      await enterRifleField(tester, 'ammo-bc', '0,14');
      await _update(tester);
      final again = await store.all();
      final a2 = again.singleWhere((x) => x.id == 'a');
      expect(a2.ammunitionId, splitId);
      expect(_solverInputs(a2)['bc'], closeTo(0.14, 1e-9));
      expect(
        _solverInputs(again.singleWhere((x) => x.id == 'b')),
        beforeB,
      );
    });

    testWidgets('a record only this profile uses is updated in place', (
      tester,
    ) async {
      _seed([_pcpRifle, _pcpAmmo, _pcpScope]);
      final store = await _pumpList(tester, [_pcpProfile()]);
      await _openEdit(tester, 'Eski Slug');
      await enterRifleField(tester, 'ammo-bc', '0,12');
      await _update(tester);
      final saved = (await store.all()).single;
      expect(saved.ammunitionId, 'manual_ammo_pcp');
      expect(_solverInputs(saved)['bc'], closeTo(0.12, 1e-9));
    });

    testWidgets('save -> reopen round trip keeps each profile\'s values', (
      tester,
    ) async {
      _seed([_pcpRifle, _pcpAmmo, _pcpScope]);
      final store = await _pumpList(tester, [_pcpProfile()]);
      await _copy(tester, store, 'orig');
      await _openEdit(tester, 'Eski Slug (kopya)');
      await enterRifleField(tester, 'ammo-bc', '0,12');
      await _update(tester);

      await _openEdit(tester, 'Eski Slug (kopya)');
      expect(_text(tester, 'ammo-bc'), anyOf('0,12', '0.12'));
      await _close(tester);
      await _openEdit(tester, 'Eski Slug');
      expect(_text(tester, 'ammo-bc'), anyOf('0,1', '0.1'));
      // Güncelle without changes keeps the original's values.
      final before = _solverInputs(
        (await store.all()).singleWhere((x) => x.id == 'orig'),
      );
      await _update(tester);
      expect(
        _solverInputs((await store.all()).singleWhere((x) => x.id == 'orig')),
        before,
      );
    });

    testWidgets('deleting the copy leaves the original intact', (
      tester,
    ) async {
      _seed([_pcpRifle, _pcpAmmo, _pcpScope]);
      final original = _pcpProfile();
      final before = _solverInputs(original);
      final store = await _pumpList(tester, [original]);
      final copy = await _copy(tester, store, 'orig');
      await _rowMenu(tester, copy.id, 'Sil');
      expect(find.text('Profil silinsin mi?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
      await tester.pumpAndSettle();
      final left = await store.all();
      expect(left.map((p) => p.id), ['orig']);
      expect(_solverInputs(left.single), before);
      final all = await _records();
      expect(_record(all, 'manual_rifle_pcp'), _pcpRifle);
      expect(_record(all, 'manual_ammo_pcp'), _pcpAmmo);
      expect(_record(all, 'manual_scope_pcp'), _pcpScope);
    });
  });
}
