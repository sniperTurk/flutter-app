import 'dart:math' as math;

import 'unit_system.dart';

/// Gyroscopic stability class of a bullet from its Miller Sg.
enum StabilityLevel { unstable, marginal, stable }

/// Kararlılık ve transonik uyarısı (Ö5, owner, 2026-10-11).
abstract final class Stability {
  /// Sg below this is unstable: the bullet may tumble.
  static const unstableBelow = 1.0;

  /// Sg below this (and >= [unstableBelow]) flies with extra yaw and drag.
  static const fullBelow = 1.5;

  /// Litz: below Sg 1.5 every 0.1 lowers the BC by about 3 %.
  static const bcLossPercentPerTenth = 3.0;

  /// Mach below this at the target is the transonic zone.
  static const transonicBelowMach = 1.2;

  /// Miller twist-rule stability factor at the muzzle, with the velocity
  /// and air (temperature, pressure) corrections. Same formula and numbers
  /// as the spin-drift path used before.
  static double millerSg({
    required double grain,
    required double caliberMm,
    required double twistIn,
    required double lengthMm,
    required double velocityMps,
    required double temperatureC,
    required double pressureHpa,
  }) {
    final dIn = caliberMm / 25.4;
    final tCal = twistIn / dIn, lCal = lengthMm / 25.4 / dIn;
    final vFps = UnitSystem.mpsToFps(velocityMps);
    final tF = temperatureC * 9 / 5 + 32;
    final pInHg = pressureHpa * 0.0295299830714;
    return 30 *
        grain /
        (tCal * tCal * dIn * dIn * dIn * lCal * (1 + lCal * lCal)) *
        math.pow(vFps / 2800, 1 / 3) *
        ((tF + 460) / 519) *
        (29.92 / pInHg);
  }

  static StabilityLevel classify(double sg) {
    if (sg < unstableBelow) return StabilityLevel.unstable;
    if (sg < fullBelow) return StabilityLevel.marginal;
    return StabilityLevel.stable;
  }

  /// Rough BC loss in percent for a marginal [sg]; 0 at or above 1.5.
  /// Shown only as a warning: the BC used by the solver is never lowered.
  static double bcLossPercent(double sg) {
    if (sg >= fullBelow) return 0;
    return (fullBelow - sg) / 0.1 * bcLossPercentPerTenth;
  }

  /// True when a supersonic load (muzzle above Mach 1) reaches the target
  /// below Mach 1.2. Subsonic loads never warn.
  static bool transonicAtTarget({
    required double muzzleMach,
    required double targetMach,
  }) => muzzleMach > 1.0 && targetMach < transonicBelowMach;
}
