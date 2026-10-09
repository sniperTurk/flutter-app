import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/tools/hit_probability_screen.dart';
import 'package:sniper_turk/tools/domain/hit_probability.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  group('HitProbabilityEngine', () {
    test('probability is the closed-form Gaussian value (5-shot group)', () {
      // sigma = 1 MOA / 3.067 at 300 m; R = 5 cm -> P = 0.7865.
      final p = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: 1.0,
        targetDiameterCm: 10.0,
        rangeM: 300,
      );
      expect(p, closeTo(0.7865, 0.0005));
    });

    test('fewer shots in the same group size means more dispersion', () {
      final three = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: 1.0,
        targetDiameterCm: 10.0,
        rangeM: 300,
        shots: 3,
      );
      expect(three, closeTo(0.6127, 0.0005));
      expect(HitProbabilityEngine.extremeSpreadFactor(2), closeTo(1.772, 1e-3));
      expect(
        () => HitProbabilityEngine.extremeSpreadFactor(1),
        throwsArgumentError,
      );
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
