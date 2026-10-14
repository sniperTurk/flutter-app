/// Ground elevation of a point from a map service (Hava Durumu → İrtifa →
/// "Haritadan", owner 2026-10-14). Never persisted by the provider.
sealed class ElevationResult {
  const ElevationResult();
}

/// Ground height above mean sea level, metres.
class ElevationRead extends ElevationResult {
  final double meters;
  const ElevationRead(this.meters);
}

enum ElevationFailure {
  /// No map key in this build: nothing was sent.
  noKey,

  /// No internet connection.
  offline,

  /// The service answered with an error or an unreadable value.
  error,
}

class ElevationUnavailable extends ElevationResult {
  final ElevationFailure reason;
  const ElevationUnavailable(this.reason);
}

/// Port for the map elevation service. UI depends on this only.
abstract interface class ElevationProvider {
  Future<ElevationResult> elevation(double latitude, double longitude);
}
