/// One weather observation as delivered by a forecast/analysis service.
///
/// This is MODEL data for a grid cell, not a measurement at the user's
/// position, and the wind is not measured by GPS. The UI must say so.
class WeatherObservation {
  final double temperatureC;
  final double humidityPercent;

  /// Pressure in hPa and what it refers to. Services usually deliver
  /// sea-level-reduced pressure, which is NOT station pressure.
  final double pressureHpa;
  final PressureKind pressureKind;
  final double windSpeedMps;

  /// Meteorological convention: the direction the wind blows FROM, degrees
  /// clockwise from north, [0, 360).
  final double windFromDeg;

  /// Provider symbol/condition code (e.g. `partlycloudy_day`), if any.
  final String? conditionCode;

  /// Validity time of the values, as stated by the provider (UTC).
  final DateTime validAt;

  /// When this app downloaded the data (UTC).
  final DateTime fetchedAt;

  /// Human readable source name for attribution.
  final String sourceName;

  const WeatherObservation({
    required this.temperatureC,
    required this.humidityPercent,
    required this.pressureHpa,
    required this.pressureKind,
    required this.windSpeedMps,
    required this.windFromDeg,
    required this.validAt,
    required this.fetchedAt,
    required this.sourceName,
    this.conditionCode,
  });
}

enum PressureKind { seaLevel, station }

enum WeatherFailureKind {
  /// No network / DNS / connection failure.
  offline,
  timeout,
  rateLimited,
  server,
  invalidResponse,

  /// The service is not configured (for example a missing contact in the
  /// required User-Agent). The app refuses to call it rather than violate
  /// the provider's terms.
  notConfigured,
}

class WeatherFailure implements Exception {
  final WeatherFailureKind kind;
  final String message;
  const WeatherFailure(this.kind, this.message);
  @override
  String toString() => 'WeatherFailure($kind): $message';
}

/// Port for any weather service. The UI never talks to a concrete API.
abstract interface class WeatherProvider {
  String get sourceName;

  /// Throws [WeatherFailure]. Coordinates are only used for this request.
  Future<WeatherObservation> fetch(double latitude, double longitude);
}
