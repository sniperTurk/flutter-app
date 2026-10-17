// Owner, 2026-10-17 17:54–17:57 (TestFlight 113, Profil Oluştur > Tüfek,
// Ateşli Tüfek, Beretta BRX1: ".30-06 Springfield" filled two lines and
// made the Kalibre | Namlu çıkış hızı row taller; Sight height was a full
// width box alone on the last row):
//   "Ateşli tüfek kalibre kutusu tek satır olacaktı; kalibre isimleri uzun,
//    kutu taşma yapıyor." · "Sight height gereksiz, aşağıda büyük kutusu
//    var." → "Tabiki A" (Sight height half width).
// 1. The closed Kalibre box (Ateşli and PCP, list and typed rifle) shows the
//    FULL chosen name on ONE line, scaled down when it does not fit: never
//    wrapped, never cut with "…"; the box is as tall as Namlu çıkış hızı.
// 2. Sight height is a half box in the left column (as wide as Sıfırlama
//    mesafesi), the right column empty.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

const _cartridges = [
  '.30-06 Springfield',
  '.375 H&H Mag',
  '6.5 Creedmoor',
  '7.62x51 NATO',
];

/// (screen width, text scale): the owner's 390 pt phone, the 320 pt SE and
/// the 320 pt SE with larger text.
const _views = [(390.0, 1.0), (320.0, 1.0), (320.0, 1.3)];

Future<void> _openNew(
  WidgetTester tester, {
  required bool firearm,
  required double width,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

/// The bordered box of the field [key] (without its label row).
Rect _box(WidgetTester tester, String key) =>
    tester.getRect(_in(key, find.byType(InputDecorator)).first);

/// Picks [label] in the open (long) Kalibre list, scrolling until it shows.
Future<void> _pickCaliber(WidgetTester tester, String label) async {
  await tester.ensureVisible(_key('rifle-caliber'));
  await tester.tap(_key('rifle-caliber'));
  await tester.pumpAndSettle();
  final inMenu = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
    ),
    matching: find.text(label),
  );
  await tester.dragUntilVisible(
    inMenu,
    find.byType(Scrollable).last,
    const Offset(0, -300),
    maxIteration: 400,
  );
  await tester.ensureVisible(inMenu.last);
  await tester.pumpAndSettle();
  await tester.tap(inMenu.last);
  await tester.pumpAndSettle();
}

/// The closed Kalibre box shows [name] whole on one line (scaled down if
/// needed, never wrapped or cut), inside the box and left of its arrow;
/// the box is as tall as Namlu çıkış hızı.
void _expectOneLine(WidgetTester tester, String name, String where) {
  expect(
    _in('rifle-caliber', find.byKey(const Key('menzil-select-wrapped'))),
    findsNothing,
    reason: '$where: wrapped text',
  );
  final fit = _in('rifle-caliber', find.byType(MenzilFitText));
  expect(fit, findsOneWidget, reason: where);
  expect(tester.widget<MenzilFitText>(fit).text, name, reason: where);
  final shown = find.descendant(of: fit, matching: find.byType(Text));
  expect(shown, findsOneWidget, reason: where);
  // The full name, not a short form.
  expect(tester.widget<Text>(shown).data, name, reason: where);
  final p = tester.renderObject<RenderParagraph>(shown);
  expect(p.maxLines, 1, reason: where);
  expect(p.softWrap, isFalse, reason: where);
  expect(p.overflow, isNot(TextOverflow.ellipsis), reason: '$where: "…"');
  expect(p.didExceedMaxLines, isFalse, reason: '$where: cut');
  final box = _box(tester, 'rifle-caliber');
  final text = tester.getRect(shown);
  expect(text.left, greaterThanOrEqualTo(box.left), reason: '$where $text');
  expect(text.top, greaterThanOrEqualTo(box.top), reason: '$where $text');
  expect(text.bottom, lessThanOrEqualTo(box.bottom), reason: '$where $text');
  final arrow = tester.getRect(
    _in('rifle-caliber', find.byIcon(Icons.expand_more)),
  );
  expect(
    text.right,
    lessThanOrEqualTo(arrow.left + 0.5),
    reason: '$where: under the arrow $text / $arrow',
  );
  final velocity = _box(tester, 'profile-velocity-fps');
  expect(
    box.height,
    moreOrLessEquals(velocity.height, epsilon: 0.5),
    reason: '$where: Kalibre $box / Namlu çıkış hızı $velocity',
  );
  // Same row (two columns) or Namlu çıkış hızı right under it (one).
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
/// on the last row of the Tüfek card.
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
  final box = _box(tester, 'scope-sight-height');
  final zeroBox = _box(tester, 'profile-zero');
  expect(box.width, moreOrLessEquals(zeroBox.width, epsilon: 0.5));
  expect(box.height, moreOrLessEquals(zeroBox.height, epsilon: 0.5));
  if (unit.left > zero.right) {
    // Two columns: the right column of the last row stays empty.
    expect(sight.right, lessThan(unit.left), reason: where);
  }
  expect(
    tester.widget<Text>(_in('scope-sight-height', find.text('mm'))).data,
    'mm',
  );
}

void main() {
  for (final (width, scale) in _views) {
    final view = '$width pt, text ×$scale';

    testWidgets('Ateşli: Kalibre one line, Sight height half ($view)', (
      tester,
    ) async {
      await _openNew(tester, firearm: true, width: width, textScale: scale);
      _expectSightHalf(tester, 'new');
      for (final name in _cartridges) {
        await _pickCaliber(tester, name);
        expect(selectedValue<String>(tester, 'rifle-caliber'), name);
        _expectOneLine(tester, name, 'list $name');
      }
      _expectSightHalf(tester, 'list');
      // The typed rifle ("Aradığın tüfek listede yok mu?"): same box.
      await openRifleManual(tester);
      for (final name in _cartridges) {
        await _pickCaliber(tester, name);
        _expectOneLine(tester, name, 'typed $name');
      }
      _expectSightHalf(tester, 'typed');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ateşli: Beretta BRX1 .30-06 Springfield ($view)', (
      tester,
    ) async {
      await _openNew(tester, firearm: true, width: width, textScale: scale);
      await chooseInSelect(tester, 'rifle-brand-select', 'Beretta');
      await chooseInSelect(tester, 'rifle-model-select', 'BRX1');
      await chooseInSelect(tester, 'rifle-caliber', '.30-06 Springfield');
      _expectOneLine(tester, '.30-06 Springfield', 'BRX1');
      _expectSightHalf(tester, 'BRX1');
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
      _expectOneLine(tester, '11.43 mm (.45)', 'Hercules');
      _expectSightHalf(tester, 'Hercules');
      await openRifleManual(tester);
      for (final name in ['18.29 mm (.72)', '4.50 mm (.177)']) {
        await chooseInSelect(tester, 'rifle-caliber', name);
        _expectOneLine(tester, name, 'typed $name');
      }
      _expectSightHalf(tester, 'typed');
      expect(tester.takeException(), isNull);
    });
  }
}
