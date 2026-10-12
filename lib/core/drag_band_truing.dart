import 'dart:math' as math;

import '../models/domain.dart';
import 'ballistic_engine.dart';
import 'ballistic_input.dart';
import 'drag_table.dart';
import 'standard_drag_tables.dart';

/// One observed hit for multi-range truing: the elevation correction (mrad,
/// up positive, as the solver reports it) that centred the group at
/// [rangeM].
class DragObservation {
  final double rangeM, observedMrad;
  const DragObservation(this.rangeM, this.observedMrad);
}

/// Why multi-range drag truing was refused. Each has a Turkish message.
enum DragTruingRejection {
  tooFewRanges,
  duplicateRange,
  rangeTooShort,
  multiBc,
  noBc,
  notSensitive,
  outOfBounds,
  unreachable,
}

class DragTruingFailure implements Exception {
  final DragTruingRejection reason;
  const DragTruingFailure(this.reason);

  String get message => switch (reason) {
    DragTruingRejection.tooFewRanges =>
      'Sürüklenme eğrisi için en az 3 farklı mesafede ölçüm girin.',
    DragTruingRejection.duplicateRange =>
      'Aynı mesafe iki kez girilmiş. Her ölçüm farklı bir mesafede olmalı.',
    DragTruingRejection.rangeTooShort =>
      'Her mesafe sıfır mesafesinden uzak olmalı.',
    DragTruingRejection.multiBc =>
      'Bu mühimmatta hıza bağlı (çoklu) BC var. Sürüklenme eğrisi tek BC '
          'veya özel eğri ile bulunur.',
    DragTruingRejection.noBc =>
      'Bu mühimmatta balistik katsayı (BC) ve model yok.',
    DragTruingRejection.notSensitive =>
      'Bu mesafelerde sürüklenme farkı düzeltmeyi yeterince değiştirmiyor. '
          'Daha uzak mesafelerde ölçün (ateşli için 500 m ve ötesi).',
    DragTruingRejection.outOfBounds =>
      'Gözlenenleri açıklamak için sürüklenmede %20\'den fazla değişim '
          'gerekirdi. Önce hızı orta mesafede doğrulayın; sıfırı, dürbün '
          'yüksekliğini ve ölçümleri kontrol edin.',
    DragTruingRejection.unreachable =>
      'Mermi en uzak mesafeye ulaşamıyor; doğrulama yapılamaz.',
  };

  @override
  String toString() => 'DragTruingFailure(${reason.name})';
}

/// Scale factor found for one Mach band (1 = unchanged).
class MachBandScale {
  final String label;
  final double minMach, maxMach;
  final double scale;

  /// False when the band was kept at 1: above Mach 2, not reached by the
  /// observations, or left out by the overfitting guard.
  final bool fitted;
  const MachBandScale(
    this.label,
    this.minMach,
    this.maxMach,
    this.scale, {
    required this.fitted,
  });
}

class DragObservationFit {
  final double rangeM, observedMrad, beforeMrad, afterMrad;
  const DragObservationFit({
    required this.rangeM,
    required this.observedMrad,
    required this.beforeMrad,
    required this.afterMrad,
  });

  double get residualBeforeMrad => observedMrad - beforeMrad;
  double get residualAfterMrad => observedMrad - afterMrad;
}

class DragBandResult {
  final List<MachBandScale> bands;

  /// One per observation, nearest first.
  final List<DragObservationFit> fits;

  /// The bullet's own Cd curve with the band scales applied; stored as an
  /// Özel sürüklenme eğrisi with [sectionalDensity] as its BC.
  final List<DragSample> curve;
  final double sectionalDensity;

  const DragBandResult({
    required this.bands,
    required this.fits,
    required this.curve,
    required this.sectionalDensity,
  });

  double get maxResidualAfterMrad =>
      fits.map((f) => f.residualAfterMrad.abs()).reduce(math.max);

  /// The fitted curve still misses an observation by more than 1.5 clicks:
  /// the observations disagree with each other (measurement, wind, zero).
  bool get inconsistent =>
      maxResidualAfterMrad > DragBandTruing.inconsistentResidualMrad;
}

/// Ö6 — Çok mesafeli doğrulama (multi-range drag truing).
///
/// Velocity is trued first at a near/medium range (supersonic). Hits
/// observed at several far ranges then give Cd scale factors per Mach band
/// (McCoy, *Modern Exterior Ballistics*, 1999, ch. 4–7: drag is a function
/// of Mach; Courtney & Courtney, arXiv:0705.0389: one BC does not describe
/// the whole flight). The result is the bullet's own Cd-vs-Mach curve
/// (form factor 1, BC = sectional density; see [DragCurve]).
///
/// Overfitting guard: at least 3 ranges; at most (ranges − 1) bands are
/// fitted, only bands an observation can resolve; a Tikhonov prior pulls
/// every scale toward 1; a change above [maxChangeFraction] is refused.
/// Above Mach 2 is never fitted: that part of the flight is what velocity
/// truing already absorbed.
abstract final class DragBandTruing {
  static const minObservations = 3;
  static const maxObservations = 6;

  /// Band edges (Mach) and the half width of the linear blend at each edge.
  static const bandEdges = [1.2, 1.5, 2.0];
  static const blendMach = 0.05;
  static const bandLabels = [
    'Mach 1,2 altı',
    'Mach 1,2–1,5',
    'Mach 1,5–2',
    'Mach 2 üstü',
  ];

  /// Bands that may be fitted (indices into [bandLabels]).
  static const fittableBands = [0, 1, 2];

  static const double maxChangeFraction = 0.20;

  /// A 10 % change in a band must move some observation by at least half a
  /// 0.1 mrad click, or the band is not fitted.
  static const double sensitivityStep = 0.10;
  static const double minSensitivityMrad = 0.05;

  /// Prior: observation error (half a click) and scale spread (5 %).
  static const double observationSigmaMrad = 0.05;
  static const double scaleSigma = 0.05;
  static const double inconsistentResidualMrad = 0.15;

  static const _derivativeStep = 0.01;
  static const _maxIterations = 10;

  /// The bullet's own Cd curve: the drag table of [base] × SD / BC, sampled
  /// at the table's points and at the band blend points. Flown with BC = SD
  /// it gives exactly the trajectory of [base] (the SD cancels).
  static List<DragSample> ownCurve({
    required BallisticInput base,
    required double sectionalDensity,
  }) {
    final bc = base.ballisticCoefficient, model = base.ballisticModel;
    if (bc == null || model == null) {
      throw const DragTruingFailure(DragTruingRejection.noBc);
    }
    if (!sectionalDensity.isFinite || sectionalDensity <= 0) {
      throw ArgumentError.value(sectionalDensity, 'sectionalDensity');
    }
    final table = base.dragTable ?? StandardDragTables.forModel(model);
    final first = table.samples.first.mach, last = table.samples.last.mach;
    final machs = <double>{
      for (final s in table.samples) s.mach,
      for (final e in bandEdges) ...[e - blendMach, e + blendMach],
    }.where((m) => m >= first && m <= last).toList()..sort();
    final factor = sectionalDensity / bc;
    return List.unmodifiable([
      for (final m in machs) DragSample(m, table.coefficientAtMach(m) * factor),
    ]);
  }

  /// [own] with the four band [scales] applied (blended at the edges).
  static List<DragSample> scaledCurve(
    List<DragSample> own,
    List<double> scales,
  ) {
    if (scales.length != bandLabels.length) {
      throw ArgumentError.value(scales, 'scales', 'one per band');
    }
    return List.unmodifiable([
      for (final p in own)
        DragSample(p.mach, p.coefficient * scaleAt(p.mach, scales)),
    ]);
  }

  /// Scale at [mach]: constant inside a band, linear across ±[blendMach]
  /// around each edge.
  static double scaleAt(double mach, List<double> scales) {
    for (var i = 0; i < bandEdges.length; i++) {
      final e = bandEdges[i];
      if (mach < e - blendMach) return scales[i];
      if (mach <= e + blendMach) {
        final t = (mach - (e - blendMach)) / (2 * blendMach);
        return scales[i] + (scales[i + 1] - scales[i]) * t;
      }
    }
    return scales.last;
  }

  static DragBandResult solve({
    required BallisticInput base,
    required List<DragObservation> observations,
    required double sectionalDensity,
    BallisticEngine engine = const BallisticEngine(),
  }) {
    if (base.ballisticCoefficient == null || base.ballisticModel == null) {
      throw const DragTruingFailure(DragTruingRejection.noBc);
    }
    if (base.bcBands.isNotEmpty) {
      throw const DragTruingFailure(DragTruingRejection.multiBc);
    }
    if (observations.length < minObservations) {
      throw const DragTruingFailure(DragTruingRejection.tooFewRanges);
    }
    if (observations.length > maxObservations) {
      throw ArgumentError.value(observations.length, 'observations');
    }
    final obs = [...observations]..sort((a, b) => a.rangeM.compareTo(b.rangeM));
    for (final o in obs) {
      if (!o.rangeM.isFinite || !o.observedMrad.isFinite || o.rangeM <= 0) {
        throw ArgumentError.value(o.rangeM, 'observation');
      }
      if (o.rangeM <= base.zeroRangeM) {
        throw const DragTruingFailure(DragTruingRejection.rangeTooShort);
      }
    }
    for (var i = 1; i < obs.length; i++) {
      if (obs[i].rangeM - obs[i - 1].rangeM < 1) {
        throw const DragTruingFailure(DragTruingRejection.duplicateRange);
      }
    }

    final own = ownCurve(base: base, sectionalDensity: sectionalDensity);
    final ranges = [for (final o in obs) o.rangeM];
    final y = [for (final o in obs) o.observedMrad];
    final n = obs.length, bands = bandLabels.length;

    // Corrections with the band scales [k]; null when a range is not reached.
    List<double>? predict(List<double> k) {
      try {
        final input = _withCurve(
          base,
          scaledCurve(own, k),
          sectionalDensity,
          ranges,
        );
        return [for (final p in engine.solve(input)) p.correctionMrad];
      } on StateError {
        return null;
      } on ArgumentError {
        return null;
      }
    }

    final ones = List<double>.filled(bands, 1);
    final before = predict(ones);
    if (before == null) {
      throw const DragTruingFailure(DragTruingRejection.unreachable);
    }

    // Which bands the observations can resolve, strongest first.
    final columns = <int, List<double>>{};
    for (final j in fittableBands) {
      final k = [...ones]..[j] = 1 + _derivativeStep;
      final p = predict(k);
      if (p == null) continue;
      columns[j] = [
        for (var i = 0; i < n; i++) (p[i] - before[i]) / _derivativeStep,
      ];
    }
    double strength(int j) =>
        columns[j]!.map((d) => d.abs()).reduce(math.max) * sensitivityStep;
    double norm(int j) => math.sqrt(columns[j]!.fold(0.0, (s, d) => s + d * d));
    final candidates =
        columns.keys.where((j) => strength(j) >= minSensitivityMrad).toList()
          ..sort((a, b) => norm(b).compareTo(norm(a)));
    final free = candidates.take(n - 1).toList()..sort();
    if (free.isEmpty) {
      throw const DragTruingFailure(DragTruingRejection.notSensitive);
    }

    // Regularised Gauss–Newton on the free scales.
    final k = [...ones];
    var current = before;
    for (var it = 0; it < _maxIterations; it++) {
      final jac = <List<double>>[];
      for (final j in free) {
        final kk = [...k]..[j] = k[j] * (1 + _derivativeStep);
        final p = predict(kk);
        if (p == null) {
          throw const DragTruingFailure(DragTruingRejection.outOfBounds);
        }
        jac.add([
          for (var i = 0; i < n; i++)
            (p[i] - current[i]) / (k[j] * _derivativeStep),
        ]);
      }
      final m = free.length;
      const wo = 1 / (observationSigmaMrad * observationSigmaMrad);
      const wk = 1 / (scaleSigma * scaleSigma);
      final a = List.generate(m, (_) => List<double>.filled(m, 0));
      final b = List<double>.filled(m, 0);
      for (var r = 0; r < m; r++) {
        for (var c = 0; c < m; c++) {
          var s = 0.0;
          for (var i = 0; i < n; i++) {
            s += jac[r][i] * jac[c][i];
          }
          a[r][c] = s * wo + (r == c ? wk : 0);
        }
        var s = 0.0;
        for (var i = 0; i < n; i++) {
          s += jac[r][i] * (y[i] - current[i]);
        }
        b[r] = s * wo - (k[free[r]] - 1) * wk;
      }
      final dx = _solveLinear(a, b);
      var largest = 0.0;
      for (var r = 0; r < m; r++) {
        final j = free[r];
        k[j] = (k[j] + dx[r]).clamp(0.5, 1.5).toDouble();
        largest = math.max(largest, dx[r].abs());
      }
      final next = predict(k);
      if (next == null) {
        throw const DragTruingFailure(DragTruingRejection.outOfBounds);
      }
      current = next;
      if (largest < 1e-4) break;
    }
    for (final j in free) {
      if ((k[j] - 1).abs() > maxChangeFraction) {
        throw const DragTruingFailure(DragTruingRejection.outOfBounds);
      }
    }

    return DragBandResult(
      bands: [
        for (var j = 0; j < bands; j++)
          MachBandScale(
            bandLabels[j],
            j == 0 ? 0 : bandEdges[j - 1],
            j < bandEdges.length ? bandEdges[j] : double.infinity,
            k[j],
            fitted: free.contains(j),
          ),
      ],
      fits: [
        for (var i = 0; i < n; i++)
          DragObservationFit(
            rangeM: ranges[i],
            observedMrad: y[i],
            beforeMrad: before[i],
            afterMrad: current[i],
          ),
      ],
      curve: scaledCurve(own, k),
      sectionalDensity: sectionalDensity,
    );
  }

  /// [base] flying [curve] as its own Cd (BC = SD), at [ranges].
  static BallisticInput _withCurve(
    BallisticInput base,
    List<DragSample> curve,
    double sd,
    List<double> ranges,
  ) => BallisticInput(
    muzzleVelocityMps: base.muzzleVelocityMps,
    grain: base.grain,
    zeroRangeM: base.zeroRangeM,
    sightHeightMm: base.sightHeightMm,
    rangesM: ranges,
    environment: base.environment,
    zeroEnvironment: base.zeroEnvironment,
    ballisticCoefficient: sd,
    ballisticModel: BallisticModel.g1,
    dragTable: DragTable(curve),
    windZones: base.windZones,
    inclineDeg: base.inclineDeg,
    cantDeg: base.cantDeg,
    latitudeDeg: base.latitudeDeg,
    azimuthDeg: base.azimuthDeg,
    zeroMuzzleVelocityMps: base.zeroMuzzleVelocityMps,
    gravityMps2: base.gravityMps2,
  );

  /// Gaussian elimination with partial pivoting (at most 3 × 3).
  static List<double> _solveLinear(List<List<double>> a, List<double> b) {
    final n = b.length;
    final m = [
      for (var i = 0; i < n; i++) [...a[i], b[i]],
    ];
    for (var c = 0; c < n; c++) {
      var p = c;
      for (var r = c + 1; r < n; r++) {
        if (m[r][c].abs() > m[p][c].abs()) p = r;
      }
      final t = m[c];
      m[c] = m[p];
      m[p] = t;
      for (var r = c + 1; r < n; r++) {
        final f = m[r][c] / m[c][c];
        for (var k = c; k <= n; k++) {
          m[r][k] -= f * m[c][k];
        }
      }
    }
    final x = List<double>.filled(n, 0);
    for (var r = n - 1; r >= 0; r--) {
      var s = m[r][n];
      for (var k = r + 1; k < n; k++) {
        s -= m[r][k] * x[k];
      }
      x[r] = s / m[r][r];
    }
    return x;
  }
}
