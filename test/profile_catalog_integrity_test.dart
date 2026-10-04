import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  const integrity = ProfileCatalogIntegrity();

  test('resolves a coherent bundled PCP profile', () {
    const profile = RifleProfile(
      id: 'ok',
      name: 'OK',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 250,
      zeroRangeM: 25,
      sightHeightMm: 65,
      pressureBar: 200,
    );
    final resolved = integrity.resolve(profile);
    expect(resolved, isNotNull);
    expect(resolved!.rifle.platform, WeaponPlatform.pcp);
    expect(resolved.ammunition.caliberMm, 6.35);
  });

  test('rejects stale catalog references instead of substituting defaults', () {
    const profile = RifleProfile(
      id: 'stale',
      name: 'Stale',
      rifleId: 'removed-rifle-id',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 250,
      zeroRangeM: 25,
      sightHeightMm: 65,
      pressureBar: 200,
    );
    expect(integrity.resolve(profile), isNull);
  });

  test('rejects platform/caliber incoherence and missing PCP pressure', () {
    const wrongAmmo = RifleProfile(
      id: 'mixed',
      name: 'Mixed',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'firearm-manual',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 250,
      zeroRangeM: 25,
      sightHeightMm: 65,
      pressureBar: 200,
    );
    const missingPressure = RifleProfile(
      id: 'pressure',
      name: 'Pressure',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 250,
      zeroRangeM: 25,
      sightHeightMm: 65,
    );
    expect(integrity.resolve(wrongAmmo), isNull);
    expect(integrity.resolve(missingPressure), isNull);
  });

  test('rejects persisted numeric values outside production guardrails', () {
    const excessiveVelocity = RifleProfile(
      id: 'fast',
      name: 'Fast',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 1501,
      zeroRangeM: 25,
      sightHeightMm: 65,
      pressureBar: 200,
    );
    const excessivePressure = RifleProfile(
      id: 'pressure-high',
      name: 'Pressure',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 250,
      zeroRangeM: 25,
      sightHeightMm: 65,
      pressureBar: 501,
    );
    const invalidSight = RifleProfile(
      id: 'sight',
      name: 'Sight',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 250,
      zeroRangeM: 25,
      sightHeightMm: 0,
      pressureBar: 200,
    );
    expect(integrity.resolve(excessiveVelocity), isNull);
    expect(integrity.resolve(excessivePressure), isNull);
    expect(integrity.resolve(invalidSight), isNull);
  });
}
