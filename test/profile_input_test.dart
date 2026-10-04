import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/profile_input.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  test('normalizes decimal comma and accepts valid PCP profile input', () {
    final input = ProfileInput.validate(
      name: '  Saha Profili  ',
      muzzleVelocityText: '250,5',
      zeroRangeText: '25',
      sightHeightText: '65,2',
      platform: WeaponPlatform.pcp,
      pressureText: '200',
    );
    expect(input.name, 'Saha Profili');
    expect(input.muzzleVelocityMps, 250.5);
    expect(input.sightHeightMm, 65.2);
    expect(input.pressureBar, 200);
  });

  test('rejects empty name instead of silently inventing one', () {
    expect(
      () => ProfileInput.validate(name: ' ', muzzleVelocityText: '250', zeroRangeText: '25', sightHeightText: '65', platform: WeaponPlatform.firearm),
      throwsFormatException,
    );
  });

  test('rejects malformed numeric values instead of silently using defaults', () {
    expect(
      () => ProfileInput.validate(name: 'Test', muzzleVelocityText: 'abc', zeroRangeText: '25', sightHeightText: '65', platform: WeaponPlatform.firearm),
      throwsFormatException,
    );
    expect(
      () => ProfileInput.validate(name: 'Test', muzzleVelocityText: '250', zeroRangeText: '0', sightHeightText: '65', platform: WeaponPlatform.firearm),
      throwsFormatException,
    );
  });

  test('PCP requires a positive pressure while firearm does not', () {
    expect(
      () => ProfileInput.validate(name: 'PCP', muzzleVelocityText: '250', zeroRangeText: '25', sightHeightText: '65', platform: WeaponPlatform.pcp, pressureText: ''),
      throwsFormatException,
    );
    final firearm = ProfileInput.validate(name: 'Ateşli', muzzleVelocityText: '800', zeroRangeText: '100', sightHeightText: '45', platform: WeaponPlatform.firearm);
    expect(firearm.pressureBar, isNull);
  });
  test('rejects values outside shared production guardrails', () {
    expect(() => ProfileInput.validate(name: 'Test', muzzleVelocityText: '1501', zeroRangeText: '25', sightHeightText: '65', platform: WeaponPlatform.firearm), throwsFormatException);
    expect(() => ProfileInput.validate(name: 'Test', muzzleVelocityText: '250', zeroRangeText: '3001', sightHeightText: '65', platform: WeaponPlatform.firearm), throwsFormatException);
    expect(() => ProfileInput.validate(name: 'Test', muzzleVelocityText: '250', zeroRangeText: '25', sightHeightText: '300', platform: WeaponPlatform.firearm), throwsFormatException);
    expect(() => ProfileInput.validate(name: 'Test', muzzleVelocityText: '250', zeroRangeText: '25', sightHeightText: '65', platform: WeaponPlatform.pcp, pressureText: '501'), throwsFormatException);
    expect(() => ProfileInput.validate(name: '${'x'*81}', muzzleVelocityText: '250', zeroRangeText: '25', sightHeightText: '65', platform: WeaponPlatform.firearm), throwsFormatException);
  });

}
