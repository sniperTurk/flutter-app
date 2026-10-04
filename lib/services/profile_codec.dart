// dart format off
import '../models/domain.dart';
import '../core/production_limits.dart';

/// Version-tolerant profile serialization kept separate from persistence so it
/// can be regression tested without platform plugins.
class ProfileCodec {
  const ProfileCodec();

  Map<String, dynamic> encode(RifleProfile p) => {
        'id': p.id,
        'name': p.name,
        'rifleId': p.rifleId,
        'ammunitionId': p.ammunitionId,
        'scopeId': p.scopeId,
        'muzzleVelocityMps': p.muzzleVelocityMps,
        'zeroRangeM': p.zeroRangeM,
        'sightHeightMm': p.sightHeightMm,
        'pressureBar': p.pressureBar,
        'angularUnit': p.angularUnit.name,
      };

  RifleProfile decode(Map<String, dynamic> j) {
    String requiredString(String key, {int? maxLength}) {
      final value = j[key];
      if (value is! String || value.trim().isEmpty ||
          (maxLength != null && value.trim().length > maxLength)) {
        throw FormatException('Invalid profile field: $key');
      }
      return value;
    }

    double requiredPositive(String key, {double? max, bool maxExclusive = false}) {
      final value = j[key];
      final numeric = value is num ? value.toDouble() : double.nan;
      if (!numeric.isFinite || numeric <= 0 ||
          (max != null && (maxExclusive ? numeric >= max : numeric > max))) {
        throw FormatException('Invalid profile field: $key');
      }
      return numeric;
    }

    // angularUnit was absent in the oldest V1 payloads; preserve that legacy
    // migration as MRAD. If the field is present, however, an unknown value is
    // corruption rather than a migration signal. Silently coercing e.g. a
    // damaged `moa` value to MRAD can change every displayed DOPE correction.
    final unitName = j['angularUnit'];
    final AngularUnit unit;
    if (unitName == null) {
      unit = AngularUnit.mrad;
    } else if (unitName is String) {
      final matchingUnits = AngularUnit.values.where((u) => u.name == unitName);
      if (matchingUnits.isEmpty) {
        throw const FormatException('Invalid profile field: angularUnit');
      }
      unit = matchingUnits.first;
    } else {
      throw const FormatException('Invalid profile field: angularUnit');
    }

    // pressureBar is optional for firearm profiles and legacy data, but a
    // present malformed value must not be silently converted to null. Doing so
    // would let the next save permanently erase a PCP profile's stored
    // pressure.
    final pressure = j['pressureBar'];
    final double? pressureBar;
    if (pressure == null) {
      pressureBar = null;
    } else if (pressure is num &&
        pressure.toDouble().isFinite &&
        pressure > 0 &&
        pressure.toDouble() <= ProductionLimits.maxPcpPressureBar) {
      pressureBar = pressure.toDouble();
    } else {
      throw const FormatException('Invalid profile field: pressureBar');
    }
    return RifleProfile(
      id: requiredString('id'),
      name: requiredString('name', maxLength: ProductionLimits.maxProfileNameLength),
      rifleId: requiredString('rifleId'),
      ammunitionId: requiredString('ammunitionId'),
      scopeId: requiredString('scopeId'),
      muzzleVelocityMps: requiredPositive('muzzleVelocityMps', max: ProductionLimits.maxMuzzleVelocityMps),
      zeroRangeM: requiredPositive('zeroRangeM', max: ProductionLimits.maxRangeM),
      sightHeightMm: requiredPositive('sightHeightMm', max: ProductionLimits.maxSightHeightMm, maxExclusive: true),
      pressureBar: pressureBar,
      angularUnit: unit,
    );
  }
}
