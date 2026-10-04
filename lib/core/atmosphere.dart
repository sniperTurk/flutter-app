import 'dart:math' as math;

import '../models/domain.dart';

/// Deterministic moist-air model used by the external-ballistics pipeline.
///
/// `pressureHpa` is treated as absolute station pressure. Altitude is therefore
/// not applied a second time; callers that only know sea-level-corrected
/// pressure must convert it to station pressure before constructing the input.
class Atmosphere {
  static const double standardDensityKgM3 = 1.225;
  static const double _dryAirGasConstant = 287.05;
  static const double _waterVaporGasConstant = 461.495;

  const Atmosphere._();

  /// Saturation vapor pressure over liquid water in hPa (Magnus formula).
  static double saturationVaporPressureHpa(double temperatureC) {
    if (!temperatureC.isFinite) {
      throw ArgumentError.value(temperatureC, 'temperatureC', 'must be finite');
    }
    return 6.112 * math.exp((17.62 * temperatureC) / (243.12 + temperatureC));
  }

  /// Moist-air density in kg/m³ from station pressure, temperature and RH.
  static double densityKgM3(EnvironmentData environment) {
    final temperatureC = environment.temperatureC;
    final pressureHpa = environment.pressureHpa;
    final humidity = environment.humidityPercent;
    if (!temperatureC.isFinite || temperatureC <= -273.15) {
      throw ArgumentError.value(temperatureC, 'temperatureC', 'must be finite and above absolute zero');
    }
    if (!pressureHpa.isFinite || pressureHpa <= 0) {
      throw ArgumentError.value(pressureHpa, 'pressureHpa', 'must be finite and > 0');
    }
    if (!humidity.isFinite || humidity < 0 || humidity > 100) {
      throw ArgumentError.value(humidity, 'humidityPercent', 'must be between 0 and 100');
    }

    final temperatureK = temperatureC + 273.15;
    final vaporPressurePa = saturationVaporPressureHpa(temperatureC) * 100 * humidity / 100;
    final totalPressurePa = pressureHpa * 100;
    if (vaporPressurePa >= totalPressurePa) {
      throw ArgumentError('water-vapor partial pressure must be below station pressure');
    }
    final dryPressurePa = totalPressurePa - vaporPressurePa;
    return dryPressurePa / (_dryAirGasConstant * temperatureK) +
        vaporPressurePa / (_waterVaporGasConstant * temperatureK);
  }

  static double densityRatio(EnvironmentData environment) =>
      densityKgM3(environment) / standardDensityKgM3;

  /// Local speed of sound in m/s using the same moist-air state as density.
  ///
  /// External drag tables are indexed by Mach, so deriving Mach from the
  /// exact atmosphere used by the trajectory solver avoids mixing a fixed
  /// 340.3 m/s constant with user-entered temperature/pressure/humidity.
  /// Gamma=1.4 is the standard engineering approximation for atmospheric air.
  static double speedOfSoundMps(EnvironmentData environment) {
    const gamma = 1.4;
    final pressurePa = environment.pressureHpa * 100;
    final rho = densityKgM3(environment);
    return math.sqrt(gamma * pressurePa / rho);
  }

  /// Converts projectile speed to local Mach number for future G1/G7 lookup.
  static double machNumber({
    required double velocityMps,
    required EnvironmentData environment,
  }) {
    if (!velocityMps.isFinite || velocityMps < 0) {
      throw ArgumentError.value(velocityMps, 'velocityMps', 'must be finite and >= 0');
    }
    return velocityMps / speedOfSoundMps(environment);
  }
}
