import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';

void main() {
  const codec = ProfileCodec();
  const profile = RifleProfile(
    id: 'p1',
    name: 'Test',
    rifleId: 'r1',
    ammunitionId: 'a1',
    scopeId: 's1',
    muzzleVelocityMps: 270,
    zeroRangeM: 25,
    sightHeightMm: 45,
    pressureBar: 180,
  );

  test('profile codec round trips persisted fields', () {
    final decoded = codec.decode(codec.encode(profile));
    expect(decoded.id, profile.id);
    expect(decoded.muzzleVelocityMps, profile.muzzleVelocityMps);
    expect(decoded.pressureBar, profile.pressureBar);
    expect(decoded.angularUnit, AngularUnit.mrad);
  });

  // An unknown PRESENT angularUnit used to fall back to MRAD; it now fails
  // closed (see 'present invalid angularUnit fails closed' below), because a
  // silent unit change would corrupt DOPE values.

  test('invalid required numeric fields are rejected', () {
    final json = codec.encode(profile)..['zeroRangeM'] = 0;
    expect(() => codec.decode(json), throwsFormatException);
  });

  test('legacy profile without angularUnit still migrates to MRAD', () {
    final encoded = codec.encode(profile)..remove('angularUnit');
    expect(codec.decode(encoded).angularUnit, AngularUnit.mrad);
  });

  test(
    'present invalid angularUnit fails closed instead of changing DOPE units',
    () {
      final encoded = codec.encode(profile)..['angularUnit'] = 'damaged-unit';
      expect(() => codec.decode(encoded), throwsFormatException);
    },
  );

  test(
    'present invalid pressure fails closed instead of erasing PCP pressure',
    () {
      final encoded = codec.encode(profile)..['pressureBar'] = -1;
      expect(() => codec.decode(encoded), throwsFormatException);
    },
  );
}
