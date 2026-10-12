// Ö8 Paralaks mesafe tablosu: interpolation between recorded wheel marks,
// clamping outside the recorded range (no extrapolation), the pick list and
// the per-profile store.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/parallax_range.dart';
import 'package:sniper_turk/services/parallax_table_store.dart';

const _p10 = ParallaxPoint(mark: 10, distanceM: 20);
const _p20 = ParallaxPoint(mark: 20, distanceM: 40);

void main() {
  group('ParallaxRange.distanceAt', () {
    test('interpolates linearly between two marks', () {
      expect(ParallaxRange.distanceAt([_p10, _p20], 15), closeTo(30, 1e-9));
      expect(ParallaxRange.distanceAt([_p20, _p10], 12), closeTo(24, 1e-9));
    });

    test('a recorded mark returns its own distance', () {
      expect(ParallaxRange.distanceAt([_p10, _p20], 20), closeTo(40, 1e-9));
    });

    test('outside the recorded range: clamped to the end value', () {
      expect(ParallaxRange.distanceAt([_p10, _p20], 5), closeTo(20, 1e-9));
      expect(ParallaxRange.distanceAt([_p10, _p20], 25), closeTo(40, 1e-9));
    });

    test('fewer than two different marks: no distance', () {
      expect(ParallaxRange.distanceAt(const [], 10), isNull);
      expect(ParallaxRange.distanceAt([_p10], 10), isNull);
      expect(
        ParallaxRange.distanceAt([
          _p10,
          const ParallaxPoint(mark: 10, distanceM: 25),
        ], 10),
        isNull,
      );
    });

    test('a wheel that counts down still interpolates', () {
      const a = ParallaxPoint(mark: 10, distanceM: 40);
      const b = ParallaxPoint(mark: 20, distanceM: 20);
      expect(ParallaxRange.distanceAt([a, b], 15), closeTo(30, 1e-9));
    });

    test('three marks: each segment on its own', () {
      const c = ParallaxPoint(mark: 30, distanceM: 100);
      expect(
        ParallaxRange.distanceAt([_p10, _p20, c], 25),
        closeTo(70, 1e-9),
      );
    });

    test('a non-finite mark gives no distance', () {
      expect(ParallaxRange.distanceAt([_p10, _p20], double.nan), isNull);
    });
  });

  group('ParallaxRange.pickMarks', () {
    test('sorted marks with the midpoints between them', () {
      const c = ParallaxPoint(mark: 30, distanceM: 60);
      expect(ParallaxRange.pickMarks([c, _p10, _p20]), [10, 15, 20, 25, 30]);
    });

    test('fewer than two marks: nothing to pick', () {
      expect(ParallaxRange.pickMarks([_p10]), isEmpty);
    });
  });

  group('ParallaxRange.upsert', () {
    test('a new mark is added, the list stays sorted by mark', () {
      final r = ParallaxRange.upsert([_p20], _p10);
      expect(r.map((p) => p.mark), [10, 20]);
    });

    test('the same mark again replaces its distance', () {
      final r = ParallaxRange.upsert([
        _p10,
        _p20,
      ], const ParallaxPoint(mark: 10, distanceM: 22));
      expect(r.length, 2);
      expect(r.first.distanceM, 22);
    });
  });

  group('ParallaxTableStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('saves and loads per profile', () async {
      const store = ParallaxTableStore();
      await store.save('a', [_p10, _p20]);
      final back = await store.load('a');
      expect(back.map((p) => p.mark), [10, 20]);
      expect(back.map((p) => p.distanceM), [20, 40]);
      expect(await store.load('b'), isEmpty);
    });

    test('damaged data loads as an empty table', () async {
      SharedPreferences.setMockInitialValues({
        ParallaxTableStore.keyFor('a'): '{not json',
      });
      expect(await const ParallaxTableStore().load('a'), isEmpty);
      SharedPreferences.setMockInitialValues({
        ParallaxTableStore.keyFor('a'):
            '[{"mark":1,"m":-5},{"mark":"x","m":3},{"mark":2,"m":30}]',
      });
      final back = await const ParallaxTableStore().load('a');
      expect(back.map((p) => p.mark), [2]);
    });
  });
}
