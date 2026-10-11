import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/beaufort.dart';

void main() {
  test('land classes 0–7 with the WMO speed limits (m/s, 10 m)', () {
    final c = Beaufort.classes;
    expect([for (final x in c) x.force], [0, 1, 2, 3, 4, 5, 6, 7]);
    expect([for (final x in c) x.minMps], [0, 0.3, 1.6, 3.4, 5.5, 8.0, 10.8, 13.9]);
    expect([for (final x in c) x.maxMps], [0.2, 1.5, 3.3, 5.4, 7.9, 10.7, 13.8, 17.1]);
  });

  test('classes are adjacent: each starts 0.1 m/s above the previous top', () {
    final c = Beaufort.classes;
    for (var i = 1; i < c.length; i++) {
      expect(c[i].minMps, closeTo(c[i - 1].maxMps + 0.1, 1e-9));
    }
  });

  test('middle value is (low + high) / 2 rounded to 0.1 m/s', () {
    expect(
      [for (final x in Beaufort.classes) x.midMps],
      [0.1, 0.9, 2.5, 4.4, 6.7, 9.4, 12.3, 15.5],
    );
  });

  test('every class has a Turkish short name and a land description', () {
    for (final x in Beaufort.classes) {
      expect(x.name, isNotEmpty);
      expect(x.land, isNotEmpty);
      expect(x.name.contains('('), isFalse);
    }
    expect(Beaufort.classes[2].name, 'Hafif');
    expect(Beaufort.classes[2].land, contains('yaprak'));
  });
}
