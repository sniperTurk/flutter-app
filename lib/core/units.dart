import 'dart:math' as math;
class Units {
  static double moaToMrad(double moa) => moa * math.pi / 10800 * 1000;
  static double mradToMoa(double mrad) => mrad * 10800 / (math.pi * 1000);
  static double mpsToFps(double v) => v * 3.280839895;
  static double fpsToMps(double v) => v / 3.280839895;
  static double grainToKg(double grain) => grain * 0.00006479891;
  static double barToPsi(double bar) => bar * 14.5037738;
  static double jouleToFootPound(double j) => j * 0.737562149;
}
