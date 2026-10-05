import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/tools/hit_probability_screen.dart';
import 'package:sniper_turk/tools/domain/hit_probability.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  group('HitProbabilityEngine', () {
    test('probability is exactly the closed-form circular Gaussian value', () {
      // sigma(100m) for 1 MOA group = (0.5 MOA -> mrad)/1000*100m.
      final p = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: 1.0,
        targetDiameterCm: 10.0,
        rangeM: 100,
      );
      expect(p, closeTo(0.99729, 0.0001));
    });

    test('probability increases as the target shrinks less than the group', () {
      final close = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: 1.0,
        targetDiameterCm: 10.0,
        rangeM: 50,
      );
      final far = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: 1.0,
        targetDiameterCm: 10.0,
        rangeM: 300,
      );
      expect(close, greaterThan(far));
      expect(far, greaterThanOrEqualTo(0));
      expect(close, lessThanOrEqualTo(1));
    });

    test('maxRangeForProbability inverts probabilityOfHit', () {
      final r = HitProbabilityEngine.maxRangeForProbability(
        groupDiameterMoa: 1.0,
        targetDiameterCm: 10.0,
        probability: 0.8,
      )!;
      final p = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: 1.0,
        targetDiameterCm: 10.0,
        rangeM: r,
      );
      expect(p, closeTo(0.8, 1e-6));
    });

    test('rejects non-positive inputs', () {
      expect(
        () => HitProbabilityEngine.probabilityOfHit(
          groupDiameterMoa: 0,
          targetDiameterCm: 10,
          rangeM: 100,
        ),
        throwsArgumentError,
      );
    });
  });

  testWidgets('Vuruş Olasılığı screen shows a result once inputs are valid', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: const HitProbabilityScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Defaults (1,0 MOA / 10 cm / 100 m) are already valid and must never
    // surface a click/hold instruction (that stays in the ballistics flow).
    expect(find.text('Vuruş Olasılığı'), findsOneWidget);
    expect(find.textContaining('Vuruş olasılığı'), findsOneWidget);
    expect(find.textContaining('klik'), findsNothing);
    expect(find.textContaining('tambur'), findsNothing);
  });
}
