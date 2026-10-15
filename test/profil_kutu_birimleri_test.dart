// Profil Oluştur: ölçü birimleri (owner, 2026-10-15 22:54): "Ölçü birimi
// girilecek kutuların içine: Tüfek bölümü — Sight height … mm, Sıfırlama
// mesafesi … m, Namlu çıkış hızı … fps; Mühimmat bölümü — Ağırlık … gr;
// Hıza göre BC kutularına da ölçü birimi gir."
//
// Each unit is the one the code reads the typed value in: Sight height is
// stored as sightHeightMm, Namlu çıkış hızı and the eşik hızı boxes are read
// as fps (UnitSystem.fpsToMps), Ağırlık as grain, and Sıfırlama mesafesi in
// the chosen Mesafe birimi (metres while it is still "Seçiniz"). Eşik altı
// BC has no unit.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

Future<void> _openNew(
  WidgetTester tester, {
  double width = 430,
  double scale = 1.0,
}) async {
  tester.view.physicalSize = Size(width * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ProfilesScreen(store: MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
}

/// The unit shown with the box under [key] (null when it has none).
String? _unit(WidgetTester tester, String key) => tester
    .widget<MenzilInput>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(MenzilInput),
        matchRoot: true,
      ),
    )
    .unit;

/// The unit text is on screen inside the box's own width.
void _expectUnitInside(WidgetTester tester, String key, String unit) {
  final box = find.byKey(Key(key));
  final text = find.descendant(of: box, matching: find.text(unit));
  expect(text, findsOneWidget, reason: '$key: $unit');
  final b = tester.getRect(box);
  final t = tester.getRect(text);
  expect(t.left, greaterThanOrEqualTo(b.left - 0.5), reason: key);
  expect(t.right, lessThanOrEqualTo(b.right + 0.5), reason: key);
}

const _rifleUnits = {
  'scope-sight-height': 'mm',
  'profile-zero': 'm',
  'profile-velocity-fps': 'fps',
};

void main() {
  group('Tüfek', () {
    testWidgets('Sight height mm, Sıfırlama mesafesi m, Namlu çıkış hızı fps', (
      tester,
    ) async {
      await _openNew(tester);
      // Mesafe birimi still "Seçiniz": the zero is read as metres.
      expect(
        selectedValue<DistanceUnit>(tester, 'profile-distance-unit'),
        isNull,
      );
      for (final e in _rifleUnits.entries) {
        expect(_unit(tester, e.key), e.value, reason: e.key);
        _expectUnitInside(tester, e.key, e.value);
      }
    });

    testWidgets('Sıfırlama mesafesi follows Mesafe birimi: yd, then m', (
      tester,
    ) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'profile-distance-unit', 'Yard');
      expect(_unit(tester, 'profile-zero'), 'yd');
      _expectUnitInside(tester, 'profile-zero', 'yd');
      await chooseInSelect(tester, 'profile-distance-unit', 'Metre');
      expect(_unit(tester, 'profile-zero'), 'm');
      _expectUnitInside(tester, 'profile-zero', 'm');
      // Other units do not change with it.
      expect(_unit(tester, 'scope-sight-height'), 'mm');
      expect(_unit(tester, 'profile-velocity-fps'), 'fps');
    });
  });

  group('Mühimmat', () {
    testWidgets('typed Ağırlık shows gr', (tester) async {
      await _openNew(tester);
      // PCP round typed by hand: the plain Ağırlık box.
      await fillRifleForm(tester);
      await fillAmmoForm(tester);
      expect(_unit(tester, 'ammo-grain'), 'gr');
      _expectUnitInside(tester, 'ammo-grain', 'gr');
    });

    testWidgets('Hıza göre BC: eşik hızı fps, Eşik altı BC no unit', (
      tester,
    ) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      for (var i = 0; i < 2; i++) {
        expect(_unit(tester, 'ammo-band-fps-$i'), 'fps');
        _expectUnitInside(tester, 'ammo-band-fps-$i', 'fps');
        expect(_unit(tester, 'ammo-band-bc-$i'), isNull);
      }
    });
  });

  // A 4-digit value with the unit fits the box on narrow phones and with
  // large text.
  for (final width in const [320.0, 390.0]) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('no overflow at $width pt, text scale $scale', (
        tester,
      ) async {
        await _openNew(tester, width: width, scale: scale);
        await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
        await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
        await chooseInSelect(tester, 'profile-distance-unit', 'Yard');
        final units = {
          ..._rifleUnits,
          'profile-zero': 'yd',
          'ammo-band-fps-0': 'fps',
          'ammo-band-fps-1': 'fps',
        };
        for (final e in units.entries) {
          await enterRifleField(tester, e.key, '1234');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: e.key);
          _expectUnitInside(tester, e.key, e.value);
          final field = find.descendant(
            of: find.byKey(Key(e.key)),
            matching: find.byType(TextField),
          );
          expect(
            tester.widget<TextField>(field).controller!.text,
            '1234',
            reason: e.key,
          );
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('typed Ağırlık: no overflow at $width pt, scale $scale', (
        tester,
      ) async {
        await _openNew(tester, width: width, scale: scale);
        await fillRifleForm(tester);
        await fillAmmoForm(tester, grain: '1234');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        _expectUnitInside(tester, 'ammo-grain', 'gr');
      });
    }
  }
}
