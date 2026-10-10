import 'dart:math' as math;

class Units {
  static double moaToMrad(double moa) => moa * math.pi / 10800 * 1000;
  static double mradToMoa(double mrad) => mrad * 10800 / (math.pi * 1000);
  static double grainToKg(double grain) => grain * 0.00006479891;
}
