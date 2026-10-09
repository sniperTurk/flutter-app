import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/reticle_holds.dart';
import 'package:sniper_turk/models/domain.dart';

BallisticInput pellet({double mv = 250, double bc = 0.03}) => BallisticInput(
  muzzleVelocityMps: mv,
  grain: 18,
  zeroRangeM: 25,
  sightHeightMm: 60,
  rangesM: const [50],
  ballisticCoefficient: bc,
  ballisticModel: BallisticModel.g1,
);

void main() {
  test('samples are dense, ordered and end where the pellet runs out', () {
    final s = ReticleHolds.sample(pellet());
    expect(s, isNotEmpty);
    expect(s.first.rangeM, 1);
    for (var i = 1; i < s.length; i++) {
      expect(s[i].rangeM, greaterThan(s[i - 1].rangeM));
    }
    // A 250 m/s pellet does not go 3000 m: the ladder fell back.
    expect(s.last.rangeM, lessThan(3000));
  });

  test('a harder hold needs a farther distance (monotone)', () {
    final s = ReticleHolds.sample(pellet());
    final m = ReticleHolds.marks(
      samples: s,
      zeroRangeM: 25,
      mils: const [1, 2, 3, 4],
    );
    final d = [for (final x in m) x.distanceM];
    expect(d.every((x) => x != null), isTrue, reason: '$d');
    for (var i = 1; i < d.length; i++) {
      expect(d[i]!, greaterThan(d[i - 1]!));
    }
    // And a mark really is where the solver's correction equals the hold.
    final at = s.firstWhere((p) => p.rangeM >= d[1]!);
    expect(at.correctionMrad, closeTo(2, 0.3));
  });

  test('a hold the pellet never needs has no distance', () {
    final s = ReticleHolds.sample(pellet(mv: 500, bc: 0.4));
    final m = ReticleHolds.marks(
      samples: s,
      zeroRangeM: 25,
      mils: const [100000],
    );
    expect(m.single.distanceM, isNull);
  });

  test('crosswind for one mil scales with the 1 m/s drift', () {
    final base = pellet();
    final w1 = ReticleHolds.crosswindForMil(base: base, rangeM: 50, mil: 1)!;
    final w2 = ReticleHolds.crosswindForMil(base: base, rangeM: 50, mil: 2)!;
    expect(w1, greaterThan(0));
    expect(w2, closeTo(2 * w1, 1e-9));
    // Longer range drifts more per m/s, so less wind is needed for one mil.
    final far = ReticleHolds.crosswindForMil(base: base, rangeM: 100, mil: 1)!;
    expect(far, lessThan(w1));
  });

  test('an unreachable range gives no wind value', () {
    expect(
      ReticleHolds.crosswindForMil(
        base: pellet(mv: 120, bc: 0.02),
        rangeM: 3000,
        mil: 1,
      ),
      isNull,
    );
  });

  // Audit 2026-10-10: holds and wind-per-mil must use the same inputs as
  // the main solution (speed bands, zeroing-day velocity).
  test('holds follow BC bands and the zeroing-day velocity', () {
    final base = BallisticInput(
      muzzleVelocityMps: 816,
      zeroMuzzleVelocityMps: 800,
      grain: 168,
      zeroRangeM: 100,
      sightHeightMm: 45,
      rangesM: const [800],
      ballisticCoefficient: 0.462,
      ballisticModel: BallisticModel.g1,
      bcBands: const [BcBand(700, 0.462), BcBand(550, 0.44), BcBand(0, 0.40)],
    );
    final main = const BallisticEngine().solve(base).single;
    final s = ReticleHolds.sample(base);
    final at800 = s.firstWhere((p) => (p.rangeM - 800).abs() < 1e-6);
    expect(at800.correctionMrad, closeTo(main.correctionMrad, 1e-6));

    final perMil = ReticleHolds.crosswindForMil(
      base: base,
      rangeM: 800,
      mil: 1,
    )!;
    final windy = const BallisticEngine()
        .solve(
          BallisticInput(
            muzzleVelocityMps: 816,
            zeroMuzzleVelocityMps: 800,
            grain: 168,
            zeroRangeM: 100,
            sightHeightMm: 45,
            rangesM: const [800],
            ballisticCoefficient: 0.462,
            ballisticModel: BallisticModel.g1,
            bcBands: const [
              BcBand(700, 0.462),
              BcBand(550, 0.44),
              BcBand(0, 0.40),
            ],
            environment: EnvironmentData(windMps: perMil, windDirectionDeg: 90),
          ),
        )
        .single;
    expect(windy.windMrad.abs(), closeTo(1, 0.02));
  });
}
