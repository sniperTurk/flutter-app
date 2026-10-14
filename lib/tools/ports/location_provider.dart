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
  ///
  /// [precise]: a fix good enough for GPS altitude, for this request only
  /// (the Hava Durumu altitude warm-up, owner 2026-10-14); other callers
  /// keep the coarse fix. [askPermission] false never shows the permission
  /// prompt: without permission it returns [LocationDenied] at once.
  Future<LocationResult> current({
    bool precise = false,
    bool askPermission = true,
  });

  /// Opens the system Settings page of the app (for permanent denials).
  Future<bool> openSettings();
}
