import 'dart:math' as math;

import '../../core/production_limits.dart';

/// Statistics of a velocity series (all values in m/s).
class VelocityStats {
  final int count;
  final double meanMps;

  /// Sample standard deviation (n-1); null for a single shot.
  final double? sdMps;

  /// Extreme spread (max - min).
  final double esMps;
  final double minMps, maxMps;
  const VelocityStats({
    required this.count,
    required this.meanMps,
    required this.sdMps,
    required this.esMps,
    required this.minMps,
    required this.maxMps,
  });
}

abstract final class ChronographStats {
  /// Largest accepted single reading. Same limit as a saved profile's muzzle
  /// velocity: a mean above it could otherwise be written to a profile that
  /// the profile decoder later rejects (the whole collection falls back to
  /// the backup copy).
  static const maxPlausibleMps = ProductionLimits.maxMuzzleVelocityMps;

  /// Returns null for an empty series. Throws [ArgumentError] for values
  /// that are not finite or not positive.
  static VelocityStats? compute(List<double> velocitiesMps) {
    if (velocitiesMps.isEmpty) return null;
    for (final v in velocitiesMps) {
      if (!v.isFinite || v <= 0 || v > maxPlausibleMps) {
        throw ArgumentError.value(v, 'velocity', 'must be finite and in (0, $maxPlausibleMps] m/s');
      }
    }
    final n = velocitiesMps.length;
    final mean = velocitiesMps.reduce((a, b) => a + b) / n;
    double? sd;
    if (n > 1) {
      final ss = velocitiesMps.fold<double>(0, (acc, v) => acc + (v - mean) * (v - mean));
      sd = math.sqrt(ss / (n - 1));
    }
    final mn = velocitiesMps.reduce(math.min);
    final mx = velocitiesMps.reduce(math.max);
    return VelocityStats(count: n, meanMps: mean, sdMps: sd, esMps: mx - mn, minMps: mn, maxMps: mx);
  }
}
