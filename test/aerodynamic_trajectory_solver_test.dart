import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/aerodynamic_trajectory_solver.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  BallisticInput input({double wind = 0}) => BallisticInput(
    muzzleVelocityMps: 270,
    grain: 51,
    zeroRangeM: 25,
    sightHeightMm: 60,
    rangesM: const [25, 50, 100],
    ballisticCoefficient: 0.12,
    ballisticModel: BallisticModel.g1,
    environment: EnvironmentData(windMps: wind),
  );

  test('experimental aerodynamic solver preserves requested range order and zero', () {
    final points = const AerodynamicTrajectorySolver().solveNoWind(input());
    expect(points.map((p) => p.rangeM), [25, 50, 100]);
    expect(points.first.dropM, closeTo(0, 2e-5));
  });

  test('duplicate requested ranges are preserved instead of failing completion check', () {
    final duplicateRanges = BallisticInput(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 25,
      sightHeightMm: 60,
      rangesM: const [100, 50, 50, 25],
      ballisticCoefficient: 0.12,
      ballisticModel: BallisticModel.g1,
    );
    final points = const AerodynamicTrajectorySolver().solveNoWind(duplicateRanges);
    expect(points.map((p) => p.rangeM), [100, 50, 50, 25]);
    expect(points[1].dropM, closeTo(points[2].dropM, 1e-12));
    expect(points[1].velocityMps, closeTo(points[2].velocityMps, 1e-12));
    expect(points[1].timeOfFlightS, closeTo(points[2].timeOfFlightS, 1e-12));
  });

  test('drag reduces velocity and energy with distance', () {
    final points = const AerodynamicTrajectorySolver().solveNoWind(input());
    expect(points[1].velocityMps, lessThan(points[0].velocityMps));
    expect(points[2].velocityMps, lessThan(points[1].velocityMps));
    expect(points[2].energyJ, lessThan(points[1].energyJ));
    expect(points[2].timeOfFlightS, greaterThan(points[1].timeOfFlightS));
  });

  test('no-wind API fails closed when wind is supplied', () {
    expect(
      () => const AerodynamicTrajectorySolver().solveNoWind(input(wind: 3)),
      throwsArgumentError,
    );
  });

  test('opposite full-value crosswinds produce opposite drift signs', () {
    BallisticInput windy(double direction) => BallisticInput(
      muzzleVelocityMps: 270, grain: 51, zeroRangeM: 25, sightHeightMm: 60,
      rangesM: const [100], ballisticCoefficient: 0.12,
      ballisticModel: BallisticModel.g1,
      environment: EnvironmentData(windMps: 5, windDirectionDeg: direction),
    );
    final right = const AerodynamicTrajectorySolver().solve(windy(90)).single;
    final left = const AerodynamicTrajectorySolver().solve(windy(270)).single;
    expect(right.windMrad, isNot(0));
    expect(left.windMrad, isNot(0));
    expect(right.windMrad.sign, -left.windMrad.sign);
    expect(right.windMrad.abs(), closeTo(left.windMrad.abs(), 0.02));
  });

  test('full-value crosswind integrates non-zero lateral displacement', () {
    final windy = BallisticInput(
      muzzleVelocityMps: 270, grain: 51, zeroRangeM: 25, sightHeightMm: 60,
      rangesM: const [50, 100], ballisticCoefficient: 0.12,
      ballisticModel: BallisticModel.g1,
      environment: const EnvironmentData(windMps: 5, windDirectionDeg: 90),
    );
    final points = const AerodynamicTrajectorySolver().solve(windy);
    expect(points.first.windMrad.abs(), greaterThan(0));
    expect(points.last.windMrad.abs(), greaterThan(points.first.windMrad.abs()));
  });


  test('crosswind trajectory reports finite positive 3-D velocity and energy', () {
    final windy = BallisticInput(
      muzzleVelocityMps: 270, grain: 51, zeroRangeM: 25, sightHeightMm: 60,
      rangesM: const [100], ballisticCoefficient: 0.12,
      ballisticModel: BallisticModel.g1,
      environment: const EnvironmentData(windMps: 5, windDirectionDeg: 90),
    );
    final point = const AerodynamicTrajectorySolver().solve(windy).single;
    expect(point.velocityMps.isFinite, isTrue);
    expect(point.velocityMps, greaterThan(0));
    expect(point.energyJ.isFinite, isTrue);
    expect(point.energyJ, greaterThan(0));
  });

  test('headwind has no lateral drift in symmetric 2-D setup', () {
    final headwind = BallisticInput(
      muzzleVelocityMps: 270, grain: 51, zeroRangeM: 25, sightHeightMm: 60,
      rangesM: const [100], ballisticCoefficient: 0.12,
      ballisticModel: BallisticModel.g1,
      environment: const EnvironmentData(windMps: 5, windDirectionDeg: 0),
    );
    final point = const AerodynamicTrajectorySolver().solve(headwind).single;
    expect(point.windMrad, closeTo(0, 1e-9));
  });

  test('RK4 solution converges when integration step is halved', () {
    final coarse = const AerodynamicTrajectorySolver(integrationStepSeconds: 0.001)
        .solveNoWind(input()).last;
    final fine = const AerodynamicTrajectorySolver(integrationStepSeconds: 0.0005)
        .solveNoWind(input()).last;
    expect(coarse.dropM, closeTo(fine.dropM, 0.0005));
    expect(coarse.velocityMps, closeTo(fine.velocityMps, 0.05));
    expect(coarse.timeOfFlightS, closeTo(fine.timeOfFlightS, 0.0005));
  });

  test('higher BC retains more velocity for the same G1 trajectory', () {
    BallisticInput withBc(double bc) => BallisticInput(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 25,
      sightHeightMm: 60,
      rangesM: const [100],
      ballisticCoefficient: bc,
      ballisticModel: BallisticModel.g1,
      environment: const EnvironmentData(),
    );
    final low = const AerodynamicTrajectorySolver().solveNoWind(withBc(0.08)).single;
    final high = const AerodynamicTrajectorySolver().solveNoWind(withBc(0.16)).single;
    expect(high.velocityMps, greaterThan(low.velocityMps));
    expect(high.timeOfFlightS, lessThan(low.timeOfFlightS));
  });


  test('current headwind does not silently re-zero the mechanical sight setting', () {
    BallisticInput shot(double wind) => BallisticInput(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 25,
      sightHeightMm: 60,
      rangesM: const [25],
      ballisticCoefficient: 0.12,
      ballisticModel: BallisticModel.g1,
      environment: EnvironmentData(windMps: wind, windDirectionDeg: 0),
    );
    final calm = const AerodynamicTrajectorySolver().solve(shot(0)).single;
    final headwind = const AerodynamicTrajectorySolver().solve(shot(20)).single;
    expect(calm.dropM, closeTo(0, 2e-5));
    // A strong current headwind changes TOF/drag at the zero distance. The
    // solver must preserve the sight setting rather than solving a new launch
    // angle that forces every environment back through the zero point.
    expect(headwind.dropM.abs(), greaterThan(1e-6));
  });

  test('mechanical zero is independent of current humidity as well as wind', () {
    BallisticInput shot(double humidity) => BallisticInput(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 25,
      sightHeightMm: 60,
      rangesM: const [25],
      ballisticCoefficient: 0.12,
      ballisticModel: BallisticModel.g1,
      environment: EnvironmentData(humidityPercent: humidity),
    );
    final dry = const AerodynamicTrajectorySolver().solve(shot(0)).single;
    final humid = const AerodynamicTrajectorySolver().solve(shot(100)).single;
    expect(dry.dropM, closeTo(0, 2e-5));
    // The shot atmosphere may move the impact, but it must not cause the
    // solver to calculate a different mechanical sight angle.
    expect(humid.dropM.abs(), greaterThan(1e-8));
  });

  test('explicit zeroing atmosphere is separate from current shot atmosphere', () {
    BallisticInput shot(EnvironmentData zeroEnv) => BallisticInput(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 100,
      sightHeightMm: 60,
      rangesM: const [100, 200],
      ballisticCoefficient: 0.12,
      ballisticModel: BallisticModel.g1,
      environment: const EnvironmentData(temperatureC: 15, pressureHpa: 1013.25, humidityPercent: 0),
      zeroEnvironment: zeroEnv,
    );
    const standard = EnvironmentData(temperatureC: 15, pressureHpa: 1013.25, humidityPercent: 0);
    const thin = EnvironmentData(temperatureC: 40, pressureHpa: 700, humidityPercent: 0);
    final standardZero = const AerodynamicTrajectorySolver().solve(shot(standard));
    final thinZero = const AerodynamicTrajectorySolver().solve(shot(thin));
    expect(standardZero.first.dropM, closeTo(0, 2e-5));
    // The same current-shot atmosphere with a zero established in a different
    // atmosphere must preserve a different mechanical launch angle.
    expect((thinZero.first.dropM - standardZero.first.dropM).abs(), greaterThan(1e-6));
    expect((thinZero.last.dropM - standardZero.last.dropM).abs(), greaterThan(1e-6));
  });

  test('invalid integration steps fail closed', () {
    expect(
      () => const AerodynamicTrajectorySolver(integrationStepSeconds: 0).solveNoWind(input()),
      throwsArgumentError,
    );
    expect(
      () => const AerodynamicTrajectorySolver(integrationStepSeconds: 0.02).solveNoWind(input()),
      throwsArgumentError,
    );
  });

}
