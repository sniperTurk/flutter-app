import 'ballistic_engine.dart';
import 'ballistic_input.dart';
import 'production_limits.dart';

/// Why a truing request was refused. Each has a Turkish user message.
enum TruingRejection {
  /// The observed range is not beyond the zero range: drop there says almost
  /// nothing about velocity.
  rangeTooShort,

  /// A 1 % velocity change moves the predicted correction by less than
  /// [MuzzleVelocityTruing.minSensitivityMrad]; the observation cannot
  /// resolve velocity (shoot farther).
  notSensitive,

  /// Matching the observation would need more than
  /// [MuzzleVelocityTruing.maxChangeFraction] change in velocity. That points
  /// at a wrong BC, zero, sight height or measurement, not at velocity.
  outOfBounds,

  /// The solver could not reach the range even at the current velocity.
  unreachable,

  /// BC truing: matching would need more than
  /// [BallisticCoefficientTruing.maxChangeFraction] change in BC.
  bcOutOfBounds,
}

extension TruingRejectionMessage on TruingRejection {
  String get message => switch (this) {
    TruingRejection.rangeTooShort =>
      'Doğrulama mesafesi sıfır mesafesinden uzak olmalı. Daha uzak bir hedefte ölçün.',
    TruingRejection.notSensitive =>
      'Bu mesafede hız farkı düşümü yeterince değiştirmiyor. Daha uzak bir hedefte ölçün.',
    TruingRejection.outOfBounds =>
      'Gözlenen düzeltme hesaplanandan çok farklı (hızda %15’ten fazla değişim gerekirdi). '
          'Balistik katsayıyı, sıfırı, dürbün yüksekliğini ve ölçümü kontrol edin.',
    TruingRejection.bcOutOfBounds =>
      'Gözlenen düzeltme hesaplanandan çok farklı (BC\'de %30\'dan fazla '
          'değişim gerekirdi). Önce hızı yakın mesafede doğrulayın; sıfırı, '
          'dürbün yüksekliğini ve ölçümü kontrol edin.',
    TruingRejection.unreachable =>
      'Mermi bu mesafeye ulaşamıyor; doğrulama yapılamaz.',
  };
}

class TruingFailure implements Exception {
  final TruingRejection reason;
  const TruingFailure(this.reason);
  String get message => reason.message;
  @override
  String toString() => 'TruingFailure(${reason.name})';
}

class TruingResult {
  /// Velocity the profile had, and the trued one (rounded to 0.1 m/s, the
  /// precision a profile stores).
  final double baseMps, truedMps;

  /// Elevation correction at [rangeM]: what the profile predicted, what was
  /// observed, and what the trued velocity predicts. Positive = dial up.
  final double rangeM, predictedMrad, observedMrad, truedPredictedMrad;

  const TruingResult({
    required this.baseMps,
    required this.truedMps,
    required this.rangeM,
    required this.predictedMrad,
    required this.observedMrad,
    required this.truedPredictedMrad,
  });

  double get changeMps => truedMps - baseMps;
  double get changePercent => changeMps / baseMps * 100;

  /// Observed minus trued prediction; ~0 unless rounding dominates.
  double get residualMrad => observedMrad - truedPredictedMrad;
}

/// Field truing by muzzle velocity ("hız kalibrasyonu", drop tuning).
///
/// The shooter fires at a known range well beyond the zero, notes the
/// elevation that actually centred the group, and this finds the muzzle
/// velocity for which the solver predicts exactly that elevation under the
/// same input (today's atmosphere, incline, cant). The zero is re-solved for
/// every candidate velocity, as on the rifle: the sight was zeroed with the
/// real velocity.
///
/// Only velocity is adjusted. BC stays as published; a large mismatch is
/// refused ([TruingRejection.outOfBounds]) rather than absorbed into an
/// implausible velocity.
abstract final class MuzzleVelocityTruing {
  static const double maxChangeFraction = 0.15;
  static const double minSensitivityMrad = 0.02;
  static const double _toleranceMps = 0.01;

  static TruingResult solve({
    required BallisticInput base,
    required double rangeM,
    required double observedCorrectionMrad,
    BallisticEngine engine = const BallisticEngine(),
  }) {
    if (!rangeM.isFinite ||
        rangeM <= 0 ||
        rangeM > ProductionLimits.maxRangeM) {
      throw ArgumentError.value(rangeM, 'rangeM', 'out of range');
    }
    if (!observedCorrectionMrad.isFinite) {
      throw ArgumentError.value(
        observedCorrectionMrad,
        'observedCorrectionMrad',
        'must be finite',
      );
    }
    if (rangeM <= base.zeroRangeM) {
      throw const TruingFailure(TruingRejection.rangeTooShort);
    }
    final at = base.withRanges([rangeM]);
    final v0 = base.muzzleVelocityMps;

    // Correction at velocity v; +infinity when the bullet cannot get there
    // (a slower bullet "drops forever"), which keeps the function monotone.
    double predict(double v) {
      try {
        return engine.solve(at.withMuzzleVelocity(v)).single.correctionMrad;
      } on StateError {
        return double.infinity;
      }
    }

    final predicted = predict(v0);
    if (!predicted.isFinite) {
      throw const TruingFailure(TruingRejection.unreachable);
    }
    final vUp = (v0 * 1.01).clamp(0, ProductionLimits.maxMuzzleVelocityMps);
    if ((predict(vUp.toDouble()) - predicted).abs() < minSensitivityMrad) {
      throw const TruingFailure(TruingRejection.notSensitive);
    }

    // Correction falls as velocity rises. Bracket the root.
    var lo = v0 * (1 - maxChangeFraction);
    var hi = (v0 * (1 + maxChangeFraction))
        .clamp(v0, ProductionLimits.maxMuzzleVelocityMps)
        .toDouble();
    if (predict(lo) < observedCorrectionMrad ||
        predict(hi) > observedCorrectionMrad) {
      throw const TruingFailure(TruingRejection.outOfBounds);
    }
    while (hi - lo > _toleranceMps) {
      final mid = (lo + hi) / 2;
      if (predict(mid) > observedCorrectionMrad) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final trued = double.parse(((lo + hi) / 2).toStringAsFixed(1));
    return TruingResult(
      baseMps: v0,
      truedMps: trued,
      rangeM: rangeM,
      predictedMrad: predicted,
      observedMrad: observedCorrectionMrad,
      truedPredictedMrad: predict(trued),
    );
  }
}

class BcTruingResult {
  /// The BC the ammunition had, and the trued one (rounded to 0.0001).
  final double baseBc, truedBc;
  final double rangeM, predictedMrad, observedMrad, truedPredictedMrad;

  const BcTruingResult({
    required this.baseBc,
    required this.truedBc,
    required this.rangeM,
    required this.predictedMrad,
    required this.observedMrad,
    required this.truedPredictedMrad,
  });

  double get changePercent => (truedBc - baseBc) / baseBc * 100;
  double get residualMrad => observedMrad - truedPredictedMrad;
}

/// Second truing step (owner, 2026-10-09): after the velocity was trued at a
/// medium range, the elevation observed at a FAR range trues the ballistic
/// coefficient — the far-range drop is governed by drag. Applied Ballistics
/// does this with a drop scale factor; adjusting the BC keeps one physical
/// model for every range (as Strelok's BC calibration does).
///
/// Only the BC is adjusted (velocity stays). A mismatch needing more than
/// [maxChangeFraction] is refused: it points at a wrong velocity, zero,
/// sight height or measurement.
abstract final class BallisticCoefficientTruing {
  static const double maxChangeFraction = 0.30;
  static const double minSensitivityMrad = 0.02;

  static BcTruingResult solve({
    required BallisticInput base,
    required double rangeM,
    required double observedCorrectionMrad,
    BallisticEngine engine = const BallisticEngine(),
  }) {
    final bc0 = base.ballisticCoefficient;
    if (bc0 == null || base.ballisticModel == null) {
      throw ArgumentError('BC truing needs a G1/G7 ballistic coefficient');
    }
    if (!rangeM.isFinite ||
        rangeM <= 0 ||
        rangeM > ProductionLimits.maxRangeM) {
      throw ArgumentError.value(rangeM, 'rangeM', 'out of range');
    }
    if (!observedCorrectionMrad.isFinite) {
      throw ArgumentError.value(
        observedCorrectionMrad,
        'observedCorrectionMrad',
        'must be finite',
      );
    }
    if (rangeM <= base.zeroRangeM) {
      throw const TruingFailure(TruingRejection.rangeTooShort);
    }
    final at = base.withRanges([rangeM]);

    // Correction at BC b; +infinity when the bullet cannot get there, which
    // keeps the function monotone (more drag = more drop).
    double predict(double b) {
      try {
        return engine
            .solve(at.withBallisticCoefficient(b))
            .single
            .correctionMrad;
      } on StateError {
        return double.infinity;
      } on ArgumentError {
        return double.infinity;
      }
    }

    final predicted = predict(bc0);
    if (!predicted.isFinite) {
      throw const TruingFailure(TruingRejection.unreachable);
    }
    if ((predict(bc0 * 1.01) - predicted).abs() < minSensitivityMrad) {
      throw const TruingFailure(TruingRejection.notSensitive);
    }
    // Correction falls as BC rises. Bracket the root.
    var lo = bc0 * (1 - maxChangeFraction);
    var hi = bc0 * (1 + maxChangeFraction);
    if (predict(lo) < observedCorrectionMrad ||
        predict(hi) > observedCorrectionMrad) {
      throw const TruingFailure(TruingRejection.bcOutOfBounds);
    }
    while (hi - lo > bc0 * 1e-5) {
      final mid = (lo + hi) / 2;
      if (predict(mid) > observedCorrectionMrad) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    // 4 decimals: a pellet BC of 0.035 needs finer steps than 0.001 (3 %).
    final trued = double.parse(((lo + hi) / 2).toStringAsFixed(4));
    return BcTruingResult(
      baseBc: bc0,
      truedBc: trued,
      rangeM: rangeM,
      predictedMrad: predicted,
      observedMrad: observedCorrectionMrad,
      truedPredictedMrad: predict(trued),
    );
  }
}
