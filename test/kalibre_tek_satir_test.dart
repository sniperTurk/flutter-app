// Owner, 2026-10-17 (Istanbul):
// - 17:54–17:57, TestFlight 113, Profil → Tüfek, Ateşli Tüfek, Beretta
//   BRX1: the Kalibre box showed ".30-06 Springfield" on two lines (the row
//   was taller than Namlu çıkış hızı); Sight height was a full-width box
//   alone. → Sight height half width ("Tabiki A").
// - 18:03–18:05, TestFlight 113: Mühimmat → Model showed a long name on ONE
//   line cut with "…", Dürbün → Model wrapped onto two lines. One rule for
//   every select box: "C: mühimmattaki gibi, sığdığı kadar görünür".
// 1. Every closed select box shows its chosen value on ONE line at the
//    normal size, cut with "…" when it does not fit: never wrapped, never
//    scaled down; the box has the standard height, equal to its neighbour.
// 2. Sight height is a half box in the left column (as wide as Sıfırlama
//    mesafesi), the right column empty, Ateşli and PCP; unit mm inside.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/reticle_library.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';
import 'support/select_one_line.dart';

/// (screen width, text scale): the owner's 390 pt phone, the 320 pt SE and
/// the 320 pt SE with larger text.
const _views = [(390.0, 1.0), (320.0, 1.0), (320.0, 1.3)];

const _scopeModel = 'SH-4J GENII 6–24×50 FFP VPR (MRAD)';
const _ammoModel = 'Gold Medal Sierra MatchKing 168 gr Sierra MatchKing BTHP';

void _setView(WidgetTester tester, double width, double textScale) {
  tester.view.physicalSize = Size(width * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _openNew(
  WidgetTester tester, {
  required bool firearm,
  required double width,
  required double textScale,
}) async {
  _setView(tester, width, textScale);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(
    tester,
    'profile-platform',
    firearm ? 'Ateşli Tüfek' : 'PCP Tüfek',
  );
}

Finder _key(String key) => find.byKey(Key(key));

Finder _in(String key, Finder f) => find.descendant(of: _key(key), matching: f);

/// The standard box height: Tür, a select with a short value.
double _standard(WidgetTester tester) =>
    selectBox(tester, 'profile-platform').height;

/// Beretta BRX1 / .30-06 Springfield, as on the owner's TestFlight 113.
Future<void> _pickBrx1(WidgetTester tester) async {
  await chooseInSelect(tester, 'rifle-brand-select', 'Beretta');
  await chooseInSelect(tester, 'rifle-model-select', 'BRX1');
  await chooseInSelect(tester, 'rifle-caliber', '.30-06 Springfield');
  expect(selectedValue<String>(tester, 'rifle-caliber'), isNotNull);
}

/// Kalibre: one line, standard height, as tall as Namlu çıkış hızı and on
/// its row (two columns) or right above it (one column).
void _expectCaliber(WidgetTester tester, String name, String where) {
  expectClosedOneLine(
    tester,
    'rifle-caliber',
    name,
    standardHeight: _standard(tester),
    where: where,
  );
  final box = selectBox(tester, 'rifle-caliber');
  final velocity = selectBox(tester, 'profile-velocity-fps');
  expect(
    box.height,
    moreOrLessEquals(velocity.height, epsilon: 0.5),
    reason: '$where: Kalibre $box / Namlu çıkış hızı $velocity',
  );
  final c = tester.getRect(_key('rifle-caliber'));
  final v = tester.getRect(_key('profile-velocity-fps'));
  if (v.left > c.right) {
    expect((v.top - c.top).abs(), lessThanOrEqualTo(0.5), reason: where);
    expect((velocity.top - box.top).abs(), lessThanOrEqualTo(0.5));
  } else {
    expect(v.top, greaterThanOrEqualTo(c.bottom - 0.5), reason: where);
  }
}

/// Sight height: as wide as Sıfırlama mesafesi, in the left column, alone
/// on the last row of the Tüfek card; mm inside the box.
void _expectSightHalf(WidgetTester tester, String where) {
  final sight = tester.getRect(_key('scope-sight-height'));
  final zero = tester.getRect(_key('profile-zero'));
  final unit = tester.getRect(_key('profile-distance-unit'));
  final card = tester.getRect(_key('profile-rifle-form'));
  expect(
    sight.width,
    moreOrLessEquals(zero.width, epsilon: 0.5),
    reason: '$where: $sight / $zero',
  );
  expect(sight.left, moreOrLessEquals(zero.left, epsilon: 0.5));
  expect(sight.top, greaterThanOrEqualTo(zero.bottom - 0.5));
  expect(sight.top, greaterThanOrEqualTo(unit.bottom - 0.5));
  expect(sight.bottom, lessThanOrEqualTo(card.bottom + 0.5));
  final box = selectBox(tester, 'scope-sight-height');
  final zeroBox = selectBox(tester, 'profile-zero');
  expect(box.width, moreOrLessEquals(zeroBox.width, epsilon: 0.5));
  expect(box.height, moreOrLessEquals(zeroBox.height, epsilon: 0.5));
  if (unit.left > zero.right) {
    // Two columns: the right column of the last row stays empty.
    expect(sight.right, lessThan(unit.left), reason: where);
  }
  final mm = tester.getRect(_in('scope-sight-height', find.text('mm')));
  expect(mm.right, lessThanOrEqualTo(box.right), reason: '$where: mm $mm');
  expect(mm.left, greaterThanOrEqualTo(box.left), reason: '$where: mm $mm');
}

void main() {
  for (final (width, scale) in _views) {
    final view = '$width pt, text ×$scale';

    testWidgets('Ateşli: BRX1 .30-06 Springfield one line ($view)', (
      tester,
    ) async {
      await _openNew(tester, firearm: true, width: width, textScale: scale);
      _expectSightHalf(tester, 'new');
      await _pickBrx1(tester);
      _expectCaliber(tester, '.30-06 Springfield', 'BRX1');
      _expectSightHalf(tester, 'BRX1');
      // Marka and Model: one line too.
      final standard = _standard(tester);
      expectClosedOneLine(
        tester,
        'rifle-brand-select',
        'Beretta',
        standardHeight: standard,
      );
      expectClosedOneLine(
        tester,
        'rifle-model-select',
        'BRX1',
        standardHeight: standard,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ateşli: long Kalibre names are cut, typed rifle ($view)', (
      tester,
    ) async {
      await _openNew(tester, firearm: true, width: width, textScale: scale);
      await openRifleManual(tester);
      for (final name in const [
        '.30-06 Springfield',
        '.338-378 Weatherby Mag',
        'Fişeğim listede yok',
      ]) {
        await chooseInSelect(tester, 'rifle-caliber', name);
        _expectCaliber(tester, name, 'typed $name');
      }
      _expectSightHalf(tester, 'typed');
      expect(tester.takeException(), isNull);
    });

    testWidgets('PCP: Kalibre one line, Sight height half ($view)', (
      tester,
    ) async {
      await _openNew(tester, firearm: false, width: width, textScale: scale);
      _expectSightHalf(tester, 'new');
      await chooseInSelect(tester, 'rifle-brand-select', 'Hatsan');
      await chooseInSelect(tester, 'rifle-model-select', 'Hercules');
      await chooseInSelect(tester, 'rifle-caliber', '11.43 mm (.45)');
      _expectCaliber(tester, '11.43 mm (.45)', 'Hercules');
      _expectSightHalf(tester, 'Hercules');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dürbün Model SH-4J GENII and Retikül one line ($view)', (
      tester,
    ) async {
      await _openNew(tester, firearm: true, width: width, textScale: scale);
      await chooseInSelect(tester, 'scope-brand-select', 'Arken Optics');
      await chooseInSelect(tester, 'scope-model-select', _scopeModel);
      expect(selectedValue<String>(tester, 'scope-model-select'), isNotNull);
      final standard = _standard(tester);
      final cut = expectClosedOneLine(
        tester,
        'scope-model-select',
        _scopeModel,
        standardHeight: standard,
        where: 'Dürbün Model',
      );
      // The model box is as tall as the Marka box above it.
      expect(
        selectBox(tester, 'scope-model-select').height,
        moreOrLessEquals(
          selectBox(tester, 'scope-brand-select').height,
          epsilon: 0.5,
        ),
      );
      if (width == 320) expect(cut, isTrue, reason: 'cut with "…"');
      final reticle = selectedValue<String>(tester, 'scope-reticle');
      if (reticle != null) {
        expectClosedOneLine(
          tester,
          'scope-reticle',
          reticle,
          standardHeight: standard,
          where: 'Retikül',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mühimmat Model Federal Gold Medal SMK 168 ($view)', (
      tester,
    ) async {
      await _openNew(tester, firearm: true, width: width, textScale: scale);
      await _pickBrx1(tester);
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await chooseInSelect(tester, 'ammo-brand-select', 'Federal');
      await chooseInSelect(tester, 'ammo-model-select', _ammoModel);
      expect(selectedValue<int>(tester, 'ammo-model-select'), isNotNull);
      final cut = expectClosedOneLine(
        tester,
        'ammo-model-select',
        _ammoModel,
        standardHeight: _standard(tester),
        where: 'Mühimmat Model',
      );
      // Too long for a phone at any of these widths: cut with "…".
      expect(cut, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long Retikül name in a half box, row neighbour ($view)', (
      tester,
    ) async {
      _setView(tester, width, scale);
      // The longest reticle name of the library.
      final name = ([
        for (final r in ReticleLibrary.all) r.name,
      ]..sort((a, b) => b.length.compareTo(a.length))).first;
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MenzilFieldGrid(
                children: [
                  KeyedSubtree(
                    key: const Key('long-reticle'),
                    child: MenzilSelect<String>(
                      label: 'Retikül',
                      initialValue: name,
                      items: [DropdownMenuItem(value: name, child: Text(name))],
                      onChanged: (_) {},
                    ),
                  ),
                  KeyedSubtree(
                    key: const Key('neighbour'),
                    child: MenzilInput(
                      controller: TextEditingController(text: '100'),
                      label: 'Sıfırlama mesafesi',
                      unit: 'm',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final neighbour = selectBox(tester, 'neighbour');
      final cut = expectClosedOneLine(
        tester,
        'long-reticle',
        name,
        standardHeight: neighbour.height,
        where: 'Retikül',
      );
      expect(cut, isTrue, reason: 'a half box is too narrow');
      expect(tester.takeException(), isNull);
    });
  }
}
