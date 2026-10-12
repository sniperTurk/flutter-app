import 'dart:math' as math;

import 'powder_temperature.dart';
import 'unit_system.dart';

/// A velocity value the series cannot use; [line] is 1-based.
class VelocitySeriesFormatException implements Exception {
  final int line;
  final String message;
  const VelocitySeriesFormatException(this.line, this.message);

  @override
  String toString() => message;
}

/// One chronograph string (Kronograf, 2026-10-12), in shot order, m/s.
///
/// Statistics follow the NIST/SEMATECH e-Handbook of Statistical Methods
/// (https://www.itl.nist.gov/div898/handbook/): the sample standard
/// deviation with n − 1 (1.3.5.6) and an ordinary least-squares line for the
/// change along the string (4.1.4.1).
class VelocitySeries {
  /// Accepted velocities, m/s.
  static const double minMps = 50;
  static const double maxMps = 1500;

  final List<double> mps;
  const VelocitySeries(this.mps);

  int get n => mps.length;

  double get meanMps => n == 0 ? 0 : mps.reduce((a, b) => a + b) / n;

  /// Sample standard deviation (n − 1); null below three shots.
  double? get sdMps {
    if (n < 3) return null;
    final m = meanMps;
    var ss = 0.0;
    for (final v in mps) {
      ss += (v - m) * (v - m);
    }
    return math.sqrt(ss / (n - 1));
  }

  /// Extreme spread: fastest − slowest.
  double get esMps {
    if (n == 0) return 0;
    var lo = mps.first, hi = mps.first;
    for (final v in mps) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    return hi - lo;
  }

  /// Least-squares slope against the shot number (m/s per shot); null below
  /// two shots. On a PCP a negative slope is the string falling off.
  double? get slopeMpsPerShot {
    if (n < 2) return null;
    final xm = (n - 1) / 2;
    final ym = meanMps;
    var sxy = 0.0, sxx = 0.0;
    for (var i = 0; i < n; i++) {
      sxy += (i - xm) * (mps[i] - ym);
      sxx += (i - xm) * (i - xm);
    }
    return sxy / sxx;
  }

  /// Reads one value per line; a space or ";" also separates values and ","
  /// is the decimal mark ("812,4"). Empty lines are skipped. [fps]: the
  /// values are feet per second and are converted to m/s.
  static VelocitySeries parse(String text, {required bool fps}) {
    final out = <double>[];
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      for (final token in lines[i].split(RegExp(r'[\s;]+'))) {
        if (token.isEmpty) continue;
        final v = double.tryParse(token.replaceAll(',', '.'));
        if (v == null || !v.isFinite) {
          throw VelocitySeriesFormatException(
            i + 1,
            '${i + 1}. satır okunamadı: "$token".',
          );
        }
        final m = fps ? UnitSystem.fpsToMps(v) : v;
        if (m < minMps || m > maxMps) {
          throw VelocitySeriesFormatException(
            i + 1,
            '${i + 1}. satırdaki hız geçerli aralığın dışında '
            '(${fps ? '165–4920 fps' : '50–1500 m/s'}).',
          );
        }
        out.add(m);
      }
    }
    return VelocitySeries(List.unmodifiable(out));
  }
}

/// Powder temperature sensitivity from series measured at different
/// temperatures: a straight line v = v0 + b·(T − T0) fitted by weighted
/// least squares (weights = shots per series, NIST/SEMATECH 4.1.4.3).
/// T0 is the weighted mean temperature, so v0 is the weighted mean velocity,
/// and k = b·15/v0·100 (% per 15 °C, the [PowderTemperature] model).
///
/// Null (nothing is guessed) with fewer than two series, a temperature span
/// below [minSpanC] or a k outside ±[PowderTemperature.maxCoef].
({double coefPercentPer15C, double referenceC, double v0Mps})?
fitPowderCoefficient(List<({double tempC, double meanMps, int n})> sessions) {
  const minSpanC = 10.0;
  final usable = [
    for (final s in sessions)
      if (s.n > 0 && s.tempC.isFinite && s.meanMps.isFinite) s,
  ];
  if (usable.length < 2) return null;
  var lo = usable.first.tempC, hi = usable.first.tempC;
  var w = 0.0, wt = 0.0, wv = 0.0;
  for (final s in usable) {
    if (s.tempC < lo) lo = s.tempC;
    if (s.tempC > hi) hi = s.tempC;
    w += s.n;
    wt += s.n * s.tempC;
    wv += s.n * s.meanMps;
  }
  if (hi - lo < minSpanC) return null;
  final t0 = wt / w, v0 = wv / w;
  var sxy = 0.0, sxx = 0.0;
  for (final s in usable) {
    sxy += s.n * (s.tempC - t0) * (s.meanMps - v0);
    sxx += s.n * (s.tempC - t0) * (s.tempC - t0);
  }
  final k = sxy / sxx * 15 / v0 * 100;
  if (!k.isFinite || k.abs() > PowderTemperature.maxCoef) return null;
  if (t0 < PowderTemperature.minTempC || t0 > PowderTemperature.maxTempC) {
    return null;
  }
  return (coefPercentPer15C: k, referenceC: t0, v0Mps: v0);
}
