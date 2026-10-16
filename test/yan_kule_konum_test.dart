// Yan kule konum (owner, 2026-10-16 21:08–21:09, TestFlight 110 Hedef on a
// 390 pt iPhone): "Sağ kulenin sağ tarafında dürbün beyazlığı var … Kuleyi
// biraz sağa al." The side (windage) turret moves 4·k pt right (its box was
// centred 4·k pt inside its 74·k pt column): the drum box's right edge now
// lies on the reticle square's right edge, over the scope circle's outer
// edge, so no white of the circle shows to its right. Size, arrows, zero on
// the horizontal line, slide-in and L-R are unchanged; the turret stays in
// the scope card and on screen.
// Report: docs/reports/yan_kule_konum.md.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-yan-kule-konum',
  name: 'Yan kule konum',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

const _right = 'Rüzgâr kulesi 1 klik sağa';
const _left = 'Rüzgâr kulesi 1 klik sola';

/// The drum box's corner radius (scope_turrets.dart, windageDrumBox).
const _boxRadius = 14.0;

Future<void> _open(
  WidgetTester tester,
  Size size, {
  double textScale = 1.0,
  bool reveal = true,
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
  if (!reveal) return;
  await tester.tap(toggle);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(ScopeDialKeys.windageDrumBox));
  await tester.pumpAndSettle();
}

int _clicks(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView)).windageClicks;

/// Right edge of the rounded drum box at height [y].
double _boxRightAt(Rect box, double y) {
  final dy = y < box.top + _boxRadius
      ? box.top + _boxRadius - y
      : y > box.bottom - _boxRadius
      ? y - (box.bottom - _boxRadius)
      : 0.0;
  if (dy <= 0) return box.right;
  return box.right -
      _boxRadius +
      math.sqrt(math.max(0, _boxRadius * _boxRadius - dy * dy));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (size, scale) in const [
    (Size(390, 844), 1.0),
    (Size(390, 844), 1.3),
    (Size(320, 568), 1.0),
    (Size(320, 568), 1.3),
    (Size(430, 932), 1.0),
  ]) {
    final name = '${size.width.toInt()}×${size.height.toInt()}, text ×$scale';

    testWidgets('$name: no scope white to the right of the drum box', (
      tester,
    ) async {
      await _open(tester, size, textScale: scale);
      expect(tester.takeException(), isNull);
      final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
      final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
      // ScopeReticlePainter: field radius side/2 − 2, a 2 pt dark ring on
      // it, so the circle's outer edge is 1 pt inside the square.
      final c = reticle.center;
      final fieldR = reticle.width / 2 - 2;
      final outerR = fieldR + 1;
      expect(box.right, greaterThanOrEqualTo(c.dx + outerR));
      // Row by row over the box's height (its rounded corners included):
      // wherever the circle reaches past the box's left edge, the box
      // reaches at least as far right as the circle does.
      for (var y = box.top; y <= box.bottom; y += 0.5) {
        final dy = (y - c.dy).abs();
        if (dy >= outerR) continue;
        final circleRight = c.dx + math.sqrt(outerR * outerR - dy * dy);
        if (circleRight <= box.left) continue;
        expect(
          _boxRightAt(box, y),
          greaterThanOrEqualTo(circleRight - 0.01),
          reason: 'white to the right of the box at y = $y',
        );
      }
    });

    testWidgets('$name: box on the reticle edge, same size, zero on the '
        'line, inside the card and the screen', (tester) async {
      await _open(tester, size, textScale: scale);
      final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
      final k = reticle.width / 334;
      final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
      final column = tester.getRect(find.byKey(ScopeDialKeys.windageDrum));
      // Moved 4·k pt right: the box ends on the reticle's right edge
      // (it ended 4·k pt inside it), its size unchanged.
      expect(box.right, moreOrLessEquals(reticle.right, epsilon: 0.5));
      expect(box.width, moreOrLessEquals(66 * k, epsilon: 0.5));
      expect(box.height, moreOrLessEquals(180 * k, epsilon: 0.5));
      expect(column.width, moreOrLessEquals(74 * k, epsilon: 0.5));
      // Zero on the reticle's horizontal line.
      expect(box.center.dy, moreOrLessEquals(reticle.center.dy, epsilon: 0.5));
      expect(
        column.center.dy,
        moreOrLessEquals(reticle.center.dy, epsilon: 0.5),
      );
      // Box still centred under its arrows.
      final up = tester.getRect(find.byTooltip(_right));
      final down = tester.getRect(find.byTooltip(_left));
      expect(up.center.dx, moreOrLessEquals(box.center.dx, epsilon: 0.5));
      expect(down.center.dx, moreOrLessEquals(box.center.dx, epsilon: 0.5));
      expect(up.bottom, lessThanOrEqualTo(box.top));
      expect(down.top, greaterThanOrEqualTo(box.bottom));
      // Covers less of the reticle than before (left edge 4·k pt further
      // right), never its centre.
      expect(box.left, moreOrLessEquals(reticle.right - 66 * k, epsilon: 0.5));
      expect(box.left, greaterThan(reticle.center.dx + 60 * k));
      // Only the column's empty margin passes the reticle square; it stays
      // inside the scope card's padding and on screen.
      final card = tester.getRect(
        find
            .ancestor(
              of: find.byKey(ScopeDialKeys.reticle),
              matching: find.byType(MenzilCard),
            )
            .first,
      );
      expect(
        column.right - reticle.right,
        moreOrLessEquals(4 * k, epsilon: 0.5),
      );
      expect(column.right, lessThanOrEqualTo(card.right - 1));
      expect(column.right, lessThanOrEqualTo(size.width));
      expect(box.right, lessThanOrEqualTo(card.right));
    });

    testWidgets('$name: both arrows step the turret, also 1 pt inside the '
        'reticle edge', (tester) async {
      await _open(tester, size, textScale: scale);
      for (final (tip, glyphKey, delta) in const [
        (_right, 'Rüzgâr kulesi-step-plus', 1),
        (_left, 'Rüzgâr kulesi-step-minus', -1),
      ]) {
        await tester.ensureVisible(find.byTooltip(tip));
        await tester.pumpAndSettle();
        final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
        final area = tester.getRect(find.byTooltip(tip));
        // ≥ 44 × 44 pt of it lies on the reticle, where taps land.
        expect(
          math.min(area.right, reticle.right) - area.left,
          greaterThanOrEqualTo(44),
        );
        expect(area.height, greaterThanOrEqualTo(44 - 0.01));
        final glyph = tester.getRect(find.byKey(ValueKey(glyphKey)));
        expect(glyph.right, lessThanOrEqualTo(reticle.right));
        for (final p in [
          glyph.center,
          Offset(reticle.right - 1, area.center.dy),
          Offset(area.left + 1, area.center.dy),
        ]) {
          final before = _clicks(tester);
          await tester.tapAt(p);
          await tester.pumpAndSettle();
          expect(_clicks(tester), before + delta, reason: '$tip at $p');
        }
      }
    });
  }

  testWidgets('L-R slides the turret in from the right and away again', (
    tester,
  ) async {
    await _open(tester, const Size(390, 844), reveal: false);
    expect(find.byKey(ScopeDialKeys.windageDrumBox), findsNothing);
    await tester.tap(find.byKey(ScopeDialKeys.turretToggle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
    final moving = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
    // Mid-slide: still right of its resting place.
    expect(moving.left, greaterThan(reticle.right - 66 * reticle.width / 334));
    await tester.pumpAndSettle();
    final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
    expect(box.right, moreOrLessEquals(reticle.right, epsilon: 0.5));
    await tester.tap(find.byKey(ScopeDialKeys.turretToggle));
    await tester.pumpAndSettle();
    expect(find.byKey(ScopeDialKeys.windageDrumBox), findsNothing);
  });

  testWidgets('the reticle square clips the turret while it slides', (
    tester,
  ) async {
    await _open(tester, const Size(390, 844));
    // The Stack over the reticle keeps its default hard-edge clip, so the
    // column's margin past the square never paints over the card.
    // The nearest Stack holding both the reticle and the side turret.
    Iterable<Element> stacksAbove(Key key) => find
        .ancestor(of: find.byKey(key), matching: find.byType(Stack))
        .evaluate();
    final aboveReticle = stacksAbove(ScopeDialKeys.reticle).toSet();
    final shared = stacksAbove(
      ScopeDialKeys.windageDrum,
    ).where(aboveReticle.contains).toList();
    expect(shared, isNotEmpty);
    final turretBox = tester.getRect(find.byKey(ScopeDialKeys.reticle));
    final stackElement = shared.firstWhere(
      (e) => (e.renderObject! as RenderBox).size.width <= turretBox.width + 0.5,
    );
    final stack = stackElement.widget as Stack;
    expect(stack.clipBehavior, Clip.hardEdge);
    // That Stack is the reticle square itself.
    final r = stackElement.renderObject! as RenderBox;
    expect(r.size.width, moreOrLessEquals(turretBox.width, epsilon: 0.5));
  });
}
