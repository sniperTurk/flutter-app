import '../core/drag_table.dart';
import '../core/pcp_pressure.dart';

export '../core/pcp_pressure.dart' show PressureVelocityPoint;

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

/// Reference drag law of a BC: G1/G7 plus the other public BRL G-functions
/// (G2, G5, G6, G8, GI), GS (sphere) and RA4 (.22 LR). The former GA pellet
/// model was removed (owner, 2026-10-12): its table had no manufacturer or
/// published source. Pellet BCs are published against G1.
enum BallisticModel { g1, g2, g5, g6, g7, g8, gi, gs, ra4 }

/// Display name of a drag law.
extension BallisticModelLabel on BallisticModel {
  String get label => switch (this) {
    BallisticModel.ra4 => 'RA4',
    _ => name.toUpperCase(),
  };
}

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

  /// Özel sürüklenme eğrisi: the bullet's own Cd-vs-Mach curve. When set,
  /// [ballisticCoefficient] holds the sectional density (lb/in²) and
  /// [ballisticModel] is G1 only for storage; the solver uses this curve.
  final List<DragSample>? dragCurve;

  /// Projectile length in mm (PCP pellet/slug; null = not given). Used for
  /// the stability check (owner, 2026-10-12: "Uzunluk hesaplamada fayda
  /// sağlar").
  final double? lengthMm;
  final String? sourceName, sourceDocument;

  /// See [Rifle.userEntered].
  final bool userEntered;

  /// BC modeli the user picked although no BC was given (PCP, owner
  /// 2026-10-14). Never fed to the solver: without a BC there is no drag
  /// law to apply, and the estimated BC is always G1. Kept so Profil shows
  /// the pick again and the Balistik note can say G1 was used instead.
  final BallisticModel? modelWithoutBc;
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
    this.dragCurve,
    this.lengthMm,
    this.sourceName,
    this.sourceDocument,
    this.userEntered = false,
    this.modelWithoutBc,
  });

  /// [dragCurve] as a solver table; null = the standard table of the model.
  DragTable? get dragTable {
    final c = dragCurve;
    return c == null ? null : DragTable(c);
  }

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

  /// PCP regülatör basıncı in bar (null = unregulated or unknown; always
  /// null on a firearm). Stored as `pressureBar` since V379 ("Atış basıncı"
  /// became the regulator pressure), so older profiles keep their value.
  final double? pressureBar;

  /// PCP tüp basıncı (dolum basıncı) in bar; null = not given / firearm.
  final double? tubePressureBar;

  /// PCP "Basınca göre hız" points saved before 2026-10-16 (tube pressure
  /// in bar, velocity in m/s). The feature is deleted (owner, 2026-10-16):
  /// the table is only carried so a re-save does not erase the user's saved
  /// data; NOTHING reads it for a calculation.
  final List<PressureVelocityPoint> pressureVelocityTable;

  /// PCP En düşük / En yüksek namlu çıkış hızı in m/s (owner, 2026-10-16:
  /// the lowest and highest of 10 chronograph shots, Mühimmat card).
  /// Optional, each on its own, and always null on a firearm. Saved and
  /// loaded only: owner 2026-10-17 ("namlu çıkış hızından yapsın
  /// hesaplamayı"), every calculation uses the Tüfek card's Namlu çıkış
  /// hızı [muzzleVelocityMps].
  final double? pcpMinVelocityMps, pcpMaxVelocityMps;
  final AngularUnit angularUnit;

  /// Metre or yard for every distance shown for this profile.
  final DistanceUnit distanceUnit;

  /// Built-in slope of the scope mount/rail (e.g. a 30 MOA "No Limit"
  /// base), in MOA; 0 for a normal flat mount. It does not change the drop
  /// or the correction from zero: it shifts the zeroed turret down in its
  /// travel, so the scope has this much more room to dial UP.
  final double mountCantMoa;

  /// Barut sıcaklığı (firearms only; null on PCP and when unknown): the
  /// velocity change in % per 15 °C and the air temperature (°C) at which
  /// [muzzleVelocityMps] was measured. Today's velocity is scaled from the
  /// Hava Durumu temperature by [PowderTemperature.factor].
  final double? powderTempCoefPercentPer15C;
  final double? powderTempReferenceC;
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
    this.tubePressureBar,
    this.pressureVelocityTable = const [],
    this.pcpMinVelocityMps,
    this.pcpMaxVelocityMps,
    this.angularUnit = AngularUnit.mrad,
    this.distanceUnit = DistanceUnit.meter,
    this.mountCantMoa = 0,
    this.powderTempCoefPercentPer15C,
    this.powderTempReferenceC,
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
