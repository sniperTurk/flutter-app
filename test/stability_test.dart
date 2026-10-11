import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/stability.dart';

/// The Miller formula exactly as it was inline in ballistics_screen.dart
/// before Ö5 moved it to lib/core/stability.dart (regression reference).
double _oldInlineSg({
  required double grain,
  required double caliberMm,
  required double twistIn,
  required double lengthMm,
  required double velocityMps,
  required double temperatureC,
  required double pressureHpa,
}) {
  final dIn = caliberMm / 25.4;
  final tCal = twistIn / dIn, lCal = lengthMm / 25.4 / dIn;
  final vFps = velocityMps / 0.3048;
  final tF = temperatureC * 9 / 5 + 32;
  final pInHg = pressureHpa * 0.0295299830714;
  return 30 *
      grain /
      (tCal * tCal * dIn * dIn * dIn * lCal * (1 + lCal * lCal)) *
      math.pow(vFps / 2800, 1 / 3) *
      ((tF + 460) / 519) *
      (29.92 / pInHg);
}

void main() {
  test('Miller Sg eski satır içi formülle aynı', () {
    for (final c in [
      (175.0, 7.82, 10.0, 31.2, 790.0, 15.0, 1013.25),
      (140.0, 6.71, 8.0, 34.8, 830.0, -5.0, 950.0),
      (250.0, 8.59, 10.0, 39.0, 900.0, 30.0, 1020.0),
      (77.0, 5.70, 7.0, 25.4, 840.0, 20.0, 1000.0),
    ]) {
      final (gr, cal, tw, len, v, t, p) = c;
      final sg = Stability.millerSg(
        grain: gr,
        caliberMm: cal,
        twistIn: tw,
        lengthMm: len,
        velocityMps: v,
        temperatureC: t,
        pressureHpa: p,
      );
      final old = _oldInlineSg(
        grain: gr,
        caliberMm: cal,
        twistIn: tw,
        lengthMm: len,
        velocityMps: v,
        temperatureC: t,
        pressureHpa: p,
      );
      expect(sg, closeTo(old, old * 1e-9));
    }
  });

  test('ölçek: .308 175 gr 1:10 yiv ~1.9; daha yavaş yiv daha düşük', () {
    final fast = Stability.millerSg(
      grain: 175,
      caliberMm: 7.82,
      twistIn: 10,
      lengthMm: 31.2,
      velocityMps: 790,
      temperatureC: 15,
      pressureHpa: 1013.25,
    );
    final slow = Stability.millerSg(
      grain: 175,
      caliberMm: 7.82,
      twistIn: 14,
      lengthMm: 31.2,
      velocityMps: 790,
      temperatureC: 15,
      pressureHpa: 1013.25,
    );
    expect(fast, inInclusiveRange(1.6, 2.2));
    expect(slow, lessThan(fast));
  });

  test('sınıflandırma: <1 kararsız, 1–1.5 sınırda, ≥1.5 kararlı', () {
    expect(Stability.classify(0.9), StabilityLevel.unstable);
    expect(Stability.classify(0.999), StabilityLevel.unstable);
    expect(Stability.classify(1.0), StabilityLevel.marginal);
    expect(Stability.classify(1.49), StabilityLevel.marginal);
    expect(Stability.classify(1.5), StabilityLevel.stable);
    expect(Stability.classify(2.4), StabilityLevel.stable);
  });

  test('BC kaybı tahmini: 1.5 altında her 0.1 için ~%3', () {
    expect(Stability.bcLossPercent(1.5), 0);
    expect(Stability.bcLossPercent(2.0), 0);
    expect(Stability.bcLossPercent(1.4), closeTo(3, 1e-9));
    expect(Stability.bcLossPercent(1.2), closeTo(9, 1e-9));
    expect(Stability.bcLossPercent(1.0), closeTo(15, 1e-9));
  });

  test('transonik: ses üstü çıkıp hedefe Mach 1.2 altında varırsa', () {
    expect(Stability.transonicAtTarget(muzzleMach: 2.4, targetMach: 1.1), true);
    expect(Stability.transonicAtTarget(muzzleMach: 2.4, targetMach: 0.9), true);
    expect(
      Stability.transonicAtTarget(muzzleMach: 2.4, targetMach: 1.2),
      false,
    );
    expect(
      Stability.transonicAtTarget(muzzleMach: 2.4, targetMach: 1.6),
      false,
    );
    // Subsonic loads (PCP, subsonic rifle ammo) never warn.
    expect(
      Stability.transonicAtTarget(muzzleMach: 0.9, targetMach: 0.8),
      false,
    );
    expect(
      Stability.transonicAtTarget(muzzleMach: 1.0, targetMach: 0.9),
      false,
    );
  });
}
