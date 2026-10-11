// Güvenlik/sağlık denetimi 2026-10-11 (docs/guvenlik-denetimi-2026-10-11.md):
// user input that used to freeze or crash the app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/features/tools/calculators_screen.dart';
import 'package:sniper_turk/features/tools/hit_probability_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/field_calc.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  test(
    'an unreachable zero (slow pellet, 600 m zero) is reported quickly, not '
    'after millions of RK4 steps per requested range',
    () {
      final input = BallisticInput(
        muzzleVelocityMps: 244,
        grain: 15.9,
        zeroRangeM: 600,
        sightHeightMm: 50,
        rangesM: const [25, 50, 100],
        ballisticCoefficient: 0.02,
        ballisticModel: BallisticModel.g1,
      );
      final watch = Stopwatch()..start();
      final r = const BallisticEngine().solveReachable(input);
      watch.stop();
      expect(r.points, isEmpty);
      expect(r.unreachableM, [25, 50, 100]);
      // The zero search used to have no flight-time cap (4 000 000 steps per
      // bracket evaluation, repeated once per range): tens of seconds on the
      // UI isolate. With the same 60 s flight cap as the main trajectory it
      // is a fraction of that.
      expect(watch.elapsed, lessThan(const Duration(seconds: 8)));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test('BC from two velocities refuses distances beyond the app range limit '
      '(an endless loop for an infinite distance)', () {
    double? bc(double distanceM) =>
        FieldCalc.ballisticCoefficientFromTwoVelocities(
          table: StandardDragTables.g1,
          v1Mps: 900,
          v2Mps: 300,
          distanceM: distanceM,
          env: const EnvironmentData(),
        );
    expect(bc(3500), isNull);
    expect(bc(double.infinity), isNull);
    expect(bc(double.nan), isNull);
    expect(
      FieldCalc.velocityAfter(
        table: StandardDragTables.g1,
        bc: 0.5,
        v1Mps: 900,
        distanceM: double.infinity,
        env: const EnvironmentData(),
      ),
      isNull,
    );
  });

  testWidgets('Tıklama değeri doğrulama: an infinite click count does not '
      'crash the page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: MenzilTheme.light(), home: const ClickCheckScreen()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('click-dist')), '100');
    await tester.enterText(find.byKey(const Key('click-moved')), '40');
    await tester.enterText(find.byKey(const Key('click-count')), '1e999');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Infinity'), findsNothing);
  });

  testWidgets('Vuruş Olasılığı: infinite group/target sizes show no NaN', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: const HitProbabilityScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('wez-group')), '1e999');
    await tester.enterText(find.byKey(const Key('wez-target')), '1e999');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('NaN'), findsNothing);
    expect(find.textContaining('Infinity'), findsNothing);
  });
}
