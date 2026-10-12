// Ö10 Sıfır grubu: grup merkezi, σ, merkez belirsizliği (σ/√n) ve gereken
// atış sayısı. Kaynak: Grubbs 1964; NIST e-Handbook 1.3.5.2.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/tools/domain/group_center.dart';

void main() {
  group('GroupCenter.compute', () {
    test('square group: centre, pooled sigma and centre uncertainty', () {
      final s = GroupCenter.compute(const [
        ImpactPoint(1, 1),
        ImpactPoint(3, 1),
        ImpactPoint(1, 3),
        ImpactPoint(3, 3),
      ])!;
      expect(s.n, 4);
      expect(s.centerRightCm, closeTo(2, 1e-12));
      expect(s.centerUpCm, closeTo(2, 1e-12));
      // (Σdx² + Σdy²) / (2(n−1)) = 8 / 6.
      expect(s.sigmaCm, closeTo(math.sqrt(8 / 6), 1e-12));
      expect(s.centerUncertaintyCm, closeTo(math.sqrt(8 / 6) / 2, 1e-12));
    });

    test('empty: no result; one shot: centre but no sigma', () {
      expect(GroupCenter.compute(const []), isNull);
      final one = GroupCenter.compute(const [ImpactPoint(-1.5, 0.5)])!;
      expect(one.centerRightCm, -1.5);
      expect(one.centerUpCm, 0.5);
      expect(one.sigmaCm, isNull);
      expect(one.centerUncertaintyCm, isNull);
    });
  });

  test('click size: 0.1 mrad at 100 m is 1 cm', () {
    expect(GroupCenter.clickCm(clickMrad: 0.1, rangeM: 100), closeTo(1, 1e-12));
    expect(GroupCenter.clickCm(clickMrad: 0.1, rangeM: 25), closeTo(0.25, 1e-12));
  });

  group('shots', () {
    test('total needed so that sigma/sqrt(n) <= one click, at least 3', () {
      expect(GroupCenter.shotsNeeded(sigmaCm: 2, clickCm: 1), 4);
      expect(GroupCenter.shotsNeeded(sigmaCm: 2.1, clickCm: 1), 5);
      expect(GroupCenter.shotsNeeded(sigmaCm: 0.5, clickCm: 1), 3);
    });

    test('more shots: below 3 asks for the rest, then by uncertainty', () {
      final two = GroupCenter.compute(const [
        ImpactPoint(0, 0),
        ImpactPoint(1, 0),
      ])!;
      expect(GroupCenter.moreShots(two, clickCm: 1), 1);
      final wide = GroupCenter.compute(const [
        ImpactPoint(-3, -3),
        ImpactPoint(3, 3),
        ImpactPoint(-3, 3),
        ImpactPoint(3, -3),
      ])!;
      // sigma = sqrt(72/6) = 3.46 cm, click 1 cm -> 12 shots in total.
      expect(GroupCenter.moreShots(wide, clickCm: 1), 8);
      expect(GroupCenter.moreShots(wide, clickCm: 4), 0);
    });
  });

  test('offset measured at another range keeps its angle at the zero', () {
    expect(
      GroupCenter.toZeroRangeCm(cm: 4, rangeM: 200, zeroRangeM: 100),
      closeTo(2, 1e-12),
    );
  });
}
