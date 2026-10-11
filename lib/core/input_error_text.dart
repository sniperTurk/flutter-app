/// Turkish text for an [ArgumentError] raised by the solver's input checks.
///
/// The core validators keep their English developer messages (parameter
/// names, bounds); the user only ever sees the Turkish field name from
/// here (owner, 2026-10-11: no English messages in the app).
abstract final class InputErrorText {
  static const _labels = <String, String>{
    'muzzleVelocityMps': 'Namlu çıkış hızı',
    'zeroMuzzleVelocityMps': 'Sıfırlamadaki hız',
    'velocityMps': 'Hız',
    'grain': 'Ağırlık',
    'sightHeightMm': 'Sight height',
    'zeroRangeM': 'Sıfırlama mesafesi',
    'rangeM': 'Mesafe',
    'rangesM': 'Mesafe',
    'ballisticCoefficient': 'BC',
    'bcBands': 'Hıza göre BC',
    'temperatureC': 'Sıcaklık',
    'pressureHpa': 'Basınç',
    'humidityPercent': 'Nem',
    'altitudeM': 'İrtifa',
    'windMps': 'Rüzgâr hızı',
    'windZones': 'Yol boyu rüzgâr',
    'windDirectionDeg': 'Rüzgâr yönü',
    'gravityMps2': 'Yerçekimi',
    'latitudeDeg': 'Enlem',
    'azimuthDeg': 'Atış yönü',
    'inclineDeg': 'Tüfek eğimi',
    'cantDeg': 'Dürbün eğimi',
  };

  /// "Geçersiz değer: Sıcaklık. Kontrol edip tekrar deneyin." for a known
  /// field, else [fallback].
  static String of(ArgumentError e, {required String fallback}) {
    final label = labelOf(e.name);
    return label == null
        ? fallback
        : 'Geçersiz değer: $label. Kontrol edip tekrar deneyin.';
  }

  /// The Turkish field name for a validator parameter name such as
  /// `zeroEnvironment.temperatureC` or `bcBands.bc`; null when unknown.
  static String? labelOf(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final part in name.split('.')) {
      final l = _labels[part];
      if (l != null) return l;
    }
    return null;
  }
}
