import 'dart:math' as math;

import 'unit_system.dart';

class Units {
  static double moaToMrad(double moa) => moa * math.pi / 10800 * 1000;
  static double mradToMoa(double mrad) => mrad * 10800 / (math.pi * 1000);
  static double grainToKg(double grain) => grain * 0.00006479891;

  /// Angle in mrad that a length [sizeM] subtends at [rangeM]:
  /// atan(size / range) · 1000. 1 cm at 100 m = 0.1 mrad. No range check:
  /// a zero range gives ±π/2·1000 (or NaN for 0/0), as the callers had it.
  /// Moved from Hedef / Doğrulama (2026-10-15, behaviour unchanged).
  static double linearToMrad(double sizeM, double rangeM) =>
      math.atan(sizeM / rangeM) * 1000;

  /// Length in metres that an angle [mrad] subtends at [rangeM]:
  /// tan(mrad / 1000) · range. Inverse of [linearToMrad].
  static double mradToLinear(double mrad, double rangeM) =>
      math.tan(mrad / 1000) * rangeM;

  /// A small length typed in cm ([metric]) or inches, in metres:
  /// cm / 100, or in → mm / 1000 (the arithmetic the screens used).
  static double cmOrInchToMeters(double value, {required bool metric}) =>
      metric ? value / 100 : UnitSystem.inchesToMillimeters(value) / 1000;

  /// Inches to metres with the exact factor 0.0254 (value · 0.0254).
  static double inchesToMeters(double value) => value * 0.0254;

  /// Metres to inches for display, with the factor the screens printed
  /// with (39.3700787, i.e. 1 / 0.0254 rounded to 7 decimals). Kept as it
  /// was so no shown inch value changes in its last digit.
  static double metersToInchesDisplay(double meters) => meters * 39.3700787;
}
