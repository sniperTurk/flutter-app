import 'ballistic_engine.dart';
import 'ballistic_input.dart';
import '../models/domain.dart';

/// How much of the wind drift comes from the near, middle and far third of
/// the path (Ö2, docs/yeni-hesaplar-2026-10-11.md). The bullet is fastest
/// and has the longest time left to drift near the muzzle, so the near wind
/// matters most (McCoy, Modern Exterior Ballistics, ch. 5, "lag" rule).
///
/// Solved with the existing engine and [WindZones]: a full-value 1 m/s
/// crosswind in one third at a time, calm in the other two. Coriolis and
/// cant are left out, as in `ReticleHolds.crosswindForMil`, so only the
/// wind moves the bullet sideways.
class WindZoneShares {
  /// Whole percents; they add up to 100.
  final int nearPct, midPct, farPct;

  const WindZoneShares(this.nearPct, this.midPct, this.farPct);

  /// Null when the range is unusable or the wind moves nothing.
  static WindZoneShares? compute(BallisticInput base, double rangeM) {
    if (!rangeM.isFinite || rangeM <= 0) return null;
    double drift(double near, double mid, double far) {
      final shot = const BallisticEngine()
          .solve(
            BallisticInput(
              muzzleVelocityMps: base.muzzleVelocityMps,
              grain: base.grain,
              zeroRangeM: base.zeroRangeM,
              sightHeightMm: base.sightHeightMm,
              rangesM: [rangeM],
              environment: EnvironmentData(
                temperatureC: base.environment.temperatureC,
                pressureHpa: base.environment.pressureHpa,
                humidityPercent: base.environment.humidityPercent,
                altitudeM: base.environment.altitudeM,
                windMps: near,
                windDirectionDeg: 90,
              ),
              windZones: WindZones(rangeM: rangeM, midMps: mid, farMps: far),
              zeroEnvironment: base.zeroEnvironment,
              ballisticCoefficient: base.ballisticCoefficient,
              ballisticModel: base.ballisticModel,
              bcBands: base.bcBands,
              dragTable: base.dragTable,
              zeroMuzzleVelocityMps: base.zeroMuzzleVelocityMps,
              gravityMps2: base.gravityMps2,
              inclineDeg: base.inclineDeg,
            ),
          )
          .single;
      return shot.windMrad.abs();
    }

    try {
      final d = [drift(1, 0, 0), drift(0, 1, 0), drift(0, 0, 1)];
      final total = d[0] + d[1] + d[2];
      if (!total.isFinite || total <= 1e-9) return null;
      final p = _wholePercents([for (final x in d) x / total * 100]);
      return WindZoneShares(p[0], p[1], p[2]);
    } on ArgumentError {
      return null;
    } on UnsupportedError {
      return null;
    } on StateError {
      return null;
    }
  }

  /// Largest-remainder rounding, so the three percents add up to 100.
  static List<int> _wholePercents(List<double> raw) {
    final floors = [for (final x in raw) x.floor()];
    var left = 100 - floors.reduce((a, b) => a + b);
    final order = [0, 1, 2]
      ..sort((a, b) => (raw[b] - floors[b]).compareTo(raw[a] - floors[a]));
    for (final i in order) {
      if (left <= 0) break;
      floors[i]++;
      left--;
    }
    return floors;
  }
}
