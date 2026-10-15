// Yan kule küçük (owner, 2026-10-15 12:52 "sağ kuleyi biraz küçültsek oklar
// yine aynı yerinde kalsa", 12:53 pointer inside). The side (windage) drum
// box is ≈ 66 × 180 pt on the 390 pt phone, scales with the reticle, stays
// centred on the reticle's horizontal line and between the unchanged
// arrows (test/yan_kule_oklar_test.dart); the red pointer sits inside it.
// Report: docs/reports/yan_kule_kucuk.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-yan-kule',
  name: 'Yan kule',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

Future<void> _openSideTurret(
  WidgetTester tester,
  Size size, {
  double textScale = 1.0,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? MenzilTheme.dark(),
      builder: (context, c) => ToolsServicesScope(
        services: testServices(),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
      ),
      home: Scaffold(
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

Finder get _drumPaint => find.descendant(
  of: find.byKey(ScopeDialKeys.windageDrumBox),
  matching: find.byType(CustomPaint),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('390 pt phone: the drum box is 66 × 180 pt (±1)', (
    tester,
  ) async {
    await _openSideTurret(tester, const Size(390, 844));
    final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
    expect(box.width, moreOrLessEquals(66, epsilon: 1));
    expect(box.height, moreOrLessEquals(180, epsilon: 1));
  });

  for (final (size, scale) in const [
    (Size(390, 844), 1.0),
    (Size(390, 2400), 1.0),
    (Size(430, 2400), 1.0),
    (Size(320, 2400), 1.3),
    (Size(320, 568), 1.3),
  ]) {
    final name = '${size.width.toInt()}×${size.height.toInt()}, text ×$scale';
    testWidgets('$name: box scales with the reticle, zero on the line, '
        'centred between the arrows, pointer inside', (tester) async {
      await _openSideTurret(tester, size, textScale: scale);
      expect(tester.takeException(), isNull);
      final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
      final k = reticle.width / 334;
      final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
      expect(box.width, moreOrLessEquals(66 * k, epsilon: 0.5));
      expect(box.height, moreOrLessEquals(180 * k, epsilon: 0.5));
      // Zero on the reticle's horizontal line.
      expect(box.center.dy, moreOrLessEquals(reticle.center.dy, epsilon: 0.5));
      // Inside the reticle's right edge, centred under the arrows, which
      // stay outside the box.
      final up = tester.getRect(find.byTooltip('Rüzgâr kulesi 1 klik sağa'));
      final down = tester.getRect(find.byTooltip('Rüzgâr kulesi 1 klik sola'));
      expect(box.right, lessThanOrEqualTo(reticle.right));
      expect(box.center.dx, moreOrLessEquals(up.center.dx, epsilon: 0.5));
      expect(box.center.dx, moreOrLessEquals(down.center.dx, epsilon: 0.5));
      expect(up.bottom, lessThanOrEqualTo(box.top));
      expect(down.top, greaterThanOrEqualTo(box.bottom));
      // The drum fills the box, so the pointer's rect in drum coordinates
      // is its rect in the box.
      final drum = tester.getRect(_drumPaint.first);
      expect(drum.size.width, moreOrLessEquals(box.width, epsilon: 0.01));
      expect(drum.size.height, moreOrLessEquals(box.height, epsilon: 0.01));
      final pointer = SideTurretPointer.rect(box.size).shift(box.topLeft);
      const margin = 3.0;
      expect(pointer.left, greaterThanOrEqualTo(box.left + margin));
      expect(pointer.right, lessThanOrEqualTo(box.right - margin));
      expect(pointer.top, greaterThanOrEqualTo(box.top + margin));
      expect(pointer.bottom, lessThanOrEqualTo(box.bottom - margin));
      // Its tip on the zero line.
      expect(
        pointer.center.dy,
        moreOrLessEquals(reticle.center.dy, epsilon: 0.5),
      );
    });
  }

  testWidgets('the drum paints the red pointer at SideTurretPointer.rect', (
    tester,
  ) async {
    await _openSideTurret(tester, const Size(390, 844));
    final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
    final r = SideTurretPointer.rect(box.size);
    final danger = MenzilColors.dark.danger;
    expect(
      _drumPaint.first,
      paints..path(
        color: danger,
        includes: [r.centerLeft + const Offset(1, 0), r.center],
        excludes: [
          Offset(1, box.height / 2),
          Offset(r.right + 1, box.height / 2),
        ],
      ),
    );
  });

  testWidgets('labels 2R / 0 / 2L / ↑R / L↓ fit the box at 320 pt', (
    tester,
  ) async {
    await _openSideTurret(tester, const Size(320, 568), textScale: 1.3);
    final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
    double width(String s, double size) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: MenzilType.familyFor(size),
            fontFeatures: MenzilType.tabular,
            fontSize: size,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp.width;
    }

    // Values: centred at 62 % of the width. Headers: centred.
    for (final s in ['2R', '0', '2L']) {
      final w = width(s, 13);
      final cx = box.width * 0.62;
      expect(cx - w / 2, greaterThanOrEqualTo(0), reason: s);
      expect(cx + w / 2, lessThanOrEqualTo(box.width - 1), reason: s);
    }
    for (final s in ['↑R', 'L↓']) {
      expect(width(s, 11), lessThanOrEqualTo(box.width - 2), reason: s);
    }
    // The zero label clears the pointer.
    final pointer = SideTurretPointer.rect(box.size);
    expect(box.width * 0.62 - width('0', 13) / 2, greaterThan(pointer.right));
  });
}
