import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/services/active_profile_store.dart';

void main() {
  test('active profile can be selected and cleared', () async {
    final store = MemoryActiveProfileStore();
    expect(await store.getActiveProfileId(), isNull);
    await store.setActiveProfileId('profile-1');
    expect(await store.getActiveProfileId(), 'profile-1');
    await store.setActiveProfileId(null);
    expect(await store.getActiveProfileId(), isNull);
  });
}
