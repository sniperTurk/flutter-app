// Pre-TestFlight audit 2026-10-15 — PRF-6 (#315) end to end.
//
// Only change since the previous TestFlight (main ea9c9e8): #315, Hız
// Doğrulama writes a shared personal ammunition record under a new id.
// These tests check, on main d86dfff:
//  * the "Mühimmata uygula" (BC) half of the PRF-6 repro (the drag half is
//    test/audit_2026_10_14c/truing_shared_record_audit_test.dart);
//  * an unshared record is still written in place and the trued value runs
//    through stored record → solver input → Hedef DOPE number, against the
//    hand calculation in tools/denetim_2026_10_15.py (independent reference
//    solver tools/formula_reference.py; no other ballistic app);
//  * a second truing after the split does not pile up records, and the old
//    shared record is neither changed nor deleted.
//
// Record and helper shapes follow test/truing_shared_record_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/profiles/shared_records.dart';
import 'package:sniper_turk/features/tools/truing_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

import '../support/tool_fakes.dart';

/// tools/denetim_2026_10_15.py: the 800 m correction a G7 BC of 0.225 needs
/// (rounded to 2 decimals, as typed), and the BC the independent reference
/// solver finds back from it.
const _observedMrad = 9.84;
const _referenceBc = 0.22490;
const _rangeM = 800.0;

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_a15',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};

const _ammoId = 'manual_ammo_a15';
const _ammo = <String, dynamic>{
  'id': _ammoId,
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 175',
  'model': '',
  'caliberMm': 7.62,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.243,
  'bcModel': 'g7',
};

RifleProfile _profile(String id, String name) => RifleProfile(
  id: id,
  name: name,
  rifleId: 'manual_rifle_a15',
  ammunitionId: _ammoId,
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 790,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

Future<void> _seed() async {
  SharedPreferences.setMockInitialValues({});
  await ManualCatalogStore().upsert(_rifle);
  await ManualCatalogStore().upsert(_ammo);
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries(await ManualCatalogStore().all()),
  );
}

Future<MemoryProfileStore> _pumpTruing(
  WidgetTester tester,
  List<RifleProfile> profiles,
  String activeId,
) async {
  tester.view.physicalSize = const Size(430, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  final active = MemoryActiveProfileStore()..value = activeId;
  await tester.pumpWidget(
    host(TruingScreen(profileStore: store, activeProfileStore: active)),
  );
  await tester.pumpAndSettle();
  return store;
}

Finder _field(Key key) => find
    .descendant(
      of: find.byKey(key),
      matching: find.byType(TextField),
      matchRoot: true,
    )
    .first;

Future<void> _enter(WidgetTester tester, Key key, String text) async {
  final f = _field(key);
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// BC mode, 800 m, observed 9,84 mrad, then Mühimmata uygula → Uygula.
Future<void> _trueBcAndApply(WidgetTester tester) async {
  await tester.tap(find.text('Namlu çıkış hızı').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Balistik katsayı (BC)').last);
  await tester.pumpAndSettle();
  await _enter(tester, const Key('truing-range'), '800');
  await _enter(tester, const Key('truing-observed'), '9,84');
  await _tap(tester, 'truing-compute');
  expect(find.byKey(const Key('truing-error')), findsNothing);
  await _tap(tester, 'truing-bc-apply');
  await _tap(tester, 'truing-bc-confirm');
}

Future<List<Map<String, dynamic>>> _records() => ManualCatalogStore().all();

Future<RifleProfile> _stored(ProfileStore store, String id) async =>
    (await store.all()).firstWhere((p) => p.id == id);

Ammunition _ammoOf(RifleProfile p) =>
    const ProfileCatalogIntegrity().resolve(p)!.ammunition;

/// Opens Hedef for [p] with the truing page's air, asks DOPE for [rangeM]
/// and returns the MRAD correction the table shows in that row.
Future<double> _hedefMrad(
  WidgetTester tester,
  RifleProfile p,
  double rangeM,
) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: BallisticsScreen(profile: p)));
  await tester.pumpAndSettle();
  await _enter(tester, BallisticsFieldKeys.temperature, '15');
  await _enter(tester, BallisticsFieldKeys.pressure, '1013,25');
  await _enter(tester, BallisticsFieldKeys.humidity, '50');
  await _enter(tester, BallisticsFieldKeys.ranges, rangeM.toStringAsFixed(0));
  final dope = find.text('DOPE oluştur').first;
  await tester.ensureVisible(dope);
  await tester.tap(dope);
  await tester.pumpAndSettle();
  final table = tester.widget<DataTable>(find.byType(DataTable).first);
  final mradCol = table.columns.indexWhere(
    (c) => c.label is Text && (c.label as Text).data == 'Yükseklik MRAD',
  );
  expect(mradCol, isNonNegative, reason: 'DOPE has no MRAD column');
  double cell(DataRow r, int i) =>
      double.parse((r.cells[i].child as Text).data!.replaceAll(',', '.'));
  final row = table.rows.firstWhere((r) => (cell(r, 0) - rangeM).abs() < 0.5);
  return cell(row, mradCol);
}

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('PRF-6 BC: Mühimmata uygula on a shared record leaves the other '
      'profile and the old record alone', (tester) async {
    await _seed();
    final a = _profile('a', 'Profil A');
    final b = _profile('b', 'Profil B');
    final store = await _pumpTruing(tester, [a, b], 'a');
    await _trueBcAndApply(tester);

    final aNow = await _stored(store, 'a');
    final bNow = await _stored(store, 'b');
    expect(aNow.ammunitionId, isNot(_ammoId));
    expect(bNow.ammunitionId, _ammoId);
    final bAmmo = _ammoOf(bNow);
    expect(bAmmo.ballisticCoefficient, closeTo(0.243, 1e-12));
    expect(bAmmo.ballisticModel, BallisticModel.g7);
    final old = (await _records()).firstWhere((e) => e['id'] == _ammoId);
    expect(old, equals(_ammo), reason: 'old shared record changed');
    expect(
      _ammoOf(aNow).ballisticCoefficient,
      closeTo(_referenceBc, _referenceBc * 0.015),
    );
  });

  testWidgets('unshared record: trued BC in place → solver input → Hedef '
      'number matches the hand calculation', (tester) async {
    await _seed();
    final a = _profile('a', 'Profil A');
    final store = await _pumpTruing(tester, [a], 'a');
    await _trueBcAndApply(tester);

    // Stored: same id, same profile, trued BC, nothing else changed.
    final aNow = await _stored(store, 'a');
    expect(aNow.ammunitionId, _ammoId);
    final records = await _records();
    expect(records.length, 2, reason: 'no extra record for an unshared one');
    final rec = records.firstWhere((e) => e['id'] == _ammoId);
    final truedBc = (rec['bc'] as num).toDouble();
    expect(truedBc, closeTo(_referenceBc, _referenceBc * 0.015));
    expect({...rec}..remove('bc'), equals({..._ammo}..remove('bc')));

    // Solver input: what Hedef resolves for the profile.
    final ammo = _ammoOf(aNow);
    expect(ammo.ballisticCoefficient, truedBc);
    expect(ammo.ballisticModel, BallisticModel.g7);
    final solved = const BallisticEngine().solve(
      BallisticInput(
        muzzleVelocityMps: 790,
        grain: 175,
        zeroRangeM: 100,
        sightHeightMm: 45,
        rangesM: const [_rangeM],
        environment: const EnvironmentData(
          temperatureC: 15,
          pressureHpa: 1013.25,
          humidityPercent: 50,
        ),
        ballisticCoefficient: ammo.ballisticCoefficient,
        ballisticModel: ammo.ballisticModel,
        bcBands: ammo.bcBands,
      ),
    );
    expect(solved.single.correctionMrad, closeTo(_observedMrad, 0.01));

    // Hedef: the DOPE number at 800 m is the observed correction.
    final shown = await _hedefMrad(tester, aNow, _rangeM);
    expect(shown, closeTo(_observedMrad, 0.02));
  });

  testWidgets('second truing after the split updates the new record in '
      'place; no records pile up, none are deleted', (tester) async {
    await _seed();
    final a = _profile('a', 'Profil A');
    final b = _profile('b', 'Profil B');
    final store = await _pumpTruing(tester, [a, b], 'a');
    await _trueBcAndApply(tester);
    final firstId = (await _stored(store, 'a')).ammunitionId;
    expect(
      sharedRecordIdsOf(await store.all(), exceptProfileId: 'a'),
      isNot(contains(firstId)),
    );

    // Reopen the page (fresh state) and true again.
    await tester.pumpWidget(const SizedBox());
    final active = MemoryActiveProfileStore()..value = 'a';
    await tester.pumpWidget(
      host(TruingScreen(profileStore: store, activeProfileStore: active)),
    );
    await tester.pumpAndSettle();
    await _trueBcAndApply(tester);

    final ids = [for (final e in await _records()) e['id']];
    expect(ids, containsAll([_rifle['id'], _ammoId, firstId]));
    expect(ids.length, 3);
    expect((await _stored(store, 'a')).ammunitionId, firstId);
    expect((await _stored(store, 'b')).ammunitionId, _ammoId);
  });
}
