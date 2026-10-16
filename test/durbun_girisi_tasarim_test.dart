// Dürbün girişi, approved design (Temiz Tasarım "Profil Oluştur",
// 2026-10-15; owner 2026-10-16 19:25–19:31): the real Profil screen end to
// end for both paths.
//
// List: Marka | Birim, Odak düzlemi | Tüp, Büyütme | Model | Üst kule klik
// sayısı, Dürbün ayağı | Retikül | "Dürbün: …" | "Aradığın dürbün listede
// yok mu?"; the filters are in their place (closed, "Seçiniz") before a
// Marka is chosen.
//
// Typed: Dürbün markası, Dürbün modeli | Minimum, Maksimum büyütme | Mercek
// çapı, Odak düzlemi | Dürbün birimi, Klik değeri | Üst kule klik sayısı,
// Dürbün ayağı | Retikül | "Dürbün: Marka Model …" | "Listeden seç".
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

import 'support/rifle_form.dart';

void _view(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pump(
  WidgetTester tester,
  ProfileStore store, {
  String? active,
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
      home: ProfilesScreen(store: store, activeProfileId: active),
    ),
  );
  await tester.pumpAndSettle();
}

Future<MemoryProfileStore> _openNew(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
}) async {
  _view(tester, width: width);
  final store = MemoryProfileStore();
  await _pump(tester, store, scale: scale);
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
  return store;
}

Future<void> _openEdit(WidgetTester tester, String name) async {
  final row = find.text(name).first;
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsOneWidget);
}

Finder _prefix(String p) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(p),
);

const _filters = [
  'scope-filter-unit-',
  'scope-filter-ffp-',
  'scope-filter-tube-',
  'scope-filter-mag-',
];

Rect _r(WidgetTester tester, Finder f) => tester.getRect(f.first);

/// [rows] top to bottom; boxes of one row share their top (±0,5 pt) and
/// stand left to right.
void _expectRows(WidgetTester tester, List<List<Finder>> rows) {
  double? lastTop;
  for (final (i, row) in rows.indexed) {
    for (final f in row) {
      expect(f, findsWidgets, reason: 'row $i: $f');
    }
    final top = _r(tester, row.first).top;
    for (var j = 1; j < row.length; j++) {
      expect(
        (_r(tester, row[j]).top - top).abs(),
        lessThanOrEqualTo(0.5),
        reason: 'row $i: ${row[j]} not beside ${row.first}',
      );
      expect(
        _r(tester, row[j - 1]).right,
        lessThan(_r(tester, row[j]).left),
        reason: 'row $i: left to right',
      );
    }
    if (lastTop != null) {
      expect(top, greaterThan(lastTop), reason: 'row $i is not below $i-1');
    }
    lastTop = top;
  }
}

Finder _k(String key) => find.byKey(Key(key));

String _missingText(WidgetTester tester) {
  final f = _k('profile-missing');
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data!;
}

String _typed(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(of: _k(key), matching: find.byType(TextField)),
    )
    .controller!
    .text;

String _designation(WidgetTester tester) =>
    tester.widget<Text>(_k('scope-designation')).data!;

/// The open list and its entries (MenzilSelect's list widgets).
final Finder _menu = find.byWidgetPredicate(
  (w) => w.runtimeType.toString().startsWith('_DropdownMenu<'),
);
final Finder _entries = find.byWidgetPredicate(
  (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
);

List<String> _entryTexts(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(
    find.descendant(of: _entries, matching: find.byType(Text)),
  ))
    t.data ?? '',
];

Future<void> _save(WidgetTester tester, String label) async {
  final button = find.widgetWithText(MenzilPrimaryButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  expect(
    tester.widget<MenzilPrimaryButton>(button).onPressed,
    isNotNull,
    reason: _missingText(tester),
  );
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _scopeInfo(WidgetTester tester, List<String> labels) async {
  for (final l in labels) {
    expect(
      find.descendant(
        of: _k('profile-scope-form'),
        matching: find.byTooltip('Bilgi: $l'),
      ),
      findsWidgets,
      reason: 'ⓘ $l',
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('list path: Marka -> filters -> Model -> Retikül -> save -> '
      'Profili Düzenle shows the same values', (tester) async {
    final store = await _openNew(tester);

    // Rows 2–3 are in their place before a Marka, closed, on "Seçiniz".
    for (final p in _filters) {
      expect(_prefix(p), findsOneWidget, reason: p);
      expect(
        (tester.widget(_prefix(p)) as dynamic).onChanged,
        isNull,
        reason: '$p is open before a Marka',
      );
    }
    List<List<Finder>> listRows() => [
      [_k('scope-brand-select')],
      [_prefix('scope-filter-unit-'), _prefix('scope-filter-ffp-')],
      [_prefix('scope-filter-tube-'), _prefix('scope-filter-mag-')],
      [_k('scope-model-select')],
      [_k('scope-travel-elevation'), _k('scope-mount')],
      [_k('scope-reticle')],
      [_k('scope-designation')],
      [_k('scope-not-listed')],
    ];
    _expectRows(tester, listRows());
    // Full rows: Marka, Model, Retikül span the card.
    final card = _r(tester, _k('profile-scope-form'));
    for (final key in ['scope-brand-select', 'scope-model-select']) {
      expect(_r(tester, _k(key)).width, greaterThan(card.width * 0.8));
    }
    await _scopeInfo(tester, [
      'Birim',
      'Odak düzlemi',
      'Tüp',
      'Büyütme',
      'Üst kule klik sayısı',
      'Dürbün ayağı',
      'Retikül',
    ]);
    // The typed boxes are not on the list path.
    expect(_k('scope-brand'), findsNothing);
    expect(_k('scope-model'), findsNothing);

    await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
    for (final p in _filters) {
      expect(
        (tester.widget(_prefix(p)) as dynamic).onChanged,
        isNotNull,
        reason: '$p stays closed after a Marka',
      );
    }
    _expectRows(tester, listRows());

    // Birim MOA and Odak düzlemi FFP narrow the Model list.
    await chooseInSelect(
      tester,
      'scope-filter-unit-Element Optics-null',
      'MOA',
    );
    await chooseInSelect(tester, 'scope-filter-ffp-Element Optics-null', 'FFP');
    await tester.ensureVisible(_k('scope-model-select'));
    await tester.pumpAndSettle();
    await tester.tap(_k('scope-model-select'));
    await tester.pumpAndSettle();
    expect(_menu, findsOneWidget);
    final lines = _entryTexts(tester);
    expect(lines, isNotEmpty);
    for (final l in lines) {
      expect(l.toUpperCase(), contains('MOA'), reason: l);
      expect(l.toUpperCase(), contains('FFP'), reason: l);
    }
    // Close the list without picking.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await chooseInSelect(tester, 'scope-model-select', 'Titan 3-18x50 FFP MOA');
    final model = selectedValue<String>(tester, 'scope-model-select');
    expect(model, isNotNull);
    await chooseInSelect(tester, 'scope-reticle', 'APR-2D MOA');
    await chooseInSelect(tester, 'scope-mount', 'Normal (0 MOA)');
    // The five record values stay hidden; the order is unchanged.
    for (final key in [
      'scope-min-mag',
      'scope-max-mag',
      'scope-objective',
      'scope-focal-plane',
      'scope-unit',
    ]) {
      expect(_k(key), findsNothing, reason: key);
    }
    _expectRows(tester, listRows());
    final line = _designation(tester);
    expect(line, startsWith('Dürbün: Element Optics Titan'));
    expect(line, contains('3-18x50 FFP'));

    await fillRifleForm(tester);
    await fillAmmoForm(tester);
    await fillShotValues(tester);
    await _save(tester, 'Kaydet');

    final saved = (await store.all()).single;
    final scope = CatalogRepository.allScopes.singleWhere(
      (o) => o.id == saved.scopeId,
    );
    expect(scope.brand, 'Element Optics Titan');
    expect(scope.model, '3-18x50 FFP');
    expect(scope.reticle, 'APR-2D MOA');
    expect(scope.clickUnit, AngularUnit.moa);

    await _openEdit(tester, saved.name);
    expect(
      selectedValue<String>(tester, 'scope-brand-select'),
      'Element Optics',
    );
    expect(selectedValue<String>(tester, 'scope-model-select'), model);
    expect(selectedValue<String>(tester, 'scope-reticle'), 'APR-2D MOA');
    expect(selectedValue<double>(tester, 'scope-mount'), 0);
    expect(_designation(tester), line);
    // Profili Düzenle: the same rows as Profil Oluştur.
    _expectRows(tester, listRows());
    expect(tester.takeException(), isNull);
  });

  testWidgets('typed path: every box in order -> save -> summary shows '
      '"Marka Model" -> Profili Düzenle keeps the model', (tester) async {
    final store = await _openNew(tester);
    await openScopeManual(tester);

    List<List<Finder>> typedRows() => [
      [_k('scope-brand'), _k('scope-model')],
      [_k('scope-min-mag'), _k('scope-max-mag')],
      [_k('scope-objective'), _k('scope-focal-plane')],
      [_k('scope-unit'), _k('scope-click')],
      [_k('scope-travel-elevation'), _k('scope-mount')],
      [_k('scope-reticle')],
      [_k('scope-designation')],
      [_k('scope-back-to-list')],
    ];
    _expectRows(tester, typedRows());
    expect(_k('scope-brand-select'), findsNothing);
    expect(_k('scope-not-listed'), findsNothing);
    for (final p in _filters) {
      expect(_prefix(p), findsNothing, reason: p);
    }
    await _scopeInfo(tester, [
      'Minimum büyütme',
      'Maksimum büyütme',
      'Mercek çapı',
      'Odak düzlemi',
      'Dürbün birimi',
      'Klik değeri',
      'Üst kule klik sayısı',
      'Dürbün ayağı',
      'Retikül',
    ]);
    // Labels as asked, no parentheses.
    expect(
      tester.widget<MenzilInput>(_k('scope-brand')).label,
      'Dürbün markası',
    );
    expect(
      tester.widget<MenzilInput>(_k('scope-model')).label,
      'Dürbün modeli',
    );

    // Both names are required.
    expect(_missingText(tester), contains('Dürbün modeli'));
    await enterRifleField(tester, 'scope-brand', 'Benim Optik');
    expect(_missingText(tester), contains('Dürbün modeli'));
    await enterRifleField(tester, 'scope-model', 'X5 Pro');
    expect(_missingText(tester), isNot(contains('Dürbün modeli')));
    expect(_designation(tester), 'Dürbün: Benim Optik X5 Pro');

    await chooseInSelect(tester, 'scope-min-mag', '5x');
    await chooseInSelect(tester, 'scope-max-mag', '25x');
    await chooseInSelect(tester, 'scope-objective', '56 mm');
    await chooseFocalPlane(tester, 'FFP');
    await chooseInSelect(tester, 'scope-unit', 'MRAD');
    await chooseInSelect(tester, 'scope-click', '0,1 MRAD');
    await enterRifleField(tester, 'scope-travel-elevation', '200');
    await chooseInSelect(tester, 'scope-mount', 'Normal (0 MOA)');
    await chooseInSelect(tester, 'scope-reticle', 'Mil-Dot');
    expect(_designation(tester), 'Dürbün: Benim Optik X5 Pro 5-25x56 FFP');
    _expectRows(tester, typedRows());

    await fillRifleForm(tester);
    await fillAmmoForm(tester);
    await fillShotValues(tester);
    await _save(tester, 'Kaydet');

    final saved = (await store.all()).single;
    final scope = CatalogRepository.allScopes.singleWhere(
      (o) => o.id == saved.scopeId,
    );
    expect(scope.userEntered, isTrue);
    expect(scope.brand, 'Benim Optik');
    expect(scope.model, 'X5 Pro 5-25x56 FFP');
    expect(scope.clickValue, 0.1);
    expect(scope.clickUnit, AngularUnit.mrad);
    expect(scope.firstFocalPlane, isTrue);
    expect(scope.elevationRangeMrad, closeTo(20, 1e-9));
    expect(scope.reticle, 'Mil-Dot');

    // Profil summary card of the active profile: "Marka Model …".
    await _pump(tester, store, active: saved.id);
    expect(
      find.descendant(
        of: _k('profile-summary-scope'),
        matching: find.textContaining(
          'Benim Optik X5 Pro 5-25 x 56 FFP',
          findRichText: true,
        ),
      ),
      findsWidgets,
    );

    await _openEdit(tester, saved.name);
    expect(_typed(tester, 'scope-brand'), 'Benim Optik');
    expect(_typed(tester, 'scope-model'), 'X5 Pro');
    expect(selectedValue<double>(tester, 'scope-min-mag'), 5);
    expect(selectedValue<double>(tester, 'scope-max-mag'), 25);
    expect(selectedValue<double>(tester, 'scope-objective'), 56);
    expect(selectedValue<bool>(tester, 'scope-focal-plane'), isTrue);
    expect(selectedValue<double>(tester, 'scope-click'), 0.1);
    expect(_typed(tester, 'scope-travel-elevation'), '200');
    expect(selectedValue<String>(tester, 'scope-reticle'), 'Mil-Dot');
    expect(_designation(tester), 'Dürbün: Benim Optik X5 Pro 5-25x56 FFP');
    _expectRows(tester, typedRows());
    // Güncelle saves it unchanged.
    await _save(tester, 'Güncelle');
    final after = (await store.all()).single;
    final again = CatalogRepository.allScopes.singleWhere(
      (o) => o.id == after.scopeId,
    );
    expect(again.brand, 'Benim Optik');
    expect(again.model, 'X5 Pro 5-25x56 FFP');
    expect(tester.takeException(), isNull);
  });

  testWidgets('old typed profile without a model loads: model box empty, '
      'everything else as before', (tester) async {
    CatalogRepository.installUserCatalog(
      const UserCatalog(
        scopes: [
          ScopeOptic(
            id: 'user-scope-eski',
            brand: 'Eski Optik',
            model: '4-16x44 FFP',
            objectiveDiameterMm: 44,
            clickValue: 0.1,
            clickUnit: AngularUnit.mrad,
            minMagnification: 4,
            maxMagnification: 16,
            firstFocalPlane: true,
            userEntered: true,
          ),
        ],
      ),
    );
    _view(tester);
    final store = MemoryProfileStore();
    await store.save(
      const RifleProfile(
        id: 'p-eski',
        name: 'Eski Dürbün',
        rifleId: 'hatsan-hercules-635',
        ammunitionId: 'gmaz-51',
        scopeId: 'user-scope-eski',
        muzzleVelocityMps: 270,
        zeroRangeM: 25,
        sightHeightMm: 60,
        pressureBar: 200,
      ),
    );
    await _pump(tester, store);
    await _openEdit(tester, 'Eski Dürbün');
    expect(_typed(tester, 'scope-brand'), 'Eski Optik');
    expect(_typed(tester, 'scope-model'), '');
    expect(selectedValue<double>(tester, 'scope-min-mag'), 4);
    expect(selectedValue<double>(tester, 'scope-max-mag'), 16);
    expect(selectedValue<double>(tester, 'scope-objective'), 44);
    expect(selectedValue<bool>(tester, 'scope-focal-plane'), isTrue);
    expect(_designation(tester), 'Dürbün: Eski Optik 4-16x44 FFP');
    // Saved before the box existed: not listed as missing.
    expect(_missingText(tester), isNot(contains('Dürbün modeli')));
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('$width pt ×$scale: both paths, no overflow, open list '
          'never wider than its box', (tester) async {
        await _openNew(tester, width: width, scale: scale);
        await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
        await chooseInSelect(
          tester,
          'scope-model-select',
          'Titan 3-18x50 FFP MOA',
        );
        expect(tester.takeException(), isNull);
        // Order holds (one column when the screen is too narrow).
        final listOrder = [
          'scope-brand-select',
          'scope-model-select',
          'scope-reticle',
          'scope-designation',
          'scope-not-listed',
        ];
        for (var i = 1; i < listOrder.length; i++) {
          expect(
            _r(tester, _k(listOrder[i])).top,
            greaterThan(_r(tester, _k(listOrder[i - 1])).top),
            reason: listOrder[i],
          );
        }
        await openScopeManual(tester);
        await enterRifleField(tester, 'scope-brand', 'Benim Optik');
        await enterRifleField(tester, 'scope-model', 'X5 Pro');
        final typedOrder = [
          'scope-brand',
          'scope-min-mag',
          'scope-objective',
          'scope-unit',
          'scope-travel-elevation',
          'scope-reticle',
          'scope-designation',
          'scope-back-to-list',
        ];
        for (var i = 1; i < typedOrder.length; i++) {
          expect(
            _r(tester, _k(typedOrder[i])).top,
            greaterThan(_r(tester, _k(typedOrder[i - 1])).top),
            reason: typedOrder[i],
          );
        }
        // Model beside or below Marka, never above.
        expect(
          _r(tester, _k('scope-model')).top,
          greaterThanOrEqualTo(_r(tester, _k('scope-brand')).top - 0.5),
        );
        // Every box inside the card.
        final card = _r(tester, _k('profile-scope-form'));
        for (final key in [...typedOrder, 'scope-model', 'scope-click']) {
          final r = _r(tester, _k(key));
          expect(r.left, greaterThanOrEqualTo(card.left), reason: key);
          expect(r.right, lessThanOrEqualTo(card.right + 0.5), reason: key);
        }
        // Text is left-aligned in the box.
        expect(
          _r(tester, find.text('Dürbün: Benim Optik X5 Pro')).left,
          lessThan(card.left + 40),
        );
        await tester.ensureVisible(_k('scope-unit'));
        await tester.pumpAndSettle();
        await tester.tap(_k('scope-unit'));
        await tester.pumpAndSettle();
        expect(_menu, findsOneWidget);
        final box = tester.getRect(
          find.descendant(
            of: _k('scope-unit'),
            matching: find.byType(InputDecorator),
          ),
        );
        expect(tester.getSize(_menu).width, lessThanOrEqualTo(box.width + 0.5));
        await tester.tap(_entries.first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
