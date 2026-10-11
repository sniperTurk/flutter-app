import 'package:flutter/foundation.dart';

/// Barut sıcaklık katsayısı of factory cartridges, only as the maker
/// publishes it (owner rule: official site, manual or data sheet; no
/// forums, dealers or other apps; unknown = no record).
///
/// Audit of the data/powder-temp branch (PR #73, 2026-10-11): every record
/// there carries a maker URL, but no maker page, data sheet or manual read
/// gives a number (only wording such as "temperature insensitive"); every
/// coefficient is null. So this list is empty and the shooter types the
/// value (Profil > Mühimmat). A record added here fills the boxes when its
/// cartridge is picked from the Fabrika fişeği list.
class FactoryPowderTemp {
  /// [FactoryAmmo.brand] and [FactoryAmmo.name] exactly as listed.
  final String brand, name;

  /// Velocity change in % per 15 °C, and the temperature (°C) at which the
  /// maker's listed velocity was measured.
  final double coefPercentPer15C, referenceTempC;
  final String sourceUrl;

  const FactoryPowderTemp(
    this.brand,
    this.name,
    this.coefPercentPer15C,
    this.referenceTempC,
    this.sourceUrl,
  );
}

abstract final class FactoryPowderTempLibrary {
  static const all = <FactoryPowderTemp>[];

  /// What [lookup] reads; tests swap in their own records.
  @visibleForTesting
  static List<FactoryPowderTemp> records = all;

  /// The maker's figure for this factory cartridge, or null.
  static FactoryPowderTemp? lookup(String brand, String name) {
    for (final r in records) {
      if (r.brand == brand && r.name == name) return r;
    }
    return null;
  }
}
