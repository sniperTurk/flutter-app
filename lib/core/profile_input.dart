import '../models/domain.dart';
import 'powder_temperature.dart';
import 'production_limits.dart';

/// Validates profile values before they are persisted.
/// This prevents malformed UI input from being silently replaced with defaults.
class ProfileInput {
  final String name;
  final double muzzleVelocityMps;
  final double zeroRangeM;
  final double sightHeightMm;
  final double? pressureBar;

  /// Built-in slope of the scope mount, in MOA (0 = normal mount).
  final double mountCantMoa;

  /// Barut sıcaklığı (firearms only): both set or both null.
  final double? powderTempCoefPercentPer15C;
  final double? powderTempReferenceC;

  const ProfileInput._({
    required this.name,
    required this.muzzleVelocityMps,
    required this.zeroRangeM,
    required this.sightHeightMm,
    required this.pressureBar,
    this.mountCantMoa = 0,
    this.powderTempCoefPercentPer15C,
    this.powderTempReferenceC,
  });

  factory ProfileInput.validate({
    required String name,
    required String muzzleVelocityText,
    required String zeroRangeText,
    required String sightHeightText,
    required WeaponPlatform platform,
    String? pressureText,
    double mountCantMoa = 0,
    String? powderCoefText,
    String? powderTempText,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const FormatException('Profil adı boş bırakılamaz.');
    }
    if (normalizedName.length > ProductionLimits.maxProfileNameLength) {
      throw const FormatException('Profil adı 80 karakterden uzun olamaz.');
    }
    final velocity = _boundedPositive(
      muzzleVelocityText,
      'Namlu çıkış hızı',
      ProductionLimits.maxMuzzleVelocityMps,
    );
    final zero = _boundedPositive(
      zeroRangeText,
      'Sıfırlama mesafesi',
      ProductionLimits.maxRangeM,
    );
    final sight = _positive(sightHeightText, 'Sight height');
    if (sight >= ProductionLimits.maxSightHeightMm) {
      throw const FormatException('Sight height 300 mm’den küçük olmalıdır.');
    }
    if (!ProductionLimits.mountCantOptionsMoa.contains(mountCantMoa)) {
      throw const FormatException('Dürbün ayağını listeden seçin.');
    }
    // Regülatör basıncı is optional (owner, 2026-10-09): no calculation uses
    // it. A value that is given (older profiles) must still be valid, and a
    // firearm never has one.
    double? pressure;
    final pressureTyped = pressureText?.trim() ?? '';
    if (platform == WeaponPlatform.pcp && pressureTyped.isNotEmpty) {
      pressure = _boundedPositive(
        pressureTyped,
        'Atış basıncı',
        ProductionLimits.maxPcpPressureBar,
      );
    }
    // Barut sıcaklığı is optional and firearm-only (a PCP never has one).
    // Given, it needs both values inside the bands the calculation accepts.
    double? coef, refC;
    final coefTyped = powderCoefText?.trim() ?? '';
    final tempTyped = powderTempText?.trim() ?? '';
    if (platform == WeaponPlatform.firearm &&
        (coefTyped.isNotEmpty || tempTyped.isNotEmpty)) {
      if (coefTyped.isEmpty || tempTyped.isEmpty) {
        throw const FormatException(
          'Barut sıcaklık katsayısı ile hız ölçüm sıcaklığı birlikte girilmeli.',
        );
      }
      coef = double.tryParse(coefTyped.replaceAll(',', '.'));
      if (coef == null ||
          !coef.isFinite ||
          coef.abs() > PowderTemperature.maxCoef) {
        throw const FormatException(
          'Barut sıcaklık katsayısı -10 ile 10 arasında olmalıdır.',
        );
      }
      refC = double.tryParse(tempTyped.replaceAll(',', '.'));
      if (refC == null ||
          !refC.isFinite ||
          refC < PowderTemperature.minTempC ||
          refC > PowderTemperature.maxTempC) {
        throw const FormatException(
          'Hız ölçüm sıcaklığı -50 ile 60 °C arasında olmalıdır.',
        );
      }
    }
    return ProfileInput._(
      name: normalizedName,
      muzzleVelocityMps: velocity,
      zeroRangeM: zero,
      sightHeightMm: sight,
      pressureBar: pressure,
      mountCantMoa: mountCantMoa,
      powderTempCoefPercentPer15C: coef,
      powderTempReferenceC: refC,
    );
  }

  static double _boundedPositive(String text, String label, double max) {
    final value = _positive(text, label);
    if (value > max) {
      throw FormatException(
        '$label en fazla ${max.toStringAsFixed(0)} olabilir.',
      );
    }
    return value;
  }

  static double _positive(String text, String label) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value <= 0) {
      throw FormatException(
        '$label için sıfırdan büyük geçerli bir sayı girin.',
      );
    }
    return value;
  }
}
