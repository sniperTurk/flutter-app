import 'dart:math' as math;

/// Local gravity (owner, 2026-10-10: "yer çekimi her yerde aynı değil").
///
/// Normal gravity on the WGS-84 ellipsoid (Somigliana closed form) with the
/// free-air height correction. Turkey (36–42° N) is 9.798–9.803 m/s²; the
/// standard 9.80665 is used when the latitude is unknown.
abstract final class Gravity {
  static const double standard = 9.80665;

  // WGS-84 normal gravity constants.
  static const double _ge = 9.7803253359;
  static const double _k = 0.00193185265241;
  static const double _e2 = 0.00669437999013;

  /// m/s² at [latitudeDeg] and [altitudeM] above sea level.
  static double at({required double latitudeDeg, double altitudeM = 0}) {
    final s = math.sin(latitudeDeg * math.pi / 180);
    final s2 = s * s;
    final g0 = _ge * (1 + _k * s2) / math.sqrt(1 - _e2 * s2);
    // Free-air gradient, with its small latitude term.
    final h = altitudeM;
    return g0 -
        (3.087691e-6 - 4.3977e-9 * s2) * h +
        7.2125e-13 * h * h;
  }
}
