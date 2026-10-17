// DEN17B-1 (audit 2026-10-17b): on the typed scope path, Üst kule klik
// sayısı is counted in the Klik değeri; when the user changes Klik değeri
// (another value, "Seçiniz", or emptied by a Dürbün birimi change) the
// count is cleared and asked again (owner, 2026-10-17 11:14 Istanbul:
// "o zaman önce düzelt"). Programmatic fills keep it: opening a saved
// profile, a catalog model, the same click picked again.
//
// Turret travel = clicks × click (profile_editor.dart _travelMrad);
// 1 MOA = π/10.8 mrad (angle definition). No other ballistic app.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

Future<void> _pump(
  WidgetTester tester,
  ProfileStore store, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ProfilesScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
}

Future<MemoryProfileStore> _openNew(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await _pump(tester, store, scale: scale);
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
  return store;
}

Finder _k(String key) => find.byKey(Key(key));

String _missingText(WidgetTester tester) {
  final f = _k('profile-missing');
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data!;
}

String _travelText(WidgetTester tester) => tester
    .widget<TextField>(
      find.descendant(
        of: _k('scope-travel-elevation'),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Future<bool> _canPress(WidgetTester tester, String label) async {
  final button = find.widgetWithText(MenzilPrimaryButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  return tester.widget<MenzilPrimaryButton>(button).onPressed != null;
}

Future<void> _press(WidgetTester tester, String label) async {
  expect(await _canPress(tester, label), isTrue, reason: _missingText(tester));
  await tester.tap(find.widgetWithText(MenzilPrimaryButton, label));
  await tester.pumpAndSettle();
}

Future<void> _openEdit(WidgetTester tester, String name) async {
  final row = find.text(name).first;
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsOneWidget);
}

/// A complete typed profile on the form (not saved).
Future<void> _fillTyped(
  WidgetTester tester, {
  String model = 'Z5',
  String unit = 'MRAD',
  String click = '0,1 MRAD',
  String travel = '200',
}) async {
  await fillScopeForm(tester, model: model, unit: unit, click: click);
  await chooseInSelect(tester, 'scope-reticle', 'Duplex');
  await enterRifleField(tester, 'scope-travel-elevation', travel);
  await fillRifleForm(tester);
  await fillAmmoForm(tester);
  await fillShotValues(tester);
}

ScopeOptic _scopeOf(RifleProfile p) =>
    CatalogRepository.allScopes.singleWhere((o) => o.id == p.scopeId);

/// Every saved scope value but the record id.
List<Object?> _scopeValues(ScopeOptic s) => [
  s.brand,
  s.model,
  s.objectiveDiameterMm,
  s.clickValue,
  s.clickUnit,
  s.minMagnification,
  s.maxMagnification,
  s.firstFocalPlane,
  s.reticle,
  s.tubeDiameterMm,
  s.windageRangeMrad,
  s.zeroStop,
  s.userEntered,
];

/// Every saved profile value but the record ids (a kept profile id is
/// checked by `store.all()` staying a single record).
Map<String, dynamic> _profileValues(RifleProfile p) =>
    const ProfileCodec().encode(p)
      ..remove('id')
      ..remove('scopeId')
      ..remove('rifleId')
      ..remove('ammunitionId');

void _expectSame(RifleProfile a, RifleProfile b) {
  expect(_profileValues(b), equals(_profileValues(a)));
  final sa = _scopeOf(a), sb = _scopeOf(b);
  expect(_scopeValues(sb), equals(_scopeValues(sa)));
  if (sa.elevationRangeMrad == null) {
    expect(sb.elevationRangeMrad, isNull);
  } else {
    expect(sb.elevationRangeMrad, closeTo(sa.elevationRangeMrad!, 1e-9));
  }
}

const _mradPerMoa = math.pi / 10.8;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('(a) typed: 200 clicks at 0,1 MRAD, click → 0,05 MRAD empties '
      'the count; 400 then saves 20 mrad', (tester) async {
    final store = await _openNew(tester);
    await _fillTyped(tester);
    expect(_travelText(tester), '200');
    await chooseInSelect(tester, 'scope-click', '0,05 MRAD');
    expect(selectedValue<double>(tester, 'scope-click'), 0.05);
    expect(_travelText(tester), '');
    // The stale 200 (= 10 mrad at 0,05) can no longer be saved. The box
    // itself stays optional as before (empty = travel unknown).
    await enterRifleField(tester, 'scope-travel-elevation', '400');
    await _press(tester, 'Kaydet');
    final scope = _scopeOf((await store.all()).single);
    expect(scope.clickValue, 0.05);
    expect(scope.clickUnit, AngularUnit.mrad);
    // 400 × 0,05 mrad = 20 mrad.
    expect(scope.elevationRangeMrad, closeTo(20, 1e-9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('(a) typed: no new count entered → nothing stale is saved', (
    tester,
  ) async {
    final store = await _openNew(tester);
    await _fillTyped(tester);
    await chooseInSelect(tester, 'scope-click', '0,05 MRAD');
    expect(_travelText(tester), '');
    await _press(tester, 'Kaydet');
    // Before the fix: 200 × 0,05 = 10 mrad was saved here.
    expect(_scopeOf((await store.all()).single).elevationRangeMrad, isNull);
  });

  testWidgets('the same click picked again keeps the count', (tester) async {
    await _openNew(tester);
    await _fillTyped(tester);
    await chooseInSelect(tester, 'scope-click', '0,1 MRAD');
    expect(_travelText(tester), '200');
  });

  testWidgets('(b) Klik değeri → "Seçiniz" clears the count; saving is '
      'blocked', (tester) async {
    await _openNew(tester);
    await _fillTyped(tester);
    expect(await _canPress(tester, 'Kaydet'), isTrue);
    await chooseInSelect(tester, 'scope-click', 'Seçiniz');
    expect(selectedValue<double>(tester, 'scope-click'), isNull);
    expect(_travelText(tester), '');
    expect(_missingText(tester), contains('Klik değeri'));
    expect(await _canPress(tester, 'Kaydet'), isFalse);
  });

  testWidgets('(c) Dürbün birimi MRAD → MOA empties Klik değeri and clears '
      'the count; 1/4 MOA + 400 saves 100 MOA', (tester) async {
    final store = await _openNew(tester);
    await _fillTyped(tester);
    await chooseInSelect(tester, 'scope-unit', 'MOA');
    expect(selectedValue<double>(tester, 'scope-click'), isNull);
    expect(_travelText(tester), '');
    expect(await _canPress(tester, 'Kaydet'), isFalse);
    await chooseInSelect(tester, 'scope-click', '1/4 MOA');
    expect(_travelText(tester), '');
    await enterRifleField(tester, 'scope-travel-elevation', '400');
    await _press(tester, 'Kaydet');
    final scope = _scopeOf((await store.all()).single);
    expect(scope.clickValue, 0.25);
    expect(scope.clickUnit, AngularUnit.moa);
    // 400 × 1/4 MOA = 100 MOA = 29.0888 mrad.
    expect(scope.elevationRangeMrad, closeTo(100 * _mradPerMoa, 1e-9));
  });

  testWidgets('(c) Dürbün birimi → "Seçiniz" clears the count too', (
    tester,
  ) async {
    await _openNew(tester);
    await _fillTyped(tester);
    await chooseInSelect(tester, 'scope-unit', 'Seçiniz');
    expect(selectedValue<double>(tester, 'scope-click'), isNull);
    expect(_travelText(tester), '');
    expect(await _canPress(tester, 'Kaydet'), isFalse);
  });

  group('(d) old saved profiles open and update unchanged', () {
    testWidgets('typed with Dürbün modeli (1/8 MOA, 400 clicks, 25 MOA)', (
      tester,
    ) async {
      final store = await _openNew(tester);
      await _fillTyped(tester, unit: 'MOA', click: '1/8 MOA', travel: '400');
      await chooseInSelect(tester, 'scope-mount', '25 MOA · +200 klik');
      await _press(tester, 'Kaydet');
      final first = (await store.all()).single;
      expect(
        _scopeOf(first).elevationRangeMrad,
        closeTo(50 * _mradPerMoa, 1e-9),
      );

      await _pump(tester, store);
      await _openEdit(tester, first.name);
      expect(_k('scope-brand'), findsOneWidget, reason: 'typed entry');
      expect(selectedValue<AngularUnit>(tester, 'scope-unit'), AngularUnit.moa);
      expect(selectedValue<double>(tester, 'scope-click'), 0.125);
      expect(_travelText(tester), '400');
      expect(selectedValue<double>(tester, 'scope-mount'), 25);
      // The same click picked again on the opened profile keeps the count.
      await chooseInSelect(tester, 'scope-click', '1/8 MOA');
      expect(_travelText(tester), '400');
      // Opening saves nothing.
      _expectSame(first, (await store.all()).single);
      await _press(tester, 'Güncelle');
      _expectSame(first, (await store.all()).single);
      expect(tester.takeException(), isNull);
    });

    testWidgets('typed without Dürbün modeli (saved before #367)', (
      tester,
    ) async {
      final store = await _openNew(tester);
      await _fillTyped(tester);
      await _press(tester, 'Kaydet');
      final first = (await store.all()).single;
      final user = CatalogRepository.userCatalog;
      final s = user.scopes.singleWhere((o) => o.id == first.scopeId);
      CatalogRepository.installUserCatalog(
        UserCatalog(
          rifles: user.rifles,
          ammunition: user.ammunition,
          scopes: [
            for (final o in user.scopes)
              if (o.id != s.id) o,
            ScopeOptic(
              id: s.id,
              brand: s.brand,
              model: '6-24x56 FFP',
              objectiveDiameterMm: s.objectiveDiameterMm,
              clickValue: s.clickValue,
              clickUnit: s.clickUnit,
              minMagnification: s.minMagnification,
              maxMagnification: s.maxMagnification,
              firstFocalPlane: s.firstFocalPlane,
              reticle: s.reticle,
              elevationRangeMrad: s.elevationRangeMrad,
              userEntered: true,
            ),
          ],
        ),
      );
      await _pump(tester, store);
      await _openEdit(tester, first.name);
      expect(selectedValue<double>(tester, 'scope-click'), 0.1);
      expect(_travelText(tester), '200');
      _expectSame(first, (await store.all()).single);
      await _press(tester, 'Güncelle');
      final again = (await store.all()).single;
      _expectSame(first, again);
      expect(_scopeOf(again).model, '6-24x56 FFP');
      expect(_scopeOf(again).elevationRangeMrad, closeTo(20, 1e-9));
    });

    testWidgets('old typed click no longer in the list: opening changes '
        'nothing saved', (tester) async {
      final store = await _openNew(tester);
      await _fillTyped(tester);
      await _press(tester, 'Kaydet');
      final first = (await store.all()).single;
      final user = CatalogRepository.userCatalog;
      final s = user.scopes.singleWhere((o) => o.id == first.scopeId);
      final old = ScopeOptic(
        id: s.id,
        brand: s.brand,
        model: s.model,
        objectiveDiameterMm: s.objectiveDiameterMm,
        clickValue: 0.2,
        clickUnit: s.clickUnit,
        minMagnification: s.minMagnification,
        maxMagnification: s.maxMagnification,
        firstFocalPlane: s.firstFocalPlane,
        reticle: s.reticle,
        elevationRangeMrad: s.elevationRangeMrad,
        userEntered: true,
      );
      CatalogRepository.installUserCatalog(
        UserCatalog(
          rifles: user.rifles,
          ammunition: user.ammunition,
          scopes: [
            for (final o in user.scopes)
              if (o.id != s.id) o,
            old,
          ],
        ),
      );
      await _pump(tester, store);
      await _openEdit(tester, first.name);
      // Owner, 2026-10-16 22:24: such a value opens on "Seçiniz" and its
      // count is asked again; the saved record is not touched.
      expect(selectedValue<double>(tester, 'scope-click'), isNull);
      expect(_travelText(tester), '');
      expect(await _canPress(tester, 'Güncelle'), isFalse);
      final still = (await store.all()).single;
      expect(_profileValues(still), equals(_profileValues(first)));
      expect(still.scopeId, first.scopeId);
      final stored = _scopeOf(still);
      expect(stored.clickValue, 0.2);
      expect(stored.elevationRangeMrad, closeTo(20, 1e-9));
    });

    testWidgets('(e) catalog-matched: the model brings click and count; '
        'reopen and Güncelle keep them', (tester) async {
      final store = await _openNew(tester);
      await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
      await chooseInSelect(
        tester,
        'scope-filter-unit-Element Optics-null',
        'MOA',
      );
      await chooseInSelect(
        tester,
        'scope-filter-ffp-Element Optics-null',
        'FFP',
      );
      await chooseInSelect(
        tester,
        'scope-model-select',
        'Titan 3-18x50 FFP MOA',
      );
      // Manufacturer record: 43.63 mrad, 1/4 MOA clicks →
      // 43.63 / (π/10.8) / 0.25 = 599.98 → 600.
      expect(_travelText(tester), '600');
      await chooseInSelect(tester, 'scope-reticle', 'APR-2D MOA');
      await chooseInSelect(tester, 'scope-mount', 'Normal (0 MOA)');
      expect(_travelText(tester), '600');
      await fillRifleForm(tester);
      await fillAmmoForm(tester);
      await fillShotValues(tester);
      await _press(tester, 'Kaydet');
      final first = (await store.all()).single;
      final scope = _scopeOf(first);
      expect(scope.clickValue, 0.25);
      expect(scope.clickUnit, AngularUnit.moa);
      expect(scope.elevationRangeMrad, closeTo(600 * 0.25 * _mradPerMoa, 1e-2));

      await _pump(tester, store);
      await _openEdit(tester, first.name);
      expect(_travelText(tester), '600');
      _expectSame(first, (await store.all()).single);
      await _press(tester, 'Güncelle');
      _expectSame(first, (await store.all()).single);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('(f) a profile whose click went 0,1 → 0,05 → 0,1 with 200 '
      'entered again saves exactly what a direct entry saves; Hedef click '
      'numbers from it are the hand values', (tester) async {
    final direct = await _openNew(tester);
    await _fillTyped(tester);
    await _press(tester, 'Kaydet');
    final a = (await direct.all()).single;

    // A fresh screen with its own store.
    await tester.pumpWidget(const SizedBox());
    final edited = await _openNew(tester);
    await _fillTyped(tester);
    await chooseInSelect(tester, 'scope-click', '0,05 MRAD');
    await chooseInSelect(tester, 'scope-click', '0,1 MRAD');
    expect(_travelText(tester), '');
    await enterRifleField(tester, 'scope-travel-elevation', '200');
    await _press(tester, 'Kaydet');
    final b = (await edited.all()).single;

    _expectSame(a, b);
    final s = _scopeOf(b);
    expect(s.elevationRangeMrad, closeTo(20, 1e-9));
    // Solver/Hedef inputs are the saved click and unit (unchanged code):
    // 3,27 mrad / 0,1 = 32,7 → 33 clicks; 45 MOA mount on 0,1 MRAD → 130.
    expect(ScopeDialMath.clicksFor(3.27, s.clickValue), 33);
    expect(ScopeDialMath.mountCantClicks(45, s.clickValue, s.clickUnit), 130);
    expect(
      ScopeDialMath.convert(
            s.elevationRangeMrad!,
            AngularUnit.mrad,
            s.clickUnit,
          ) /
          s.clickValue,
      closeTo(200, 1e-9),
    );
  });

  testWidgets('320 pt, text scale 1.3: the click change and the empty count '
      'fit without overflow', (tester) async {
    await _openNew(tester, width: 320, scale: 1.3);
    await _fillTyped(tester);
    await chooseInSelect(tester, 'scope-click', '0,05 MRAD');
    expect(_travelText(tester), '');
    await chooseInSelect(tester, 'scope-click', 'Seçiniz');
    await tester.ensureVisible(_k('scope-travel-elevation'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
