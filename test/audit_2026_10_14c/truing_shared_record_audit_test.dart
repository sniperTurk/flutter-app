// Pre-TestFlight audit 2026-10-14c — PRF-6 (new finding, high).
//
// PRF-2 (#313) stops Kopyala from sharing personal records and makes the
// profile editor split a shared record on its first Güncelle. Copies made
// BEFORE #313 still point at the same personal ammunition record until one
// of them is edited. Araçlar → Hız Doğrulama → "Mühimmata kaydet" (drag
// curve) and "Mühimmata uygula" (BC) write that record in place, so the
// other profile silently gets the trued drag too.
//
// PRF-6 is fixed (fix/prf6-hiz-dogrulama): the truing save writes a shared
// record under a new id and re-points only the active profile, so the PRF-6
// test is un-skipped and must pass (CLAUDE.md). The guard test (records not
// shared, as every copy made after #313) keeps passing.
//
// Record and helper shapes follow test/truing_drag_band_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/tools/truing_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

import '../support/tool_fakes.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_sh',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};

const _ammo = <String, dynamic>{
  'id': 'manual_ammo_sh',
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

/// The same round under its own id: what Kopyala writes since #313.
final _ammoOwnCopy = <String, dynamic>{..._ammo, 'id': 'manual_ammo_sh_b'};

RifleProfile _profile(String id, String name, String ammoId) => RifleProfile(
  id: id,
  name: name,
  rifleId: 'manual_rifle_sh',
  ammunitionId: ammoId,
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 790,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

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

Future<void> _seed(List<Map<String, dynamic>> entries) async {
  SharedPreferences.setMockInitialValues({});
  for (final e in entries) {
    await ManualCatalogStore().upsert(e);
  }
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries(await ManualCatalogStore().all()),
  );
}

Future<MemoryProfileStore> _pump(
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

/// Sürüklenme eğrisi mode, 3 ranges a little lower far out, then
/// Mühimmata kaydet → Kaydet.
Future<void> _trueDragAndSave(WidgetTester tester) async {
  await tester.tap(find.text('Namlu çıkış hızı').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sürüklenme eğrisi').last);
  await tester.pumpAndSettle();
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

/// What Hedef reads for [p]'s ammunition after the save.
({double? bc, BallisticModel? model, bool curve}) _ammoOf(RifleProfile p) {
  final a = const ProfileCatalogIntegrity().resolve(p)!.ammunition;
  return (
    bc: a.ballisticCoefficient,
    model: a.ballisticModel,
    curve: a.dragCurve != null,
  );
}

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  final a = _profile('a', 'Profil A', 'manual_ammo_sh');

  testWidgets(
    'PRF-6: truing on a copy made before #313 leaves the other profile alone',
    (tester) async {
      // Two profiles that still share one personal round (a Kopyala made
      // before #313, never edited since).
      await _seed([_rifle, _ammo]);
      final b = _profile('b', 'Profil B', 'manual_ammo_sh');
      final store = await _pump(tester, [a, b], 'a');
      await _trueDragAndSave(tester);
      // The active profile got the trued curve (under its own new record) …
      final aNow = (await store.all()).firstWhere((p) => p.id == 'a');
      expect(_ammoOf(aNow).curve, isTrue);
      // … the other profile must still fly with its own G7 0,243.
      final other = _ammoOf(b);
      expect(other.curve, isFalse, reason: 'B got A\'s trued drag curve');
      expect(other.model, BallisticModel.g7);
      expect(other.bc, closeTo(0.243, 1e-9));
    },
  );

  testWidgets('guard: a copy with its own record (Kopyala since #313) keeps '
      'its drag when the original is trued', (tester) async {
    await _seed([_rifle, _ammo, _ammoOwnCopy]);
    final b = _profile('b', 'Profil B', 'manual_ammo_sh_b');
    await _pump(tester, [a, b], 'a');
    await _trueDragAndSave(tester);
    expect(_ammoOf(a).curve, isTrue);
    final other = _ammoOf(b);
    expect(other.curve, isFalse);
    expect(other.model, BallisticModel.g7);
    expect(other.bc, closeTo(0.243, 1e-9));
  });
}
