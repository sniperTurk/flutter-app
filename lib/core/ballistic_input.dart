import '../models/domain.dart';
import 'production_limits.dart';

/// Validated boundary object for trajectory calculations.
/// Keeps malformed UI/profile values out of the solver.
class BallisticInput {
  final double muzzleVelocityMps;
  final double grain;
  final double zeroRangeM;
  final double sightHeightMm;
  final List<double> rangesM;
  final EnvironmentData environment;

  /// Atmosphere/wind state in which the mechanical zero was established.
  /// Kept separate from the current-shot environment so changing today's
  /// weather cannot silently re-zero the sight. Defaults to ICAO dry standard.
  final EnvironmentData zeroEnvironment;
  final double? ballisticCoefficient;
  final BallisticModel? ballisticModel;

  /// Shot incline: angle of the line of sight above (+) or below (−) the
  /// horizontal, degrees. Ranges are measured ALONG the line of sight (what a
  /// laser rangefinder reports). The zero is always solved level.
  final double inclineDeg;

  /// Scope cant: roll of the scope about the line of sight, degrees;
  /// positive = rotated clockwise as seen by the shooter (top to the right).
  /// Corrections are then reported in the canted scope's own axes, i.e. the
  /// clicks to dial on the canted turrets. The zero is solved without cant.
  final double cantDeg;

  /// The same input for different [ranges] (validated again).
  BallisticInput withRanges(Iterable<double> ranges) => BallisticInput(
    muzzleVelocityMps: muzzleVelocityMps,
    grain: grain,
    zeroRangeM: zeroRangeM,
    sightHeightMm: sightHeightMm,
    rangesM: ranges,
    environment: environment,
    zeroEnvironment: zeroEnvironment,
    ballisticCoefficient: ballisticCoefficient,
    ballisticModel: ballisticModel,
    inclineDeg: inclineDeg,
    cantDeg: cantDeg,
  );

  BallisticInput({
    required this.muzzleVelocityMps,
    required this.grain,
    required this.zeroRangeM,
    required this.sightHeightMm,
    required Iterable<double> rangesM,
    this.environment = const EnvironmentData(),
    this.zeroEnvironment = const EnvironmentData(
      temperatureC: 15,
      pressureHpa: 1013.25,
      humidityPercent: 0,
      altitudeM: 0,
      windMps: 0,
      windDirectionDeg: 90,
    ),
    this.ballisticCoefficient,
    this.ballisticModel,
    this.inclineDeg = 0,
    this.cantDeg = 0,
  }) : rangesM = List.unmodifiable(rangesM) {
    _positiveFinite('muzzleVelocityMps', muzzleVelocityMps);
    _max(
      'muzzleVelocityMps',
      muzzleVelocityMps,
      ProductionLimits.maxMuzzleVelocityMps,
    );
    _positiveFinite('grain', grain);
    _positiveFinite('zeroRangeM', zeroRangeM);
    _max('zeroRangeM', zeroRangeM, ProductionLimits.maxRangeM);
    _positiveFinite('sightHeightMm', sightHeightMm);
    _max(
      'sightHeightMm',
      sightHeightMm,
      ProductionLimits.maxSightHeightMm,
      inclusive: false,
    );
    if (this.rangesM.isEmpty) throw ArgumentError('rangesM must not be empty');
    for (final range in this.rangesM) {
      _positiveFinite('rangeM', range);
      _max('rangeM', range, ProductionLimits.maxRangeM);
    }
    if ((ballisticCoefficient == null) != (ballisticModel == null)) {
      throw ArgumentError(
        'ballisticCoefficient and ballisticModel must be supplied together',
      );
    }
    if (ballisticCoefficient != null) {
      _positiveFinite('ballisticCoefficient', ballisticCoefficient!);
      _max('ballisticCoefficient', ballisticCoefficient!, 5);
    }
    _finite('temperatureC', environment.temperatureC);
    _range('temperatureC', environment.temperatureC, -60, 60);
    _positiveFinite('pressureHpa', environment.pressureHpa);
    _range('pressureHpa', environment.pressureHpa, 300, 1100);
    _finite('humidityPercent', environment.humidityPercent);
    if (environment.humidityPercent < 0 || environment.humidityPercent > 100) {
      throw ArgumentError.value(
        environment.humidityPercent,
        'humidityPercent',
        'must be between 0 and 100',
      );
    }
    _finite('altitudeM', environment.altitudeM);
    _finite('windMps', environment.windMps);
    if (environment.windMps < 0) {
      throw ArgumentError.value(environment.windMps, 'windMps', 'must be >= 0');
    }
    _max('windMps', environment.windMps, 60, inclusive: false);
    _finite('windDirectionDeg', environment.windDirectionDeg);
    if (environment.windDirectionDeg < 0 ||
        environment.windDirectionDeg > 360) {
      throw ArgumentError.value(
        environment.windDirectionDeg,
        'windDirectionDeg',
        'must be between 0 and 360',
      );
    }
    _validateEnvironment('zeroEnvironment', zeroEnvironment);
    _finite('inclineDeg', inclineDeg);
    _range(
      'inclineDeg',
      inclineDeg,
      -ProductionLimits.maxInclineDeg,
      ProductionLimits.maxInclineDeg,
    );
    _finite('cantDeg', cantDeg);
    _range(
      'cantDeg',
      cantDeg,
      -ProductionLimits.maxCantDeg,
      ProductionLimits.maxCantDeg,
    );
  }

  static void _validateEnvironment(String prefix, EnvironmentData environment) {
    _finite('$prefix.temperatureC', environment.temperatureC);
    _range('$prefix.temperatureC', environment.temperatureC, -60, 60);
    _positiveFinite('$prefix.pressureHpa', environment.pressureHpa);
    _range('$prefix.pressureHpa', environment.pressureHpa, 300, 1100);
    _finite('$prefix.humidityPercent', environment.humidityPercent);
    if (environment.humidityPercent < 0 || environment.humidityPercent > 100) {
      throw ArgumentError.value(
        environment.humidityPercent,
        '$prefix.humidityPercent',
        'must be between 0 and 100',
      );
    }
    _finite('$prefix.altitudeM', environment.altitudeM);
    _finite('$prefix.windMps', environment.windMps);
    if (environment.windMps < 0 || environment.windMps >= 60) {
      throw ArgumentError.value(
        environment.windMps,
        '$prefix.windMps',
        'must be >= 0 and < 60',
      );
    }
    _finite('$prefix.windDirectionDeg', environment.windDirectionDeg);
    if (environment.windDirectionDeg < 0 ||
        environment.windDirectionDeg > 360) {
      throw ArgumentError.value(
        environment.windDirectionDeg,
        '$prefix.windDirectionDeg',
        'must be between 0 and 360',
      );
    }
  }

  static void _finite(String name, double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }

  static void _range(String name, double value, double min, double max) {
    if (value < min || value > max) {
      throw ArgumentError.value(value, name, 'must be between $min and $max');
    }
  }

  static void _max(
    String name,
    double value,
    double max, {
    bool inclusive = true,
  }) {
    final invalid = inclusive ? value > max : value >= max;
    if (invalid) {
      throw ArgumentError.value(
        value,
        name,
        inclusive ? 'must be <= $max' : 'must be < $max',
      );
    }
  }

  static void _positiveFinite(String name, double value) {
    _finite(name, value);
    if (value <= 0) throw ArgumentError.value(value, name, 'must be > 0');
  }
}
