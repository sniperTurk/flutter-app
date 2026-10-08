import 'dart:math' as math;

import '../ports/tilt_provider.dart';

/// Shot incline and scope cant from the phone's accelerometer.
///
/// `sensors_plus` reports the reaction to gravity in device axes (Android
/// convention, also on iOS): x to the right of the screen, y to its top,
/// z out of the screen toward the user. Upright in portrait gives y ≈ +9.8,
/// lying flat screen-up gives z ≈ +9.8.
abstract final class ShotAngleMath {
  /// |g| below this is not a usable gravity reading.
  static const minGravity = 4.0;

  /// Incline of the BACK camera's line of sight above (+) or below (−) the
  /// horizontal, degrees, with the phone held upright and the camera aimed
  /// at the target. Lying flat screen-up reads −90° (camera straight down).
  /// Rolling the phone sideways does not change the reading.
  static double? inclineDeg(GravityVector g) {
    final inPlane = math.sqrt(g.x * g.x + g.y * g.y);
    final mag = math.sqrt(inPlane * inPlane + g.z * g.z);
    if (!mag.isFinite || mag < minGravity) return null;
    return math.atan2(-g.z, inPlane) * 180 / math.pi;
  }

  /// Roll of the phone (held upright, screen facing the shooter, its top
  /// edge along the scope's vertical) in degrees; positive = rotated
  /// clockwise (top to the right), which is the scope-cant sign used by the
  /// solver. Null when the phone lies too flat to tell (|roll| ill-defined).
  static double? cantDeg(GravityVector g) {
    final inPlane = math.sqrt(g.x * g.x + g.y * g.y);
    if (!inPlane.isFinite || inPlane < minGravity) return null;
    return -math.atan2(g.x, g.y) * 180 / math.pi;
  }

  /// Applies a user "Set 0°" offset and keeps the result in −180…180.
  static double relative(double reading, double zeroOffset) {
    var v = reading - zeroOffset;
    while (v > 180) {
      v -= 360;
    }
    while (v < -180) {
      v += 360;
    }
    return v;
  }

  /// Clock-face reading of a cant angle (0° = 12:00, 90° = 3:00); minutes
  /// are rounded. Matches the "0:00" readout of field apps.
  static String clock(double cantDeg) {
    var minutes = ((cantDeg % 360) / 360 * 12 * 60).round() % (12 * 60);
    if (minutes < 0) minutes += 12 * 60;
    final h = minutes ~/ 60, m = minutes % 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  /// "12°" / "−7°" display (whole degrees, Unicode minus, never "−0°").
  static String degrees(double v) {
    final r = v.round();
    if (r == 0) return '0°';
    return r < 0 ? '−${-r}°' : '$r°';
  }
}
