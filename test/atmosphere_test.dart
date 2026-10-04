import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/atmosphere.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  test('standard dry sea-level air is approximately 1.225 kg/m3', () {
    const environment = EnvironmentData(
      temperatureC: 15,
      pressureHpa: 1013.25,
      humidityPercent: 0,
    );
    expect(Atmosphere.densityKgM3(environment), closeTo(1.2250, 0.0005));
    expect(Atmosphere.densityRatio(environment), closeTo(1.0, 0.0005));
  });

  test('humidity lowers density at equal pressure and temperature', () {
    const dry = EnvironmentData(temperatureC: 25, pressureHpa: 1013.25, humidityPercent: 0);
    const humid = EnvironmentData(temperatureC: 25, pressureHpa: 1013.25, humidityPercent: 100);
    expect(Atmosphere.densityKgM3(humid), lessThan(Atmosphere.densityKgM3(dry)));
  });

  test('invalid atmosphere is rejected', () {
    expect(
      () => Atmosphere.densityKgM3(const EnvironmentData(temperatureC: -273.15)),
      throwsArgumentError,
    );
    expect(
      () => Atmosphere.densityKgM3(const EnvironmentData(pressureHpa: 0)),
      throwsArgumentError,
    );
  });


  test('speed of sound is near ISA value at 15 C', () {
    const env = EnvironmentData(
      temperatureC: 15,
      pressureHpa: 1013.25,
      humidityPercent: 0,
    );
    expect(Atmosphere.speedOfSoundMps(env), closeTo(340.3, 0.6));
  });

  test('Mach conversion uses local atmosphere and validates velocity', () {
    const env = EnvironmentData(temperatureC: 15, humidityPercent: 0);
    final sound = Atmosphere.speedOfSoundMps(env);
    expect(Atmosphere.machNumber(velocityMps: sound, environment: env), closeTo(1, 1e-12));
    expect(
      () => Atmosphere.machNumber(velocityMps: -1, environment: env),
      throwsArgumentError,
    );
  });
}
