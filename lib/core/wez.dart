import 'dart:math' as math;

/// One error source of a shot, as a 1-sigma spread in mrad on the target,
/// horizontal (x, + right) and vertical (y, + up).
class WezSource {
  final String name;
  final double sigmaX, sigmaY;
  const WezSource(this.name, {this.sigmaX = 0, this.sigmaY = 0});

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
}
