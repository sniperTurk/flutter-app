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

  /// Turret click used when the profile's unit differs from the catalog
  /// scope's click unit: 0.1 mrad or ¼ MOA, the common click of each unit.
  static double standardClick(AngularUnit unit) =>
      unit == AngularUnit.mrad ? 0.1 : 0.25;

  /// Converts [angle] from [from] to [to] (1 mrad = 3.43775 MOA).
  static double convert(double angle, AngularUnit from, AngularUnit to) {
    if (from == to) return angle;
    return to == AngularUnit.moa
        ? Units.mradToMoa(angle)
        : Units.moaToMrad(angle);
  }

  /// Angle, in the reticle's own unit, that ONE reticle unit really covers.
  ///
  /// * FFP (first focal plane): the reticle is magnified with the image, so
  ///   a 1 mrad / 1 MOA mark covers exactly that at every magnification.
  /// * SFP (second focal plane): the reticle stays the same size while the
  ///   image grows, so the marks are true only at the calibration
  ///   magnification; at [magnification] one mark covers
  ///   `calibration / magnification` units.
  static double reticleSubtension({
    required bool firstFocalPlane,
    required double magnification,
    required double calibrationMagnification,
  }) {
    if (firstFocalPlane) return 1;
    if (!magnification.isFinite || magnification <= 0) {
      throw ArgumentError.value(magnification, 'magnification', 'must be > 0');
    }
    if (!calibrationMagnification.isFinite || calibrationMagnification <= 0) {
      throw ArgumentError.value(
        calibrationMagnification,
        'calibrationMagnification',
        'must be > 0',
      );
    }
    return calibrationMagnification / magnification;
  }

  /// Half of the visible field (true angle, reticle unit) at [magnification]
  /// when [halfFieldAtReference] is visible at [referenceMagnification].
  /// The field of view shrinks in proportion to magnification.
  static double visibleHalfField({
    required double halfFieldAtReference,
    required double magnification,
    required double referenceMagnification,
  }) {
    if (!magnification.isFinite || magnification <= 0) {
      throw ArgumentError.value(magnification, 'magnification', 'must be > 0');
    }
    return halfFieldAtReference * referenceMagnification / magnification;
  }

  /// Converts an angle in [unit] to milliradians.
  static double toMrad(double angle, AngularUnit unit) =>
      unit == AngularUnit.mrad ? angle : Units.moaToMrad(angle);

  /// Linear size subtended by [angle] at [rangeM], in metres.
  static double linearAtRange(double angle, double rangeM, AngularUnit unit) =>
      rangeM * math.tan(toMrad(angle, unit) / 1000);

  /// Angle (in [unit]) subtended by an object [sizeM] metres across at
  /// [rangeM]. Inverse of [linearAtRange]: a 10 cm target at 50 m is 2 mrad.
  static double angleAtRange(double sizeM, double rangeM, AngularUnit unit) {
    if (!rangeM.isFinite || rangeM <= 0) {
      throw ArgumentError.value(rangeM, 'rangeM', 'must be > 0');
    }
    final mrad = math.atan(sizeM / rangeM) * 1000;
    return unit == AngularUnit.mrad ? mrad : Units.mradToMoa(mrad);
  }

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
