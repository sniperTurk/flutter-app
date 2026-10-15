import 'units.dart';

/// Hareketli hedef (owner, 2026-10-09): how far ahead of a crossing target
/// to aim. Moved from the Hedef screen (2026-10-15, same arithmetic).
abstract final class MovingTarget {
  /// Distance the target walks while the bullet flies, in metres:
  /// speed (m/s) · time of flight (s). 2 m/s for 0.5 s = 1 m.
  static double leadM(double speedMps, double timeOfFlightS) =>
      speedMps * timeOfFlightS;

  /// [leadM] as an angle at [rangeM], in mrad (atan(lead / range) · 1000).
  static double leadMrad(
    double speedMps,
    double timeOfFlightS,
    double rangeM,
  ) => Units.linearToMrad(leadM(speedMps, timeOfFlightS), rangeM);
}
