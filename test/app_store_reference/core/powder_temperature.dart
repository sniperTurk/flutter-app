/// Powder temperature sensitivity (firearms): the profile velocity was
/// measured at a reference powder temperature; today's velocity is
///   v = v0 · (1 + k/100 · (T − T0) / 15)
/// with k the change in % per 15 °C (Strelok convention).
///
/// Shared by Atış and Hız Doğrulama so both read the profile velocity the
/// same way (2026-10-09: truing used to ignore it and Atış then scaled the
/// trued velocity a second time).
abstract final class PowderTemperature {
  /// Velocity factor today / reference; 1 when the data is missing or out of
  /// the accepted bands (|k| ≤ 10 %/15 °C, −50..60 °C).
  static double factor({
    required double? coefPercentPer15C,
    required double? referenceTempC,
    required double todayTempC,
  }) {
    final k = coefPercentPer15C, t0 = referenceTempC;
    if (k == null || t0 == null || !k.isFinite || !t0.isFinite) return 1;
    if (!todayTempC.isFinite) return 1;
    if (k.abs() > 10 || t0 < -50 || t0 > 60) return 1;
    final f = 1 + k / 100 * (todayTempC - t0) / 15;
    return f > 0 ? f : 1;
  }
}
