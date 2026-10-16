// Yan kule okları yerinde kalır (owner, 2026-10-15 12:52: "sağ kuleyi biraz
// küçültsek oklar yine aynı yerinde kalsa"). The side turret's ↑ / ↓ step
// arrows are measured against main's geometry: chevrons whose
// centres sat 37 pt left of the reticle's right edge (33 pt since the
// whole turret moved 4 pt right, docs/reports/yan_kule_konum.md) and
// 133 pt above / below its centre on the 334 pt reticle of a 390 pt phone,
// scaling with the reticle. Since HDF-2 the tap areas are 74 × 44 pt
// (chevrons unmoved).
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (size, scale) in const [
    (Size(390, 844), 1.0),
    (Size(390, 2400), 1.0),
    (Size(430, 2400), 1.0),
    (Size(320, 2400), 1.3),
  ]) {
    testWidgets('side turret arrows stay where main has them '
        '(${size.width.toInt()}×${size.height.toInt()}, text ×$scale)', (
      tester,
    ) async {
      await _openSideTurret(tester, size, textScale: scale);
      expect(tester.takeException(), isNull);
      final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
      final k = reticle.width / 334;
      final up = tester.getRect(find.byTooltip('Rüzgâr kulesi 1 klik sağa'));
      final down = tester.getRect(find.byTooltip('Rüzgâr kulesi 1 klik sola'));
      // HDF-2 (owner, 2026-10-15 22:29): the tap areas grew from 74 × 30 pt
      // to 74 × 44 pt toward the drum box, anchored at the column's ends;
      // the chevrons themselves did not move.
      for (final (arrow, glyphKey, dy) in [
        (up, 'Rüzgâr kulesi-step-plus', -133.0),
        (down, 'Rüzgâr kulesi-step-minus', 133.0),
      ]) {
        expect(arrow.width, moreOrLessEquals(74 * k, epsilon: 0.5));
        expect(arrow.height, moreOrLessEquals(44, epsilon: 0.5));
        // Chevron centre: 33 pt in from the right edge since the turret
        // moved 4 pt right (yan kule konum, owner 2026-10-16 21:08; it was
        // 37 pt), ±133 pt from the reticle's horizontal line.
        final glyph = tester.getRect(find.byKey(ValueKey(glyphKey)));
        expect(
          glyph.center.dx,
          moreOrLessEquals(reticle.right - 33 * k, epsilon: 0.5),
        );
        expect(
          glyph.center.dy,
          moreOrLessEquals(reticle.center.dy + dy * k, epsilon: 0.5),
        );
      }
      // Total arrow-to-arrow span unchanged: 296 pt at the design size.
      expect(down.bottom - up.top, moreOrLessEquals(296 * k, epsilon: 0.5));
    });
  }
}
