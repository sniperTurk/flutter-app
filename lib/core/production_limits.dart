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
}
