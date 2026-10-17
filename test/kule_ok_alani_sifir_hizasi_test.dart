// Kule ok alanı ve sıfır hizası (owner, 2026-10-15 Istanbul).
// 22:29 HDF-2 "görünüş aynı, alan büyük": every turret step arrow keeps its
// look and place, while its invisible tap area is at least 44 × 44 pt.
// 22:31: the areas never cover L-R or another control; they grow toward the
// drum. 22:29 "sağ kule sıfır çizgi ile hizalı değil": the side turret's
// "0" label, zero tick and red pointer sit on the reticle's horizontal line,
// the top turret's on its vertical line (±0,5 pt).
// Report: docs/reports/kule_ok_alani_sifir_hizasi.md.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/tool_fakes.dart';

// Gazi Sniper 6–36×56 FFP in MOA (1/4 MOA clicks): labels 2R / 0 / 2L.
const _profile = RifleProfile(
  id: 'p-kule-ok',
  name: 'Kule ok',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

const _elevUp = 'Yükseklik kulesi 1 klik yukarı';
const _elevDown = 'Yükseklik kulesi 1 klik aşağı';
const _windRight = 'Rüzgâr kulesi 1 klik sağa';
const _windLeft = 'Rüzgâr kulesi 1 klik sola';

Future<void> _open(
  WidgetTester tester,
  Size size, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.dark(),
      builder: (context, c) => ToolsServicesScope(
        services: testServices(),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
      ),
      home: const Scaffold(
        body: BallisticsScreen(profile: _profile, view: BallisticsView.shot),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final toggle = find.byKey(ScopeDialKeys.turretToggle);
  await tester.ensureVisible(toggle);
  await tester.pumpAndSettle();
  await tester.tap(toggle);
  await tester.pumpAndSettle();
}

/// Clicks on a drum, read from its slider semantics value
/// ("… sıfırda" or "N klik yukarı/aşağı/sağa/sola, …").
int _clicks(WidgetTester tester, Key drum) {
  final value = tester.getSemantics(find.byKey(drum)).value;
  if (value.endsWith('sıfırda')) return 0;
  final n = int.parse(value.split(' ').first);
  return value.contains('yukarı') || value.contains('sağa') ? n : -n;
}

Rect _rect(WidgetTester tester, String tooltip) =>
    tester.getRect(find.byTooltip(tooltip));

Rect _glyph(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

/// The drum's own painter (not the arrow chevrons) under [of].
Finder _drumPaint(Key of) => find.descendant(
  of: find.byKey(of),
  matching: find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.painter != null &&
        w.painter is! TurretChevronPainter,
  ),
);

/// Canvas calls of [finder]'s painter, in its own coordinates.
({List<Rect> labels, List<(Offset, Offset)> lines, List<Rect> paths}) _record(
  Finder finder,
) {
  final labels = <Rect>[];
  final lines = <(Offset, Offset)>[];
  final paths = <Rect>[];
  expect(
    finder,
    paints..everything((method, args) {
      if (method == #drawParagraph) {
        final p = args[0] as ui.Paragraph;
        final o = args[1] as Offset;
        // TextPainter reports the max intrinsic width for a single,
        // left-aligned line laid out without a width limit.
        labels.add(o & Size(p.maxIntrinsicWidth, p.height));
      } else if (method == #drawLine) {
        lines.add((args[0] as Offset, args[1] as Offset));
      } else if (method == #drawPath) {
        paths.add((args[0] as Path).getBounds());
      }
      return true;
    }),
  );
  return (labels: labels, lines: lines, paths: paths);
}

void _noOverlap(Rect area, Rect control, String reason) {
  final i = area.intersect(control);
  expect(
    i.width <= 0.01 || i.height <= 0.01,
    isTrue,
    reason: '$reason: $area overlaps $control',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in const [320.0, 390.0, 430.0]) {
    for (final scale in const [1.0, 1.3]) {
      final name = '${width.toInt()} pt, text ×$scale';

      testWidgets('$name: arrow tap areas ≥ 44 × 44, not over L-R or other '
          'controls; glyphs unchanged', (tester) async {
        await _open(tester, Size(width, 2400), textScale: scale);
        expect(tester.takeException(), isNull);
        final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
        final k = reticle.width / 334;
        final turret = tester.getRect(find.byKey(ScopeDialKeys.elevationDrum));
        final toggle = tester.getRect(find.byKey(ScopeDialKeys.turretToggle));
        final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));

        // (a) sizes. Top: 44 pt wide, the old 78 pt height kept. Side: the
        // 74 pt column wide, 44 pt tall where arrow + gap holds it.
        for (final tip in [_elevUp, _elevDown]) {
          final r = _rect(tester, tip);
          expect(r.width, moreOrLessEquals(44, epsilon: 0.01), reason: tip);
          expect(r.height, moreOrLessEquals(78, epsilon: 0.01), reason: tip);
        }
        final sideH = (30 * k + 28 * k).clamp(30 * k, 44.0);
        for (final tip in [_windRight, _windLeft]) {
          final r = _rect(tester, tip);
          expect(r.width, moreOrLessEquals(74 * k, epsilon: 0.5), reason: tip);
          expect(r.width, greaterThanOrEqualTo(44), reason: tip);
          expect(r.height, moreOrLessEquals(sideH, epsilon: 0.5), reason: tip);
          // Yan kule konum (owner, 2026-10-16 21:08): the column moved 4·k pt
          // right, its empty margin past the reticle square, which bounds
          // hit testing. The part a finger can hit is still ≥ 44 pt wide.
          expect(
            r.right - reticle.right,
            moreOrLessEquals(4 * k, epsilon: 0.5),
            reason: tip,
          );
          expect(
            math.min(r.right, reticle.right) - r.left,
            greaterThanOrEqualTo(44),
            reason: tip,
          );
        }
        // On every supported phone (reticle ≥ 254 pt) the side fits 44.
        expect(reticle.width, greaterThanOrEqualTo(254));
        expect(sideH, moreOrLessEquals(44, epsilon: 0.01));

        // (b) no overlap with L-R, the drum box, the reticle's eye button,
        // the turret buttons, the zoom row or (top) the reticle.
        final up = _rect(tester, _elevUp);
        final down = _rect(tester, _elevDown);
        final right = _rect(tester, _windRight);
        final left = _rect(tester, _windLeft);
        expect(down.right, lessThanOrEqualTo(toggle.left + 0.01));
        final controls = <String, Rect>{
          'L-R': toggle,
          'eye': tester.getRect(find.byKey(ScopeDialKeys.labelsToggle)),
          'kur': tester.getRect(find.byKey(ScopeDialKeys.dialSolution)),
          'sıfırla': tester.getRect(find.byKey(ScopeDialKeys.reset)),
          if (find.byKey(ScopeDialKeys.magnification).evaluate().isNotEmpty)
            'zoom': tester.getRect(find.byKey(ScopeDialKeys.magnification)),
        };
        for (final (n, a) in [
          ('‹', up),
          ('›', down),
          ('˄', right),
          ('˅', left),
        ]) {
          for (final e in controls.entries) {
            _noOverlap(a, e.value, '$n vs ${e.key}');
          }
        }
        for (final (n, a) in [('‹', up), ('›', down)]) {
          _noOverlap(a, reticle, '$n vs reticle');
        }
        for (final (n, a) in [('˄', right), ('˅', left)]) {
          _noOverlap(a, box, '$n vs drum box');
        }
        _noOverlap(up, down, '‹ vs ›');

        // (c) glyphs: 24 pt chevrons exactly where main draws them. As on
        // main, a side chevron is never taller than its 30·k pt cell
        // (23,7 pt on a 320 pt phone).
        final sideGlyph = math.min(24.0, 30 * k);
        Rect at(Offset c, [double h = 24]) =>
            Rect.fromCenter(center: c, width: 24, height: h);
        for (final (key, want) in [
          (
            'Yükseklik kulesi-step-plus',
            at(Offset(turret.left + 14, turret.center.dy)),
          ),
          (
            'Yükseklik kulesi-step-minus',
            at(Offset(turret.right - 14, turret.center.dy)),
          ),
          (
            'Rüzgâr kulesi-step-plus',
            at(
              Offset(reticle.right - 33 * k, reticle.center.dy - 133 * k),
              sideGlyph,
            ),
          ),
          (
            'Rüzgâr kulesi-step-minus',
            at(
              Offset(reticle.right - 33 * k, reticle.center.dy + 133 * k),
              sideGlyph,
            ),
          ),
        ]) {
          final g = _glyph(tester, key);
          expect(
            g.left,
            moreOrLessEquals(want.left, epsilon: 0.5),
            reason: key,
          );
          expect(g.top, moreOrLessEquals(want.top, epsilon: 0.5), reason: key);
          expect(g.width, moreOrLessEquals(24, epsilon: 0.01), reason: key);
          expect(
            g.height,
            moreOrLessEquals(want.height, epsilon: 0.01),
            reason: key,
          );
        }
        // Top row layout unchanged: [48][4][‹ 28][4][drum][4][› 28][4][L-R].
        expect(toggle.left - turret.right, moreOrLessEquals(4, epsilon: 0.5));
        expect(toggle.width, moreOrLessEquals(48, epsilon: 0.01));
        expect(
          turret.center.dx,
          moreOrLessEquals(reticle.center.dx, epsilon: 0.5),
        );
      });

      testWidgets('$name: taps at the arrow centre and near the area edges '
          'step the turret; L-R left edge + 1 pt goes to L-R', (tester) async {
        await _open(tester, Size(width, 2400), textScale: scale);
        for (final (tip, drum, delta, glyphKey) in [
          (
            _elevUp,
            ScopeDialKeys.elevationDrum,
            1,
            'Yükseklik kulesi-step-plus',
          ),
          (
            _elevDown,
            ScopeDialKeys.elevationDrum,
            -1,
            'Yükseklik kulesi-step-minus',
          ),
          (_windRight, ScopeDialKeys.windageDrum, 1, 'Rüzgâr kulesi-step-plus'),
          (
            _windLeft,
            ScopeDialKeys.windageDrum,
            -1,
            'Rüzgâr kulesi-step-minus',
          ),
        ]) {
          // At ×1.3 the page is taller than the view: bring the area in.
          await tester.ensureVisible(find.byTooltip(tip));
          await tester.pumpAndSettle();
          final area = _rect(tester, tip);
          // The side column's margin past the reticle square (yan kule
          // konum, 2026-10-16) is not hit-testable; the rest of the area is.
          final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
          final r = drum == ScopeDialKeys.windageDrum
              ? Rect.fromLTRB(
                  area.left,
                  area.top,
                  math.min(area.right, reticle.right),
                  area.bottom,
                )
              : area;
          for (final p in [
            _glyph(tester, glyphKey).center,
            r.center,
            r.topLeft + const Offset(1, 1),
            r.topRight + const Offset(-1, 1),
            r.bottomLeft + const Offset(1, -1),
            r.bottomRight + const Offset(-1, -1),
          ]) {
            final before = _clicks(tester, drum);
            await tester.tapAt(p);
            await tester.pumpAndSettle();
            expect(
              _clicks(tester, drum),
              before + delta,
              reason: '$tip at $p (area $r)',
            );
          }
        }

        // L-R's left edge + 1 pt toggles the side turret; no turret steps.
        await tester.ensureVisible(find.byKey(ScopeDialKeys.turretToggle));
        await tester.pumpAndSettle();
        final toggle = tester.getRect(find.byKey(ScopeDialKeys.turretToggle));
        final elev = _clicks(tester, ScopeDialKeys.elevationDrum);
        expect(find.byKey(ScopeDialKeys.windageDrum), findsOneWidget);
        await tester.tapAt(Offset(toggle.left + 1, toggle.center.dy));
        await tester.pumpAndSettle();
        expect(find.byKey(ScopeDialKeys.windageDrum), findsNothing);
        expect(_clicks(tester, ScopeDialKeys.elevationDrum), elev);
        await tester.tapAt(Offset(toggle.left + 1, toggle.center.dy));
        await tester.pumpAndSettle();
        expect(find.byKey(ScopeDialKeys.windageDrum), findsOneWidget);
        expect(_clicks(tester, ScopeDialKeys.elevationDrum), elev);
      });

      testWidgets('$name: side zero on the horizontal line, top zero on the '
          'vertical line (±0,5 pt)', (tester) async {
        await _open(tester, Size(width, 2400), textScale: scale);
        expect(_clicks(tester, ScopeDialKeys.elevationDrum), 0);
        expect(_clicks(tester, ScopeDialKeys.windageDrum), 0);
        final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
        final lineY = reticle.center.dy;
        final lineX = reticle.center.dx;

        // (d) side turret.
        final sideFinder = _drumPaint(ScopeDialKeys.windageDrumBox).first;
        final side = tester.getRect(sideFinder);
        final s = _record(sideFinder);
        // Value labels are centred at 62 % of the width (headers at 50 %).
        final values = [
          for (final l in s.labels)
            if ((l.center.dx - side.width * 0.62).abs() < 0.5) l,
        ]..sort((a, b) => a.center.dy.compareTo(b.center.dy));
        final zero = values.reduce(
          (a, b) =>
              (a.center.dy - side.height / 2).abs() <
                  (b.center.dy - side.height / 2).abs()
              ? a
              : b,
        );
        expect(
          side.top + zero.center.dy,
          moreOrLessEquals(lineY, epsilon: 0.5),
          reason: '"0" label',
        );
        // 2R / 2L the same distance above and below.
        final i = values.indexOf(zero);
        expect(i, greaterThan(0));
        expect(i, lessThan(values.length - 1));
        expect(
          zero.center.dy - values[i - 1].center.dy,
          moreOrLessEquals(
            values[i + 1].center.dy - zero.center.dy,
            epsilon: 0.01,
          ),
        );
        final zeroTick = s.lines
            .where((l) => (l.$1.dy - l.$2.dy).abs() < 0.01)
            .reduce(
              (a, b) =>
                  (a.$1.dy - side.height / 2).abs() <
                      (b.$1.dy - side.height / 2).abs()
                  ? a
                  : b,
            );
        expect(
          side.top + zeroTick.$1.dy,
          moreOrLessEquals(lineY, epsilon: 0.5),
          reason: 'zero tick',
        );
        final pointer = SideTurretPointer.rect(side.size).shift(side.topLeft);
        expect(pointer.center.dy, moreOrLessEquals(lineY, epsilon: 0.5));
        expect(s.paths, isNotEmpty);
        expect(
          side.top + s.paths.last.center.dy,
          moreOrLessEquals(lineY, epsilon: 0.5),
          reason: 'red pointer as painted',
        );

        // (e) top turret.
        final topFinder = _drumPaint(ScopeDialKeys.elevationDrum).first;
        final top = tester.getRect(topFinder);
        final t = _record(topFinder);
        final topValues = [
          for (final l in t.labels)
            if ((l.center.dy - top.height * 0.40).abs() < 0.5) l,
        ];
        final topZero = topValues.reduce(
          (a, b) =>
              (a.center.dx - top.width / 2).abs() <
                  (b.center.dx - top.width / 2).abs()
              ? a
              : b,
        );
        expect(
          top.left + topZero.center.dx,
          moreOrLessEquals(lineX, epsilon: 0.5),
          reason: 'top "0" label',
        );
        expect(t.paths, isNotEmpty);
        expect(
          top.left + t.paths.last.center.dx,
          moreOrLessEquals(lineX, epsilon: 0.5),
          reason: 'top red pointer',
        );
      });
    }
  }

  testWidgets('dragging the top drum from inside an arrow area still turns '
      'it', (tester) async {
    await _open(tester, const Size(390, 2400));
    final up = _rect(tester, _elevUp);
    // The part of the area over the drum (beyond the 28 pt arrow + 4 pt).
    final start = Offset(up.left + 40, up.center.dy);
    await tester.dragFrom(start, const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(_clicks(tester, ScopeDialKeys.elevationDrum), greaterThan(0));
  });

  for (final (size, scale) in const [
    (Size(320, 568), 1.3),
    (Size(390, 844), 1.0),
    (Size(430, 932), 1.3),
  ]) {
    testWidgets('${size.width.toInt()}×${size.height.toInt()}, text ×$scale: '
        'no overflow with the side turret open', (tester) async {
      await _open(tester, size, textScale: scale);
      expect(tester.takeException(), isNull);
      expect(find.byKey(ScopeDialKeys.windageDrum), findsOneWidget);
    });
  }
}
