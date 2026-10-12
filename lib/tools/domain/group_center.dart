import 'dart:math' as math;

/// One hole on the zero target, relative to the aim point: + = right / up,
/// centimetres.
class ImpactPoint {
  final double rightCm;
  final double upCm;
  const ImpactPoint(this.rightCm, this.upCm);
}

/// Group centre, its spread and how well the centre is known.
class GroupStats {
  final int n;
  final double centerRightCm;
  final double centerUpCm;

  /// Per-axis standard deviation pooled over both axes; null below 2 shots.
  final double? sigmaCm;

  /// Standard error of the centre on each axis, sigma / sqrt(n).
  final double? centerUncertaintyCm;

  const GroupStats({
    required this.n,
    required this.centerRightCm,
    required this.centerUpCm,
    required this.sigmaCm,
    required this.centerUncertaintyCm,
  });
}

/// Ö10 Sıfır grubu (Grubbs, F. "Statistical Measures of Accuracy for
/// Riflemen and Missile Engineers", 1964; NIST/SEMATECH e-Handbook of
/// Statistical Methods, 1.3.5.2): the shots are taken as a circular normal
/// spread around the group centre.
abstract final class GroupCenter {
  /// Below this the spread cannot be estimated usefully.
  static const minShots = 3;

  static GroupStats? compute(List<ImpactPoint> points) {
    final n = points.length;
    if (n == 0) return null;
    var sx = 0.0, sy = 0.0;
    for (final p in points) {
      sx += p.rightCm;
      sy += p.upCm;
    }
    final mx = sx / n, my = sy / n;
    double? sigma;
    double? se;
    if (n >= 2) {
      var ss = 0.0;
      for (final p in points) {
        ss +=
            (p.rightCm - mx) * (p.rightCm - mx) + (p.upCm - my) * (p.upCm - my);
      }
      sigma = math.sqrt(ss / (2 * (n - 1)));
      se = sigma / math.sqrt(n);
    }
    return GroupStats(
      n: n,
      centerRightCm: mx,
      centerUpCm: my,
      sigmaCm: sigma,
      centerUncertaintyCm: se,
    );
  }

  /// One turret click at [rangeM], cm (1 mrad = 10 cm at 100 m).
  static double clickCm({required double clickMrad, required double rangeM}) =>
      clickMrad * rangeM / 10;

  /// Shots in total so that sigma / sqrt(n) is at most one click; never
  /// fewer than [minShots].
  static int shotsNeeded({required double sigmaCm, required double clickCm}) {
    if (!(clickCm > 0) || !sigmaCm.isFinite) return minShots;
    final r = sigmaCm / clickCm;
    final n = (r * r - 1e-9).ceil();
    return math.max(minShots, n);
  }

  /// How many more shots the group needs (0 = enough).
  static int moreShots(GroupStats s, {required double clickCm}) {
    final sigma = s.sigmaCm;
    if (s.n < minShots || sigma == null) return minShots - s.n;
    return math.max(0, shotsNeeded(sigmaCm: sigma, clickCm: clickCm) - s.n);
  }

  /// A centre measured at [rangeM], moved to the zero range at the same
  /// angle (Sıfır ofseti is stored as cm at the zero range).
  static double toZeroRangeCm({
    required double cm,
    required double rangeM,
    required double zeroRangeM,
  }) => cm * zeroRangeM / rangeM;
}
