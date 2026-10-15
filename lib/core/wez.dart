import 'dart:math' as math;

import 'units.dart';

/// One error source of a shot, as a 1-sigma spread in mrad on the target,
/// horizontal (x, + right) and vertical (y, + up).
class WezSource {
  final String name;
  final double sigmaX, sigmaY;

  /// True when the error is the same for every shot of a series (range,
  /// wind, BC: a wrong range read stays wrong for the follow-up shot);
  /// false when it changes from shot to shot (group, SD). Only
  /// [Wez.seriesHitProbability] reads it; the single-shot result does not
  /// depend on it.
  final bool shared;
  const WezSource(
    this.name, {
    this.sigmaX = 0,
    this.sigmaY = 0,
    this.shared = false,
  });

  double get variance => sigmaX * sigmaX + sigmaY * sigmaY;
}

class WezResult {
  /// Share of simulated shots inside the target, 0..1.
  final double probability;

  /// Simulated impacts relative to the aim point, mrad (x right, y up).
  final List<(double, double)> impacts;

  /// The source with the biggest spread; null when nothing spreads.
  final WezSource? dominant;
  const WezResult(this.probability, this.impacts, this.dominant);
}

/// WEZ isabet olasılığı (owner, 2026-10-10): every source is a Gaussian
/// spread around the aim point; [shots] shots are drawn with a fixed seed
/// so the number does not flicker, and the share inside the target circle
/// of radius [targetRadiusMrad] is the hit probability.
abstract final class Wez {
  static const shots = 1000;

  /// Atış sayısı choices for "en az bir isabet" (owner, 2026-10-11); the
  /// list starts at 1 shot, which is also the default.
  static const shotCounts = [1, 3, 5, 10];
  static const defaultShotCount = 1;

  /// Chance of at least one hit in [shotCount] shots that each hit with
  /// [probability]: 1 − (1 − p)^n. Assumes the shots are independent (no
  /// shared range/wind/BC error), so it is an upper estimate for follow-up
  /// shots fired without correction; the screen uses
  /// [seriesHitProbability], which keeps the shared errors.
  static double atLeastOneHit(double probability, int shotCount) {
    if (shotCount < 1) {
      throw ArgumentError.value(shotCount, 'shotCount', 'must be >= 1');
    }
    final p = probability.isNaN ? 0.0 : probability.clamp(0.0, 1.0);
    return 1 - math.pow(1 - p, shotCount).toDouble();
  }

  /// Number of simulated series for [seriesHitProbability].
  static const series = 2000;

  /// "En az bir isabet" in [shotCount] shots with shared errors (Ö12,
  /// owner, 2026-10-11). Two-layer Monte Carlo: for every series the
  /// [WezSource.shared] sources are drawn once, then every shot adds its
  /// own draw of the per-shot sources; a series counts when any shot is
  /// inside the circle. One shot returns [simulate]'s probability exactly,
  /// so the first-shot number never changes. Fixed [seed]: no flicker.
  static double seriesHitProbability({
    required List<WezSource> sources,
    required double targetRadiusMrad,
    required int shotCount,
    int seed = 7,
    int count = series,
  }) {
    if (shotCount < 1) {
      throw ArgumentError.value(shotCount, 'shotCount', 'must be >= 1');
    }
    if (shotCount == 1) {
      return simulate(
        sources: sources,
        targetRadiusMrad: targetRadiusMrad,
        seed: seed,
      ).probability;
    }
    final rnd = math.Random(seed);
    final gauss = _gauss(rnd);
    final shared = [
      for (final s in sources)
        if (s.shared) s,
    ];
    final perShot = [
      for (final s in sources)
        if (!s.shared) s,
    ];
    final r2 = targetRadiusMrad * targetRadiusMrad;
    var hits = 0;
    for (var i = 0; i < count; i++) {
      var sx = 0.0, sy = 0.0;
      for (final s in shared) {
        if (s.sigmaX > 0) sx += s.sigmaX * gauss();
        if (s.sigmaY > 0) sy += s.sigmaY * gauss();
      }
      for (var k = 0; k < shotCount; k++) {
        var x = sx, y = sy;
        for (final s in perShot) {
          if (s.sigmaX > 0) x += s.sigmaX * gauss();
          if (s.sigmaY > 0) y += s.sigmaY * gauss();
        }
        if (x * x + y * y <= r2) {
          hits++;
          break;
        }
      }
    }
    return hits / count;
  }

  /// Box–Muller standard normal draws from [rnd].
  static double Function() _gauss(math.Random rnd) => () {
    final u = 1 - rnd.nextDouble(), v = rnd.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  };

  static WezResult simulate({
    required List<WezSource> sources,
    required double targetRadiusMrad,
    int seed = 7,
    int count = shots,
  }) {
    final rnd = math.Random(seed);
    double gauss() {
      // Box–Muller.
      final u = 1 - rnd.nextDouble(), v = rnd.nextDouble();
      return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
    }

    final impacts = <(double, double)>[];
    var hits = 0;
    final r2 = targetRadiusMrad * targetRadiusMrad;
    for (var i = 0; i < count; i++) {
      var x = 0.0, y = 0.0;
      for (final s in sources) {
        if (s.sigmaX > 0) x += s.sigmaX * gauss();
        if (s.sigmaY > 0) y += s.sigmaY * gauss();
      }
      if (x * x + y * y <= r2) hits++;
      impacts.add((x, y));
    }
    WezSource? top;
    for (final s in sources) {
      if (s.variance <= 0) continue;
      if (top == null || s.variance > top.variance) top = s;
    }
    return WezResult(hits / count, List.unmodifiable(impacts), top);
  }

  /// Group size (extreme spread of a 5-shot group) as a 1-sigma radius per
  /// axis: ES ≈ 3.067 σ for 5 shots.
  static double groupSigmaMrad(double groupM, double atRangeM) =>
      math.atan(groupM / atRangeM) * 1000 / 3.067;

  /// A "± value" the user types is read as about 2 sigma (95 %).
  static double sigmaOfPlusMinus(double v) => v / 2;

  /// Target radius in mrad for a round target [diameterM] across at
  /// [rangeM]: atan((d / 2) / range) · 1000. A 10 cm ring at 100 m = 0.5
  /// mrad. Moved from the Hedef screen (2026-10-15, same arithmetic).
  static double targetRadiusMrad(double diameterM, double rangeM) =>
      Units.linearToMrad(diameterM / 2, rangeM);
}
