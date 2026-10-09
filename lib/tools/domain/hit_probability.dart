import 'dart:math' as math;

import '../../core/units.dart';

/// V1.1: closed-form hit-probability ("WEZ"-style) estimate from a measured
/// group size. This intentionally does NOT model wind or velocity-SD as
/// separate inputs: those error sources are already baked into a real,
/// shot-on-paper group, and layering an unvalidated wind/SD contribution on
/// top would double count error or require the still-unvalidated drag model
/// (see validation/README.md). Treat it as a simplifying assumption, not a
/// full closed-form ballistic solution.
///
/// Model: shot impacts are assumed to be an isotropic (circular) 2-D Gaussian
/// around the aim point with per-axis standard deviation sigma. The measured
/// group size is the extreme spread (centre-to-centre of the two widest
/// holes) of an N-shot group; its expected value is k(N)·sigma (see
/// [extremeSpreadFactor]), so sigma = groupDiameter / k(N). (Before
/// 2026-10-09 the group radius was taken as sigma, which overstated the
/// dispersion 1.5× for a 5-shot group.) The probability that a shot lands
/// within a circular target of radius R then has the closed Rayleigh form:
///   P(hit) = 1 - exp(-R^2 / (2*sigma^2))
/// "sigma" scales linearly with range because the group size is supplied as
/// an angular (MOA) value.
class HitProbabilityEngine {
  const HitProbabilityEngine._();

  /// Default number of shots in the measured group.
  static const defaultShots = 5;

  /// Expected extreme spread of an N-shot circular-Gaussian group, in units
  /// of the per-axis sigma (Monte Carlo, 200 000 groups each; N = 2 is the
  /// exact sqrt(pi)).
  static const _esFactor = <int, double>{
    2: 1.772,
    3: 2.404,
    4: 2.793,
    5: 3.067,
    6: 3.273,
    7: 3.444,
    8: 3.586,
    9: 3.705,
    10: 3.811,
  };

  /// k(N) for 2..10 shots; throws for other counts.
  static double extremeSpreadFactor(int shots) {
    final k = _esFactor[shots];
    if (k == null) {
      throw ArgumentError.value(shots, 'shots', 'must be 2..10');
    }
    return k;
  }

  /// Per-axis one-sigma dispersion, in meters, at [rangeM] for a measured
  /// [groupDiameterMoa] (extreme spread of [shots] shots).
  static double sigmaM({
    required double groupDiameterMoa,
    required double rangeM,
    int shots = defaultShots,
  }) {
    final sigmaMoa = groupDiameterMoa / extremeSpreadFactor(shots);
    return Units.moaToMrad(sigmaMoa) / 1000 * rangeM;
  }

  /// Probability (0..1) that a single shot lands inside a circular target of
  /// [targetDiameterCm] at [rangeM], given a measured [groupDiameterMoa].
  static double probabilityOfHit({
    required double groupDiameterMoa,
    required double targetDiameterCm,
    required double rangeM,
    int shots = defaultShots,
  }) {
    if (groupDiameterMoa <= 0 || targetDiameterCm <= 0 || rangeM <= 0) {
      throw ArgumentError(
        'groupDiameterMoa, targetDiameterCm and rangeM must be > 0',
      );
    }
    final sigma = sigmaM(
      groupDiameterMoa: groupDiameterMoa,
      rangeM: rangeM,
      shots: shots,
    );
    final targetRadiusM = targetDiameterCm / 100 / 2;
    if (sigma <= 0) return 1.0;
    final p =
        1 - math.exp(-(targetRadiusM * targetRadiusM) / (2 * sigma * sigma));
    return p.clamp(0.0, 1.0);
  }

  /// The longest range at which a single-shot hit probability of at least
  /// [probability] (0..1, exclusive of 1) is still met, for the same group
  /// and target. Returns null when [probability] is out of (0,1) or the
  /// group size is zero (sigma never grows, so every range already hits).
  static double? maxRangeForProbability({
    required double groupDiameterMoa,
    required double targetDiameterCm,
    required double probability,
    int shots = defaultShots,
  }) {
    if (groupDiameterMoa <= 0 || targetDiameterCm <= 0) return null;
    if (probability <= 0 || probability >= 1) return null;
    final sigmaMradPerM = sigmaM(
      groupDiameterMoa: groupDiameterMoa,
      rangeM: 1,
      shots: shots,
    ); // sigma(m) per 1 m of range
    if (sigmaMradPerM <= 0) return null;
    final targetRadiusM = targetDiameterCm / 100 / 2;
    final denom = sigmaMradPerM * math.sqrt(-2 * math.log(1 - probability));
    if (denom <= 0) return null;
    return targetRadiusM / denom;
  }
}
