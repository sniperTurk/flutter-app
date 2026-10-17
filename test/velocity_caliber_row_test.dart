// Owner, 2026-10-16 20:49–21:04 (Profil Oluştur / Profili Düzenle > Tüfek,
// approved drawing): the first row under Marka, Model and the "listede yok"
// link is Kalibre | Namlu çıkış hızı, PCP and Ateşli Tüfek alike (Namlu
// çıkış hızı stays on the Tüfek card for a PCP). This supersedes the
// 2026-10-14 18:56–18:58 layout (Kalibre alone, Sıfırlama mesafesi | Namlu
// çıkış hızı last), which this file pinned before. A long caliber stays on
// ONE line in its box, scaled down when it does not fit, and the box keeps
// the height of Namlu çıkış hızı (owner, 2026-10-17 17:54–17:57: "kalibre
// kutusu tek satır olacaktı"; it wrapped and grew before).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

/// Screen widths: a large phone, iPhone SE (2nd/3rd gen) and the 320 pt
/// first-generation SE.
const _wide = 430.0;
const _se = 375.0;
const _narrowest = 320.0;

Future<void> _openNew(
  WidgetTester tester, {
  required bool firearm,
  required double width,
  double textScale = 1.0,
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

/// Kalibre | Namlu çıkış hızı on the first row under Model when the card
/// has two columns (Kalibre left), Namlu çıkış hızı right under Kalibre when
/// it has one. Nothing else on that row; every box inside the rifle card.
void _expectLayout(WidgetTester tester) {
  final card = tester.getRect(_key('profile-rifle-form'));
  final model = tester.getRect(_key('rifle-model-select'));
  final c = tester.getRect(_key('rifle-caliber'));
  final v = tester.getRect(_key('profile-velocity-fps'));
  expect(c.top, greaterThanOrEqualTo(model.bottom));
  expect((c.left - model.left).abs(), lessThan(1));
  for (final r in [c, v]) {
    expect(r.left, greaterThanOrEqualTo(card.left));
    expect(r.right, lessThanOrEqualTo(card.right + 0.5));
  }
  if (c.width < model.width * 0.75) {
    // Two columns: Kalibre | Namlu çıkış hızı.
    expect((v.top - c.top).abs(), lessThanOrEqualTo(1), reason: '$c / $v');
    expect(c.right, lessThan(v.left));
    expect((v.width - c.width).abs(), lessThan(1));
  } else {
    // One column: Namlu çıkış hızı right under Kalibre.
    expect(v.top, greaterThanOrEqualTo(c.bottom - 0.5));
  }
  // Yiv oranı starts the next row, under both.
  final twist = tester.getRect(_key('rifle-twist-rate'));
  expect(twist.top, greaterThanOrEqualTo(c.bottom - 0.5));
  expect(twist.top, greaterThanOrEqualTo(v.bottom - 0.5));
}

/// The closed Kalibre box shows [text] whole on ONE line (scaled down when
/// it does not fit, never wrapped or cut), inside the box, which is as tall
/// as Namlu çıkış hızı (owner, 2026-10-17).
void _expectOneLine(WidgetTester tester, String text) {
  expect(
    _in('rifle-caliber', find.byKey(const Key('menzil-select-wrapped'))),
    findsNothing,
  );
  final fit = _in('rifle-caliber', find.byType(MenzilFitText));
  expect(fit, findsOneWidget);
  final shown = find.descendant(of: fit, matching: find.byType(Text));
  final t = tester.widget<Text>(shown);
  expect(t.data, text);
  final p = tester.renderObject<RenderParagraph>(shown);
  expect(p.maxLines, 1);
  expect(p.overflow, isNot(TextOverflow.ellipsis));
  expect(p.didExceedMaxLines, isFalse);
  final rect = tester.getRect(shown);
  final box = tester.getRect(_in('rifle-caliber', find.byType(InputDecorator)));
  expect(rect.left, greaterThanOrEqualTo(box.left));
  expect(rect.right, lessThanOrEqualTo(box.right));
  expect(rect.top, greaterThanOrEqualTo(box.top));
  expect(rect.bottom, lessThanOrEqualTo(box.bottom));
  final v = tester.getRect(
    _in('profile-velocity-fps', find.byType(InputDecorator)).first,
  );
  expect(box.height, moreOrLessEquals(v.height, epsilon: 0.5));
}

/// Picks [label] in the open Kalibre list. The list is as wide as the box
/// (#273); with the test font at 320 pt and ×1.3 its entries may wrap onto
/// several lines, so the list is scrolled until the entry shows instead of
/// the shared helper's fixed number of drags.
Future<void> _pickInLongList(WidgetTester tester, String label) async {
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
  // Built is not shown: bring the entry into the list's visible part.
  await tester.ensureVisible(inMenu.last);
  await tester.pumpAndSettle();
  // The entry grows with its wrapped text (MenzilSelect.itemHeight null):
  // the whole text lies inside its own row, so a finger anywhere on it
  // picks it. With Flutter's fixed 48 pt rows the 1-em test font at 320 pt
  // × 1.3 drew ".338-378 Weatherby Mag" 120 pt high in a 48 pt row and a
  // tap on its centre chose nothing (run 38442566759).
  final row = tester.getRect(
    find
        .ancestor(
          of: inMenu.last,
          matching: find.byWidgetPredicate(
            (w) =>
                w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
          ),
        )
        .first,
  );
  final text = tester.getRect(inMenu.last);
  expect(row.top, lessThanOrEqualTo(text.top + 0.5), reason: '$row / $text');
  expect(row.bottom, greaterThanOrEqualTo(text.bottom - 0.5));
  expect(inMenu.last.hitTestable(), findsOneWidget);
  await tester.tap(inMenu.last);
  await tester.pumpAndSettle();
}

void main() {
  for (final firearm in [false, true]) {
    final kind = firearm ? 'Ateşli Tüfek' : 'PCP';
    for (final (width, textScale) in [
      (_wide, 1.0),
      (_se, 1.0),
      (_se, 1.3),
      (_narrowest, 1.0),
      (_narrowest, 1.3),
    ]) {
      testWidgets('$kind: Kalibre | Namlu çıkış hızı '
          '(width $width, text ×$textScale)', (tester) async {
        await _openNew(
          tester,
          firearm: firearm,
          width: width,
          textScale: textScale,
        );
        _expectLayout(tester);
        if (firearm) {
          // The longest cartridge name of the list.
          await _pickInLongList(tester, '.338-378 Weatherby Mag');
          _expectOneLine(tester, '.338-378 Weatherby Mag');
        } else {
          // The owner's screenshot: Hatsan Hercules.
          await chooseInSelect(tester, 'rifle-brand-select', 'Hatsan');
          await chooseInSelect(tester, 'rifle-model-select', 'Hercules');
          await chooseInSelect(tester, 'rifle-caliber', '11.43 mm (.45)');
          _expectOneLine(tester, '11.43 mm (.45)');
        }
        _expectLayout(tester);
        // A velocity error stays in its own box; the layout holds.
        await enterRifleField(tester, 'profile-velocity-fps', '6000');
        await tester.pumpAndSettle();
        final error = _in(
          'profile-velocity-fps',
          find.text('100–4900 arasında bir değer girin.'),
        );
        expect(error, findsOneWidget);
        final e = tester.getRect(error);
        final v = tester.getRect(_key('profile-velocity-fps'));
        expect(e.left, greaterThanOrEqualTo(v.left));
        expect(e.right, lessThanOrEqualTo(v.right + 0.5));
        _expectLayout(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final (width, textScale) in [
    (_wide, 1.0),
    (_se, 1.3),
    (_narrowest, 1.3),
  ]) {
    testWidgets(
      'Fişeğim listede yok shows whole; Mermi çapı takes the row below '
      '(width $width, text ×$textScale)',
      (tester) async {
        await _openNew(
          tester,
          firearm: true,
          width: width,
          textScale: textScale,
        );
        // The last item of the long list.
        await _pickInLongList(tester, 'Fişeğim listede yok');
        _expectLayout(tester);
        _expectOneLine(tester, 'Fişeğim listede yok');
        final c = tester.getRect(_key('rifle-caliber'));
        final v = tester.getRect(_key('profile-velocity-fps'));
        final model = tester.getRect(_key('rifle-model-select'));
        final d = tester.getRect(_key('rifle-bullet-diameter'));
        // Full width, under the Kalibre | Namlu çıkış hızı row.
        expect(d.top, greaterThanOrEqualTo(c.bottom));
        expect(d.top, greaterThanOrEqualTo(v.bottom));
        expect((d.left - model.left).abs(), lessThan(1));
        expect((d.width - model.width).abs(), lessThan(1));
        // Yiv oranı comes after Mermi çapı.
        final twist = tester.getRect(_key('rifle-twist-rate'));
        expect(twist.top, greaterThanOrEqualTo(d.bottom - 0.5));
        await chooseInSelect(
          tester,
          'rifle-bullet-diameter',
          '.308 in · 7,82 mm',
        );
        _expectLayout(tester);
        _expectOneLine(tester, 'Fişeğim listede yok');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a wide box shows the full cartridge name', (tester) async {
    await _openNew(tester, firearm: true, width: _wide);
    await chooseInSelect(tester, 'rifle-caliber', '.300 Win Mag');
    expect(_in('rifle-caliber', find.text('.300 Win Mag')), findsOneWidget);
    await chooseInSelect(tester, 'rifle-caliber', '6.5 Creedmoor');
    expect(_in('rifle-caliber', find.text('6.5 Creedmoor')), findsOneWidget);
  });
}
