import 'dart:math' as math;

/// One logged shot as the cold-bore statistics need it.
class ColdBoreShot {
  final double rangeM;

  /// Observed miss after the dialled correction: + = high / right, cm.
  final double missUpCm;
  final double missRightCm;
  final bool firstShot;
  final bool suppressor;

  const ColdBoreShot({
    required this.rangeM,
    required this.missUpCm,
    required this.missRightCm,
    required this.firstShot,
    required this.suppressor,
  });
}

enum ColdBoreVerdict {
  /// Fewer than [ColdBore.minFirstShots] first shots.
  tooFew,

  /// The mean is inside twice its standard error on both axes.
  notSignificant,

  /// A first-shot correction can be offered.
  suggest,
}

class ColdBoreSummary {
  final bool suppressor;
  final int firstShots;
  final ColdBoreVerdict verdict;

  /// Mean first-shot miss and its standard error, mrad (+ = high / right);
  /// null while there are too few first shots.
  final double? meanUpMrad;
  final double? meanRightMrad;
  final double? seUpMrad;
  final double? seRightMrad;

  const ColdBoreSummary({
    required this.suppressor,
    required this.firstShots,
    required this.verdict,
    this.meanUpMrad,
    this.meanRightMrad,
    this.seUpMrad,
    this.seRightMrad,
  });

  /// The extra first-shot correction: against the mean miss.
  double? get correctionUpMrad => meanUpMrad == null ? null : -meanUpMrad!;
  double? get correctionRightMrad =>
      meanRightMrad == null ? null : -meanRightMrad!;
}

/// Ö9 Soğuk namlu (Litz 2012, cold-bore shift; NIST/SEMATECH e-Handbook,
/// mean and its standard error). Nothing is assumed: without enough logged
/// first shots there is no suggestion.
abstract final class ColdBore {
  static const minFirstShots = 5;

  /// A mean counts when it is at least this many standard errors from zero
  /// on one axis (~95 %).
  static const significance = 2.0;

  static ColdBoreSummary forState(
    Iterable<ColdBoreShot> shots, {
    required bool suppressor,
  }) {
    final up = <double>[];
    final right = <double>[];
    for (final s in shots) {
      if (!s.firstShot || s.suppressor != suppressor) continue;
      if (!s.rangeM.isFinite || s.rangeM <= 0) continue;
      if (!s.missUpCm.isFinite || !s.missRightCm.isFinite) continue;
      up.add(s.missUpCm * 10 / s.rangeM);
      right.add(s.missRightCm * 10 / s.rangeM);
    }
    final n = up.length;
    if (n < minFirstShots) {
      return ColdBoreSummary(
        suppressor: suppressor,
        firstShots: n,
        verdict: ColdBoreVerdict.tooFew,
      );
    }
    double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    double se(List<double> v, double m) {
      var ss = 0.0;
      for (final x in v) {
        ss += (x - m) * (x - m);
      }
      return math.sqrt(ss / (v.length - 1)) / math.sqrt(v.length);
    }

    final mu = mean(up), mr = mean(right);
    final su = se(up, mu), sr = se(right, mr);
    bool clear(double m, double s) =>
        m.abs() > 1e-12 && m.abs() >= significance * s;
    return ColdBoreSummary(
      suppressor: suppressor,
      firstShots: n,
      verdict: clear(mu, su) || clear(mr, sr)
          ? ColdBoreVerdict.suggest
          : ColdBoreVerdict.notSignificant,
      meanUpMrad: mu,
      meanRightMrad: mr,
      seUpMrad: su,
      seRightMrad: sr,
    );
  }
}
