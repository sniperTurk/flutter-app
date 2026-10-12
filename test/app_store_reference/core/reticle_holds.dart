import '../models/domain.dart';
import 'ballistic_engine.dart';
import 'ballistic_input.dart';
import 'production_limits.dart';

/// One reticle dot with the distance at which holding that many mil lands the
/// shot on target.
class HoldMark {
  /// Hold in mil (milliradians) below the centre of the reticle.
  final double mil;

  /// Distance (m) whose elevation correction equals [mil], or null when the
  /// projectile never needs that much (it cannot reach, or the correction
  /// stays smaller).
  final double? distanceM;
  const HoldMark(this.mil, this.distanceM);
}

/// Pure helpers that turn the drag solver's elevation and wind output into
/// reticle marks. Nothing here invents a ballistic value: every number is a
/// point (or a linear interpolation between neighbouring points) of the
/// production solver.
abstract final class ReticleHolds {
  /// Spacing of the sampled ranges (m).
  static const double stepM = 1.0;

  /// Largest range the helper ever asks the solver for.
  static const double maxRangeM = ProductionLimits.maxRangeM;

  /// Range ladder used when the full range is not reachable.
  static const List<double> _ladder = [3000, 1500, 800, 500, 300, 150, 80, 40];

  /// Samples the elevation correction (mrad) at 1 m steps up to the farthest
  /// range the projectile reaches. Returns an empty list when nothing is
  /// reachable. The input must carry a ballistic coefficient and drag law.
  static List<TrajectoryPoint> sample(BallisticInput base) {
    for (final limit in _ladder) {
      final top = limit > maxRangeM ? maxRangeM : limit;
      if (top < stepM * 2) continue;
      final ranges = <double>[
        for (var r = stepM; r <= top + 1e-9; r += stepM) r,
      ];
      try {
        return const BallisticEngine().solve(
          BallisticInput(
            muzzleVelocityMps: base.muzzleVelocityMps,
            grain: base.grain,
            zeroRangeM: base.zeroRangeM,
            sightHeightMm: base.sightHeightMm,
            rangesM: ranges,
            environment: base.environment,
            zeroEnvironment: base.zeroEnvironment,
            ballisticCoefficient: base.ballisticCoefficient,
            ballisticModel: base.ballisticModel,
            bcBands: base.bcBands,
            zeroMuzzleVelocityMps: base.zeroMuzzleVelocityMps,
            inclineDeg: base.inclineDeg,
            cantDeg: base.cantDeg,
            latitudeDeg: base.latitudeDeg,
            azimuthDeg: base.azimuthDeg,
          ),
        );
      } on StateError {
        continue;
      }
    }
    return const [];
  }

  /// Distance where the elevation correction first reaches each of [mils],
  /// searched beyond the zero range. Linear interpolation between samples.
  static List<HoldMark> marks({
    required List<TrajectoryPoint> samples,
    required double zeroRangeM,
    required List<double> mils,
  }) {
    final beyond = samples.where((p) => p.rangeM >= zeroRangeM).toList();
    return [for (final mil in mils) HoldMark(mil, _distanceFor(beyond, mil))];
  }

  static double? _distanceFor(List<TrajectoryPoint> pts, double mil) {
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      if (a.correctionMrad < mil && b.correctionMrad >= mil) {
        final span = b.correctionMrad - a.correctionMrad;
        final f = span == 0 ? 0.0 : (mil - a.correctionMrad) / span;
        return a.rangeM + (b.rangeM - a.rangeM) * f;
      }
    }
    return null;
  }

  /// Crosswind speed (m/s) that moves the impact [mil] at [rangeM], for the
  /// projectile in [base], from the drag solver with a 1 m/s full-value
  /// crosswind. Drift is close to linear in crosswind speed for the speeds a
  /// shooter meets, so the single 1 m/s run is scaled. Null when the solver
  /// cannot reach [rangeM] or the drift is zero.
  static double? crosswindForMil({
    required BallisticInput base,
    required double rangeM,
    required double mil,
  }) {
    try {
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
                windMps: 1,
                windDirectionDeg: 90,
              ),
              zeroEnvironment: base.zeroEnvironment,
              ballisticCoefficient: base.ballisticCoefficient,
              ballisticModel: base.ballisticModel,
              bcBands: base.bcBands,
              zeroMuzzleVelocityMps: base.zeroMuzzleVelocityMps,
              inclineDeg: base.inclineDeg,
              // Cant adds its own sideways drift; this helper measures only
              // what the wind does, so the scope is taken as level here.
            ),
          )
          .single;
      final perMps = shot.windMrad.abs();
      if (!perMps.isFinite || perMps <= 0) return null;
      return mil / perMps;
    } on StateError {
      return null;
    }
  }
}
