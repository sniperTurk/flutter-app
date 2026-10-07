import 'dart:math' as math;

import '../ports/tilt_provider.dart';

/// How the phone is held while levelling.
enum TiltMode {
  /// Lying flat, screen up (horizontal surfaces).
  flat,

  /// Held upright, screen facing the user (vertical surfaces).
  upright,
}

class TiltAngles {
  /// Left/right tilt in degrees.
  final double xDeg;

  /// Forward/back tilt in degrees.
  final double yDeg;
  const TiltAngles(this.xDeg, this.yDeg);
}

/// Pure tilt maths. All results are derived from the accelerometer's gravity
/// vector. The 0.01° in the UI is a DISPLAY resolution only: it is not the
/// accuracy of a phone accelerometer.
abstract final class TiltMath {
  /// |g| below this means the vector is not a usable gravity reading
  /// (free fall, sensor fault).
  static const minGravity = 4.0;

  /// Returns null when the vector cannot be used.
  static TiltAngles? angles(GravityVector g, TiltMode mode) {
    final mag = math.sqrt(g.x * g.x + g.y * g.y + g.z * g.z);
    if (!mag.isFinite || mag < minGravity) return null;
    double asinDeg(double v) =>
        math.asin((v / mag).clamp(-1.0, 1.0)) * 180.0 / math.pi;
    switch (mode) {
      case TiltMode.flat:
        return TiltAngles(asinDeg(g.x), asinDeg(g.y));
      case TiltMode.upright:
        final roll = math.atan2(g.x, g.y) * 180.0 / math.pi;
        return TiltAngles(roll, asinDeg(g.z));
    }
  }

  /// Pose from gravity: flat when most of gravity is along the screen
  /// normal (|gz|/|g| >= 0.8), upright when it is mostly in the screen plane
  /// (<= 0.6); in between the [current] pose is kept (hysteresis).
  static TiltMode poseFor(GravityVector g, TiltMode current) {
    final mag = math.sqrt(g.x * g.x + g.y * g.y + g.z * g.z);
    if (!mag.isFinite || mag < minGravity) return current;
    final f = g.z.abs() / mag;
    if (f >= 0.8) return TiltMode.flat;
    if (f <= 0.6) return TiltMode.upright;
    return current;
  }

  /// "0,00" style text (Turkish comma) with a fixed 0.01° resolution; never "-0,00".
  static String format(double degrees) {
    final text = degrees.toStringAsFixed(2).replaceAll('.', ',');
    return text == '-0,00' ? '0,00' : text;
  }

  /// UI aid threshold for the "Seviyede" state, NOT a sensor specification.
  static const levelToleranceDeg = 0.5;

  static bool isLevel(TiltAngles a) =>
      a.xDeg.abs() <= levelToleranceDeg && a.yDeg.abs() <= levelToleranceDeg;

  /// Angle beyond which a percent-grade or roof-pitch conversion is not
  /// meaningful (the surface is effectively vertical and tan() diverges).
  static const _percentGuardDeg = 89.9;

  /// Percent grade (tan(θ)×100), or null beyond [_percentGuardDeg].
  static double? percentGrade(double degrees) {
    if (degrees.abs() >= _percentGuardDeg) return null;
    return math.tan(degrees * math.pi / 180.0) * 100.0;
  }

  /// Roofing "rise per 12" pitch (tan(θ)×12), or null beyond
  /// [_percentGuardDeg]. This is the common "x/12" notation, not a
  /// certified roofing measurement.
  static double? roofPitchPer12(double degrees) {
    if (degrees.abs() >= _percentGuardDeg) return null;
    return math.tan(degrees * math.pi / 180.0) * 12.0;
  }

  /// "0,0%" style text for [percentGrade], or '—' when not meaningful.
  static String percentText(double degrees) {
    final p = percentGrade(degrees);
    if (p == null) return '—';
    var text = p.toStringAsFixed(1).replaceAll('.', ',');
    if (text == '-0,0') text = '0,0';
    return '$text%';
  }

  /// "n/12" style text for [roofPitchPer12], or '—' when not meaningful.
  static String roofPitchText(double degrees) {
    final p = roofPitchPer12(degrees);
    if (p == null) return '—';
    final rounded = (p * 2).round() / 2; // nearest 0.5
    final mag = rounded.abs();
    final magText = mag == mag.roundToDouble()
        ? mag.toStringAsFixed(0)
        : mag.toStringAsFixed(1).replaceAll('.', ',');
    final sign = rounded < 0 ? '-' : '';
    return '$sign$magText/12';
  }
}

/// Which layout the Su Terazisi screen shows. Mirrors the view choices of
/// dedicated physical level tools: a single bar vial ("torpedo" level, used
/// along edges and rails), a circular bullseye vial (used on flat surfaces,
/// "mason's" style), or every gauge together (a precision/"engineer's"
/// combined view — this app's original design).
enum LevelViewType { all, torpedo, bullseye }

/// How an angle is displayed next to its gauge.
enum AngleDisplayUnit { degrees, percent, roofPitch }

/// Two-point "flip" calibration for one [TiltMode]: a reading captured in
/// the normal orientation and a second reading after physically rotating
/// the phone 180° on the same surface. The average of the pair is a
/// constant sensor/mounting bias that cancels out regardless of which way
/// is physically "up" — unlike [TiltAngles] offsets set from a single
/// reading, it does not depend on any assumption about the accelerometer's
/// sign convention (never verified in this codebase without a physical
/// device). A complete calibration is one pair per mode (flat, upright):
/// four captures in total.
class FlipCalibration {
  final TiltAngles? normal;
  final TiltAngles? flipped;
  const FlipCalibration({this.normal, this.flipped});

  bool get isComplete => normal != null && flipped != null;

  /// Constant bias to subtract from future readings, or null until both
  /// captures are in.
  TiltAngles? get bias {
    final n = normal, f = flipped;
    if (n == null || f == null) return null;
    return TiltAngles((n.xDeg + f.xDeg) / 2, (n.yDeg + f.yDeg) / 2);
  }

  FlipCalibration withNormal(TiltAngles a) =>
      FlipCalibration(normal: a, flipped: flipped);

  FlipCalibration withFlipped(TiltAngles a) =>
      FlipCalibration(normal: normal, flipped: a);
}

/// Exponential smoothing of the gravity vector. Reduces jitter only.
class GravityFilter {
  final double alpha;
  GravityVector? _state;

  GravityFilter({this.alpha = 0.15})
    : assert(alpha > 0 && alpha <= 1, 'alpha must be in (0, 1]');

  GravityVector add(GravityVector v) {
    final s = _state;
    if (s == null) {
      _state = v;
    } else {
      _state = GravityVector(
        s.x + alpha * (v.x - s.x),
        s.y + alpha * (v.y - s.y),
        s.z + alpha * (v.z - s.z),
      );
    }
    return _state!;
  }

  void reset() => _state = null;
}
