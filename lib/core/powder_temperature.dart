import '../models/domain.dart';

/// Powder temperature sensitivity (firearms): the profile velocity was
/// measured at a reference air temperature; today's velocity is
///   v = v0 · (1 + k/100 · (T − T0) / 15)
/// with k the change in % per 15 °C.
///
/// Shared by Atış and Hız Doğrulama so both read the profile velocity the
/// same way (2026-10-09: truing used to ignore it and Atış then scaled the
/// trued velocity a second time). The values live on the profile
/// (Profil > Mühimmat, 2026-10-11); older installs kept them on Pro Ayarlar
/// and those are still read when the profile has none ([forProfile]).
abstract final class PowderTemperature {
  /// Accepted bands: |k| ≤ [maxCoef] %/15 °C, reference [minTempC]..[maxTempC].
  static const double maxCoef = 10;
  static const double minTempC = -50;
  static const double maxTempC = 60;

  /// Velocity factor today / reference; 1 when the data is missing or out of
  /// the accepted bands.
  static double factor({
    required double? coefPercentPer15C,
    required double? referenceTempC,
    required double todayTempC,
  }) {
    final k = coefPercentPer15C, t0 = referenceTempC;
    if (k == null || t0 == null || !k.isFinite || !t0.isFinite) return 1;
    if (!todayTempC.isFinite) return 1;
    if (k.abs() > maxCoef || t0 < minTempC || t0 > maxTempC) return 1;
    final f = 1 + k / 100 * (todayTempC - t0) / 15;
    return f > 0 ? f : 1;
  }

  /// The coefficient and reference temperature that apply to [profile]:
  /// its own values when both are set, else the legacy Pro Ayarlar text
  /// (as typed, "," or "."). Null on PCP or for a missing profile.
  static ({double? coef, double? referenceC, bool fromProfile}) forProfile({
    required RifleProfile? profile,
    required WeaponPlatform? platform,
    String legacyCoefText = '',
    String legacyTempText = '',
  }) {
    if (profile == null || platform != WeaponPlatform.firearm) {
      return (coef: null, referenceC: null, fromProfile: false);
    }
    final k = profile.powderTempCoefPercentPer15C;
    final t = profile.powderTempReferenceC;
    if (k != null && t != null) {
      return (coef: k, referenceC: t, fromProfile: true);
    }
    double? p(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
    return (
      coef: p(legacyCoefText),
      referenceC: p(legacyTempText),
      fromProfile: false,
    );
  }
}
