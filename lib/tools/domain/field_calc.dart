import 'dart:math' as math;

import '../../core/atmosphere.dart';
import '../../core/drag_table.dart';
import '../../core/reference_drag_model.dart';
import '../../models/domain.dart';

/// Pure formulas for the Hesaplayıcılar tools. No I/O, no state.
abstract final class FieldCalc {
  /// One true MOA in radians (1/60 degree).
  static const radPerMoa = math.pi / 10800;

  /// One milliradian in radians.
  static const radPerMil = 0.001;

  // ---- Stadyametrik / angular size -------------------------------------

  /// Distance (m) to an object of [sizeM] that spans [angleRad].
  static double? distanceFromAngle(double sizeM, double angleRad) {
    if (!sizeM.isFinite || !angleRad.isFinite || sizeM <= 0 || angleRad <= 0) {
      return null;
    }
    return sizeM / math.tan(angleRad);
  }

  /// Size (m) that spans [angleRad] at [distanceM].
  static double? sizeFromAngle(double distanceM, double angleRad) {
    if (!distanceM.isFinite ||
        !angleRad.isFinite ||
        distanceM <= 0 ||
        angleRad <= 0) {
      return null;
    }
    return distanceM * math.tan(angleRad);
  }

  /// Angle (rad) subtended by [sizeM] at [distanceM].
  static double? angleFromSize(double sizeM, double distanceM) {
    if (!sizeM.isFinite ||
        !distanceM.isFinite ||
        sizeM <= 0 ||
        distanceM <= 0) {
      return null;
    }
    return math.atan(sizeM / distanceM);
  }

  // ---- Click verification ----------------------------------------------

  /// Real value of one click, in the same unit as the angle inputs.
  ///
  /// [movedM] is the measured point-of-impact shift at [distanceM] after
  /// [clicks] clicks. Returns the angle per click in radians.
  static double? realClickRad({
    required double distanceM,
    required double movedM,
    required int clicks,
  }) {
    if (!distanceM.isFinite ||
        !movedM.isFinite ||
        distanceM <= 0 ||
        movedM <= 0 ||
        clicks <= 0) {
      return null;
    }
    return math.atan(movedM / distanceM) / clicks;
  }

  // ---- Geodesy ----------------------------------------------------------

  static const earthRadiusM = 6371008.8;

  /// Great-circle distance in metres (haversine).
  static double haversineM(double lat1, double lon1, double lat2, double lon2) {
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dp = (lat2 - lat1) * math.pi / 180;
    final dl = (lon2 - lon1) * math.pi / 180;
    final a =
        math.sin(dp / 2) * math.sin(dp / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
    return 2 * earthRadiusM * math.asin(math.min(1.0, math.sqrt(a)));
  }

  /// Initial bearing in degrees from point 1 to point 2, 0..360.
  static double bearingDeg(double lat1, double lon1, double lat2, double lon2) {
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dl = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dl) * math.cos(p2);
    final x =
        math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static bool validLatLon(double lat, double lon) =>
      lat.isFinite &&
      lon.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lon >= -180 &&
      lon <= 180;

  // ---- Air laboratory ---------------------------------------------------

  /// Station pressure (hPa) from a sea-level pressure and altitude (ISA).
  static double stationPressureHpa(double seaLevelHpa, double altitudeM) =>
      seaLevelHpa * math.pow(1 - 2.25577e-5 * altitudeM, 5.25588);

  /// Dew point (°C), Magnus formula.
  static double dewPointC(double temperatureC, double humidityPercent) {
    const a = 17.62, b = 243.12;
    final rh = humidityPercent.clamp(0.01, 100.0);
    final g = math.log(rh / 100) + a * temperatureC / (b + temperatureC);
    return b * g / (a - g);
  }

  /// Density altitude (m) for an air density, ICAO standard atmosphere.
  static double densityAltitudeM(double densityKgM3) =>
      44330.77 * (1 - math.pow(densityKgM3 / 1.225, 0.234969));

  /// Air laboratory results for [env] (station pressure).
  static AirLab airLab(EnvironmentData env) {
    final rho = Atmosphere.densityKgM3(env);
    return AirLab(
      densityKgM3: rho,
      densityRatioPercent: rho / Atmosphere.standardDensityKgM3 * 100,
      densityAltitudeM: densityAltitudeM(rho),
      speedOfSoundMps: Atmosphere.speedOfSoundMps(env),
      vaporPressureHpa:
          Atmosphere.saturationVaporPressureHpa(env.temperatureC) *
          env.humidityPercent /
          100,
      dewPointC: dewPointC(env.temperatureC, env.humidityPercent),
    );
  }

  // ---- BC from two velocities -------------------------------------------

  /// Velocity (m/s) after flying [distanceM] from [v1Mps] with [bc] (lb/in²
  /// relative to [table]) in [env]. Fixed-step RK4 on dv/dx = -a(v)/v.
  static double? velocityAfter({
    required DragTable table,
    required double bc,
    required double v1Mps,
    required double distanceM,
    required EnvironmentData env,
    double stepM = 0.5,
  }) {
    final model = ReferenceDragModel(table);
    double f(double v) {
      if (v <= 1) return 0;
      return -model.decelerationMps2(
            speedMps: v,
            ballisticCoefficient: bc,
            environment: env,
          ) /
          v;
    }

    var v = v1Mps;
    var x = 0.0;
    while (x < distanceM) {
      final h = math.min(stepM, distanceM - x);
      final k1 = f(v);
      final k2 = f(v + h / 2 * k1);
      final k3 = f(v + h / 2 * k2);
      final k4 = f(v + h * k3);
      v += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4);
      x += h;
      if (v <= 1) return null;
    }
    return v;
  }

  /// Solves the BC that takes [v1Mps] to [v2Mps] over [distanceM], by
  /// bisection (retained speed grows monotonically with BC). Null when no
  /// BC in 0.005..3.0 fits.
  static double? ballisticCoefficientFromTwoVelocities({
    required DragTable table,
    required double v1Mps,
    required double v2Mps,
    required double distanceM,
    required EnvironmentData env,
  }) {
    if (!(v1Mps > 0 && v2Mps > 0 && v2Mps < v1Mps && distanceM > 0)) {
      return null;
    }
    var lo = 0.005, hi = 3.0;
    double? at(double bc) => velocityAfter(
      table: table,
      bc: bc,
      v1Mps: v1Mps,
      distanceM: distanceM,
      env: env,
    );
    final vHi = at(hi);
    if (vHi == null || vHi < v2Mps) return null; // would need BC > 3
    final vLo = at(lo);
    if (vLo != null && vLo > v2Mps) return null; // slower than BC 0.005
    for (var i = 0; i < 60; i++) {
      final mid = (lo + hi) / 2;
      final v = at(mid);
      if (v == null || v < v2Mps) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }
}

class AirLab {
  final double densityKgM3,
      densityRatioPercent,
      densityAltitudeM,
      speedOfSoundMps,
      vaporPressureHpa,
      dewPointC;
  const AirLab({
    required this.densityKgM3,
    required this.densityRatioPercent,
    required this.densityAltitudeM,
    required this.speedOfSoundMps,
    required this.vaporPressureHpa,
    required this.dewPointC,
  });
}

/// One unit of a converter: [factor] converts it to the category base unit.
class ConvUnit {
  final String label;
  final double factor;
  const ConvUnit(this.label, this.factor);
}

class ConvCategory {
  final String id;
  final String title;
  final List<ConvUnit> units;
  const ConvCategory(this.id, this.title, this.units);

  double convert(double value, ConvUnit from, ConvUnit to) =>
      value * from.factor / to.factor;
}

abstract final class Converters {
  static const angle = ConvCategory('angle', 'Açı birimleri', [
    ConvUnit('Derece (°)', math.pi / 180),
    ConvUnit('Radyan', 1),
    ConvUnit('MOA', FieldCalc.radPerMoa),
    ConvUnit('MIL (mrad)', FieldCalc.radPerMil),
    ConvUnit('NATO mil (6400)', 2 * math.pi / 6400),
    ConvUnit('SMOA (inç/100 yd)', 1 / 3600),
    ConvUnit('cm/100 m', 1e-4),
  ]);

  static const speed = ConvCategory('speed', 'Hız birimleri', [
    ConvUnit('m/s', 1),
    ConvUnit('fps (ft/s)', 0.3048),
    ConvUnit('km/sa', 1 / 3.6),
    ConvUnit('mph', 0.44704),
    ConvUnit('knot', 0.514444444444444),
  ]);

  static const weight = ConvCategory('weight', 'Ağırlık birimleri', [
    ConvUnit('grain (gr)', 0.06479891),
    ConvUnit('gram (g)', 1),
    ConvUnit('miligram (mg)', 0.001),
    ConvUnit('kilogram (kg)', 1000),
    ConvUnit('ons (oz)', 28.349523125),
    ConvUnit('libre (lb)', 453.59237),
  ]);

  static const pressure = ConvCategory('pressure', 'Basınç birimleri', [
    ConvUnit('bar', 100000),
    ConvUnit('psi', 6894.757293168),
    ConvUnit('hPa (mbar)', 100),
    ConvUnit('kPa', 1000),
    ConvUnit('MPa', 1000000),
    ConvUnit('atm', 101325),
    ConvUnit('mmHg', 133.322387415),
    ConvUnit('inHg', 3386.38866667),
    ConvUnit('kgf/cm²', 98066.5),
  ]);

  static const length = ConvCategory('length', 'Uzunluk birimleri', [
    ConvUnit('milimetre (mm)', 0.001),
    ConvUnit('santimetre (cm)', 0.01),
    ConvUnit('metre (m)', 1),
    ConvUnit('kilometre (km)', 1000),
    ConvUnit('inç (in)', 0.0254),
    ConvUnit('fit (ft)', 0.3048),
    ConvUnit('yarda (yd)', 0.9144),
    ConvUnit('mil (mi)', 1609.344),
  ]);

  static const torque = ConvCategory('torque', 'Tork birimleri', [
    ConvUnit('N·m', 1),
    ConvUnit('N·cm', 0.01),
    ConvUnit('lbf·ft', 1.3558179483314),
    ConvUnit('lbf·in', 0.1129848290276),
    ConvUnit('ozf·in', 0.00706155181423),
    ConvUnit('kgf·m', 9.80665),
  ]);
}
