enum WeaponPlatform { pcp, firearm }

enum AmmunitionType { pellet, slug, bullet }

enum AngularUnit { mrad, moa }

enum BallisticModel { g1, g7 }

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
      '$brand $model • ${caliberMm.toStringAsFixed(2)} mm';
}

class Ammunition {
  final String id, brand, model;
  final WeaponPlatform platform;
  final double caliberMm, grain;
  final AmmunitionType type;
  final double? ballisticCoefficient;
  final BallisticModel? ballisticModel;
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
    this.sourceName,
    this.sourceDocument,
    this.userEntered = false,
  });
  String get displayName =>
      '$brand $model • ${grain.toStringAsFixed(grain % 1 == 0 ? 0 : 1)} gr';
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
  String get displayName => '$brand $model';
}

class RifleProfile {
  final String id, name, rifleId, ammunitionId, scopeId;
  final double muzzleVelocityMps, zeroRangeM, sightHeightMm;
  final double? pressureBar;
  final AngularUnit angularUnit;

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
