// Yan kule okları yerinde kalır (owner, 2026-10-15 12:52: "sağ kuleyi biraz
// küçültsek oklar yine aynı yerinde kalsa"). The side turret's ↑ / ↓ step
// arrows are measured against main's geometry: 74 × 30 pt hit areas whose
// centres sit 37 pt left of the reticle's right edge and 133 pt above /
// below its centre on the 334 pt reticle of a 390 pt phone, scaling with the
// reticle. This file passes on main and on design/yan-kule-kucuk alike.
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
      for (final (arrow, dy) in [(up, -133.0), (down, 133.0)]) {
        // Hit area unchanged: 74 × 30 pt at the design size.
        expect(arrow.width, moreOrLessEquals(74 * k, epsilon: 0.5));
        expect(arrow.height, moreOrLessEquals(30 * k, epsilon: 0.5));
        // Centre unchanged: 37 pt in from the right edge, ±133 pt from the
        // reticle's horizontal line.
        expect(
          arrow.center.dx,
          moreOrLessEquals(reticle.right - 37 * k, epsilon: 0.5),
        );
        expect(
          arrow.center.dy,
          moreOrLessEquals(reticle.center.dy + dy * k, epsilon: 0.5),
        );
      }
      // Total arrow-to-arrow span unchanged: 296 pt at the design size.
      expect(down.bottom - up.top, moreOrLessEquals(296 * k, epsilon: 0.5));
    });
  }
}
