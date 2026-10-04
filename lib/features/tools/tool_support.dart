import '../../core/profile_input.dart';
import '../../core/unit_system.dart';
import '../../data/catalog_repository.dart';
import '../../models/domain.dart';

/// Updates written by the tools go through the SAME validation as the
/// profile editor ([ProfileInput.validate]). Saving a value the decoder
/// would later reject makes the stored collection unreadable.
abstract final class ToolProfileUpdate {
  /// Returns [base] with the new muzzle velocity and/or sight height.
  /// Throws [FormatException] with a user-facing message.
  static RifleProfile apply(
    RifleProfile base, {
    double? muzzleVelocityMps,
    double? sightHeightMm,
    double? pressureBar,
  }) {
    Rifle? rifle;
    for (final r in CatalogRepository.rifles) {
      if (r.id == base.rifleId) rifle = r;
    }
    final platform =
        rifle?.platform ??
        (base.pressureBar != null
            ? WeaponPlatform.pcp
            : WeaponPlatform.firearm);
    final input = ProfileInput.validate(
      name: base.name,
      muzzleVelocityText: (muzzleVelocityMps ?? base.muzzleVelocityMps)
          .toString(),
      zeroRangeText: base.zeroRangeM.toString(),
      sightHeightText: (sightHeightMm ?? base.sightHeightMm).toString(),
      platform: platform,
      pressureText: (pressureBar ?? base.pressureBar)?.toString(),
    );
    return RifleProfile(
      id: base.id,
      name: input.name,
      rifleId: base.rifleId,
      ammunitionId: base.ammunitionId,
      scopeId: base.scopeId,
      muzzleVelocityMps: input.muzzleVelocityMps,
      zeroRangeM: input.zeroRangeM,
      sightHeightMm: input.sightHeightMm,
      pressureBar: input.pressureBar,
      angularUnit: base.angularUnit,
    );
  }
}

/// Display helpers shared by the tool screens (pure, unit-aware).
abstract final class ToolFormat {
  static String two(int v) => v.toString().padLeft(2, '0');

  /// "03.10.2026 18:30" in the device's local time.
  static String dateTime(DateTime t) {
    final l = t.toLocal();
    return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  /// Decimal text with the Turkish comma ("270,4"). The tool pages follow the
  /// Menzil design, which prints measured values with a comma. Inputs accept
  /// both "," and ".".
  static String dec(double v, int digits) =>
      v.toStringAsFixed(digits).replaceAll('.', ',');

  static String windSpeed(double mps, {required bool metric}) =>
      metric ? '${dec(mps, 1)} m/s' : '${dec(UnitSystem.mpsToMph(mps), 1)} mph';

  static String windSpeedAlt(double mps, {required bool metric}) => metric
      ? '${dec(UnitSystem.mpsToKmh(mps), 1)} km/sa'
      : '${dec(mps, 1)} m/s';

  static String temperature(double c, {required bool metric}) => metric
      ? '${dec(c, 1)} °C'
      : '${dec(UnitSystem.celsiusToFahrenheit(c), 1)} °F';

  static String pressure(double hpa, {required bool metric}) => metric
      ? '${dec(hpa, 1)} hPa'
      : '${dec(UnitSystem.hpaToInHg(hpa), 2)} inHg';

  static String velocity(double mps, {required bool metric}) =>
      metric ? '${dec(mps, 1)} m/s' : '${dec(UnitSystem.mpsToFps(mps), 0)} fps';

  /// Short Turkish condition text from a provider symbol code
  /// (e.g. `partlycloudy_day` -> "Parçalı bulutlu"). Unknown codes return
  /// null so the UI shows nothing instead of a guess.
  static String? condition(String? code) {
    if (code == null) return null;
    final base = code.replaceAll(RegExp(r'_(day|night|polartwilight)$'), '');
    const known = <String, String>{
      'clearsky': 'Açık',
      'fair': 'Az bulutlu',
      'partlycloudy': 'Parçalı bulutlu',
      'cloudy': 'Bulutlu',
      'fog': 'Sisli',
      'lightrain': 'Hafif yağmur',
      'rain': 'Yağmur',
      'heavyrain': 'Şiddetli yağmur',
      'lightrainshowers': 'Hafif sağanak',
      'rainshowers': 'Sağanak',
      'heavyrainshowers': 'Şiddetli sağanak',
      'lightsleet': 'Hafif karla karışık yağmur',
      'sleet': 'Karla karışık yağmur',
      'heavysleet': 'Yoğun karla karışık yağmur',
      'lightsnow': 'Hafif kar',
      'snow': 'Kar',
      'heavysnow': 'Yoğun kar',
      'lightsnowshowers': 'Hafif kar sağanağı',
      'snowshowers': 'Kar sağanağı',
      'heavysnowshowers': 'Yoğun kar sağanağı',
      'rainandthunder': 'Gök gürültülü yağmur',
      'lightrainandthunder': 'Gök gürültülü hafif yağmur',
      'heavyrainandthunder': 'Gök gürültülü şiddetli yağmur',
      'snowandthunder': 'Gök gürültülü kar',
    };
    return known[base];
  }
}
