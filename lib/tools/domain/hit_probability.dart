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
/// around the aim point, with the group RADIUS (half the measured group
/// DIAMETER) taken directly as the one-sigma radial dispersion. Under that
/// assumption the probability that a shot lands within a circular target of
/// radius R has the closed Rayleigh form:
///   P(hit) = 1 - exp(-R^2 / (2*sigma^2))
/// This is exact for a circular Gaussian, so no Monte Carlo sampling noise is
/// introduced. "sigma" scales linearly with range because the group size is
/// supplied as an angular (MOA) value.
class HitProbabilityEngine {
  const HitProbabilityEngine._();

  /// One-sigma radial dispersion, in meters, at [rangeM] for a measured
  /// [groupDiameterMoa] (group diameter, not radius).
  static double sigmaM({
    required double groupDiameterMoa,
    required double rangeM,
  }) {
    final sigmaRadiusMoa = groupDiameterMoa / 2;
    final sigmaMrad = Units.moaToMrad(sigmaRadiusMoa);
    return sigmaMrad / 1000 * rangeM;
  }

  /// Probability (0..1) that a single shot lands inside a circular target of
  /// [targetDiameterCm] at [rangeM], given a measured [groupDiameterMoa].
  static double probabilityOfHit({
    required double groupDiameterMoa,
    required double targetDiameterCm,
    required double rangeM,
  }) {
    if (groupDiameterMoa <= 0 || targetDiameterCm <= 0 || rangeM <= 0) {
      throw ArgumentError(
        'groupDiameterMoa, targetDiameterCm and rangeM must be > 0',
      );
    }
    final sigma = sigmaM(groupDiameterMoa: groupDiameterMoa, rangeM: rangeM);
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
  }) {
    if (groupDiameterMoa <= 0 || targetDiameterCm <= 0) return null;
    if (probability <= 0 || probability >= 1) return null;
    final sigmaRadiusMoa = groupDiameterMoa / 2;
    final sigmaMradPerM =
        Units.moaToMrad(sigmaRadiusMoa) / 1000; // sigma(m) per 1 m of range
    if (sigmaMradPerM <= 0) return null;
    final targetRadiusM = targetDiameterCm / 100 / 2;
    final denom = sigmaMradPerM * math.sqrt(-2 * math.log(1 - probability));
    if (denom <= 0) return null;
    return targetRadiusM / denom;
  }
}
