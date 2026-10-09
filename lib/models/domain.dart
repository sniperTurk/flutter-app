enum WeaponPlatform { pcp, firearm }

enum AmmunitionType { pellet, slug, bullet }

/// Turret / reticle angle unit. SMOA ("shooter's MOA", IPHY) is 1 inch at
/// 100 yards — 4.5 % smaller than a true MOA; American turrets marked
/// "1/4 IN @ 100 YDS" use it.
enum AngularUnit { mrad, moa, smoa }

/// Every angle conversion goes through these, so a third unit can never be
/// silently treated as MRAD by a two-way `moa ? … : …` test.
extension AngularUnitMath on AngularUnit {
  /// Milliradians in one unit: 1, π/10.8 (true MOA), 1000/3600 (SMOA:
  /// 0.0254 m / 91.44 m = 1/3600 rad).
  double get mradPerUnit => switch (this) {
    AngularUnit.mrad => 1.0,
    AngularUnit.moa => 3.141592653589793 / 10.8,
    AngularUnit.smoa => 1000 / 3600,
  };

  double toMrad(double angle) => angle * mradPerUnit;
  double fromMrad(double mrad) => mrad / mradPerUnit;

  /// MOA and SMOA share the MOA-style reticle spacing and ¼ clicks.
  bool get moaFamily => this != AngularUnit.mrad;

  /// "MRAD" / "MOA" / "SMOA".
  String get label => switch (this) {
    AngularUnit.mrad => 'MRAD',
    AngularUnit.moa => 'MOA',
    AngularUnit.smoa => 'SMOA',
  };

  /// The common click of the unit: 0.1 MRAD, ¼ MOA, ¼ SMOA (¼ inç @ 100 yd).
  double get standardClick => this == AngularUnit.mrad ? 0.1 : 0.25;
}

/// How distances are shown and typed (owner, 2026-10-09). Everything is
/// stored and solved in metres; yards are only display and input.
enum DistanceUnit { meter, yard }

extension DistanceUnitMath on DistanceUnit {
  static const metersPerYard = 0.9144;
  double fromMeters(double m) =>
      this == DistanceUnit.yard ? m / metersPerYard : m;
  double toMeters(double v) =>
      this == DistanceUnit.yard ? v * metersPerYard : v;
  String get symbol => this == DistanceUnit.yard ? 'yd' : 'm';
}

/// Drag law a ballistic coefficient refers to. GA is ChairGun's diabolo
/// pellet model (see StandardDragTables.ga).
enum BallisticModel { g1, g7, ga }

/// One step of a velocity-dependent BC (çoklu BC): [bc] applies while the
/// projectile is at least [minVelocityMps] fast (Applied Ballistics / Hornady
/// convention). Below every threshold the lowest band applies.
class BcBand {
  final double minVelocityMps;
  final double bc;
  const BcBand(this.minVelocityMps, this.bc);

  @override
  bool operator ==(Object other) =>
      other is BcBand &&
      other.minVelocityMps == minVelocityMps &&
      other.bc == bc;

  @override
  int get hashCode => Object.hash(minVelocityMps, bc);
}

/// Rifling twist direction ("namlu yiv yönü").
enum TwistDirection { right, left }

class Rifle {
  final String id, brand, model;
  final WeaponPlatform platform;
  final double caliberMm;

  /// Optional manufacturer-verified catalog metadata. Null means unknown, not zero.
  final int? magazineCapacity;
  final double? barrelLengthMm,
      airCapacityCc,
      overallLengthMm,
      weightKg,
      plenumCc;
  final String? barrelType, rail, moderatorThread, sourceName, sourceDocument;

  /// Rifling twist, entered by the user: direction and inches of barrel per
  /// full turn (1:N"). Null means not entered. Informational for now; the
  /// point-mass solver does not model spin drift.
  final TwistDirection? twistDirection;
  final double? twistRateIn;

  /// PCP regulator pressure in bar, entered by the user. Null for firearms
  /// or when not entered.
  final double? regulatorBar;

  /// True for records the user typed in (manual catalog). Such records are
  /// never manufacturer-verified and must be labelled as personal everywhere.
  final bool userEntered;
  const Rifle({
    required this.id,
    required this.brand,
    required this.model,
    required this.platform,
    required this.caliberMm,
    this.magazineCapacity,
    this.barrelLengthMm,
    this.airCapacityCc,
    this.overallLengthMm,
    this.weightKg,
    this.plenumCc,
    this.barrelType,
    this.rail,
    this.moderatorThread,
    this.sourceName,
    this.sourceDocument,
    this.twistDirection,
    this.twistRateIn,
    this.regulatorBar,
    this.userEntered = false,
  });
  String get displayName =>
      '${_joinName(brand, model)} • ${caliberMm.toStringAsFixed(2)} mm';
}

class Ammunition {
  final String id, brand, model;
  final WeaponPlatform platform;
  final double caliberMm, grain;
  final AmmunitionType type;
  final double? ballisticCoefficient;
  final BallisticModel? ballisticModel;

  /// Optional velocity-dependent BC steps (same drag law); empty = the
  /// single [ballisticCoefficient] applies at every speed.
  final List<BcBand> bcBands;
  final String? sourceName, sourceDocument;

  /// See [Rifle.userEntered].
  final bool userEntered;
  const Ammunition({
    required this.id,
    required this.brand,
    required this.model,
    required this.platform,
    required this.caliberMm,
    required this.grain,
    required this.type,
    this.ballisticCoefficient,
    this.ballisticModel,
    this.bcBands = const [],
    this.sourceName,
    this.sourceDocument,
    this.userEntered = false,
  });
  String get displayName =>
      '${_joinName(brand, model)} • '
      '${grain.toStringAsFixed(grain % 1 == 0 ? 0 : 1)} gr';
}

class ScopeOptic {
  final String id, brand, model;
  final double objectiveDiameterMm, clickValue;
  final AngularUnit clickUnit;

  /// Optional manufacturer-verified optic metadata. `objectiveDiameterMm` is
  /// the optical objective size in the model designation;
  /// `objectiveOuterDiameterMm` is the physical bell/housing diameter when
  /// the manufacturer publishes it. They must never be treated as the same.
  final double? objectiveOuterDiameterMm,
      tubeDiameterMm,
      minMagnification,
      maxMagnification;
  final double? elevationRangeMrad, windageRangeMrad, lengthMm, weightG;
  final bool? firstFocalPlane, zeroStop;

  /// True when the manufacturer publishes the corresponding adjustment range
  /// as a strict lower bound (for example `>17.5 MIL`) rather than an exact
  /// total travel. This prevents catalog consumers from silently presenting a
  /// lower bound as an exact manufacturer value.
  final bool elevationRangeIsLowerBound, windageRangeIsLowerBound;
  final String? reticle, sourceName, sourceDocument;

  /// See [Rifle.userEntered].
  final bool userEntered;
  const ScopeOptic({
    required this.id,
    required this.brand,
    required this.model,
    required this.objectiveDiameterMm,
    required this.clickValue,
    required this.clickUnit,
    this.objectiveOuterDiameterMm,
    this.tubeDiameterMm,
    this.minMagnification,
    this.maxMagnification,
    this.elevationRangeMrad,
    this.windageRangeMrad,
    this.lengthMm,
    this.weightG,
    this.firstFocalPlane,
    this.zeroStop,
    this.elevationRangeIsLowerBound = false,
    this.windageRangeIsLowerBound = false,
    this.reticle,
    this.sourceName,
    this.sourceDocument,
    this.userEntered = false,
  });
  String get displayName => _joinName(brand, model);
}

/// "Brand Model" without a stray space when one part is empty (personal
/// ammunition keeps its whole name in the brand since 2026-10-09).
String _joinName(String brand, String model) =>
    [brand.trim(), model.trim()].where((s) => s.isNotEmpty).join(' ');

class RifleProfile {
  final String id, name, rifleId, ammunitionId, scopeId;
  final double muzzleVelocityMps, zeroRangeM, sightHeightMm;
  final double? pressureBar;
  final AngularUnit angularUnit;

  /// Metre or yard for every distance shown for this profile.
  final DistanceUnit distanceUnit;

  /// Built-in slope of the scope mount/rail (e.g. a 30 MOA "No Limit"
  /// base), in MOA; 0 for a normal flat mount. It does not change the drop
  /// or the correction from zero: it shifts the zeroed turret down in its
  /// travel, so the scope has this much more room to dial UP.
  final double mountCantMoa;
  const RifleProfile({
    required this.id,
    required this.name,
    required this.rifleId,
    required this.ammunitionId,
    required this.scopeId,
    required this.muzzleVelocityMps,
    required this.zeroRangeM,
    required this.sightHeightMm,
    this.pressureBar,
    this.angularUnit = AngularUnit.mrad,
    this.distanceUnit = DistanceUnit.meter,
    this.mountCantMoa = 0,
  });
}

class EnvironmentData {
  final double temperatureC,
      pressureHpa,
      humidityPercent,
      altitudeM,
      windMps,
      windDirectionDeg;
  const EnvironmentData({
    this.temperatureC = 15,
    this.pressureHpa = 1013.25,
    this.humidityPercent = 50,
    this.altitudeM = 0,
    this.windMps = 0,
    this.windDirectionDeg = 90,
  });
}

class TrajectoryPoint {
  final double rangeM,
      dropM,
      correctionMrad,
      correctionMoa,
      velocityMps,
      energyJ,
      timeOfFlightS,
      windMrad;
  const TrajectoryPoint({
    required this.rangeM,
    required this.dropM,
    required this.correctionMrad,
    required this.correctionMoa,
    required this.velocityMps,
    required this.energyJ,
    required this.timeOfFlightS,
    required this.windMrad,
  });
}
