import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/serial_mutation_lock.dart';

RifleProfile _profile(String id) => RifleProfile(
  id: id,
  name: id,
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

/// A zone that runs its microtasks only while [alive] — the situation of a
/// caller whose zone has ended (an abandoned guarded zone, or a finished test).
class _EndableZone {
  bool alive = true;
  late final Zone zone = Zone.current.fork(
    specification: ZoneSpecification(
      scheduleMicrotask: (self, parent, zone, f) {
        if (alive) parent.scheduleMicrotask(zone, f);
      },
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a profile mutation made from an ended zone does not stall later '
      'mutations (root cause of the Home recovery hang)', () async {
    final store = PersistentProfileStore();
    final caller = _EndableZone();
    await caller.zone.run(() => store.save(_profile('a')));
    caller.alive = false;

    // With the former static Future tail this never started: the tail was a
    // future of the ended zone, so its listener was scheduled there.
    await store.save(_profile('b')).timeout(const Duration(seconds: 5));
    expect((await store.all()).map((p) => p.id), ['a', 'b']);
  });

  test('manual catalog mutations are equally zone-independent', () async {
    final store = ManualCatalogStore();
    final caller = _EndableZone();
    await caller.zone.run(
      () => store.upsert({
        'id': 'm1',
        'kind': 'rifle',
        'platform': 'pcp',
        'brand': 'A',
        'model': 'B',
        'caliberMm': 5.5,
      }),
    );
    caller.alive = false;
    await store.remove('m1').timeout(const Duration(seconds: 5));
    expect(await store.all(), isEmpty);
  });

  test('the lock serialises, keeps order and is released after errors', () async {
    final lock = SerialMutationLock();
    final log = <String>[];
    final gate = Completer<void>();
    final first = lock.run(() async {
      log.add('first-start');
      await gate.future;
      log.add('first-end');
    });
    final second = lock.run(() async {
      log.add('second');
      throw StateError('boom');
    });
    final third = lock.run(() async => log.add('third'));
    await Future<void>.delayed(Duration.zero);
    expect(log, ['first-start']);
    expect(lock.isHeld, isTrue);

    gate.complete();
    await first;
    await expectLater(second, throwsStateError);
    await third;
    expect(log, ['first-start', 'first-end', 'second', 'third']);
    expect(lock.isHeld, isFalse);
  });
}
