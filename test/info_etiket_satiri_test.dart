// ⓘ at the right end of the label row, units inside the box (owner,
// 2026-10-17 11:18–11:21 Istanbul: "Hayır fps bar kutu içi, infolar sağ
// üst"). Every MenzilInput / MenzilSelect, regular and compact (PCP
// Mühimmat, Hava Durumu): the ⓘ is outside the box, in the label row, its
// right edge on the box's right edge, its centre on the label text; the
// unit is inside the box at its right and not in the label row. The boxes
// inside the Pro Ayarlar sections have no ⓘ (owner, 2026-10-16 21:17).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';
import 'support/rifle_form.dart';
import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

void _size(WidgetTester tester, double width, double textScale) {
  tester.view.physicalSize = Size(width * 3, 3200 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _openProfile(
  WidgetTester tester, {
  required bool pcp,
  double width = 390,
  double textScale = 1.0,
}) async {
  _size(tester, width, textScale);
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
    pcp ? 'PCP Tüfek' : 'Ateşli Tüfek',
  );
}

Future<void> _openBallistics(
  WidgetTester tester,
  BallisticsView view, {
  double width = 390,
  double textScale = 1.0,
}) async {
  _size(tester, width, textScale);
  final services = testServices(
    location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
    weather: TestWeather(observation(fetchedAt: DateTime.utc(2026, 10, 12))),
    pressure: TestPressure(const PressureRead(912.4)),
    clock: TestClock(DateTime(2026, 10, 14, 11, 20)),
  );
  await tester.pumpWidget(
    host(
      Scaffold(
        body: BallisticsScreen(profile: _profile, view: view),
      ),
      services: services,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

/// The field's box: the text field or the closed list.
Rect _box(WidgetTester tester, Finder field) => tester.getRect(
  find.descendant(of: field, matching: find.byType(InputDecorator)).first,
);

/// ⓘ outside the box, in the label row at its right end; [unit] inside the
/// box at its right, not in the label row.
Future<void> _expectField(
  WidgetTester tester,
  Finder field, {
  required String label,
  String? unit,
}) async {
  final why = label;
  expect(field, findsOneWidget, reason: why);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  final box = _box(tester, field);
  final whole = tester.getRect(field);
  final info = find.descendant(
    of: field,
    matching: find.byType(MenzilInfoButton),
  );
  expect(info, findsOneWidget, reason: '$why ⓘ');
  final i = tester.getRect(info);
  // 44 pt tap target, its semantics label kept.
  expect(i.width, greaterThanOrEqualTo(44 - 0.01), reason: why);
  expect(i.height, greaterThanOrEqualTo(44 - 0.01), reason: why);
  expect(find.byTooltip('Bilgi: $label'), findsWidgets, reason: why);
  // Outside the box, above it.
  expect(i.bottom, lessThanOrEqualTo(box.top + 0.5), reason: '$why above');
  expect(i.overlaps(box.deflate(0.5)), isFalse, reason: '$why outside');
  // Right-aligned with the box.
  expect((i.right - box.right).abs(), lessThanOrEqualTo(1), reason: why);
  // Vertically in the label row, centred on the label text.
  expect(i.center.dy, greaterThan(whole.top), reason: why);
  expect(i.center.dy, lessThan(box.top), reason: why);
  final labelText = find.descendant(of: field, matching: find.text(label));
  expect(labelText, findsOneWidget, reason: '$why label');
  final l = tester.getRect(labelText);
  final icon = tester.getRect(
    find.descendant(of: info, matching: find.byIcon(Icons.info_outline)),
  );
  expect(icon.center.dy, greaterThan(l.top - 3), reason: '$why centre');
  expect(icon.center.dy, lessThan(l.bottom + 3), reason: '$why centre');
  expect(l.bottom, lessThanOrEqualTo(box.top + 0.5), reason: why);
  // The label never runs under the icon.
  expect(l.right, lessThanOrEqualTo(icon.left), reason: '$why label');
  if (unit == null) return;
  final u = find.descendant(of: field, matching: find.text(unit));
  expect(u, findsOneWidget, reason: '$why unit once');
  final r = tester.getRect(u);
  expect(r.left, greaterThanOrEqualTo(box.left), reason: '$why unit');
  expect(r.right, lessThanOrEqualTo(box.right), reason: '$why unit');
  expect(r.top, greaterThanOrEqualTo(box.top - 0.5), reason: '$why unit');
  expect(r.bottom, lessThanOrEqualTo(box.bottom + 0.5), reason: '$why unit');
  expect(r.center.dx, greaterThan(box.center.dx), reason: '$why unit right');
}

Finder _k(String k) => find.byKey(Key(k));

void main() {
  const sizes = [(390.0, 1.0), (320.0, 1.0), (320.0, 1.3)];

  group('Profil', () {
    for (final (width, scale) in sizes) {
      testWidgets('PCP Mühimmat: ⓘ top right, unit in the box '
          '($width pt, ×$scale)', (tester) async {
        await _openProfile(tester, pcp: true, width: width, textScale: scale);
        await chooseInSelect(tester, 'ammo-type', 'Pellet');
        for (final (key, label, unit) in const [
          ('ammo-type', 'Tip', null),
          ('ammo-brand-select', 'Marka', null),
          ('ammo-grain', 'Ağırlık', 'gr'),
          ('ammo-bc', 'BC', null),
          ('ammo-bc-model', 'BC modeli', null),
          ('ammo-length', 'Mermi uzunluğu', 'mm'),
          ('profile-pcp-velocity-min', 'En düşük namlu çıkış hızı', 'fps'),
          ('profile-pcp-velocity-max', 'En yüksek namlu çıkış hızı', 'fps'),
        ]) {
          await _expectField(tester, _k(key), label: label, unit: unit);
        }
        // Side by side boxes still line up (two columns at 390 pt).
        for (final (a, b) in const [
          ('ammo-type', 'ammo-brand-select'),
          ('ammo-grain', 'ammo-bc'),
          ('profile-pcp-velocity-min', 'profile-pcp-velocity-max'),
        ]) {
          if (width != 390 || scale != 1.0) break;
          final ra = _box(tester, _k(a)), rb = _box(tester, _k(b));
          expect(rb.top, closeTo(ra.top, 0.5), reason: '$a | $b');
          expect(rb.left, greaterThan(ra.right), reason: '$a | $b');
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('PCP Tüfek: ⓘ top right, unit in the box '
          '($width pt, ×$scale)', (tester) async {
        await _openProfile(tester, pcp: true, width: width, textScale: scale);
        for (final (key, label, unit) in const [
          ('rifle-caliber', 'Kalibre', null),
          ('profile-velocity-fps', 'Namlu çıkış hızı', 'fps'),
          ('profile-tube-pressure', 'Tüp basıncı', 'bar'),
          ('profile-regulator-pressure', 'Regülatör basıncı', 'bar'),
        ]) {
          await _expectField(tester, _k(key), label: label, unit: unit);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Ateşli Tüfek: same placement', (tester) async {
      await _openProfile(tester, pcp: false);
      for (final (key, label, unit) in const [
        ('rifle-caliber', 'Kalibre', null),
        ('profile-velocity-fps', 'Namlu çıkış hızı', 'fps'),
        ('ammo-grain', 'Ağırlık', 'gr'),
      ]) {
        await _expectField(tester, _k(key), label: label, unit: unit);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('ⓘ in the label row opens its popup, never the field', (
      tester,
    ) async {
      await _openProfile(tester, pcp: true);
      final field = _k('ammo-grain');
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: field, matching: find.byType(MenzilInfoButton)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final editable = tester.widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isFalse);
      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();
    });
  });

  group('Hava Durumu', () {
    for (final (width, scale) in sizes) {
      testWidgets('Sıcaklık, Bağıl nem, Rüzgâr: ⓘ kept, top right; unit in '
          'the box ($width pt, ×$scale)', (tester) async {
        await _openBallistics(
          tester,
          BallisticsView.environment,
          width: width,
          textScale: scale,
        );
        await _expectField(
          tester,
          find.byKey(BallisticsFieldKeys.temperature),
          label: 'Sıcaklık',
          unit: '°C',
        );
        await _expectField(
          tester,
          find.byKey(BallisticsFieldKeys.humidity),
          label: 'Bağıl nem',
          unit: '%',
        );
        await _expectField(
          tester,
          find.byKey(BallisticsFieldKeys.wind),
          label: 'Rüzgâr hızı',
          unit: 'm/s',
        );
        await _expectField(
          tester,
          find.byKey(BallisticsFieldKeys.windDirection),
          label: 'Rüzgâr yönü',
          unit: 'saat',
        );
        // Rüzgâr başlık ⓘ stays; Rüzgâr gözlemi too while it is shown.
        expect(find.byKey(const Key('environment-wind-info')), findsOneWidget);
        final obs = find.byWidgetPredicate(
          (w) => w is MenzilSelect<int> && w.label == 'Rüzgâr gözlemi',
        );
        if (obs.evaluate().isNotEmpty) {
          await _expectField(tester, obs, label: 'Rüzgâr gözlemi');
        }
        // Side by side boxes still line up.
        for (final (a, b) in [
          (BallisticsFieldKeys.temperature, BallisticsFieldKeys.humidity),
          (BallisticsFieldKeys.wind, BallisticsFieldKeys.windDirection),
        ]) {
          if (width != 390 || scale != 1.0) break;
          final ra = _box(tester, find.byKey(a));
          final rb = _box(tester, find.byKey(b));
          expect(rb.top, closeTo(ra.top, 0.5), reason: '$a | $b');
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Pro Ayarlar', () {
    testWidgets('no ⓘ at the boxes inside the sections', (tester) async {
      await _openBallistics(tester, BallisticsView.pro);
      for (final k in const [
        Key('pro-target-speed'),
        Key('pro-bc-error'),
        Key('pro-wez-shots'),
      ]) {
        await openProFor(tester, k);
        expect(find.byKey(k), findsOneWidget, reason: '$k');
        expect(
          find.descendant(
            of: find.byKey(k),
            matching: find.byType(MenzilInfoButton),
          ),
          findsNothing,
          reason: '$k',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 pt, text ×1.3: no overflow', (tester) async {
      await _openBallistics(
        tester,
        BallisticsView.pro,
        width: 320,
        textScale: 1.3,
      );
      for (final k in const [Key('pro-group'), Key('pro-wez-shots')]) {
        await openProFor(tester, k);
        expect(tester.takeException(), isNull, reason: '$k');
      }
    });
  });
}
