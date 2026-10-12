import 'ballistic_engine.dart';
import 'ballistic_input.dart';

/// Sampling of the MPBR scan: trajectory heights every [stepM] up to
/// [maxRangeM]; candidate zeros every [zeroStepM].
class MpbrGrid {
  final double stepM, maxRangeM, zeroStepM;
  const MpbrGrid({
    required this.stepM,
    required this.maxRangeM,
    required this.zeroStepM,
  });

  static const pcp = MpbrGrid(stepM: 1, maxRangeM: 150, zeroStepM: 2);
  static const firearm = MpbrGrid(stepM: 5, maxRangeM: 600, zeroStepM: 10);
}

/// Avcı sıfırı result (metres along the line of sight).
class MpbrResult {
  /// Zero range to sight in at: where the path comes back down through the
  /// line of sight (far crossing).
  final double zeroM;

  /// Where the path first rises through the line of sight (near crossing);
  /// the same trajectory, so either range can be used to zero.
  final double? nearZeroM;

  /// From [nearM] to [farM] the path stays inside the target zone: no hold.
  final double nearM, farM;

  /// Highest point above the line of sight (about half the zone).
  final double apexM;

  const MpbrResult({
    required this.zeroM,
    required this.nearZeroM,
    required this.nearM,
    required this.farM,
    required this.apexM,
  });
}

class _Eval {
  final double apexM;
  final double nearM;
  final double? farM, upCrossM, downCrossM;
  const _Eval(this.apexM, this.nearM, this.farM, this.upCrossM, this.downCrossM);
}

/// Ö7 Avcı sıfırı / en uzun tutuşsuz menzil (maximum point-blank range).
///
/// The flat-fire rule (McCoy, Modern Exterior Ballistics, ch. 2): the path
/// may rise at most half the zone above the line of sight and the farthest
/// no-hold range is reached when the apex is exactly that high. The scan
/// uses the production solver unchanged: zeros are stepped until the apex
/// leaves the zone, then the last good and first bad zero are bisected.
abstract final class Mpbr {
  /// Hedef bölge çapı choices (owner list, 2026-10-12).
  static const List<double> zoneDiametersCm = [2.5, 4, 10, 15, 20];

  /// [build] returns the caller's input for a zero range and sample ranges
  /// (atmosphere, velocity, drag model are the caller's). Null when no zero
  /// keeps the path inside the zone.
  static MpbrResult? solve({
    required BallisticInput Function(double zeroM, List<double> rangesM)
    build,
    required double zoneDiameterM,
    required MpbrGrid grid,
  }) {
    if (!zoneDiameterM.isFinite || zoneDiameterM <= 0) return null;
    final half = zoneDiameterM / 2;
    final ranges = <double>[
      for (var i = 1; i * grid.stepM <= grid.maxRangeM + 1e-9; i++)
        i * grid.stepM,
    ];

    _Eval? eval(double zeroM) {
      final BallisticInput input;
      try {
        input = build(zeroM, ranges);
      } on ArgumentError {
        return null;
      }
      final points = const BallisticEngine().solveReachable(input).points;
      if (points.isEmpty) return null;
      final r = <double>[0, for (final p in points) p.rangeM];
      final h = <double>[
        -input.sightHeightMm / 1000,
        for (final p in points) -p.dropM,
      ];
      var apexI = 0;
      for (var i = 1; i < h.length; i++) {
        if (h[i] > h[apexI]) apexI = i;
      }
      double cross(int i, double level) =>
          r[i - 1] + (level - h[i - 1]) / (h[i] - h[i - 1]) * (r[i] - r[i - 1]);
      var near = double.nan;
      for (var i = 0; i < h.length; i++) {
        if (h[i] >= -half) {
          near = i == 0 ? 0 : cross(i, -half);
          break;
        }
      }
      double? far, up, down;
      for (var i = 1; i < h.length; i++) {
        if (up == null && i <= apexI && h[i - 1] < 0 && h[i] >= 0) {
          up = cross(i, 0);
        }
        if (i > apexI && down == null && h[i - 1] >= 0 && h[i] < 0) {
          down = cross(i, 0);
        }
        if (i > apexI && h[i] < -half) {
          far = cross(i, -half);
          break;
        }
      }
      return _Eval(h[apexI], near, far, up, down);
    }

    bool ok(_Eval? e) =>
        e != null && e.farM != null && !e.nearM.isNaN && e.apexM <= half;

    _Eval? best;
    double? good, bad;
    for (var z = grid.zeroStepM; z <= grid.maxRangeM; z += grid.zeroStepM) {
      final e = eval(z);
      if (ok(e)) {
        if (best == null || e!.farM! > best.farM!) best = e;
        good = z;
      } else if (good != null) {
        bad = z;
        break;
      }
    }
    if (best == null) return null;
    if (good != null && bad != null) {
      var lo = good, hi = bad;
      for (var i = 0; i < 14; i++) {
        final mid = (lo + hi) / 2;
        final e = eval(mid);
        if (ok(e)) {
          lo = mid;
          if (e!.farM! >= best!.farM!) best = e;
        } else {
          hi = mid;
        }
      }
    }
    final b = best!;
    return MpbrResult(
      zeroM: b.downCrossM ?? b.upCrossM ?? b.farM!,
      nearZeroM: b.downCrossM == null ? null : b.upCrossM,
      nearM: b.nearM,
      farM: b.farM!,
      apexM: b.apexM,
    );
  }
}
