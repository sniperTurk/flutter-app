// Kronograf "Ortalamayı profile uygula" behaviour, driven through the real
// screen with an in-memory store that records every write.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/features/tools/chronograph_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';

import 'support/tool_fakes.dart';

class _RecordingStore extends MemoryProfileStore {
  int saves = 0;
  @override
  Future<void> save(RifleProfile profile) async {
    saves++;
    await super.save(profile);
  }
}

const _rifleId = 'hatsan-hercules-635';
const _ammoId = 'gmaz-51';

const _original = RifleProfile(
  id: 'p1',
  name: 'Hercules akşam',
  rifleId: _rifleId,
  ammunitionId: _ammoId,
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 255,
  zeroRangeM: 30,
  sightHeightMm: 55,
  pressureBar: 180,
  angularUnit: AngularUnit.moa,
);

Future<_RecordingStore> _store() async {
  final s = _RecordingStore();
  await s.save(_original);
  s.saves = 0;
  return s;
}

Future<void> _pick(WidgetTester tester, Key selectKey, String text) async {
  final dropdown = find.descendant(
    of: find.byKey(selectKey),
    matching: find.byType(DropdownButtonFormField<String>),
  );
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _openScreen(WidgetTester tester, ProfileStore store) async {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(host(ChronographScreen(profileStore: store)));
  final rifle = CatalogRepository.rifles.firstWhere((r) => r.id == _rifleId);
  final ammo = CatalogRepository.ammunition.firstWhere((a) => a.id == _ammoId);
  await _pick(tester, const ValueKey('chrono-rifle-pcp'), rifle.displayName);
  await _pick(tester, ValueKey('chrono-ammo-$_rifleId'), ammo.displayName);
}

Future<void> _addShots(WidgetTester tester, List<String> speeds) async {
  for (final v in speeds) {
    await tester.enterText(find.byKey(const Key('chrono-velocity')), v);
    await tester.ensureVisible(find.text('Atış ekle'));
    await tester.tap(find.text('Atış ekle'));
    await tester.pump();
  }
}

Future<void> _tapApply(WidgetTester tester) async {
  final button = find.text('Ortalamayı profile uygula');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Vazgeç writes nothing', (tester) async {
    final store = await _store();
    await _openScreen(tester, store);
    await _addShots(tester, ['270', '272', '268']);
    await _tapApply(tester);
    expect(find.text('Profile uygula'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(store.saves, 0);
    expect((await store.all()).single.muzzleVelocityMps, 255);
  });

  testWidgets('Uygula changes only the velocity; all other fields are kept', (
    tester,
  ) async {
    final store = await _store();
    await _openScreen(tester, store);
    await _addShots(tester, ['270', '272', '268']);
    await _tapApply(tester);
    // Uygula stays disabled until a profile is explicitly chosen.
    final apply = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Uygula'),
    );
    expect(apply.onPressed, isNull);
    await tester.tap(find.text('Hercules akşam'));
    await tester.pump();
    await tester.tap(find.text('Uygula'));
    await tester.pumpAndSettle();

    expect(store.saves, 1);
    final p = (await store.all()).single;
    expect(p.muzzleVelocityMps, 270.0);
    expect(p.id, _original.id);
    expect(p.name, _original.name);
    expect(p.rifleId, _original.rifleId);
    expect(p.ammunitionId, _original.ammunitionId);
    expect(p.scopeId, _original.scopeId);
    expect(p.zeroRangeM, _original.zeroRangeM);
    expect(p.sightHeightMm, _original.sightHeightMm);
    expect(p.pressureBar, 180, reason: 'pressure untouched without checkbox');
    expect(p.angularUnit, AngularUnit.moa);
  });

  testWidgets('pressure checkbox updates velocity AND pressure, nothing else', (
    tester,
  ) async {
    final store = await _store();
    await _openScreen(tester, store);
    await tester.enterText(find.byKey(const Key('chrono-start-bar')), '200');
    await tester.enterText(find.byKey(const Key('chrono-end-bar')), '180');
    await _addShots(tester, ['270', '272', '268']);
    await _tapApply(tester);
    await tester.tap(find.text('Hercules akşam'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('chrono-write-pressure')));
    await tester.pump();
    await tester.tap(find.text('Uygula'));
    await tester.pumpAndSettle();

    final p = (await store.all()).single;
    expect(p.muzzleVelocityMps, 270.0);
    expect(p.pressureBar, 200);
    expect(p.zeroRangeM, _original.zeroRangeM);
    expect(p.sightHeightMm, _original.sightHeightMm);
    expect(p.angularUnit, AngularUnit.moa);
    expect(p.name, _original.name);
  });

  testWidgets('apply stays disabled below three shots', (tester) async {
    final store = await _store();
    await _openScreen(tester, store);
    await _addShots(tester, ['270', '272']);
    expect(find.textContaining('en az 3 atış'), findsOneWidget);
    expect(store.saves, 0);
  });

  testWidgets('manual ammunition cannot be transferred to a profile', (
    tester,
  ) async {
    final store = await _store();
    await _openScreen(tester, store);
    await tester.ensureVisible(find.byKey(const Key('chrono-manual-switch')));
    await tester.tap(find.byKey(const Key('chrono-manual-switch')));
    await tester.pumpAndSettle();
    await _addShots(tester, ['270', '272', '268']);
    expect(find.text('Manuel mühimmat profile aktarılamaz.'), findsOneWidget);
    expect(store.saves, 0);
  });
}
