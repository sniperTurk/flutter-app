import 'dart:async';
import 'dart:collection';

/// Process-wide serialisation for read-modify-write storage mutations.
///
/// Replaces the former "static Future tail" pattern
/// (`_tail = _tail.then(...)`). A Future dispatches listeners through the zone
/// it was created in, so a static tail created by one caller made every later
/// mutation depend on that first caller's zone staying alive: once it was gone
/// (an abandoned or guarded zone), the next mutation was queued but never
/// started and every following profile/catalog write hung.
///
/// Here the lock is plain state. Each waiter waits on its own [Completer]
/// created in its own zone, and the lock is released synchronously in the
/// `finally` of the operation that held it, so no caller ever depends on
/// another caller's zone.
final class SerialMutationLock {
  bool _held = false;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  bool get isHeld => _held;

  Future<T> run<T>(Future<T> Function() operation) async {
    while (_held) {
      final ready = Completer<void>();
      _waiters.add(ready);
      await ready.future;
    }
    _held = true;
    try {
      return await operation();
    } finally {
      _held = false;
      // Wake every waiter; each re-checks the lock. A waiter whose zone can no
      // longer run simply never re-acquires, so it cannot block the others.
      while (_waiters.isNotEmpty) {
        _waiters.removeFirst().complete();
      }
    }
  }
}
