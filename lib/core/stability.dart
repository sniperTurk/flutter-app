import 'dart:math' as math;

import 'unit_system.dart';
import 'units.dart';
import 'wind_clock.dart';

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
  /// and air (temperature, pressure) corrections (Miller, "A New Rule for
  /// Estimating Rifling Twist", Precision Shooting, March 2005).
  ///
  /// Subsonic (formula audit 2026-10-13): the velocity factor
  /// (v/2800)^(1/3) is only defined down to the speed of sound. Courtney &
  /// Miller, "A Stability Formula for Plastic-Tipped Bullets: Part 1",
  /// Precision Shooting, Jan 2012 (arXiv:1410.5340): "This correction
  /// factor for all velocities below the velocity of sound has the value
  /// at the velocity of sound." So a PCP slug at 300 m/s uses the factor of
  /// the local speed of sound (dry air, ideal gas, γ = 1.4) instead of its
  /// own velocity; before this the subsonic Sg came out ~4 % too low.
  /// Supersonic results are unchanged.
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
    final sound = speedOfSoundMps(temperatureC);
    final vFps = UnitSystem.mpsToFps(
      sound.isFinite && sound > velocityMps ? sound : velocityMps,
    );
    final tF = temperatureC * 9 / 5 + 32;
    final pInHg = pressureHpa * 0.0295299830714;
    return 30 *
        grain /
        (tCal * tCal * dIn * dIn * dIn * lCal * (1 + lCal * lCal)) *
        math.pow(vFps / 2800, 1 / 3) *
        ((tF + 460) / 519) *
        (29.92 / pInHg);
  }

  /// Speed of sound in dry air at [temperatureC] (ideal gas, γ = 1.4,
  /// R = 287.05 J/(kg·K); ICAO Doc 7488/3: 340.29 m/s at 15 °C). Only the
  /// Miller subsonic floor uses it; the trajectory uses
  /// `Atmosphere.speedOfSoundMps` (moist air).
  static double speedOfSoundMps(double temperatureC) =>
      math.sqrt(1.4 * 287.05 * (temperatureC + 273.15));

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

  /// Bullet length in calibres: (length mm / 25.4) / (calibre mm / 25.4),
  /// the l used by Miller and by the aerodynamic-jump fit. Moved from the
  /// Hedef screen (2026-10-15, same arithmetic).
  static double lengthCalibers(double lengthMm, double caliberMm) =>
      lengthMm / 25.4 / (caliberMm / 25.4);

  /// Spin drift in inches (Litz, Applied Ballistics for Long Range
  /// Shooting): 1.25 · (Sg + 1.2) · t^1.83, t = time of flight in seconds.
  static double spinDriftInches({
    required double sg,
    required double timeOfFlightS,
  }) => 1.25 * (sg + 1.2) * math.pow(timeOfFlightS, 1.83);

  /// Spin drift as a sideways angle at [rangeM] in mrad, + = to the right
  /// (right-hand twist drifts right, left-hand twist left).
  static double spinDriftMrad({
    required double sg,
    required double timeOfFlightS,
    required double rangeM,
    required bool rightHandTwist,
  }) {
    final driftIn = spinDriftInches(sg: sg, timeOfFlightS: timeOfFlightS);
    final m = Units.inchesToMeters(driftIn) * (rightHandTwist ? 1 : -1);
    return Units.linearToMrad(m, rangeM);
  }

  /// Aerodynamic jump per mph of crosswind, in MOA (Litz):
  /// 0.01 · Sg − 0.0024 · l + 0.032, l = bullet length in calibres.
  static double aeroJumpMoaPerMph({required double sg, required double lCal}) =>
      0.01 * sg - 0.0024 * lCal + 0.032;

  /// Aerodynamic jump in mrad, + = impact moves UP. [windMps] and
  /// [windDirectionDeg] use the solver's convention (90° = from the left,
  /// 270° = from the right). Right-hand twist: wind from the right lifts,
  /// from the left drops (mirrored for left-hand twist).
  static double aeroJumpMrad({
    required double sg,
    required double lCal,
    required double windMps,
    required double windDirectionDeg,
    required bool rightHandTwist,
  }) {
    final fromRightMph = WindClock.crosswindFromRight(
      UnitSystem.mpsToMph(windMps),
      windDirectionDeg,
    );
    final moa =
        aeroJumpMoaPerMph(sg: sg, lCal: lCal) *
        fromRightMph *
        (rightHandTwist ? 1 : -1);
    return Units.moaToMrad(moa);
  }
}
