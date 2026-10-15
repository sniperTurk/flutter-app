// Owner, 2026-10-15 22:56 Istanbul (Profil Oluştur): "Ölçü birimi girilecek
// kutu içleri: Sight height … mm, Sıfırlama mesafesi … m, Namlu çıkış hızı …
// fps, Ağırlık … gr. Hıza göre BC kutularına da ölçü birimi gir."
// Each box gets its unit through MenzilInput `unit:`, shown the same way as
// the existing Hız ölçüm sıcaklığı °C and PCP 1. hız fps (right end of the
// box's own label row, above the text field). Sıfırlama mesafesi follows
// Mesafe birimi (m / yd). Eşik altı BC stays without a unit (BC has none;
// temiz tasarım: "Eşik altı BC birimsiz").
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

Future<void> _openNew(
  WidgetTester tester, {
  double width = 430,
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
}

Finder _in(String key, Finder f) =>
    find.descendant(of: find.byKey(Key(key)), matching: f);

/// The box's own label row (label left, unit right, above the text field).
Finder _labelRow(String key) => _in(key, find.byType(MenzilFieldLabel));

/// The unit shown with [key]'s box, or null.
String? _unitText(WidgetTester tester, String key) {
  final f = _labelRow(key);
  if (f.evaluate().isEmpty) return null;
  return tester.widget<MenzilFieldLabel>(f).unit;
}

Finder _unitFinder(String key, String unit) =>
    find.descendant(of: _labelRow(key), matching: find.text(unit));

/// Ateşli Tüfek, .308 Win, Fabrika fişeği: Hıza göre BC is shown.
Future<void> _firearm308(WidgetTester tester) async {
  await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
  await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
  await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
}

/// PCP, 5.50 mm (.22): the typed Ağırlık box is shown.
Future<void> _pcp(WidgetTester tester) async {
  await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
  await chooseInSelect(tester, 'rifle-caliber', '5.50 mm (.22)');
}

/// The app's system-font names loaded with the bundled Inter files as a
/// width stand-in (as test/ekran_boyutu_test.dart does): the default test
/// font draws every letter as a square and reports cuts a phone never has.
Future<void> _loadAppFont() async {
  final files = Directory('assets/fonts')
      .listSync()
      .whereType<File>()
      .where((f) {
        final name = f.uri.pathSegments.last;
        return name.startsWith('Inter-') &&
            (name.endsWith('.ttf') || name.endsWith('.otf'));
      })
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

/// [key] shows [unit] at the right end of its label row, over the box; the
/// label is whole (never "…") and the typed [value] fits the box.
void _expectUnit(
  WidgetTester tester,
  String key,
  String unit, {
  required String label,
  required String value,
}) {
  expect(_unitText(tester, key), unit, reason: key);
  final row = tester.widget<MenzilFieldLabel>(_labelRow(key));
  expect(row.label, label, reason: key);
  final box = tester.getRect(_in(key, find.byType(InputDecorator)));
  final unitFinder = _unitFinder(key, unit);
  expect(unitFinder, findsOneWidget, reason: key);
  final u = tester.getRect(unitFinder);
  expect(u.left, greaterThanOrEqualTo(box.left), reason: '$key $u / $box');
  expect(u.right, lessThanOrEqualTo(box.right), reason: '$key $u / $box');
  expect(u.bottom, lessThanOrEqualTo(box.top + 0.5), reason: '$key $u / $box');
  expect(
    tester.renderObject<RenderParagraph>(unitFinder).didExceedMaxLines,
    isFalse,
    reason: '$key unit cut',
  );
  // The label: whole, left of the unit.
  final labelText = find.descendant(
    of: _labelRow(key),
    matching: find.text(label),
  );
  expect(labelText, findsOneWidget, reason: key);
  expect(
    tester.renderObject<RenderParagraph>(labelText).didExceedMaxLines,
    isFalse,
    reason: '$key label cut to "…"',
  );
  expect(
    tester.getRect(labelText).left,
    lessThan(u.left),
    reason: '$key label / unit',
  );
  // The typed value fits the text area.
  final editable = _in(key, find.byType(EditableText));
  final field = tester.widget<EditableText>(editable);
  expect(field.controller.text, value, reason: key);
  final painter = TextPainter(
    text: TextSpan(text: value, style: field.style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(tester.element(editable)),
    maxLines: 1,
  )..layout();
  final input = tester.getRect(editable);
  expect(
    input.width,
    greaterThanOrEqualTo(painter.width),
    reason: '$key: "$value" needs ${painter.width}, has ${input.width}',
  );
  painter.dispose();
}

void main() {
  setUpAll(_loadAppFont);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('Tüfek: Sight height mm, Sıfırlama m, Namlu çıkış hızı fps', (
    tester,
  ) async {
    await _openNew(tester);
    await _firearm308(tester);
    expect(_unitText(tester, 'scope-sight-height'), 'mm');
    expect(_unitText(tester, 'profile-zero'), 'm');
    expect(_unitText(tester, 'profile-velocity-fps'), 'fps');
    // Labels unchanged.
    expect(_in('scope-sight-height', find.text('Sight height')), findsWidgets);
    expect(
      _in('profile-zero', find.text('Sıfırlama mesafesi')),
      findsWidgets,
    );
    expect(
      _in('profile-velocity-fps', find.text('Namlu çıkış hızı')),
      findsWidgets,
    );
  });

  testWidgets('Sıfırlama mesafesi: m, then yd for Yard, then m for Metre', (
    tester,
  ) async {
    await _openNew(tester);
    await _firearm308(tester);
    // Nothing chosen yet: "m".
    expect(selectedValue<DistanceUnit>(tester, 'profile-distance-unit'), isNull);
    expect(_unitText(tester, 'profile-zero'), 'm');
    await enterRifleField(tester, 'profile-zero', '100');
    await chooseInSelect(tester, 'profile-distance-unit', 'Yard');
    expect(_unitText(tester, 'profile-zero'), 'yd');
    // The stored value converts as before (100 m = 109.4 yd).
    expect(
      tester
          .widget<TextField>(_in('profile-zero', find.byType(TextField)))
          .controller!
          .text,
      '109.4',
    );
    await chooseInSelect(tester, 'profile-distance-unit', 'Metre');
    expect(_unitText(tester, 'profile-zero'), 'm');
  });

  testWidgets('Mühimmat Ağırlık (typed) shows gr', (tester) async {
    await _openNew(tester);
    await _pcp(tester);
    expect(_unitText(tester, 'ammo-grain'), 'gr');
    expect(_in('ammo-grain', find.text('Ağırlık')), findsWidgets);
  });

  testWidgets('Ağırlık list items already show "gr"; values unchanged', (
    tester,
  ) async {
    await _openNew(tester);
    await _firearm308(tester);
    await openAmmoManual(tester);
    final select = tester.widget<MenzilSelect<double>>(
      _in('ammo-grain-select', find.byType(MenzilSelect<double>)),
    );
    final weights = [
      for (final i in select.items)
        if ((i.child as Text).data != 'Listede yok') i,
    ];
    expect(weights, isNotEmpty);
    for (final i in weights) {
      final label = (i.child as Text).data!;
      expect(label, startsWith('${_num(i.value!)} gr ('), reason: label);
    }
  });

  testWidgets('Hıza göre BC: eşik hızı fps, Eşik altı BC without a unit', (
    tester,
  ) async {
    await _openNew(tester);
    await _firearm308(tester);
    for (var i = 0; i < 2; i++) {
      expect(_unitText(tester, 'ammo-band-fps-$i'), 'fps');
      expect(
        _in('ammo-band-fps-$i', find.text('${i + 1}. eşik hızı')),
        findsWidgets,
      );
      expect(_unitText(tester, 'ammo-band-bc-$i'), isNull);
    }
  });

  for (final width in const [320.0, 390.0]) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('Ateşli: no overflow, label and value whole: '
          '$width pt × $scale', (tester) async {
        await _openNew(tester, width: width, textScale: scale);
        await _firearm308(tester);
        await chooseInSelect(tester, 'profile-distance-unit', 'Yard');
        const values = {
          'scope-sight-height': ('Sight height', 'mm', '50'),
          'profile-zero': ('Sıfırlama mesafesi', 'yd', '100'),
          'profile-velocity-fps': ('Namlu çıkış hızı', 'fps', '2700'),
          'ammo-band-fps-0': ('1. eşik hızı', 'fps', '2500'),
          'ammo-band-fps-1': ('2. eşik hızı', 'fps', '2000'),
        };
        for (final e in values.entries) {
          await enterRifleField(tester, e.key, e.value.$3);
        }
        await tester.pumpAndSettle();
        for (final e in values.entries) {
          await tester.ensureVisible(find.byKey(Key(e.key)));
          await tester.pumpAndSettle();
          _expectUnit(
            tester,
            e.key,
            e.value.$2,
            label: e.value.$1,
            value: e.value.$3,
          );
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('PCP Ağırlık: no overflow, label and value whole: '
          '$width pt × $scale', (tester) async {
        await _openNew(tester, width: width, textScale: scale);
        await _pcp(tester);
        await enterRifleField(tester, 'ammo-grain', '33,95');
        await tester.ensureVisible(find.byKey(const Key('ammo-grain')));
        await tester.pumpAndSettle();
        _expectUnit(
          tester,
          'ammo-grain',
          'gr',
          label: 'Ağırlık',
          value: '33,95',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

String _num(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toString().replaceAll('.', ',');
