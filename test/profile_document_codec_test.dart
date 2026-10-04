import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_document_codec.dart';

void main() {
  const codec = ProfileDocumentCodec();
  const profile = RifleProfile(id:'p1', name:'Test', rifleId:'r1', ammunitionId:'a1', scopeId:'s1', muzzleVelocityMps:270, zeroRangeM:25, sightHeightMm:45, pressureBar:180);

  test('new profile documents carry an explicit schema version', () {
    final encoded = codec.encode([profile]);
    expect(encoded['schemaVersion'], ProfileDocumentCodec.currentSchemaVersion);
    expect(codec.decode(encoded).single.id, 'p1');
  });

  test('legacy bare-list profile documents remain readable', () {
    final legacy = [const ProfileCodec().encode(profile)];
    expect(codec.decode(legacy).single.id, 'p1');
  });

  test('future profile schema is rejected instead of guessed', () {
    expect(() => codec.decode({'schemaVersion': 999, 'profiles': []}), throwsFormatException);
  });

  test('malformed record fails closed instead of returning a partial collection', () {
    final good = const ProfileCodec().encode(profile);
    expect(
      () => codec.decode({'schemaVersion': 1, 'profiles': [good, {'id':'broken'}]}),
      throwsFormatException,
    );
  });

  test('non-map profile record also fails closed', () {
    final good = const ProfileCodec().encode(profile);
    expect(
      () => codec.decode({'schemaVersion': 1, 'profiles': [good, 'broken']}),
      throwsFormatException,
    );
  });
}
