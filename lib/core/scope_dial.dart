import 'dart:math' as math;

import '../models/domain.dart';
import 'units.dart';

/// One correction value of a trajectory, expressed in the reticle's angular
/// unit. Positive [correction] means the point of impact is BELOW the line of
/// sight at [rangeM] (the turret must be dialled UP), matching the sign of
/// [TrajectoryPoint.correctionMrad] / [TrajectoryPoint.correctionMoa].
class CorrectionSample {
  final double rangeM;
  final double correction;
  const CorrectionSample(this.rangeM, this.correction);
}

/// A hold mark on the reticle's vertical stadia and the range at which
/// holding that mark on the target hits it with the current turret setting.
class HoldoverMark {
  /// Angular distance of the mark from the crosshair, in reticle units.
  /// Positive = below the crosshair (a holdover), negative = above (holdunder).
  final double markAngle;
  final double rangeM;
  const HoldoverMark(this.markAngle, this.rangeM);
}

/// Pure turret/reticle arithmetic for the interactive scope view.
///
/// Sign conventions (all angles in the reticle's own unit):
/// * dialled elevation: positive = turret dialled UP (U),
/// * dialled windage: positive = turret dialled RIGHT (R),
/// * impact offset: positive `up` = point of impact above the crosshair,
///   positive `right` = right of the crosshair.
///
/// Dialling UP raises the point of impact by the dialled angle, so with a
/// required correction `c` the impact sits `dialled - c` above the crosshair.
/// Holding a mark that is `a` below the crosshair on the target raises the
/// impact by `a`, so that mark hits at the range where `c == dialled + a`.
abstract final class ScopeDialMath {
  static void _validClickValue(double clickValue) {
    if (!clickValue.isFinite || clickValue <= 0) {
      throw ArgumentError.value(clickValue, 'clickValue', 'must be > 0');
    }
  }

  /// Angle dialled by [clicks] turret clicks of [clickValue] each.
  static double clicksToAngle(int clicks, double clickValue) {
    _validClickValue(clickValue);
    return clicks * clickValue;
  }

  /// Nearest whole number of clicks for an angular [correction].
  static int clicksFor(double correction, double clickValue) {
    _validClickValue(clickValue);
    if (!correction.isFinite) {
      throw ArgumentError.value(correction, 'correction', 'must be finite');
    }
    return (correction / clickValue).round();
  }

  /// Point of impact relative to the crosshair.
  static ({double up, double right}) impactOffset({
    required double dialedUp,
    required double requiredUp,
    required double dialedRight,
    double requiredRight = 0,
  }) => (up: dialedUp - requiredUp, right: dialedRight - requiredRight);

  /// Converts an angle in [unit] to milliradians.
  static double toMrad(double angle, AngularUnit unit) =>
      unit == AngularUnit.mrad ? angle : Units.moaToMrad(angle);

  /// Linear size subtended by [angle] at [rangeM], in metres.
  static double linearAtRange(double angle, double rangeM, AngularUnit unit) =>
      rangeM * math.tan(toMrad(angle, unit) / 1000);

  /// Converts a vacuum/drag trajectory point to a [CorrectionSample] in [unit].
  static CorrectionSample sampleOf(TrajectoryPoint p, AngularUnit unit) =>
      CorrectionSample(
        p.rangeM,
        unit == AngularUnit.mrad ? p.correctionMrad : p.correctionMoa,
      );

  /// For every mark in [markAngles], the far range at which holding that mark
  /// hits with [dialedUp] dialled. [samples] must be sorted by ascending range.
  ///
  /// Near the muzzle the projectile first rises toward the line of sight (the
  /// correction *decreases*); a reticle hold is only meaningful on the far,
  /// descending branch, so only crossings where the correction increases
  /// through the target value are used and the farthest one is reported.
  /// Marks whose range lies outside the sampled interval are omitted —
  /// a label is never extrapolated.
  static List<HoldoverMark> holdovers({
    required double dialedUp,
    required Iterable<double> markAngles,
    required List<CorrectionSample> samples,
  }) {
    if (samples.length < 2) return const [];
    final result = <HoldoverMark>[];
    for (final mark in markAngles) {
      final target = dialedUp + mark;
      double? found;
      for (var i = 1; i < samples.length; i++) {
        final a = samples[i - 1];
        final b = samples[i];
        if (b.rangeM <= a.rangeM) {
          throw ArgumentError('samples must be sorted by ascending range');
        }
        if (a.correction < target && b.correction >= target) {
          final span = b.correction - a.correction;
          final f = span == 0 ? 0.0 : (target - a.correction) / span;
          found = a.rangeM + (b.rangeM - a.rangeM) * f;
        }
      }
      if (found != null) result.add(HoldoverMark(mark, found));
    }
    return result;
  }
}
