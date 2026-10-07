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

  /// A bias measured in an earlier session and restored from storage. A new
  /// capture starts a fresh pair and replaces it.
  final TiltAngles? restored;
  const FlipCalibration({this.normal, this.flipped}) : restored = null;
  const FlipCalibration.restored(TiltAngles this.restored)
    : normal = null,
      flipped = null;

  bool get isComplete =>
      (normal != null && flipped != null) || restored != null;

  /// Constant bias to subtract from future readings, or null until both
  /// captures are in.
  TiltAngles? get bias {
    final n = normal, f = flipped;
    if (n == null || f == null) return restored;
    return TiltAngles((n.xDeg + f.xDeg) / 2, (n.yDeg + f.yDeg) / 2);
  }

  FlipCalibration withNormal(TiltAngles a) =>
      FlipCalibration(normal: a, flipped: flipped);

  FlipCalibration withFlipped(TiltAngles a) =>
      FlipCalibration(normal: normal, flipped: a);
}

/// Exponential smoothing of the gravity vector. Reduces jitter only.
///
/// With a fixed [alpha] every sample moves the estimate by the same share.
/// [GravityFilter.adaptive] instead smooths hard while the phone is still
/// (a steady read-out) and lets go while it moves (no lag): the share grows
/// with how far the new sample is from the current estimate.
class GravityFilter {
  final double alpha;

  /// Adaptive mode: share used while still (deviations up to
  /// [stillBandMps2], i.e. sensor noise), share reached at [motionMps2] of
  /// deviation, both in m/s². Null in fixed mode.
  final double? stillAlpha;
  final double? movingAlpha;
  final double? stillBandMps2;
  final double? motionMps2;
  GravityVector? _state;

  GravityFilter({this.alpha = 0.15})
    : stillAlpha = null,
      movingAlpha = null,
      stillBandMps2 = null,
      motionMps2 = null,
      assert(alpha > 0 && alpha <= 1, 'alpha must be in (0, 1]');

  /// About 0.5 s time constant while still at the ~50 Hz game rate (noise
  /// up to ~0.1 m/s², ~0.6°), close to raw response once a sample is
  /// ~0.8 m/s² (~4.5°) off the estimate.
  GravityFilter.adaptive({
    double still = 0.04,
    double moving = 0.6,
    double stillBand = 0.1,
    double motion = 0.8,
  }) : alpha = still,
       stillAlpha = still,
       movingAlpha = moving,
       stillBandMps2 = stillBand,
       motionMps2 = motion,
       assert(still > 0 && still <= moving && moving <= 1),
       assert(stillBand >= 0 && motion > stillBand);

  bool get isAdaptive => stillAlpha != null;

  /// Share of the new sample for a given deviation from the estimate.
  double shareFor(double deviationMps2) {
    final still = stillAlpha, moving = movingAlpha;
    final band = stillBandMps2, motion = motionMps2;
    if (still == null || moving == null || band == null || motion == null) {
      return alpha;
    }
    final t = ((deviationMps2 - band) / (motion - band))
        .clamp(0.0, 1.0)
        .toDouble();
    return still + (moving - still) * t;
  }

  GravityVector add(GravityVector v) {
    final s = _state;
    if (s == null) {
      _state = v;
    } else {
      final dx = v.x - s.x, dy = v.y - s.y, dz = v.z - s.z;
      final a = shareFor(math.sqrt(dx * dx + dy * dy + dz * dz));
      _state = GravityVector(s.x + a * dx, s.y + a * dy, s.z + a * dz);
    }
    return _state!;
  }

  void reset() => _state = null;
}

/// Averages raw gravity samples for one calibration reading and rejects the
/// reading if the phone moved: the first [settleSamples] are skipped (the
/// tap that started it), then [samples] are collected; any sample further
/// than [stillToleranceMps2] from the running mean starts the collection
/// over. Pure and synchronous: the caller feeds samples.
class StillAverager {
  final int settleSamples;
  final int samples;
  final double stillToleranceMps2;

  int _skipped = 0;
  int _n = 0;
  double _sx = 0, _sy = 0, _sz = 0;
  int _restarts = 0;

  StillAverager({
    this.settleSamples = 15,
    this.samples = 100,
    this.stillToleranceMps2 = 0.12,
  }) : assert(settleSamples >= 0 && samples > 0 && stillToleranceMps2 > 0);

  /// 0..1 progress of the current attempt.
  double get progress => _n / samples;

  /// How many times the phone moved and the collection started over.
  int get restarts => _restarts;

  bool get isComplete => _n >= samples;

  /// Mean of the collected samples once [isComplete], else null.
  GravityVector? get mean =>
      isComplete ? GravityVector(_sx / _n, _sy / _n, _sz / _n) : null;

  /// Feeds one sample. Returns true when the reading is complete.
  bool add(GravityVector v) {
    if (isComplete) return true;
    if (_skipped < settleSamples) {
      _skipped++;
      return false;
    }
    if (_n > 0) {
      final dx = v.x - _sx / _n, dy = v.y - _sy / _n, dz = v.z - _sz / _n;
      if (math.sqrt(dx * dx + dy * dy + dz * dz) > stillToleranceMps2) {
        _restarts++;
        _n = 0;
        _sx = _sy = _sz = 0;
        _skipped = 0;
        return false;
      }
    }
    _n++;
    _sx += v.x;
    _sy += v.y;
    _sz += v.z;
    return isComplete;
  }
}
