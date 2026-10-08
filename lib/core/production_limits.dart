/// Central production guardrails shared by profile persistence and ballistics.
///
/// These are application safety bounds, not claims about a specific rifle.
/// Keeping them in one place prevents a profile from being accepted by the UI
/// and later rejected only when DOPE is requested.
abstract final class ProductionLimits {
  static const double maxMuzzleVelocityMps = 1500;
  static const double maxRangeM = 3000;
  static const double maxSightHeightMm = 300; // exclusive
  static const double maxPcpPressureBar = 500;
  static const int maxProfileNameLength = 80;

  /// Dürbün ayağı choices in MOA (0 = normal mount). Picked from a list,
  /// never typed (owner, 2026-10-08), so a stored value is always one of
  /// these.
  static const List<double> mountCantOptionsMoa = [0, 15, 20, 30, 45, 60, 90];

  /// Shot incline and scope cant accept the full circle, like field apps
  /// (ChairGun measures e.g. −102°). The solver works in the rotated scope
  /// frame, so any angle is geometrically exact; a shot that cannot reach the
  /// range (e.g. straight up) is reported as unreachable, not invented.
  static const double maxInclineDeg = 180;

  static const double maxCantDeg = 180;
}
