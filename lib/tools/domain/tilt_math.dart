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
    double asinDeg(double v) => math.asin((v / mag).clamp(-1.0, 1.0)) * 180.0 / math.pi;
    switch (mode) {
      case TiltMode.flat:
        return TiltAngles(asinDeg(g.x), asinDeg(g.y));
      case TiltMode.upright:
        final roll = math.atan2(g.x, g.y) * 180.0 / math.pi;
        return TiltAngles(roll, asinDeg(g.z));
    }
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
