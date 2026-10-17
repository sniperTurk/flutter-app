// dart format off
import '../models/domain.dart';
import '../core/powder_temperature.dart';
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
        'tubePressureBar': p.tubePressureBar,
        'pressureVelocity': [
          for (final pt in p.pressureVelocityTable) {'bar': pt.bar, 'mps': pt.mps},
        ],
        'pcpMinVelocityMps': p.pcpMinVelocityMps,
        'pcpMaxVelocityMps': p.pcpMaxVelocityMps,
        'angularUnit': p.angularUnit.name,
        'distanceUnit': p.distanceUnit.name,
        'mountCantMoa': p.mountCantMoa,
        'powderTempCoef': p.powderTempCoefPercentPer15C,
        'powderTempRefC': p.powderTempReferenceC,
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

    // distanceUnit is absent before 2026-10-09: metres. A present unknown
    // value is corruption (it would change every shown distance).
    final distanceName = j['distanceUnit'];
    final DistanceUnit distanceUnit;
    if (distanceName == null) {
      distanceUnit = DistanceUnit.meter;
    } else if (distanceName is String &&
        DistanceUnit.values.any((u) => u.name == distanceName)) {
      distanceUnit = DistanceUnit.values.byName(distanceName);
    } else {
      throw const FormatException('Invalid profile field: distanceUnit');
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
    // PCP tüp basıncı (2026-10-12) is absent in older profiles: none. A
    // present malformed value is corruption. The "Basınca göre hız" table is
    // deleted (2026-10-16) but a saved one is still read and written back
    // unchanged, so the user's data is never erased; nothing calculates
    // with it.
    final tubeRaw = j['tubePressureBar'];
    final double? tubePressureBar;
    if (tubeRaw == null) {
      tubePressureBar = null;
    } else if (tubeRaw is num && tubeRaw.toDouble().isFinite && tubeRaw > 0 &&
        tubeRaw.toDouble() <= ProductionLimits.maxPcpPressureBar) {
      tubePressureBar = tubeRaw.toDouble();
    } else {
      throw const FormatException('Invalid profile field: tubePressureBar');
    }
    final tableRaw = j['pressureVelocity'];
    final table = <PressureVelocityPoint>[];
    if (tableRaw != null) {
      if (tableRaw is! List) {
        throw const FormatException('Invalid profile field: pressureVelocity');
      }
      for (final row in tableRaw) {
        final bar = row is Map ? row['bar'] : null;
        final mps = row is Map ? row['mps'] : null;
        if (bar is! num || mps is! num ||
            !bar.toDouble().isFinite || bar <= 0 ||
            bar.toDouble() > ProductionLimits.maxPcpPressureBar ||
            !mps.toDouble().isFinite || mps <= 0 ||
            mps.toDouble() > ProductionLimits.maxMuzzleVelocityMps ||
            table.any((p) => p.bar == bar.toDouble())) {
          throw const FormatException('Invalid profile field: pressureVelocity');
        }
        table.add(PressureVelocityPoint(bar: bar.toDouble(), mps: mps.toDouble()));
      }
      table.sort((a, b) => a.bar.compareTo(b.bar));
    }
    // PCP En düşük / En yüksek namlu çıkış hızı (owner, 2026-10-16) are
    // optional and absent in older profiles: none. A lone value (saved on
    // 2026-10-17, before the pair rule came back) still loads; the
    // calculation then uses Namlu çıkış hızı (RifleProfile.velocityMps).
    // Both present come lowest first, as ProfileInput saves them; a
    // reversed pair is corruption.
    double? optionalVelocity(String key) {
      final value = j[key];
      if (value == null) return null;
      if (value is num && value.toDouble().isFinite && value > 0 &&
          value.toDouble() <= ProductionLimits.maxMuzzleVelocityMps) {
        return value.toDouble();
      }
      throw FormatException('Invalid profile field: $key');
    }
    final pcpMin = optionalVelocity('pcpMinVelocityMps');
    final pcpMax = optionalVelocity('pcpMaxVelocityMps');
    if (pcpMin != null && pcpMax != null && pcpMin > pcpMax) {
      throw const FormatException('Invalid profile field: pcpVelocity');
    }
    // mountCantMoa is absent in profiles saved before the field existed:
    // those are normal (0 MOA) mounts. A present malformed value is
    // corruption and must not silently become 0.
    final cant = j['mountCantMoa'];
    final double mountCantMoa;
    if (cant == null) {
      mountCantMoa = 0;
    } else if (cant is num &&
        ProductionLimits.mountCantOptionsMoa.contains(cant.toDouble())) {
      mountCantMoa = cant.toDouble();
    } else {
      throw const FormatException('Invalid profile field: mountCantMoa');
    }
    // Barut sıcaklığı (2026-10-11) is absent in older profiles: none. A
    // present value outside the accepted band, or only one of the pair, is
    // corruption (it would silently change today's velocity).
    double? optionalIn(String key, double min, double max) {
      final value = j[key];
      if (value == null) return null;
      if (value is num && value.toDouble().isFinite &&
          value >= min && value <= max) {
        return value.toDouble();
      }
      throw FormatException('Invalid profile field: $key');
    }
    final powderCoef = optionalIn('powderTempCoef',
        -PowderTemperature.maxCoef, PowderTemperature.maxCoef);
    final powderRef = optionalIn('powderTempRefC',
        PowderTemperature.minTempC, PowderTemperature.maxTempC);
    if ((powderCoef == null) != (powderRef == null)) {
      throw const FormatException('Invalid profile field: powderTemp');
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
      tubePressureBar: tubePressureBar,
      pressureVelocityTable: List.unmodifiable(table),
      pcpMinVelocityMps: pcpMin,
      pcpMaxVelocityMps: pcpMax,
      angularUnit: unit,
      distanceUnit: distanceUnit,
      mountCantMoa: mountCantMoa,
      powderTempCoefPercentPer15C: powderCoef,
      powderTempReferenceC: powderRef,
    );
  }
}
