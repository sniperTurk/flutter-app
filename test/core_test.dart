import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/units.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  test(
    '90 MOA is about 26.18 MRAD',
    () => expect(Units.moaToMrad(90), closeTo(26.1799, 0.001)),
  );
  test(
    'energy is positive',
    () => expect(
      const BallisticEngine().energyJ(grain: 51, velocityMps: 270),
      greaterThan(0),
    ),
  );

  test('vacuum solver intersects line of sight at zero range', () {
    final point = const BallisticEngine()
        .vacuumDope(
          muzzleVelocityMps: 270,
          grain: 51,
          zeroRangeM: 25,
          sightHeightMm: 65,
          rangesM: [25],
        )
        .single;
    expect(point.dropM, closeTo(0, 1e-12));
    expect(point.correctionMrad, closeTo(0, 1e-9));
  });

  test('vacuum solver does not invent aerodynamic wind drift', () {
    final right = const BallisticEngine().vacuumDope(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 25,
      sightHeightMm: 65,
      rangesM: [100],
      environment: const EnvironmentData(windMps: 5, windDirectionDeg: 90),
    );
    final left = const BallisticEngine().vacuumDope(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 25,
      sightHeightMm: 65,
      rangesM: [100],
      environment: const EnvironmentData(windMps: 5, windDirectionDeg: 270),
    );
    expect(right.single.windMrad, 0);
    expect(left.single.windMrad, 0);
  });

  test('vacuum zero solution remains exact for demanding geometry', () {
    final point = const BallisticEngine()
        .vacuumDope(
          muzzleVelocityMps: 90,
          grain: 51,
          zeroRangeM: 100,
          sightHeightMm: 100,
          rangesM: [100],
        )
        .single;
    expect(point.dropM, closeTo(0, 1e-10));
  });

  test(
    'vacuum solver rejects an unreachable zero instead of returning bogus DOPE',
    () {
      expect(
        () => const BallisticEngine().vacuumDope(
          muzzleVelocityMps: 10,
          grain: 51,
          zeroRangeM: 1000,
          sightHeightMm: 100,
          rangesM: [1000],
        ),
        throwsArgumentError,
      );
    },
  );

  test('production solve uses the drag solver for G1/G7, never vacuum', () {
    BallisticInput input(double? bc, BallisticModel? model) => BallisticInput(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 25,
      sightHeightMm: 60,
      rangesM: const [100],
      ballisticCoefficient: bc,
      ballisticModel: model,
    );
    final drag = const BallisticEngine()
        .solve(input(0.12, BallisticModel.g1))
        .single;
    final vacuum = const BallisticEngine().solve(input(null, null)).single;
    // Drag slows the projectile; the vacuum baseline keeps muzzle speed.
    expect(drag.velocityMps, lessThan(270));
    expect(vacuum.velocityMps, 270);
    // More time of flight, so more drop at the same range.
    expect(drag.timeOfFlightS, greaterThan(vacuum.timeOfFlightS));
    expect(drag.dropM, isNot(closeTo(vacuum.dropM, 1e-6)));
  });

  test('a projectile that cannot reach the range is an error, not a number', () {
    final input = BallisticInput(
      muzzleVelocityMps: 120,
      grain: 8,
      zeroRangeM: 10,
      sightHeightMm: 40,
      rangesM: const [3000],
      ballisticCoefficient: 0.02,
      ballisticModel: BallisticModel.g1,
    );
    expect(() => const BallisticEngine().solve(input), throwsStateError);
  });

  test('solveReachable drops the ranges a slow pellet cannot reach', () {
    final input = BallisticInput(
      muzzleVelocityMps: 250,
      grain: 18,
      zeroRangeM: 25,
      sightHeightMm: 60,
      rangesM: const [25, 50, 100, 3000],
      ballisticCoefficient: 0.03,
      ballisticModel: BallisticModel.g1,
    );
    final r = const BallisticEngine().solveReachable(input);
    expect(r.points.map((p) => p.rangeM), [25, 50, 100]);
    expect(r.unreachableM, [3000]);
  });

  test('solveReachable on vacuum input never drops anything', () {
    final input = BallisticInput(
      muzzleVelocityMps: 250,
      grain: 18,
      zeroRangeM: 25,
      sightHeightMm: 60,
      rangesM: const [25, 3000],
    );
    final r = const BallisticEngine().solveReachable(input);
    expect(r.points, hasLength(2));
    expect(r.unreachableM, isEmpty);
  });
}
