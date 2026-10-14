// PRF-6 fix: Hız Doğrulama writes a personal ammunition record that another
// profile also points at (a Kopyala made before #313) under a NEW id and
// re-points only the active profile, the Profili Düzenle rule
// (sharedRecordIdsOf). An unshared record is still updated in place.
//
// Record and helper shapes follow
// test/audit_2026_10_14c/truing_shared_record_audit_test.dart.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/shared_records.dart';
import 'package:sniper_turk/features/tools/truing_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';

import 'support/tool_fakes.dart';

const _ammoId = 'manual_ammo_p6';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_p6',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};

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
  rifleId: 'manual_rifle_p6',
  ammunitionId: _ammoId,
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 790,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

final _a = _profile('a', 'Profil A');
final _b = _profile('b', 'Profil B');

/// Truing page default air (15 °C, 1013,25 hPa, %50), as the page predicts.
List<double> _predicted(List<double> ranges) => [
  for (final p in const BallisticEngine().solve(
    BallisticInput(
      muzzleVelocityMps: 790,
      grain: 175,
      zeroRangeM: 100,
      sightHeightMm: 45,
      rangesM: ranges,
      environment: const EnvironmentData(
        temperatureC: 15,
        pressureHpa: 1013.25,
        humidityPercent: 50,
      ),
      ballisticCoefficient: 0.243,
      ballisticModel: BallisticModel.g7,
    ),
  ))
    p.correctionMrad,
];

Future<void> _installFromStore() async => CatalogRepository.installUserCatalog(
  UserCatalog.fromManualEntries(await ManualCatalogStore().all()),
);

Future<void> _seed() async {
  SharedPreferences.setMockInitialValues({});
  await ManualCatalogStore().upsert(_rifle);
  await ManualCatalogStore().upsert(_ammo);
  await _installFromStore();
}

Future<void> _pump(
  WidgetTester tester,
  ProfileStore store,
  String activeId,
) async {
  tester.view.physicalSize = const Size(430, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final active = MemoryActiveProfileStore()..value = activeId;
  await tester.pumpWidget(
    host(TruingScreen(profileStore: store, activeProfileStore: active)),
  );
  await tester.pumpAndSettle();
}

Future<MemoryProfileStore> _storeWith(List<RifleProfile> profiles) async {
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  return store;
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final f = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> _pickMode(WidgetTester tester, String label) async {
  await tester.tap(find.text('Namlu çıkış hızı').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Sürüklenme eğrisi → 500/700/900 m → Hesapla → Mühimmata kaydet → Kaydet.
Future<void> _trueDragAndSave(WidgetTester tester) async {
  await _pickMode(tester, 'Sürüklenme eğrisi');
  const ranges = [500.0, 700.0, 900.0];
  final p = _predicted(ranges);
  final observed = [p[0] + 0.02, p[1] + 0.06, p[2] + 0.16];
  for (var i = 0; i < 3; i++) {
    await _enter(tester, 'truing-drag-range-$i', ranges[i].toStringAsFixed(0));
    await _enter(
      tester,
      'truing-drag-observed-$i',
      observed[i].toStringAsFixed(2),
    );
  }
  await _tap(tester, 'truing-compute');
  expect(find.byKey(const Key('truing-error')), findsNothing);
  await _tap(tester, 'truing-drag-apply');
  await _tap(tester, 'truing-drag-confirm');
}

/// Balistik katsayı (BC) → 800 m, a little more drop → Hesapla →
/// Mühimmata uygula → Uygula.
Future<void> _trueBcAndApply(WidgetTester tester) async {
  await _pickMode(tester, 'Balistik katsayı (BC)');
  final observed = _predicted(const [800])[0] + 0.15;
  await _enter(tester, 'truing-range', '800');
  await _enter(tester, 'truing-observed', observed.toStringAsFixed(2));
  await _tap(tester, 'truing-compute');
  expect(find.byKey(const Key('truing-error')), findsNothing);
  await _tap(tester, 'truing-bc-apply');
  await _tap(tester, 'truing-bc-confirm');
}

Future<RifleProfile> _stored(ProfileStore store, String id) async =>
    (await store.all()).firstWhere((p) => p.id == id);

Future<Map<String, dynamic>?> _record(String id) async =>
    (await ManualCatalogStore().all()).where((e) => e['id'] == id).firstOrNull;

Ammunition _ammoOf(RifleProfile p) =>
    const ProfileCatalogIntegrity().resolve(p)!.ammunition;

String _profileBytes(RifleProfile p) =>
    jsonEncode(const ProfileCodec().encode(p));

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  test('sharedRecordIdsOf lists the records of every other profile', () {
    final c = RifleProfile(
      id: 'c',
      name: 'C',
      rifleId: 'r-c',
      ammunitionId: 'a-c',
      scopeId: 's-c',
      muzzleVelocityMps: 790,
      zeroRangeM: 100,
      sightHeightMm: 45,
    );
    expect(sharedRecordIdsOf([_a, c], exceptProfileId: 'a'), {
      'r-c',
      'a-c',
      's-c',
    });
    expect(sharedRecordIdsOf([_a, c], exceptProfileId: 'c'), {
      'manual_rifle_p6',
      _ammoId,
      'gazi-6-36',
    });
    expect(sharedRecordIdsOf([_a], exceptProfileId: 'a'), isEmpty);
  });

  for (final path in ['drag', 'bc']) {
    final apply = path == 'drag' ? _trueDragAndSave : _trueBcAndApply;

    testWidgets('$path: shared record → new record, only the active profile '
        're-pointed, the other profile and old record unchanged', (
      tester,
    ) async {
      await _seed();
      final store = await _storeWith([_a, _b]);
      final bBefore = _profileBytes(await _stored(store, 'b'));
      final oldBefore = jsonEncode(await _record(_ammoId));
      await _pump(tester, store, 'a');
      await apply(tester);

      // Active profile: new id, every other value kept.
      final aNow = await _stored(store, 'a');
      expect(aNow.ammunitionId, isNot(_ammoId));
      expect(aNow.ammunitionId, startsWith('manual_ammo_'));
      expect(
        _profileBytes(aNow),
        _profileBytes(_a).replaceFirst(_ammoId, aNow.ammunitionId),
      );
      final trued = _ammoOf(aNow);
      expect(trued.userEntered, isTrue);
      if (path == 'drag') {
        expect(trued.dragCurve, isNotNull);
      } else {
        expect(trued.dragCurve, isNull);
        expect(trued.ballisticModel, BallisticModel.g7);
        expect(trued.ballisticCoefficient, isNot(closeTo(0.243, 1e-9)));
      }

      // Other profile and the old record: byte-identical.
      expect(_profileBytes(await _stored(store, 'b')), bBefore);
      expect(jsonEncode(await _record(_ammoId)), oldBefore);
      final other = _ammoOf(await _stored(store, 'b'));
      expect(other.dragCurve, isNull);
      expect(other.ballisticModel, BallisticModel.g7);
      expect(other.ballisticCoefficient, closeTo(0.243, 1e-9));
      // Nothing deleted: rifle, old ammo and the new ammo are all there.
      expect((await ManualCatalogStore().all()).length, 3);
    });

    testWidgets('$path: unshared record is updated in place (same id)', (
      tester,
    ) async {
      await _seed();
      final store = await _storeWith([_a]);
      await _pump(tester, store, 'a');
      await apply(tester);

      final aNow = await _stored(store, 'a');
      expect(aNow.ammunitionId, _ammoId);
      expect(_profileBytes(aNow), _profileBytes(_a));
      expect((await ManualCatalogStore().all()).length, 2);
      final rec = (await _record(_ammoId))!;
      if (path == 'drag') {
        expect(rec['dragCurve'], isNotNull);
      } else {
        expect(rec['bc'], isNot(closeTo(0.243, 1e-9)));
      }
    });

    testWidgets('$path: save → reopen loads the active profile with the '
        'trued values', (tester) async {
      await _seed();
      final store = await _storeWith([_a, _b]);
      await _pump(tester, store, 'a');
      await apply(tester);
      final aNow = await _stored(store, 'a');
      final trued = _ammoOf(aNow);

      // Reopen: the user catalog is rebuilt from the saved records, as at
      // app start, and the page loads the active profile again.
      CatalogRepository.installUserCatalog(UserCatalog.empty);
      await _installFromStore();
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, store, 'a');

      final reopened = _ammoOf(await _stored(store, 'a'));
      expect(reopened.id, aNow.ammunitionId);
      expect(reopened.ballisticCoefficient, trued.ballisticCoefficient);
      expect(reopened.ballisticModel, trued.ballisticModel);
      expect(reopened.dragCurve != null, trued.dragCurve != null);
      final other = _ammoOf(await _stored(store, 'b'));
      expect(other.id, _ammoId);
      expect(other.dragCurve, isNull);
      expect(other.ballisticCoefficient, closeTo(0.243, 1e-9));
      // The page shows the active profile's (trued) ammunition.
      expect(find.byKey(const Key('truing-no-profile')), findsNothing);
    });
  }

  testWidgets('catalog ammunition is never written', (tester) async {
    await _seed();
    final catalogAmmo = CatalogRepository.allAmmunition.firstWhere(
      (x) =>
          !x.userEntered &&
          x.platform == WeaponPlatform.firearm &&
          (x.caliberMm - 7.62).abs() < 0.05 &&
          x.ballisticCoefficient != null &&
          x.ballisticModel != null,
    );
    final p = RifleProfile(
      id: 'k',
      name: 'Katalog',
      rifleId: 'manual_rifle_p6',
      ammunitionId: catalogAmmo.id,
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 790,
      zeroRangeM: 100,
      sightHeightMm: 45,
    );
    final store = await _storeWith([p, _profile('k2', 'K2')]);
    final before = jsonEncode(await ManualCatalogStore().all());
    await _pump(tester, store, 'k');
    await _pickMode(tester, 'Balistik katsayı (BC)');
    await _enter(tester, 'truing-range', '800');
    await _enter(tester, 'truing-observed', '12');
    await _tap(tester, 'truing-compute');
    if (find.byKey(const Key('truing-bc-apply')).evaluate().isNotEmpty) {
      await _tap(tester, 'truing-bc-apply');
    }
    expect(find.byKey(const Key('truing-bc-confirm')), findsNothing);
    expect(jsonEncode(await ManualCatalogStore().all()), before);
    expect(_profileBytes(await _stored(store, 'k')), _profileBytes(p));
  });
}
