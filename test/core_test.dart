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

  test('production solve never silently substitutes vacuum for G1/G7', () {
    final input = BallisticInput(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 25,
      sightHeightMm: 60,
      rangesM: const [100],
      ballisticCoefficient: 0.12,
      ballisticModel: BallisticModel.g1,
    );
    expect(() => const BallisticEngine().solve(input), throwsUnsupportedError);
  });
}
