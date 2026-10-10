import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/gravity.dart';
import 'package:sniper_turk/models/domain.dart';

BallisticInput _input(double g) => BallisticInput(
  muzzleVelocityMps: 800,
  grain: 168,
  zeroRangeM: 100,
  sightHeightMm: 45,
  rangesM: const [1000],
  ballisticCoefficient: 0.462,
  ballisticModel: BallisticModel.g1,
  gravityMps2: g,
);

void main() {
  test('WGS-84 normal gravity anchors', () {
    expect(Gravity.at(latitudeDeg: 0), closeTo(9.7803, 1e-4));
    expect(Gravity.at(latitudeDeg: 90), closeTo(9.8322, 1e-4));
    expect(Gravity.at(latitudeDeg: 45), closeTo(9.8062, 1e-4));
    // Ankara, ~39.9° N, 900 m.
    final ankara = Gravity.at(latitudeDeg: 39.9, altitudeM: 900);
    expect(ankara, closeTo(9.7988, 1e-4));
    // Higher is lighter.
    expect(
      Gravity.at(latitudeDeg: 40, altitudeM: 2000),
      lessThan(Gravity.at(latitudeDeg: 40)),
    );
  });

  test('stronger gravity drops more; standard is the default', () {
    const engine = BallisticEngine();
    final std = engine.solve(_input(Gravity.standard)).single;
    final pole = engine.solve(_input(9.832)).single;
    final eq = engine.solve(_input(9.780)).single;
    expect(pole.correctionMrad, greaterThan(std.correctionMrad));
    expect(eq.correctionMrad, lessThan(std.correctionMrad));
    // A few hundredths of a mrad at 1000 m: real but small.
    expect((pole.correctionMrad - eq.correctionMrad).abs(), lessThan(0.2));
  });

  test('implausible gravity is rejected', () {
    expect(() => _input(5), throwsArgumentError);
  });
}
