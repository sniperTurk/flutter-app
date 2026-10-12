// Kronograf series are kept per profile so the powder coefficient can be
// fitted from series measured on different days (2026-10-12).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/services/chrono_store.dart';

void main() {
  const store = ChronoStore();
  final session = ChronoSession(
    date: DateTime.utc(2026, 10, 12, 9, 30),
    tempC: 32,
    mps: const [800, 805.5, 795],
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a saved series loads back unchanged', () async {
    await store.add('p1', session);
    final loaded = await store.load('p1');
    expect(loaded, hasLength(1));
    expect(loaded.single.date, session.date);
    expect(loaded.single.tempC, 32);
    expect(loaded.single.mps, [800, 805.5, 795]);
    expect(await store.load('p2'), isEmpty);
  });

  test('damaged data reads as no series', () async {
    SharedPreferences.setMockInitialValues({
      ChronoStore.keyFor('p1'): '{not json',
      ChronoStore.keyFor('p2'): '[{"date":"x","tempC":"a","mps":[1]}]',
    });
    expect(await store.load('p1'), isEmpty);
    expect(await store.load('p2'), isEmpty);
  });

  test('one series can be removed', () async {
    await store.add('p1', session);
    await store.add(
      'p1',
      ChronoSession(date: DateTime.utc(2026, 2, 3), tempC: 4, mps: const [790]),
    );
    await store.removeAt('p1', 0);
    final left = await store.load('p1');
    expect(left.single.tempC, 4);
  });

  test('deleting the profile deletes its series', () async {
    await store.add('p1', session);
    await store.deleteProfile('p1');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(ChronoStore.keyFor('p1')), isFalse);
  });
}
