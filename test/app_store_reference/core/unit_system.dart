class UnitSystem {
  const UnitSystem._();

  static const metersPerYard = 0.9144;
  static const metersPerFoot = 0.3048;
  static const metersPerSecondPerFps = 0.3048;
  static const millimetersPerInch = 25.4;
  static const hpaPerInHg = 33.8638866667;
  static const metersPerSecondPerMph = 0.44704;
  static const joulesPerFootPound = 1.3558179483314004;
  static const metersPerSecondPerKmh = 1 / 3.6;
  static const metersPerSecondPerKnot = 0.514444444444444;

  static double yardsToMeters(double value) => value * metersPerYard;
  static double metersToYards(double value) => value / metersPerYard;
  static double feetToMeters(double value) => value * metersPerFoot;
  static double metersToFeet(double value) => value / metersPerFoot;
  static double fpsToMps(double value) => value * metersPerSecondPerFps;
  static double mpsToFps(double value) => value / metersPerSecondPerFps;
  static double inchesToMillimeters(double value) => value * millimetersPerInch;
  static double millimetersToInches(double value) => value / millimetersPerInch;
  static double inHgToHpa(double value) => value * hpaPerInHg;
  static double hpaToInHg(double value) => value / hpaPerInHg;
  static double mphToMps(double value) => value * metersPerSecondPerMph;
  static double mpsToMph(double value) => value / metersPerSecondPerMph;
  static double fahrenheitToCelsius(double value) => (value - 32) * 5 / 9;
  static double celsiusToFahrenheit(double value) => value * 9 / 5 + 32;
  static double joulesToFootPounds(double value) => value / joulesPerFootPound;
  static double mpsToKmh(double value) => value / metersPerSecondPerKmh;
}
