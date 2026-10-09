import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/velocity_truing.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  const engine = BallisticEngine();

  BallisticInput pcp({double mv = 270}) => BallisticInput(
    muzzleVelocityMps: mv,
    grain: 51,
    zeroRangeM: 25,
    sightHeightMm: 60,
    rangesM: const [100],
    ballisticCoefficient: 0.12,
    ballisticModel: BallisticModel.g1,
  );

  BallisticInput firearm({double mv = 800}) => BallisticInput(
    muzzleVelocityMps: mv,
    grain: 175,
    zeroRangeM: 100,
    sightHeightMm: 45,
    rangesM: const [600],
    ballisticCoefficient: 0.25,
    ballisticModel: BallisticModel.g7,
    environment: const EnvironmentData(temperatureC: 25, pressureHpa: 980),
  );

  double correctionAt(BallisticInput input, double range) =>
      engine.solve(input.withRanges([range])).single.correctionMrad;

  group('MuzzleVelocityTruing', () {
    test('recovers a slower real velocity from the observed elevation', () {
      final observed = correctionAt(pcp(mv: 258), 100);
      final r = MuzzleVelocityTruing.solve(
        base: pcp(),
        rangeM: 100,
        observedCorrectionMrad: observed,
      );
      expect(r.baseMps, 270);
      expect(r.truedMps, closeTo(258, 0.15));
      expect(r.changeMps, lessThan(0));
      expect(r.predictedMrad, lessThan(observed));
      expect(r.residualMrad.abs(), lessThan(0.01));
    });

    test('recovers a faster real velocity', () {
      final observed = correctionAt(pcp(mv: 283), 100);
      final r = MuzzleVelocityTruing.solve(
        base: pcp(),
        rangeM: 100,
        observedCorrectionMrad: observed,
      );
      expect(r.truedMps, closeTo(283, 0.15));
      expect(r.changePercent, closeTo(13 / 270 * 100, 0.1));
    });

    test('keeps the velocity when the observation matches the prediction', () {
      final r = MuzzleVelocityTruing.solve(
        base: pcp(),
        rangeM: 100,
        observedCorrectionMrad: correctionAt(pcp(), 100),
      );
      expect(r.truedMps, closeTo(270, 0.1));
    });

    test('G7 firearm profile with non-standard atmosphere round-trips', () {
      final observed = correctionAt(firearm(mv: 785), 600);
      final r = MuzzleVelocityTruing.solve(
        base: firearm(),
        rangeM: 600,
        observedCorrectionMrad: observed,
      );
      expect(r.truedMps, closeTo(785, 0.15));
    });

    test('result is rounded to the 0.1 m/s a profile stores', () {
      final r = MuzzleVelocityTruing.solve(
        base: pcp(),
        rangeM: 100,
        observedCorrectionMrad: correctionAt(pcp(mv: 261.37), 100),
      );
      expect(r.truedMps, double.parse(r.truedMps.toStringAsFixed(1)));
    });

    test('refuses a range at or inside the zero', () {
      for (final range in [10.0, 25.0]) {
        expect(
          () => MuzzleVelocityTruing.solve(
            base: pcp(),
            rangeM: range,
            observedCorrectionMrad: 0,
          ),
          throwsA(
            isA<TruingFailure>().having(
              (f) => f.reason,
              'reason',
              TruingRejection.rangeTooShort,
            ),
          ),
        );
      }
    });

    test('refuses a mismatch that would need more than 15 % velocity', () {
      final predicted = correctionAt(pcp(), 100);
      for (final observed in [predicted * 3, -predicted]) {
        expect(
          () => MuzzleVelocityTruing.solve(
            base: pcp(),
            rangeM: 100,
            observedCorrectionMrad: observed,
          ),
          throwsA(
            isA<TruingFailure>().having(
              (f) => f.reason,
              'reason',
              TruingRejection.outOfBounds,
            ),
          ),
        );
      }
    });

    test('refuses an observation too close to resolve velocity', () {
      // Just past a 100 m zero the drop barely depends on velocity.
      expect(
        () => MuzzleVelocityTruing.solve(
          base: firearm(),
          rangeM: 101,
          observedCorrectionMrad: correctionAt(firearm(), 101),
        ),
        throwsA(
          isA<TruingFailure>().having(
            (f) => f.reason,
            'reason',
            TruingRejection.notSensitive,
          ),
        ),
      );
    });

    test('rejects malformed arguments', () {
      expect(
        () => MuzzleVelocityTruing.solve(
          base: pcp(),
          rangeM: 100,
          observedCorrectionMrad: double.nan,
        ),
        throwsArgumentError,
      );
      expect(
        () => MuzzleVelocityTruing.solve(
          base: pcp(),
          rangeM: double.infinity,
          observedCorrectionMrad: 1,
        ),
        throwsArgumentError,
      );
    });

    test('every rejection has a Turkish message', () {
      for (final r in TruingRejection.values) {
        expect(r.message, isNotEmpty);
        expect(TruingFailure(r).message, r.message);
      }
    });
  });

  test('withMuzzleVelocity changes only the velocity and validates it', () {
    final base = firearm();
    final faster = base.withMuzzleVelocity(820);
    expect(faster.muzzleVelocityMps, 820);
    expect(faster.grain, base.grain);
    expect(faster.zeroRangeM, base.zeroRangeM);
    expect(faster.rangesM, base.rangesM);
    expect(faster.ballisticModel, base.ballisticModel);
    expect(faster.environment.pressureHpa, 980);
    expect(() => base.withMuzzleVelocity(-1), throwsArgumentError);
  });

  group('BallisticCoefficientTruing (second step, far range)', () {
    BallisticInput withBc(BallisticInput b, double bc) =>
        b.withBallisticCoefficient(bc);

    test('recovers the real BC from the far-range elevation (G1 PCP)', () {
      final real = withBc(pcp(), 0.105);
      final observed = correctionAt(real, 100);
      final r = BallisticCoefficientTruing.solve(
        base: pcp(),
        rangeM: 100,
        observedCorrectionMrad: observed,
      );
      expect(r.truedBc, closeTo(0.105, 0.0002));
      expect(r.baseBc, 0.12);
      expect(r.residualMrad.abs(), lessThan(0.01));
    });

    test('recovers the real BC for a G7 firearm at 800 m', () {
      final real = withBc(firearm(), 0.27);
      final observed = correctionAt(real, 800);
      final r = BallisticCoefficientTruing.solve(
        base: firearm(),
        rangeM: 800,
        observedCorrectionMrad: observed,
      );
      expect(r.truedBc, closeTo(0.27, 0.0002));
      expect(r.changePercent, closeTo(8, 0.2));
    });

    test('refuses inside the zero and beyond ±30 %', () {
      expect(
        () => BallisticCoefficientTruing.solve(
          base: pcp(),
          rangeM: 20,
          observedCorrectionMrad: 1,
        ),
        throwsA(
          isA<TruingFailure>().having(
            (f) => f.reason,
            'reason',
            TruingRejection.rangeTooShort,
          ),
        ),
      );
      final wild = correctionAt(withBc(pcp(), 0.05), 100);
      expect(
        () => BallisticCoefficientTruing.solve(
          base: pcp(),
          rangeM: 100,
          observedCorrectionMrad: wild,
        ),
        throwsA(
          isA<TruingFailure>().having(
            (f) => f.reason,
            'reason',
            TruingRejection.bcOutOfBounds,
          ),
        ),
      );
    });

    test('withBallisticCoefficient changes only the BC', () {
      final b = firearm().withBallisticCoefficient(0.3);
      expect(b.ballisticCoefficient, 0.3);
      expect(b.muzzleVelocityMps, 800);
      expect(b.ballisticModel, BallisticModel.g7);
    });
  });
}
