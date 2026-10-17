// Pre-TestFlight audit 2026-10-17b — Dürbün girişi (#367) on the real
// Profil screen (main 8cc3aab against TestFlight 112, 9db11e3).
//
// DEN17B-1 (ORTA, open): clearing Klik değeri by hand ("Seçiniz" in the
//   Klik değeri list, or a Dürbün birimi change that empties it) leaves
//   Üst kule klik sayısı filled. The count was made with the old click;
//   the next click picked turns it into another turret travel, which is
//   saved (profile_editor_scope.dart _clickSelect onChanged and
//   _scopeUnitSelect onChanged; only the opening path in
//   profile_editor.dart clears it). Tests below are skipped until fixed.
//
// Guards (no finding):
// - a typed scope saves exactly the picked click, unit, travel and mount
//   (1/8 MOA, 400 clicks, 25 MOA → 0.125 MOA, 14.544 mrad, 25);
// - "Seçiniz" in Dürbün ayağı / Dürbün birimi blocks saving (no silent 0
//   or MRAD);
// - an old typed scope saved without Dürbün modeli, values in the lists,
//   old mount 45 MOA: opens with nothing missing and Güncelle keeps every
//   number.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/rifle_form.dart';

Future<void> _pump(WidgetTester tester, ProfileStore store) async {
  final app = MaterialApp(
    theme: MenzilTheme.light(),
    home: ProfilesScreen(store: store),
  );
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Future<MemoryProfileStore> _openNew(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await _pump(tester, store);
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

String _travelText(WidgetTester tester) {
  final field = find.descendant(
    of: _k('scope-travel-elevation'),
    matching: find.byType(TextField),
  );
  return tester.widget<TextField>(field).controller!.text;
}

Finder get _saveButton => find.widgetWithText(MenzilPrimaryButton, 'Kaydet');

Future<bool> _canPress(WidgetTester tester, Finder button) async {
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  return tester.widget<MenzilPrimaryButton>(button).onPressed != null;
}

/// A complete typed profile on the form (not saved).
Future<void> _fillTyped(
  WidgetTester tester, {
  String unit = 'MRAD',
  String click = '0,1 MRAD',
  String travel = '200',
}) async {
  await fillScopeForm(tester, model: 'Z5', unit: unit, click: click);
  await chooseInSelect(tester, 'scope-reticle', 'Duplex');
  await enterRifleField(tester, 'scope-travel-elevation', travel);
  await fillRifleForm(tester);
  await fillAmmoForm(tester);
  await fillShotValues(tester);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('DEN17B-1: a cleared Klik değeri clears Üst kule klik sayısı', () {
    testWidgets('Klik değeri back on "Seçiniz"', (tester) async {
      await _openNew(tester);
      await _fillTyped(tester);
      expect(_travelText(tester), '200');
      await chooseInSelect(tester, 'scope-click', 'Seçiniz');
      expect(selectedValue<double>(tester, 'scope-click'), isNull);
      // Expected (owner rule, #367): the count made with 0,1 MRAD is asked
      // again. Today: "200" stays and 0,05 MRAD then saves 10 mrad.
      expect(_travelText(tester), '');
    }); // DEN17B-1 TEMP-UNSKIPPED

    testWidgets('Dürbün birimi MRAD → MOA empties Klik değeri and '
        'clears the count', (tester) async {
      await _openNew(tester);
      await _fillTyped(tester);
      await chooseInSelect(tester, 'scope-unit', 'MOA');
      expect(selectedValue<double>(tester, 'scope-click'), isNull);
      // Today: "200" stays; 1/4 MOA then saves 50 MOA = 14.54 mrad.
      expect(_travelText(tester), '');
    }); // DEN17B-1 TEMP-UNSKIPPED

    testWidgets('today: the stale count is saved with the new click '
        '(documents DEN17B-1; delete when fixed)', (tester) async {
      final store = await _openNew(tester);
      await _fillTyped(tester);
      await chooseInSelect(tester, 'scope-click', 'Seçiniz');
      await chooseInSelect(tester, 'scope-click', '0,05 MRAD');
      expect(
        await _canPress(tester, _saveButton),
        isTrue,
        reason: _missingText(tester),
      );
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      final scope = CatalogRepository.allScopes.singleWhere(
        (o) => o.id == saved.scopeId,
      );
      expect(scope.clickValue, 0.05);
      // 200 clicks counted on a 0,1 MRAD turret (20 mrad) saved as 10 mrad.
      expect(scope.elevationRangeMrad, closeTo(10, 1e-9));
    }); // DEN17B-1 TEMP-UNSKIPPED
  });

  testWidgets('typed scope: click, unit, travel and new mount value reach '
      'the saved records exactly', (tester) async {
    final store = await _openNew(tester);
    await _fillTyped(tester, unit: 'MOA', click: '1/8 MOA', travel: '400');
    // 25 MOA (new since #367) on a 1/8 MOA turret: 25 × 8 = 200 clicks.
    await chooseInSelect(tester, 'scope-mount', '25 MOA · +200 klik');
    expect(selectedValue<double>(tester, 'scope-mount'), 25);
    expect(
      await _canPress(tester, _saveButton),
      isTrue,
      reason: _missingText(tester),
    );
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    final saved = (await store.all()).single;
    expect(saved.mountCantMoa, 25);
    expect(saved.angularUnit, AngularUnit.moa);
    final scope = CatalogRepository.allScopes.singleWhere(
      (o) => o.id == saved.scopeId,
    );
    expect(scope.clickValue, 0.125);
    expect(scope.clickUnit, AngularUnit.moa);
    expect(scope.firstFocalPlane, isTrue);
    expect(scope.minMagnification, 6);
    expect(scope.maxMagnification, 24);
    // 400 × 1/8 MOA = 50 MOA = 50 × π/10.8 mrad = 14.5444 mrad.
    expect(
      scope.elevationRangeMrad,
      closeTo(50 * 3.141592653589793 / 10.8, 1e-9),
    );
    expect(scope.model, 'Z5 6-24x56 FFP');
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Seçiniz" in Dürbün ayağı or Dürbün birimi blocks '
      'saving', (tester) async {
    await _openNew(tester);
    await _fillTyped(tester);
    expect(
      await _canPress(tester, _saveButton),
      isTrue,
      reason: _missingText(tester),
    );

    await chooseInSelect(tester, 'scope-mount', 'Seçiniz');
    expect(selectedValue<double>(tester, 'scope-mount'), isNull);
    expect(_missingText(tester), contains('Dürbün ayağı'));
    expect(await _canPress(tester, _saveButton), isFalse);
    await chooseInSelect(tester, 'scope-mount', 'Normal (0 MOA)');
    expect(
      await _canPress(tester, _saveButton),
      isTrue,
      reason: _missingText(tester),
    );

    await chooseInSelect(tester, 'scope-unit', 'Seçiniz');
    expect(selectedValue<AngularUnit>(tester, 'scope-unit'), isNull);
    expect(selectedValue<double>(tester, 'scope-click'), isNull);
    expect(_missingText(tester), contains('Dürbün birimi'));
    expect(_missingText(tester), contains('Klik değeri'));
    expect(await _canPress(tester, _saveButton), isFalse);
  });

  testWidgets('old typed scope without Dürbün modeli, old mount 45 MOA: '
      'Güncelle keeps every number', (tester) async {
    final store = await _openNew(tester);
    await _fillTyped(tester);
    await chooseInSelect(tester, 'scope-mount', '45 MOA · +130 klik');
    expect(
      await _canPress(tester, _saveButton),
      isTrue,
      reason: _missingText(tester),
    );
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    final first = (await store.all()).single;
    expect(first.mountCantMoa, 45);
    // The same record as written before #367: the model is only the
    // designation (no Dürbün modeli).
    final user = CatalogRepository.userCatalog;
    final s = user.scopes.singleWhere((o) => o.id == first.scopeId);
    final legacy = ScopeOptic(
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
    );
    final others = user.scopes.where((o) => o.id != s.id).toList();
    CatalogRepository.installUserCatalog(
      UserCatalog(
        rifles: user.rifles,
        ammunition: user.ammunition,
        scopes: [...others, legacy],
      ),
    );
    await _pump(tester, store);
    final row = find.text(first.name).first;
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsOneWidget);
    expect(_k('scope-brand'), findsOneWidget, reason: 'typed entry');
    expect(selectedValue<double>(tester, 'scope-click'), 0.1);
    expect(selectedValue<double>(tester, 'scope-mount'), 45);
    expect(_travelText(tester), '200');
    expect(_missingText(tester), isNot(contains('Dürbün')));
    final update = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
    expect(
      await _canPress(tester, update),
      isTrue,
      reason: _missingText(tester),
    );
    await tester.tap(update);
    await tester.pumpAndSettle();
    final again = (await store.all()).single;
    expect(again.mountCantMoa, 45);
    final scope = CatalogRepository.allScopes.singleWhere(
      (o) => o.id == again.scopeId,
    );
    expect(scope.model, '6-24x56 FFP');
    expect(scope.clickValue, 0.1);
    expect(scope.clickUnit, AngularUnit.mrad);
    expect(scope.elevationRangeMrad, closeTo(20, 1e-9));
    expect(scope.minMagnification, 6);
    expect(scope.maxMagnification, 24);
    expect(scope.objectiveDiameterMm, 56);
    expect(scope.firstFocalPlane, isTrue);
    expect(scope.reticle, 'Duplex');
    expect(tester.takeException(), isNull);
  });
}
