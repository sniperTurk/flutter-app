import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/unit_system.dart';

void main() {
  test('imperial conversions round-trip to canonical SI', () {
    expect(UnitSystem.fpsToMps(UnitSystem.mpsToFps(270)), closeTo(270, 1e-9));
    expect(
      UnitSystem.yardsToMeters(UnitSystem.metersToYards(100)),
      closeTo(100, 1e-9),
    );
    expect(
      UnitSystem.inchesToMillimeters(UnitSystem.millimetersToInches(65)),
      closeTo(65, 1e-9),
    );
    expect(
      UnitSystem.inHgToHpa(UnitSystem.hpaToInHg(1013.25)),
      closeTo(1013.25, 1e-8),
    );
    expect(UnitSystem.mphToMps(UnitSystem.mpsToMph(5)), closeTo(5, 1e-9));
    expect(
      UnitSystem.fahrenheitToCelsius(UnitSystem.celsiusToFahrenheit(15)),
      closeTo(15, 1e-9),
    );
  });

  test('known display conversions are stable', () {
    expect(UnitSystem.metersToYards(100), closeTo(109.3613, 0.0001));
    expect(UnitSystem.mpsToFps(300), closeTo(984.252, 0.001));
    expect(UnitSystem.joulesToFootPounds(100), closeTo(73.7562, 0.0001));
  });
}
