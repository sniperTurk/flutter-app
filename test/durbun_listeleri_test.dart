// Dürbün listeleri (owner, 2026-10-16 22:14–22:49 Istanbul), on the real
// Profil screen:
//
// - Minimum / Maksimum büyütme, Mercek çapı offer every value of the
//   manufacturer-sourced scope catalog (plus the earlier values); Retikül of
//   a typed scope offers every catalog reticle name, by Dürbün birimi.
// - Dürbün ayağı: MOA only, 0–60 in 5 MOA steps and 90.
// - Every opened list (MenzilSelect, app-wide) is 8 rows high at most,
//   scrolls inside with a visible scroll bar and opens with the picked
//   entry in view; a shorter list is only as tall as its rows.
// - In a new profile every Dürbün list box is on "Seçiniz", each list
//   starts with a "Seçiniz" row and every empty required box is named in
//   "Kaydetmek için eksik".
// - An old typed scope whose value is no longer a list entry opens with
//   that box on "Seçiniz" and cannot be saved until it is picked again.
// - Labels stay on one line at 390 pt ("Maksimum büyütme").
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/production_limits.dart';
import 'package:sniper_turk/core/reticle.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/reticle_catalog.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

void _view(WidgetTester tester, {double width = 390, double height = 2600}) {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

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
  double height = 2600,
  double scale = 1,
}) async {
  _view(tester, width: width, height: height);
  final store = MemoryProfileStore();
  await _pump(tester, store, scale: scale);
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
  return store;
}

Finder _k(String key) => find.byKey(Key(key));

Finder _prefix(String p) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(p),
);

String _missingText(WidgetTester tester) {
  final f = _k('profile-missing');
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data!;
}

/// The MenzilSelect under [box] (a keyed subtree or the select itself).
MenzilSelect<T> _select<T>(WidgetTester tester, Finder box) =>
    tester.widget<MenzilSelect<T>>(
      find.descendant(
        of: box,
        matching: find.byType(MenzilSelect<T>),
        matchRoot: true,
      ),
    );

/// The open list and its entries (MenzilSelect's list widgets).
final Finder _menu = find.byWidgetPredicate(
  (w) => w.runtimeType.toString().startsWith('_DropdownMenu<'),
);
final Finder _entries = find.byWidgetPredicate(
  (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
);

ScrollPosition _menuScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(of: _menu, matching: find.byType(Scrollable)).first,
    )
    .position;

String _entryText(WidgetTester tester, Element entry) {
  final texts = find.descendant(
    of: find.byElementPredicate((e) => identical(e, entry)),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(texts.first).data ?? '';
}

/// The entries fully inside the open list's visible part, top to bottom.
List<String> _visibleRows(WidgetTester tester) {
  final menu = tester.getRect(_menu);
  final rows = <(double, String)>[];
  for (final e in _entries.evaluate()) {
    final r = tester.getRect(find.byElementPredicate((x) => identical(x, e)));
    if (r.top >= menu.top - 0.5 && r.bottom <= menu.bottom + 0.5) {
      rows.add((r.top, _entryText(tester, e)));
    }
  }
  rows.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final (_, t) in rows) t];
}

/// Every entry of the open list, read by scrolling it to its end.
Future<List<String>> _scrollThrough(WidgetTester tester) async {
  final seen = <String>[];
  final position = _menuScroll(tester);
  position.jumpTo(0);
  await tester.pumpAndSettle();
  for (var i = 0; i < 400; i++) {
    for (final t in _visibleRows(tester)) {
      if (!seen.contains(t)) seen.add(t);
    }
    if (position.pixels >= position.maxScrollExtent - 0.5) break;
    await tester.drag(
      find.descendant(of: _menu, matching: find.byType(Scrollable)).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
  }
  return seen;
}

Future<void> _openList(WidgetTester tester, String key) async {
  await tester.ensureVisible(_k(key));
  await tester.pumpAndSettle();
  await tester.tap(_k(key));
  await tester.pumpAndSettle();
  expect(_menu, findsOneWidget, reason: key);
}

Future<void> _closeList(WidgetTester tester) async {
  await tester.tapAt(const Offset(2, 2));
  await tester.pumpAndSettle();
  expect(_menu, findsNothing);
}

/// "2,75" for 2.75, "6" for 6.0 (Turkish decimal comma).
String _num(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : '$v'.replaceAll('.', ',');

List<ScopeOptic> get _catalog => [
  for (final s in CatalogRepository.scopes)
    if (!s.userEntered) s,
];

Set<double> _catalogValues(double? Function(ScopeOptic) of) => {
  for (final s in _catalog)
    if (of(s) case final v? when v > 0) v,
};

/// Loads the bundled Inter files under the iPhone system font names (as
/// test/sistem_yazisi_test.dart does), so label widths are close to the
/// phone's.
Future<void> _loadStandIn() async {
  final files = Directory('assets/fonts')
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('Inter-'))
      .toList();
  expect(files, isNotEmpty);
  for (final name in {MenzilType.textFamily, MenzilType.displayFamily}) {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
}

const _typedSelects = [
  'scope-unit',
  'scope-focal-plane',
  'scope-min-mag',
  'scope-max-mag',
  'scope-objective',
  'scope-click',
  'scope-mount',
  'scope-reticle',
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('pick lists from the catalog', () {
    for (final (key, label, suffix, of) in <(
      String,
      String,
      String,
      double? Function(ScopeOptic),
    )>[
      ('scope-min-mag', 'Minimum büyütme', 'x', (s) => s.minMagnification),
      ('scope-max-mag', 'Maksimum büyütme', 'x', (s) => s.maxMagnification),
      ('scope-objective', 'Mercek çapı', ' mm', (s) => s.objectiveDiameterMm),
    ]) {
      testWidgets('$label: every catalog value is in the list (scrolled '
          'through), sorted, each once', (tester) async {
        await _openNew(tester);
        await openScopeManual(tester);
        final catalog = _catalogValues(of);
        expect(catalog.length, greaterThan(10));
        await _openList(tester, key);
        final shown = await _scrollThrough(tester);
        expect(shown.first, 'Seçiniz');
        final values = shown.skip(1).toList();
        expect(values.toSet().length, values.length, reason: 'each once');
        double parse(String t) => double.parse(
          t.replaceAll(suffix, '').replaceAll(',', '.').trim(),
        );
        final numbers = [for (final t in values) parse(t)];
        expect(numbers, [...numbers]..sort(), reason: 'sorted');
        for (final v in catalog) {
          expect(values, contains('${_num(v)}$suffix'), reason: '$v');
        }
        // The values offered before 2026-10-16 are still there.
        for (final old in switch (key) {
          'scope-min-mag' => const [1.0, 1.5, 2.5, 3.0, 12.0],
          'scope-max-mag' => const [4.0, 21.0, 56.0, 60.0],
          _ => const [20.0, 33.0, 54.0, 58.0, 64.0, 72.0],
        }) {
          expect(values, contains('${_num(old)}$suffix'), reason: '$old');
        }
        await _closeList(tester);
      });
    }

    testWidgets('values named by the owner are picked and kept, with a '
        'decimal comma', (tester) async {
      await _openNew(tester);
      await openScopeManual(tester);
      await chooseInSelect(tester, 'scope-min-mag', '0,75x');
      expect(selectedValue<double>(tester, 'scope-min-mag'), 0.75);
      await chooseInSelect(tester, 'scope-min-mag', '2,75x');
      expect(selectedValue<double>(tester, 'scope-min-mag'), 2.75);
      await chooseInSelect(tester, 'scope-max-mag', '12,8x');
      expect(selectedValue<double>(tester, 'scope-max-mag'), 12.8);
      await chooseInSelect(tester, 'scope-objective', '15 mm');
      expect(selectedValue<double>(tester, 'scope-objective'), 15);
      expect(
        tester.widget<Text>(_k('scope-designation')).data,
        'Dürbün: 2,75-12,8x15',
      );
      expect(_missingText(tester), isNot(contains('Min. büyütme')));
      expect(_missingText(tester), isNot(contains('Maks. büyütme')));
      expect(_missingText(tester), isNot(contains('Mercek çapı')));
    });

    testWidgets('Retikül of a typed scope: every catalog reticle name, '
        'filtered by Dürbün birimi, plain patterns too', (tester) async {
      await _openNew(tester);
      await openScopeManual(tester);
      List<String?> items() => [
        for (final i in _select<String>(tester, _k('scope-reticle')).items)
          i.value,
      ];
      final names = <String>{
        for (final s in _catalog) ...ReticleCatalog.options(s.reticle),
      };
      expect(names.length, greaterThan(20));
      // Dürbün birimi on "Seçiniz": everything.
      final all = items();
      expect(all.first, isNull);
      expect(all.skip(1).toSet().length, all.length - 1, reason: 'each once');
      for (final n in names) {
        expect(all, contains(n), reason: n);
      }
      for (final g in Reticles.genericNames) {
        expect(all, contains(g), reason: g);
      }
      // A name that says its unit follows the chosen Dürbün birimi.
      final moaNames = [
        for (final n in names)
          if (ReticleCatalog.nameKey(n).unit == 'moa') n,
      ];
      final milNames = [
        for (final n in names)
          if (ReticleCatalog.nameKey(n).unit == 'mil') n,
      ];
      expect(moaNames, isNotEmpty);
      expect(milNames, isNotEmpty);
      await chooseInSelect(tester, 'scope-unit', 'MRAD');
      final mil = items();
      for (final n in moaNames) {
        expect(mil, isNot(contains(n)), reason: n);
      }
      for (final n in milNames) {
        expect(mil, contains(n), reason: n);
      }
      await chooseInSelect(tester, 'scope-unit', 'MOA');
      final moa = items();
      for (final n in milNames) {
        expect(moa, isNot(contains(n)), reason: n);
      }
      for (final n in moaNames) {
        expect(moa, contains(n), reason: n);
      }
      // The last entry is reached by scrolling inside the list and picked.
      final last = moa.last!;
      await chooseInSelect(tester, 'scope-reticle', last);
      expect(selectedValue<String>(tester, 'scope-reticle'), last);
      await chooseInSelect(tester, 'scope-reticle', 'APR-2D MOA');
      expect(selectedValue<String>(tester, 'scope-reticle'), 'APR-2D MOA');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dürbün ayağı: MOA only, 0–60 in 5 MOA steps and 90', (
      tester,
    ) async {
      const want = <double>[
        0,
        5,
        10,
        15,
        20,
        25,
        30,
        35,
        40,
        45,
        50,
        55,
        60,
        90,
      ];
      expect(ProductionLimits.mountCantOptionsMoa, want);
      await _openNew(tester);
      final items = _select<double>(tester, _k('scope-mount')).items;
      expect(items.first.value, isNull);
      expect([for (final i in items.skip(1)) i.value], want);
      await openScopeManual(tester);
      await chooseInSelect(tester, 'scope-unit', 'MRAD');
      await chooseInSelect(tester, 'scope-click', '0,1 MRAD');
      await chooseInSelect(tester, 'scope-mount', '25 MOA · +72 klik');
      expect(selectedValue<double>(tester, 'scope-mount'), 25);
      expect(
        find.descendant(of: _k('scope-mount'), matching: find.text('25 MOA')),
        findsWidgets,
      );
      for (final i in items) {
        final t = (i.child as Text).data!;
        expect(t, isNot(contains('MRAD')), reason: t);
      }
    });
  });

  group('opened list: 8 rows, scrolls inside (app-wide)', () {
    testWidgets('390×844: a long list shows exactly 8 rows, a short one only '
        'its rows; scroll bar shown; never wider than its box', (
      tester,
    ) async {
      await _openNew(tester, height: 844);
      await openScopeManual(tester);
      await _openList(tester, 'scope-min-mag');
      expect(_visibleRows(tester).length, 8);
      expect(_visibleRows(tester).first, 'Seçiniz');
      expect(
        tester.getSize(_menu).height,
        closeTo(MenzilSelect.menuHeightFor(8, kMinInteractiveDimension), 0.5),
      );
      expect(_menuScroll(tester).maxScrollExtent, greaterThan(0));
      final bar = tester.widget<Scrollbar>(
        find.descendant(of: _menu, matching: find.byType(Scrollbar)),
      );
      expect(bar.thumbVisibility, isTrue);
      final box = tester.getRect(
        find.descendant(
          of: _k('scope-min-mag'),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(tester.getSize(_menu).width, lessThanOrEqualTo(box.width + 0.5));
      // The list lies under the box, inside the screen.
      expect(tester.getRect(_menu).top, greaterThan(box.bottom));
      expect(tester.getRect(_menu).bottom, lessThanOrEqualTo(844));
      await _closeList(tester);

      // Odak düzlemi: Seçiniz, FFP, SFP — three rows, no empty space.
      await _openList(tester, 'scope-focal-plane');
      expect(_visibleRows(tester), ['Seçiniz', 'FFP', 'SFP']);
      expect(
        tester.getSize(_menu).height,
        closeTo(MenzilSelect.menuHeightFor(3, kMinInteractiveDimension), 0.5),
      );
      expect(_menuScroll(tester).maxScrollExtent, 0);
      await _closeList(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the picked entry is in view when the list opens', (
      tester,
    ) async {
      await _openNew(tester, height: 844);
      await openScopeManual(tester);
      await chooseInSelect(tester, 'scope-max-mag', '55x');
      await _openList(tester, 'scope-max-mag');
      expect(_visibleRows(tester), contains('55x'));
      expect(_visibleRows(tester).length, 8);
      await _closeList(tester);
      await chooseInSelect(tester, 'scope-max-mag', '1x');
      await _openList(tester, 'scope-max-mag');
      expect(_visibleRows(tester), contains('1x'));
      await _closeList(tester);
    });

    testWidgets('a small screen shows as many whole rows as fit', (
      tester,
    ) async {
      // 390×500: under the box there is no room for 8 rows.
      await _openNew(tester, height: 500);
      await openScopeManual(tester);
      await _openList(tester, 'scope-min-mag');
      final rows = _visibleRows(tester).length;
      expect(rows, inInclusiveRange(1, 8));
      expect(
        tester.getSize(_menu).height,
        closeTo(
          MenzilSelect.menuHeightFor(rows, kMinInteractiveDimension),
          kMinInteractiveDimension,
        ),
      );
      expect(tester.getRect(_menu).bottom, lessThanOrEqualTo(500));
      await _closeList(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 pt × 1.3: lists open, no overflow', (tester) async {
      await _openNew(tester, width: 320, height: 844, scale: 1.3);
      await openScopeManual(tester);
      for (final key in ['scope-min-mag', 'scope-reticle', 'scope-mount']) {
        await _openList(tester, key);
        expect(_visibleRows(tester), isNotEmpty);
        final box = tester.getRect(
          find.descendant(of: _k(key), matching: find.byType(InputDecorator)),
        );
        expect(
          tester.getSize(_menu).width,
          lessThanOrEqualTo(box.width + 0.5),
        );
        await _closeList(tester);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('new profile: every box on "Seçiniz"', () {
    testWidgets('list path: Marka, filters, Model, Dürbün ayağı, Retikül', (
      tester,
    ) async {
      await _openNew(tester);
      final boxes = <Finder>[
        _k('scope-brand-select'),
        _prefix('scope-filter-unit-'),
        _prefix('scope-filter-ffp-'),
        _prefix('scope-filter-tube-'),
        _prefix('scope-filter-mag-'),
        _k('scope-model-select'),
        _k('scope-mount'),
        _k('scope-reticle'),
      ];
      for (final box in boxes) {
        final s = tester.widget(
          find.descendant(
            of: box,
            matching: find.byWidgetPredicate((w) => w is MenzilSelect),
            matchRoot: true,
          ),
        );
        final items = (s as dynamic).items as List<DropdownMenuItem<Object?>>;
        expect(items.first.value, isNull, reason: '$box');
        expect((items.first.child as Text).data, 'Seçiniz', reason: '$box');
        expect(
          find.descendant(of: box, matching: find.text('Seçiniz')),
          findsOneWidget,
          reason: '$box',
        );
      }
      // Seçiniz is grey; a picked filter value is in the normal ink.
      final c = MenzilColors.of(tester.element(_k('profile-scope-form')));
      Color? colorOf(Finder box, String text) => tester
          .renderObject<RenderParagraph>(
            find.descendant(of: box, matching: find.text(text)).first,
          )
          .text
          .style
          ?.color;
      expect(colorOf(_k('scope-brand-select'), 'Seçiniz'), c.ink2);
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
      expect(colorOf(_prefix('scope-filter-unit-'), 'MOA'), c.ink);
      expect(colorOf(_prefix('scope-filter-ffp-'), 'FFP'), c.ink);
      expect(colorOf(_prefix('scope-filter-tube-'), 'Seçiniz'), c.ink2);
      expect(_missingText(tester), contains('Dürbün: Model'));
      expect(_missingText(tester), contains('Dürbün ayağı'));
    });

    testWidgets('typed path: every list on "Seçiniz", Üst kule empty, each '
        'empty required box named in "Kaydetmek için eksik"', (tester) async {
      await _openNew(tester);
      await openScopeManual(tester);
      for (final key in _typedSelects) {
        final s = tester.widget(
          find.descendant(
            of: _k(key),
            matching: find.byWidgetPredicate((w) => w is MenzilSelect),
            matchRoot: true,
          ),
        );
        final items = (s as dynamic).items as List<DropdownMenuItem<Object?>>;
        expect(items.first.value, isNull, reason: key);
        expect((items.first.child as Text).data, 'Seçiniz', reason: key);
        expect((s as dynamic).initialValue, isNull, reason: key);
        expect(
          find.descendant(of: _k(key), matching: find.text('Seçiniz')),
          findsOneWidget,
          reason: key,
        );
      }
      String typed(String key) => tester
          .widget<TextField>(
            find.descendant(of: _k(key), matching: find.byType(TextField)),
          )
          .controller!
          .text;
      expect(typed('scope-brand'), '');
      expect(typed('scope-model'), '');
      expect(typed('scope-travel-elevation'), '');
      final missing = _missingText(tester);
      final dürbün = missing
          .split(' · ')
          .firstWhere((p) => p.startsWith('Dürbün: '));
      expect(
        dürbün,
        'Dürbün: Marka, Dürbün modeli, Dürbün birimi, Odak düzlemi, '
        'Min. büyütme, Maks. büyütme, Mercek çapı, Klik değeri, '
        'Dürbün ayağı',
      );
      // A list's "Seçiniz" row empties the box again.
      await chooseInSelect(tester, 'scope-unit', 'MOA');
      expect(_missingText(tester), isNot(contains('Dürbün birimi')));
      await chooseInSelect(tester, 'scope-unit', 'Seçiniz');
      expect(selectedValue<AngularUnit>(tester, 'scope-unit'), isNull);
      expect(_missingText(tester), contains('Dürbün birimi'));
    });
  });

  testWidgets('labels on one line at 390 pt (iPhone font stand-in)', (
    tester,
  ) async {
    await _loadStandIn();
    await _openNew(tester);
    await openScopeManual(tester);
    for (final (key, label) in const [
      ('scope-brand', 'Dürbün markası'),
      ('scope-model', 'Dürbün modeli'),
      ('scope-unit', 'Dürbün birimi'),
      ('scope-focal-plane', 'Odak düzlemi'),
      ('scope-min-mag', 'Minimum büyütme'),
      ('scope-max-mag', 'Maksimum büyütme'),
      ('scope-objective', 'Mercek çapı'),
      ('scope-click', 'Klik değeri'),
      ('scope-travel-elevation', 'Üst kule klik sayısı'),
      ('scope-mount', 'Dürbün ayağı'),
    ]) {
      final text = find.descendant(
        of: find.descendant(of: _k(key), matching: find.byType(MenzilFieldLabel)),
        matching: find.text(label),
      );
      expect(text, findsOneWidget, reason: key);
      final p = tester.renderObject<RenderParagraph>(text);
      // One line of the 12,5 pt label (line height 1,25).
      expect(p.size.height, lessThan(12.5 * 1.25 * 1.5), reason: label);
      // The ⓘ stays where it was: 22 pt from the box's right edge.
      final info = find.descendant(
        of: _k(key),
        matching: find.byType(MenzilInfoButton),
      );
      if (info.evaluate().isNotEmpty) {
        final box = tester.getRect(_k(key));
        expect(
          tester.getCenter(info).dx,
          closeTo(box.right - 22, 0.5),
          reason: key,
        );
        // Its own text never runs under the icon.
        expect(tester.getRect(text).right, lessThan(box.right - 31 + 0.5));
      }
    }
  });

  testWidgets('old typed profile: a value no longer in the list opens on '
      '"Seçiniz", blocks saving, and is saved once picked again', (
    tester,
  ) async {
    CatalogRepository.installUserCatalog(
      const UserCatalog(
        scopes: [
          ScopeOptic(
            id: 'user-scope-eski-deger',
            brand: 'Eski Optik',
            model: 'Z3 1,3-16x44 FFP',
            objectiveDiameterMm: 44,
            clickValue: 0.1,
            clickUnit: AngularUnit.mrad,
            minMagnification: 1.3,
            maxMagnification: 16,
            firstFocalPlane: true,
            reticle: 'Mil-Dot',
            userEntered: true,
          ),
        ],
      ),
    );
    _view(tester);
    final store = MemoryProfileStore();
    await store.save(
      const RifleProfile(
        id: 'p-eski-deger',
        name: 'Eski Değer',
        rifleId: 'hatsan-hercules-635',
        ammunitionId: 'gmaz-51',
        scopeId: 'user-scope-eski-deger',
        muzzleVelocityMps: 270,
        zeroRangeM: 25,
        sightHeightMm: 60,
        pressureBar: 200,
      ),
    );
    await _pump(tester, store);
    final row = find.text('Eski Değer').first;
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsOneWidget);
    expect(_k('scope-brand'), findsOneWidget, reason: 'typed entry');
    // 1,3x is no list value: the box is empty, the others keep theirs.
    expect(selectedValue<double>(tester, 'scope-min-mag'), isNull);
    expect(
      find.descendant(of: _k('scope-min-mag'), matching: find.text('Seçiniz')),
      findsOneWidget,
    );
    expect(selectedValue<double>(tester, 'scope-max-mag'), 16);
    expect(selectedValue<double>(tester, 'scope-objective'), 44);
    expect(selectedValue<double>(tester, 'scope-click'), 0.1);
    expect(selectedValue<String>(tester, 'scope-reticle'), 'Mil-Dot');
    expect(_missingText(tester), contains('Min. büyütme'));
    final button = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
    await tester.ensureVisible(button);
    expect(tester.widget<MenzilPrimaryButton>(button).onPressed, isNull);

    await chooseInSelect(tester, 'scope-min-mag', '1x');
    expect(_missingText(tester), isNot(contains('Min. büyütme')));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MenzilPrimaryButton>(button).onPressed,
      isNotNull,
      reason: _missingText(tester),
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    final saved = (await store.all()).single;
    final scope = CatalogRepository.allScopes.singleWhere(
      (o) => o.id == saved.scopeId,
    );
    expect(scope.minMagnification, 1);
    expect(scope.maxMagnification, 16);
    expect(scope.reticle, 'Mil-Dot');
    expect(tester.takeException(), isNull);
  });

  group('Retikül drawing on Hedef for a typed scope', () {
    test('a catalog name with its own drawing uses it; the name is shown', () {
      // A name whose catalog scopes lead to exactly one data record.
      String? name;
      AngularUnit? unit;
      for (final s in _catalog) {
        for (final n in ReticleCatalog.options(s.reticle)) {
          final own = ReticleCatalog.forScope(
            n,
            s.clickUnit,
            brand: s.brand,
            model: s.model,
            source: s.sourceDocument,
          );
          if (own != null && own.fromData) {
            final typed = ReticleCatalog.forScope(
              n,
              s.clickUnit,
              brand: 'Benim Optik',
              typed: true,
            );
            if (typed != null && typed.fromData) {
              name = n;
              unit = s.clickUnit;
              break;
            }
          }
        }
        if (name != null) break;
      }
      expect(name, isNotNull, reason: 'the catalog has drawn reticles');
      final spec = ReticleCatalog.forScope(
        name,
        unit!,
        brand: 'Benim Optik',
        typed: true,
      )!;
      expect(spec.fromData, isTrue);
      expect(spec.name, name);
      // A list scope (not typed) of another brand keeps the generic grid.
      expect(
        ReticleCatalog.forScope(name, unit, brand: 'Benim Optik')!.fromData,
        isFalse,
      );
    });

    test('a name without a drawing: the generic grid of its unit', () {
      final mil = ReticleCatalog.forScope(
        'Benim Retikülüm',
        AngularUnit.mrad,
        brand: 'Benim Optik',
        typed: true,
      )!;
      expect(mil.fromData, isFalse);
      expect(mil.unit, AngularUnit.mrad);
      expect(mil.name, 'Benim Retikülüm');
      final moa = ReticleCatalog.forScope(
        'Benim Retikülüm',
        AngularUnit.moa,
        brand: 'Benim Optik',
        typed: true,
      )!;
      expect(moa.fromData, isFalse);
      expect(moa.unit, AngularUnit.moa);
    });
  });
}
