// Arken Optics SFP dürbünleri (owner, 2026-10-17 17:59–18:01 Istanbul:
// "ekle"): on the real Profil screen, Dürbün list path Arken Optics → MOA →
// SFP offers OUTRIDER 2-12x42 SFP, OUTRIDER 3-18x50 SFP and LH-6 1-6x24 SFP
// with their own magnification, objective and reticle lists; Arken → MRAD
// still offers only FFP (Arken lists no MRAD SFP scope).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/reticle_catalog.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

const _brand = 'Arken Optics';

/// Model → (min, max, objective, tube, reticles, elevation/windage MOA).
const _want =
    <String, (double, double, double, double, List<String>, double, double)>{
      'OUTRIDER 2-12x42 SFP': (2, 12, 42, 30, ['FDR', 'DLR'], 90, 80),
      'OUTRIDER 3-18x50 SFP': (3, 18, 50, 30, ['FDR', 'DLR'], 56, 48),
      'LH-6 1-6x24 SFP': (1, 6, 24, 30, ['KLBOX'], 180, 180),
    };

List<ScopeOptic> get _arken => [
  for (final s in CatalogRepository.scopes)
    if (!s.userEntered && s.brand == _brand) s,
];

/// MOA → mrad as the catalog stores MOA turret ranges (× π/10.8, 2 places).
double _mrad(double moa) =>
    double.parse((moa * 3.141592653589793 / 10.8).toStringAsFixed(2));

Future<void> _openNew(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
}

Finder _k(String key) => find.byKey(Key(key));

Finder _prefix(String p) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(p),
);

/// The non-"Seçiniz" values of the MenzilSelect under [box].
List<Object?> _values(WidgetTester tester, Finder box) {
  final s = tester.widget(
    find.descendant(
      of: box,
      matching: find.byWidgetPredicate((w) => w is MenzilSelect),
      matchRoot: true,
    ),
  );
  final items = (s as dynamic).items as List<DropdownMenuItem<Object?>>;
  return [
    for (final i in items)
      if (i.value != null) i.value,
  ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  test('catalog: the three Arken SFP records with the maker values', () {
    final sfp = [
      for (final s in _arken)
        if (s.firstFocalPlane == false) s,
    ];
    expect({for (final s in sfp) s.model}, _want.keys.toSet());
    for (final s in sfp) {
      final (lo, hi, obj, tube, reticles, elev, wind) = _want[s.model]!;
      expect(s.minMagnification, lo, reason: s.model);
      expect(s.maxMagnification, hi, reason: s.model);
      expect(s.objectiveDiameterMm, obj, reason: s.model);
      expect(s.tubeDiameterMm, tube, reason: s.model);
      expect(s.clickUnit, AngularUnit.moa, reason: s.model);
      expect(s.clickValue, 0.25, reason: s.model);
      expect(s.elevationRangeMrad, _mrad(elev), reason: s.model);
      expect(s.windageRangeMrad, _mrad(wind), reason: s.model);
      expect(s.zeroStop, isFalse, reason: s.model);
      expect(ReticleCatalog.options(s.reticle), reticles, reason: s.model);
      expect(
        s.sourceDocument,
        endsWith('official manufacturer page, read 2026-10-17'),
        reason: s.model,
      );
      // Every reticle name opens its Arken MOA drawing record.
      for (final r in reticles) {
        final hit = ReticleCatalog.find(
          r,
          s.clickUnit,
          brand: s.brand,
          model: s.model,
          source: s.sourceDocument,
        );
        expect(hit?.id, 'arken-${r.toLowerCase()}-moa', reason: s.model);
      }
    }
    // LH-6: the three maker sources give three weights; left empty.
    expect(sfp.singleWhere((s) => s.model.startsWith('LH-6')).weightG, isNull);
    // No MRAD SFP Arken scope: the maker lists none.
    expect(
      _arken.where(
        (s) => s.clickUnit == AngularUnit.mrad && s.firstFocalPlane == false,
      ),
      isEmpty,
    );
  });

  testWidgets('Dürbün: Arken Optics, MOA, SFP offers the three models with '
      'their magnification, objective and reticle lists', (tester) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'scope-brand-select', _brand);
    await chooseInSelect(tester, 'scope-filter-unit-$_brand-null', 'MOA');
    expect(_values(tester, _prefix('scope-filter-ffp-')), [true, false]);
    await chooseInSelect(tester, 'scope-filter-ffp-$_brand-null', 'SFP');

    expect(_values(tester, _prefix('scope-filter-tube-')), [30.0]);
    expect(_values(tester, _prefix('scope-filter-mag-')), [
      '1-6x',
      '2-12x',
      '3-18x',
    ]);
    expect(
      _values(tester, _k('scope-model-select')).toSet(),
      _want.keys.toSet(),
    );

    for (final MapEntry(key: model, value: v) in _want.entries) {
      final (lo, hi, obj, _, reticles, _, _) = v;
      await chooseInSelect(tester, 'scope-model-select', '$model · MOA');
      expect(_values(tester, _k('scope-reticle')), reticles, reason: model);
      String n(double x) => x.toStringAsFixed(0);
      expect(
        tester.widget<Text>(_k('scope-designation')).data,
        contains('${n(lo)}-${n(hi)}x${n(obj)} SFP'),
        reason: model,
      );
    }
  });

  testWidgets('Dürbün: Arken Optics, MRAD still offers only FFP', (
    tester,
  ) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'scope-brand-select', _brand);
    await chooseInSelect(tester, 'scope-filter-unit-$_brand-null', 'MRAD');
    expect(_values(tester, _prefix('scope-filter-ffp-')), [true]);
    for (final m in _values(tester, _k('scope-model-select'))) {
      expect(m, isNot(contains('SFP')));
    }
  });
}
