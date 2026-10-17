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

  /// PCP regülatör basıncı (bar); null = unregulated / firearm.
  final double? pressureBar;

  /// PCP tüp basıncı (bar); PCP only. Owner 2026-10-16: kept for future
  /// regulator use; not in the formula.
  final double? tubePressureBar;

  /// PCP En düşük / En yüksek namlu çıkış hızı (m/s), optional, each on
  /// its own; PCP only (owner, 2026-10-16). Saved only: the calculations
  /// use the Tüfek card's Namlu çıkış hızı [muzzleVelocityMps] (owner,
  /// 2026-10-17).
  final double? pcpMinVelocityMps, pcpMaxVelocityMps;

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
    this.tubePressureBar,
    this.pcpMinVelocityMps,
    this.pcpMaxVelocityMps,
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
    String? tubePressureText,
    String? pcpMinVelocityText,
    String? pcpMaxVelocityText,
    double mountCantMoa = 0,
    String? powderCoefText,
    String? powderTempText,
  }) {
    // PCP (owner, 2026-10-16): En düşük and En yüksek namlu çıkış hızı
    // (m/s) are optional, each on its own (owner, 2026-10-17); both given,
    // lowest first. Saved only: the Tüfek card's [muzzleVelocityText] is
    // the velocity every calculation uses.
    double? pcpMin, pcpMax;
    if (platform == WeaponPlatform.pcp) {
      final minTyped = pcpMinVelocityText?.trim() ?? '';
      final maxTyped = pcpMaxVelocityText?.trim() ?? '';
      if (minTyped.isNotEmpty) {
        pcpMin = _boundedPositive(
          minTyped,
          'En düşük namlu çıkış hızı',
          ProductionLimits.maxMuzzleVelocityMps,
        );
      }
      if (maxTyped.isNotEmpty) {
        pcpMax = _boundedPositive(
          maxTyped,
          'En yüksek namlu çıkış hızı',
          ProductionLimits.maxMuzzleVelocityMps,
        );
      }
      if (pcpMin != null && pcpMax != null && pcpMin > pcpMax) {
        throw const FormatException(
          'En düşük namlu çıkış hızı en yüksek hızdan büyük olamaz.',
        );
      }
    }
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
    // PCP tüp ve regülatör basıncı (owner, 2026-10-12), all optional: an
    // empty regülatör basıncı means an unregulated rifle; a firearm never
    // has any of them. Owner 2026-10-16: kept for future regulator use; not
    // in the formula.
    double? pressure, tube;
    if (platform == WeaponPlatform.pcp) {
      final pressureTyped = pressureText?.trim() ?? '';
      if (pressureTyped.isNotEmpty) {
        pressure = _boundedPositive(
          pressureTyped,
          'Regülatör basıncı',
          ProductionLimits.maxPcpPressureBar,
        );
      }
      final tubeTyped = tubePressureText?.trim() ?? '';
      if (tubeTyped.isNotEmpty) {
        tube = _boundedPositive(
          tubeTyped,
          'Tüp basıncı',
          ProductionLimits.maxPcpPressureBar,
        );
      }
      if (pressure != null && tube != null && pressure >= tube) {
        throw const FormatException(
          'Regülatör basıncı tüp basıncından küçük olmalıdır.',
        );
      }
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
      tubePressureBar: tube,
      pcpMinVelocityMps: pcpMin,
      pcpMaxVelocityMps: pcpMax,
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
