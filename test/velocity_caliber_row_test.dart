// Owner, 2026-10-13 (TestFlight, Profil Oluştur > Tüfek, PCP Hatsan
// Hercules): "Namlu çıkış hızı, Kalibre tek sütun olmasın, her satır 2 kutu
// olsun." Namlu çıkış hızı (left) and Kalibre (right) share ONE row for PCP
// and Ateşli Tüfek, at every width and text size, and a long caliber stays
// on one readable line inside its half-width box.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

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

/// Velocity left, Kalibre right, same row; their boxes line up too.
void _expectOneRow(WidgetTester tester) {
  final v = tester.getRect(_key('profile-velocity-fps'));
  final c = tester.getRect(_key('rifle-caliber'));
  expect((v.top - c.top).abs(), lessThanOrEqualTo(1), reason: '$v / $c');
  expect(v.right, lessThan(c.left));
  expect((v.width - c.width).abs(), lessThan(1));
  // Both boxes inside the rifle card.
  final card = tester.getRect(_key('profile-rifle-form'));
  expect(v.left, greaterThanOrEqualTo(card.left));
  expect(c.right, lessThanOrEqualTo(card.right));
  // The text box and the list box start at the same height.
  final field = tester.getRect(_in('profile-velocity-fps', find.byType(TextField)));
  final select = tester.getRect(
    _in('rifle-caliber', find.byType(InputDecorator)),
  );
  expect((field.top - select.top).abs(), lessThanOrEqualTo(1));
  // Marka and Model keep their own full rows above.
  final model = tester.getRect(_key('rifle-model-select'));
  expect(v.top, greaterThanOrEqualTo(model.bottom));
  expect(model.width, greaterThan(v.width * 1.8));
}

/// The closed Kalibre box shows [full] or its [short] form on one line,
/// inside the box, at a readable size (from iPhone SE's 375 pt up; the
/// 320 pt phone only has to fit).
void _expectFits(WidgetTester tester, String full, String short) {
  final shown = _in(
    'rifle-caliber',
    find.byWidgetPredicate(
      (w) => w is Text && (w.data == full || w.data == short),
    ),
  );
  expect(shown, findsOneWidget, reason: 'closed box shows $full / $short');
  final rect = tester.getRect(shown);
  final box = tester.getRect(_in('rifle-caliber', find.byType(InputDecorator)));
  expect(rect.left, greaterThanOrEqualTo(box.left));
  expect(rect.right, lessThanOrEqualTo(box.right));
  expect(rect.top, greaterThanOrEqualTo(box.top));
  expect(rect.bottom, lessThanOrEqualTo(box.bottom));
  final paragraph = tester.renderObject<RenderParagraph>(shown);
  // One line, not cut with "…".
  expect(paragraph.maxLines, 1);
  expect(paragraph.didExceedMaxLines, isFalse);
  // Shown font size: 15 pt × text scale × the fit scale.
  final scale = rect.width / paragraph.size.width;
  final textScale = tester.platformDispatcher.textScaleFactor;
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  expect(
    15 * textScale * scale,
    greaterThanOrEqualTo(width >= _se ? 10 : 7),
    reason: '$full at ${width}pt',
  );
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
      testWidgets(
        '$kind: Namlu çıkış hızı | Kalibre on one row '
        '(width $width, text ×$textScale)',
        (tester) async {
          await _openNew(
            tester,
            firearm: firearm,
            width: width,
            textScale: textScale,
          );
          _expectOneRow(tester);
          if (firearm) {
            // The longest cartridge name of the list.
            await chooseInSelect(
              tester,
              'rifle-caliber',
              '.338-378 Weatherby Mag',
            );
            _expectFits(tester, '.338-378 Weatherby Mag', '.338-378 Wby Mag');
          } else {
            // The owner's screenshot: Hatsan Hercules.
            await chooseInSelect(tester, 'rifle-brand-select', 'Hatsan');
            await chooseInSelect(tester, 'rifle-model-select', 'Hercules');
            await chooseInSelect(tester, 'rifle-caliber', '11.43 mm (.45)');
            _expectFits(tester, '11.43 mm (.45)', '11.43 mm (.45)');
          }
          _expectOneRow(tester);
          // A velocity error stays in the left box; the row holds.
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
          _expectOneRow(tester);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final (width, textScale) in [(_wide, 1.0), (_se, 1.3), (_narrowest, 1.3)]) {
    testWidgets(
      'Fişeğim listede yok fits the half box; Mermi çapı takes the row below '
      '(width $width, text ×$textScale)',
      (tester) async {
        await _openNew(
          tester,
          firearm: true,
          width: width,
          textScale: textScale,
        );
        await chooseInSelect(tester, 'rifle-caliber', 'Fişeğim listede yok');
        _expectOneRow(tester);
        _expectFits(tester, 'Fişeğim listede yok', 'Listede yok');
        final c = tester.getRect(_key('rifle-caliber'));
        final d = tester.getRect(_key('rifle-bullet-diameter'));
        expect(d.top, greaterThanOrEqualTo(c.bottom));
        final card = tester.getRect(_key('profile-rifle-form'));
        expect(d.width, greaterThan(card.width * 0.8));
        await chooseInSelect(
          tester,
          'rifle-bullet-diameter',
          '.308 in · 7,82 mm',
        );
        _expectOneRow(tester);
        _expectFits(tester, 'Fişeğim listede yok', 'Listede yok');
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
