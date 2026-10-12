// Ö6 on Hız Doğrulama: "Sürüklenme eğrisi" mode — at least 3 ranges, the
// Mach-band fit and the confirmed save into the personal ammunition record.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/drag_curve.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/tools/truing_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_dt',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_dt',
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
const _profile = RifleProfile(
  id: 'p-dt',
  name: 'DT',
  rifleId: 'manual_rifle_dt',
  ammunitionId: 'manual_ammo_dt',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 790,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

/// What the page predicts with its default air (15 °C, 1013,25 hPa, %50).
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

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_profile);
  final active = MemoryActiveProfileStore()..value = _profile.id;
  await tester.pumpWidget(
    host(TruingScreen(profileStore: store, activeProfileStore: active)),
  );
  await tester.pumpAndSettle();
}

Future<void> _chooseDragMode(WidgetTester tester) async {
  await tester.tap(find.text('Namlu çıkış hızı').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sürüklenme eğrisi').last);
  await tester.pumpAndSettle();
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

Future<void> _fillAndCompute(WidgetTester tester) async {
  const ranges = [500.0, 700.0, 900.0];
  final p = _predicted(ranges);
  // The far hits a little lower than the published BC says.
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
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('mode list offers Sürüklenme eğrisi with 3 range rows', (
    tester,
  ) async {
    await _pump(tester);
    await _chooseDragMode(tester);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(Key('truing-drag-range-$i')), findsOneWidget);
      expect(find.byKey(Key('truing-drag-observed-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('truing-drag-range-3')), findsNothing);
    // The single-range boxes of the other modes are gone.
    expect(find.byKey(const Key('truing-range')), findsNothing);
  });

  testWidgets('Mesafe ekle adds rows up to 6, then disappears', (
    tester,
  ) async {
    await _pump(tester);
    await _chooseDragMode(tester);
    for (var n = 4; n <= 6; n++) {
      await _tap(tester, 'truing-drag-add');
      expect(find.byKey(Key('truing-drag-range-${n - 1}')), findsOneWidget);
    }
    expect(find.byKey(const Key('truing-drag-add')), findsNothing);
  });

  testWidgets('every new box has an ⓘ and no helper text', (tester) async {
    await _pump(tester);
    await _chooseDragMode(tester);
    for (var i = 0; i < 3; i++) {
      for (final key in ['truing-drag-range-$i', 'truing-drag-observed-$i']) {
        final input = tester.widget<MenzilInput>(find.byKey(Key(key)));
        expect(input.info, isNotNull, reason: key);
        expect(input.info, isNotEmpty, reason: key);
        expect(input.helperText, isNull, reason: key);
        expect(input.label.contains('('), isFalse, reason: key);
      }
    }
  });

  testWidgets('fewer than 3 ranges is refused with a message', (tester) async {
    await _pump(tester);
    await _chooseDragMode(tester);
    await _enter(tester, 'truing-drag-range-0', '500');
    await _enter(tester, 'truing-drag-observed-0', '3');
    await _tap(tester, 'truing-compute');
    expect(find.byKey(const Key('truing-error')), findsOneWidget);
    expect(find.textContaining('en az 3'), findsOneWidget);
  });

  testWidgets('computes band scales and before / after residuals', (
    tester,
  ) async {
    await _pump(tester);
    await _chooseDragMode(tester);
    await _fillAndCompute(tester);
    expect(find.byKey(const Key('truing-error')), findsNothing);
    expect(find.byKey(const Key('truing-drag-result')), findsOneWidget);
    expect(find.text('Mach 2 üstü'), findsOneWidget);
    expect(find.text('değişmedi'), findsWidgets);
  });

  testWidgets('saving writes the curve into the personal ammunition record', (
    tester,
  ) async {
    await ManualCatalogStore().upsert(_rifle);
    await ManualCatalogStore().upsert(_ammo);
    await _pump(tester);
    await _chooseDragMode(tester);
    await _fillAndCompute(tester);
    await _tap(tester, 'truing-drag-apply');
    await _tap(tester, 'truing-drag-confirm');
    final entry = (await ManualCatalogStore().all()).singleWhere(
      (e) => e['id'] == 'manual_ammo_dt',
    );
    expect(DragCurve.fromJson(entry['dragCurve']), isNotNull);
    expect(entry['bcModel'], 'g1');
    expect(
      entry['bc'],
      closeTo(DragCurve.sectionalDensity(grain: 175, diameterMm: 7.62), 1e-9),
    );
    expect(entry.containsKey('bcBands'), isFalse);
  });

  testWidgets('a record missing from the personal store is never changed', (tester) async {
    // Same ammunition, but not in the personal store: catalog-like.
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
    await _pump(tester);
    await _chooseDragMode(tester);
    await _fillAndCompute(tester);
    await _tap(tester, 'truing-drag-apply');
    expect(find.byKey(const Key('truing-drag-confirm')), findsNothing);
    expect(await ManualCatalogStore().all(), isEmpty);
  });
}
