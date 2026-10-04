import 'dart:math' as math;

/// Pure compass helpers (no sensors, no UI).
abstract final class CompassMath {
  /// Normalises any angle to [0, 360).
  static double normalize(double degrees) {
    final r = degrees % 360.0;
    return r < 0 ? r + 360.0 : (r >= 360.0 ? 0.0 : r);
  }

  /// Shortest signed difference `to - from` in (-180, 180].
  static double shortestDelta(double from, double to) {
    var d = normalize(to) - normalize(from);
    if (d > 180) d -= 360;
    if (d <= -180) d += 360;
    return d;
  }

  /// Turkish 16-wind abbreviations: K kuzey, D doğu, G güney, B batı.
  static const _names16 = <String>[
    'K', 'KKD', 'KD', 'DKD', 'D', 'DGD', 'GD', 'GGD',
    'G', 'GGB', 'GB', 'BGB', 'B', 'BKB', 'KB', 'KKB',
  ];

  static const _spoken16 = <String>[
    'kuzey', 'kuzey kuzeydoğu', 'kuzeydoğu', 'doğu kuzeydoğu',
    'doğu', 'doğu güneydoğu', 'güneydoğu', 'güney güneydoğu',
    'güney', 'güney güneybatı', 'güneybatı', 'batı güneybatı',
    'batı', 'batı kuzeybatı', 'kuzeybatı', 'kuzey kuzeybatı',
  ];

  static int _index16(double degrees) => ((normalize(degrees) + 11.25) / 22.5).floor() % 16;

  /// 16-point Turkish abbreviation (K, KKD, KD, ...).
  static String cardinal16(double degrees) => _names16[_index16(degrees)];

  /// Full Turkish direction name for screen readers.
  static String cardinal16Spoken(double degrees) => _spoken16[_index16(degrees)];

  /// Whole degrees for display, 360 never shown (359.6 -> 0).
  static int wholeDegrees(double degrees) => normalize(degrees).round() % 360;
}

/// Smooths angles on the unit circle so 359° -> 1° does not swing through
/// 180°. Smoothing only reduces jitter; it does NOT make the sensor more
/// accurate and must never be presented as such.
class CircularSmoother {
  /// 0 < alpha <= 1; larger follows the input faster.
  final double alpha;
  double? _sin;
  double? _cos;

  CircularSmoother({this.alpha = 0.2})
      : assert(alpha > 0 && alpha <= 1, 'alpha must be in (0, 1]');

  double add(double degrees) {
    final r = degrees * math.pi / 180.0;
    final s = math.sin(r), c = math.cos(r);
    if (_sin == null || _cos == null) {
      _sin = s;
      _cos = c;
    } else {
      _sin = _sin! + alpha * (s - _sin!);
      _cos = _cos! + alpha * (c - _cos!);
    }
    return CompassMath.normalize(math.atan2(_sin!, _cos!) * 180.0 / math.pi);
  }

  void reset() {
    _sin = null;
    _cos = null;
  }
}
