import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  test('valid ballistic input is immutable and accepted by solver', () {
    final source = <double>[25, 50, 100];
    final input = BallisticInput(
      muzzleVelocityMps: 270,
      grain: 51,
      zeroRangeM: 25,
      sightHeightMm: 60,
      rangesM: source,
    );
    source.add(150);
    expect(input.rangesM, [25, 50, 100]);
    expect(() => input.rangesM.add(200), throwsUnsupportedError);
    expect(const BallisticEngine().solveVacuum(input), hasLength(3));
  });

  test('rejects malformed physical inputs before solver', () {
    expect(
      () => BallisticInput(
        muzzleVelocityMps: double.nan,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 0,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: -1,
        rangesM: [100],
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [],
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid environment boundaries', () {
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
        environment: const EnvironmentData(humidityPercent: 101),
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
        environment: const EnvironmentData(windMps: -1),
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
        environment: const EnvironmentData(windDirectionDeg: 361),
      ),
      throwsArgumentError,
    );
  });

  test('BC and drag model must be supplied as a pair', () {
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
        ballisticCoefficient: 0.12,
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
        ballisticModel: BallisticModel.g1,
      ),
      throwsArgumentError,
    );
  });

  test('validates zeroing environment independently', () {
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: const [100],
        zeroEnvironment: const EnvironmentData(pressureHpa: 299),
      ),
      throwsArgumentError,
    );
  });

  test('rejects finite but physically implausible production inputs', () {
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 1501,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [3001],
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
        environment: const EnvironmentData(temperatureC: 61),
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
        environment: const EnvironmentData(pressureHpa: 299),
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
        environment: const EnvironmentData(windMps: 60),
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 60,
        rangesM: [100],
        ballisticCoefficient: 5.01,
        ballisticModel: BallisticModel.g1,
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 0,
        rangesM: [100],
      ),
      throwsArgumentError,
    );
    expect(
      () => BallisticInput(
        muzzleVelocityMps: 270,
        grain: 51,
        zeroRangeM: 25,
        sightHeightMm: 300,
        rangesM: [100],
      ),
      throwsArgumentError,
    );
  });
}
