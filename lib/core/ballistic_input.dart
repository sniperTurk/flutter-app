import '../models/domain.dart';
import 'gravity.dart';
import 'production_limits.dart';

/// Rüzgâr bölgeleri (owner, 2026-10-09): the shooter's wind (the
/// environment's) applies over the first third of [rangeM], [midMps] over the
/// middle third and [farMps] beyond. Same direction everywhere.
class WindZones {
  final double rangeM, midMps, farMps;
  const WindZones({
    required this.rangeM,
    required this.midMps,
    required this.farMps,
  });

  double at(double downrangeM, double nearMps) {
    if (downrangeM < rangeM / 3) return nearMps;
    if (downrangeM < rangeM * 2 / 3) return midMps;
    return farMps;
  }
}

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

  /// Velocity-dependent BC steps (çoklu BC); empty = [ballisticCoefficient]
  /// at every speed. Thresholds are projectile speed through the air.
  final List<BcBand> bcBands;

  /// Wind by distance (shot only; the zero is solved in calm air).
  final WindZones? windZones;

  /// Wind speed at [downrangeM] for the current shot.
  double windAt(double downrangeM) =>
      windZones?.at(downrangeM, environment.windMps) ?? environment.windMps;

  /// BC that applies at [speedMps]: the band with the highest threshold the
  /// speed still reaches, else the lowest band, else [ballisticCoefficient].
  double bcAtSpeed(double speedMps) {
    final base = ballisticCoefficient;
    if (bcBands.isEmpty) {
      if (base == null) throw StateError('no ballistic coefficient');
      return base;
    }
    for (final b in bcBands) {
      if (speedMps >= b.minVelocityMps) return b.bc;
    }
    return bcBands.last.bc;
  }

  /// Shot incline: angle of the line of sight above (+) or below (−) the
  /// horizontal, degrees. Ranges are measured ALONG the line of sight (what a
  /// laser rangefinder reports). The zero is always solved level.
  final double inclineDeg;

  /// Scope cant: roll of the scope about the line of sight, degrees;
  /// positive = rotated clockwise as seen by the shooter (top to the right).
  /// Corrections are then reported in the canted scope's own axes, i.e. the
  /// clicks to dial on the canted turrets. The zero is solved without cant.
  final double cantDeg;

  /// Coriolis (Earth's rotation): shooter latitude in degrees (+ north,
  /// − south) and the shot azimuth in degrees clockwise from true north.
  /// Both null = Coriolis off. The zero is solved without it.
  final double? latitudeDeg;
  final double? azimuthDeg;

  bool get coriolis => latitudeDeg != null && azimuthDeg != null;

  /// Muzzle velocity the rifle had when it was zeroed, when it differs from
  /// today's (barut sıcaklığı, owner 2026-10-09). Null = the same velocity.
  final double? zeroMuzzleVelocityMps;

  double get zeroVelocityMps => zeroMuzzleVelocityMps ?? muzzleVelocityMps;

  /// Local gravity (m/s²); [Gravity.standard] when the place is unknown.
  final double gravityMps2;

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
    bcBands: bcBands,
    windZones: windZones,
    inclineDeg: inclineDeg,
    cantDeg: cantDeg,
    latitudeDeg: latitudeDeg,
    azimuthDeg: azimuthDeg,
    zeroMuzzleVelocityMps: zeroMuzzleVelocityMps,
    gravityMps2: gravityMps2,
  );

  /// The same input with another muzzle velocity (validated again). Used by
  /// truing, which searches the velocity that reproduces an observed hit.
  ///
  /// A separate zero-day velocity (powder temperature) is scaled by the same
  /// ratio, so a velocity error found by truing applies to both days.
  BallisticInput withMuzzleVelocity(double mps) => BallisticInput(
    muzzleVelocityMps: mps,
    grain: grain,
    zeroRangeM: zeroRangeM,
    sightHeightMm: sightHeightMm,
    rangesM: rangesM,
    environment: environment,
    zeroEnvironment: zeroEnvironment,
    ballisticCoefficient: ballisticCoefficient,
    ballisticModel: ballisticModel,
    bcBands: bcBands,
    windZones: windZones,
    inclineDeg: inclineDeg,
    cantDeg: cantDeg,
    latitudeDeg: latitudeDeg,
    azimuthDeg: azimuthDeg,
    zeroMuzzleVelocityMps: zeroMuzzleVelocityMps == null
        ? null
        : zeroMuzzleVelocityMps! * mps / muzzleVelocityMps,
    gravityMps2: gravityMps2,
  );

  /// The same input with another G1/G7 ballistic coefficient (validated
  /// again). Used by BC truing at a far range.
  BallisticInput withBallisticCoefficient(double bc) => BallisticInput(
    muzzleVelocityMps: muzzleVelocityMps,
    grain: grain,
    zeroRangeM: zeroRangeM,
    sightHeightMm: sightHeightMm,
    rangesM: rangesM,
    environment: environment,
    zeroEnvironment: zeroEnvironment,
    ballisticCoefficient: bc,
    ballisticModel: ballisticModel,
    // Truing scales a velocity-dependent BC as a whole.
    bcBands: [
      for (final b in bcBands)
        BcBand(b.minVelocityMps, b.bc * bc / ballisticCoefficient!),
    ],
    windZones: windZones,
    inclineDeg: inclineDeg,
    cantDeg: cantDeg,
    latitudeDeg: latitudeDeg,
    azimuthDeg: azimuthDeg,
    zeroMuzzleVelocityMps: zeroMuzzleVelocityMps,
    gravityMps2: gravityMps2,
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
    Iterable<BcBand> bcBands = const [],
    this.windZones,
    this.inclineDeg = 0,
    this.cantDeg = 0,
    this.latitudeDeg,
    this.azimuthDeg,
    this.zeroMuzzleVelocityMps,
    this.gravityMps2 = Gravity.standard,
  }) : rangesM = List.unmodifiable(rangesM),
       // Fastest band first, so [bcAtSpeed] takes the first one reached.
       bcBands = List.unmodifiable(
         bcBands.toList()
           ..sort((a, b) => b.minVelocityMps.compareTo(a.minVelocityMps)),
       ) {
    final z = windZones;
    if (z != null) {
      _positiveFinite('windZones.rangeM', z.rangeM);
      for (final w in [z.midMps, z.farMps]) {
        if (!w.isFinite || w < 0 || w > 60) {
          throw ArgumentError.value(w, 'windZones', '0..60 m/s');
        }
      }
    }
    if (this.bcBands.length > 5) {
      throw ArgumentError.value(this.bcBands.length, 'bcBands', 'at most 5');
    }
    for (final b in this.bcBands) {
      _positiveFinite('bcBands.bc', b.bc);
      if (!b.minVelocityMps.isFinite || b.minVelocityMps < 0) {
        throw ArgumentError.value(b.minVelocityMps, 'bcBands.minVelocityMps');
      }
    }
    _positiveFinite('muzzleVelocityMps', muzzleVelocityMps);
    _max(
      'muzzleVelocityMps',
      muzzleVelocityMps,
      ProductionLimits.maxMuzzleVelocityMps,
    );
    if (!gravityMps2.isFinite || gravityMps2 < 9.7 || gravityMps2 > 9.9) {
      throw ArgumentError.value(gravityMps2, 'gravityMps2', 'must be 9.7–9.9');
    }
    final zv = zeroMuzzleVelocityMps;
    if (zv != null) {
      _positiveFinite('zeroMuzzleVelocityMps', zv);
      _max('zeroMuzzleVelocityMps', zv, ProductionLimits.maxMuzzleVelocityMps);
    }
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
    if (this.bcBands.isNotEmpty && ballisticCoefficient == null) {
      throw ArgumentError('bcBands need a ballisticCoefficient and model');
    }
    for (final b in this.bcBands) {
      _max('bcBands.bc', b.bc, 5);
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
    if ((latitudeDeg == null) != (azimuthDeg == null)) {
      throw ArgumentError('latitudeDeg and azimuthDeg must be given together');
    }
    if (latitudeDeg != null) {
      _finite('latitudeDeg', latitudeDeg!);
      _range('latitudeDeg', latitudeDeg!, -90, 90);
      _finite('azimuthDeg', azimuthDeg!);
      _range('azimuthDeg', azimuthDeg!, 0, 360);
    }
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
