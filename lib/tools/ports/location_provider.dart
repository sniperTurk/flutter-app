/// Result of a one-shot location request. Never persisted by the app.
sealed class LocationResult {
  const LocationResult();
}

class LocationFix extends LocationResult {
  final double latitude;
  final double longitude;

  /// GPS altitude above sea level in metres, when the device reports it with
  /// a usable vertical accuracy; null otherwise (never guessed).
  final double? altitudeM;
  const LocationFix(this.latitude, this.longitude, {this.altitudeM});
}

/// The user refused. [permanent] means iOS will not prompt again; the only
/// way forward is the system Settings app.
class LocationDenied extends LocationResult {
  final bool permanent;
  const LocationDenied({required this.permanent});
}

/// Location Services are switched off system-wide.
class LocationServiceOff extends LocationResult {
  const LocationServiceOff();
}

class LocationFailure extends LocationResult {
  final String message;
  const LocationFailure(this.message);
}

/// Port for the device location. UI and controllers depend on this only.
abstract interface class LocationProvider {
  /// Asks for permission when needed and returns one coarse fix.
  Future<LocationResult> current();

  /// Opens the system Settings page of the app (for permanent denials).
  Future<bool> openSettings();
}
