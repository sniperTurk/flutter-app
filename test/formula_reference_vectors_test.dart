// dart format off
// Formula audit 2026-10-11 (docs/formul-denetimi-2026-10-11.md).
//
// Every number below comes from tools/formula_reference.py, an independent
// standard-library implementation written from the published formulas
// (CIPM-2007 air density, ICAO Doc 7488 standard atmosphere, WGS-84
// Somigliana gravity, BRL drag functions with PCHIP interpolation, a
// world-frame Dormand–Prince trajectory). It is NOT the output of any other
// ballistic app.
//
// Two checks per trajectory point:
//  * "same model": the reference run with the app's own air model and linear
//    Cd interpolation. Only the integrator, the frame algebra (incline, cant,
//    Coriolis, wind direction) and the units differ, so the tolerance is
//    tight: a sign or axis mistake cannot pass.
//  * "independent": the reference with its own air model and interpolation.
//    The tolerance is the modelling spread, well below one click (0.1 mrad).
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/atmosphere.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/gravity.dart';
import 'package:sniper_turk/core/powder_temperature.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/core/units.dart';
import 'package:sniper_turk/core/wez.dart';
import 'package:sniper_turk/core/wind_clock.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/field_calc.dart';
import 'package:sniper_turk/tools/domain/hit_probability.dart';
import 'package:sniper_turk/tools/domain/shot_angle_math.dart';
import 'package:sniper_turk/tools/domain/sight_height_geometry.dart';
import 'package:sniper_turk/tools/domain/sight_height_physical.dart';
import 'package:sniper_turk/tools/domain/tilt_math.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';

class RefPoint {
  final double rangeM, corrMrad, windMrad, velocityMps, tofS, energyJ;
  final double sameCorrMrad, sameWindMrad, sameVelocityMps, sameTofS;
  const RefPoint(
    this.rangeM,
    this.corrMrad,
    this.windMrad,
    this.velocityMps,
    this.tofS,
    this.energyJ,
    this.sameCorrMrad,
    this.sameWindMrad,
    this.sameVelocityMps,
    this.sameTofS,
  );
}

class RefScenario {
  final String id;
  final BallisticModel model;
  final double bc, grain, mvMps, zeroM, sightMm, g, inclineDeg, cantDeg;
  final double? latitudeDeg, azimuthDeg;
  final EnvironmentData env;
  final List<RefPoint> points;
  const RefScenario({
    required this.id,
    required this.model,
    required this.bc,
    required this.grain,
    required this.mvMps,
    required this.zeroM,
    required this.sightMm,
    required this.g,
    required this.env,
    required this.inclineDeg,
    required this.cantDeg,
    required this.latitudeDeg,
    required this.azimuthDeg,
    required this.points,
  });

  BallisticInput input() => BallisticInput(
    muzzleVelocityMps: mvMps,
    grain: grain,
    zeroRangeM: zeroM,
    sightHeightMm: sightMm,
    rangesM: [for (final p in points) p.rangeM],
    environment: env,
    ballisticCoefficient: bc,
    ballisticModel: model,
    inclineDeg: inclineDeg,
    cantDeg: cantDeg,
    latitudeDeg: latitudeDeg,
    azimuthDeg: azimuthDeg,
    gravityMps2: g,
  );
}

double _max(double a, double b) => a > b ? a : b;

void main() {
  group('trajectory = independent reference', () {
    for (final s in referenceScenarios) {
      test(s.id, () {
        final app = const BallisticEngine().solve(s.input());
        expect(app, hasLength(s.points.length));
        for (var i = 0; i < app.length; i++) {
          final a = app[i], r = s.points[i];
          final at = '${s.id} @ ${r.rangeM} m';
          for (final v in [
            a.correctionMrad,
            a.windMrad,
            a.velocityMps,
            a.energyJ,
            a.timeOfFlightS,
          ]) {
            expect(v.isFinite, isTrue, reason: at);
          }
          // Same model: integrator / frame / units only.
          expect(a.correctionMrad, closeTo(r.sameCorrMrad, 0.005), reason: at);
          expect(a.windMrad, closeTo(r.sameWindMrad, 0.005), reason: at);
          expect(a.velocityMps, closeTo(r.sameVelocityMps, 0.05), reason: at);
          expect(a.timeOfFlightS, closeTo(r.sameTofS, 2e-4), reason: at);
          // Independent air model and drag interpolation.
          expect(
            a.correctionMrad,
            closeTo(r.corrMrad, _max(0.03, 0.005 * r.corrMrad.abs())),
            reason: at,
          );
          expect(
            a.windMrad,
            closeTo(r.windMrad, _max(0.03, 0.01 * r.windMrad.abs())),
            reason: at,
          );
          expect(a.velocityMps, closeTo(r.velocityMps, 0.005 * r.velocityMps), reason: at);
          expect(a.timeOfFlightS, closeTo(r.tofS, 0.005 * r.tofS), reason: at);
          expect(a.energyJ, closeTo(r.energyJ, 0.01 * r.energyJ), reason: at);
        }
      });
    }
  });

  group('atmosphere = CIPM-2007 / ideal humid air / Buck', () {
    for (final row in referenceAir) {
      final env = EnvironmentData(
        temperatureC: row[0],
        pressureHpa: row[1],
        humidityPercent: row[2],
      );
      test('${row[0]} °C, ${row[1]} hPa, %${row[2]}', () {
        // Magnus + ideal gas vs CIPM-2007: < 0.2 %.
        expect(Atmosphere.densityKgM3(env), closeTo(row[3], 0.002 * row[3]));
        // γ = 1.4 vs the humid mixture: < 0.4 % even at 50 °C / 90 %.
        expect(Atmosphere.speedOfSoundMps(env), closeTo(row[4], 0.004 * row[4]));
        if (row[2] > 0) {
          expect(FieldCalc.dewPointC(row[0], row[2]), closeTo(row[5], 0.2));
        }
      });
    }
  });

  test('gravity = WGS-84 Somigliana + NIMA free-air', () {
    for (final row in referenceGravity) {
      expect(
        Gravity.at(latitudeDeg: row[0], altitudeM: row[1]),
        closeTo(row[2], 1e-6),
        reason: 'lat ${row[0]}, h ${row[1]}',
      );
    }
  });

  test('station pressure and density altitude = ICAO standard atmosphere', () {
    for (final row in referenceIsa) {
      expect(
        FieldCalc.stationPressureHpa(1013.25, row[0]),
        closeTo(row[1], 0.05),
      );
      expect(FieldCalc.densityAltitudeM(row[2]), closeTo(row[0], 1.0));
      expect(
        FieldCalc.stationPressureHpa(1013.25, row[0], temperatureC: 30),
        closeTo(row[3], 0.01),
      );
    }
  });

  test('unit factors = NIST SP 811 exact definitions', () {
    const inch = 0.0254, foot = 0.3048, pound = 0.45359237;
    expect(UnitSystem.metersPerYard, closeTo(3 * foot, 1e-15));
    expect(UnitSystem.metersPerFoot, closeTo(foot, 1e-15));
    expect(UnitSystem.millimetersPerInch, closeTo(inch * 1000, 1e-12));
    expect(UnitSystem.metersPerSecondPerMph, closeTo(1609.344 / 3600, 1e-15));
    expect(UnitSystem.metersPerSecondPerKnot, closeTo(1852 / 3600, 1e-12));
    expect(
      UnitSystem.joulesPerFootPound,
      closeTo(foot * pound * 9.80665, 1e-12),
    );
    expect(UnitSystem.hpaPerInHg * 100, closeTo(inch * 13595.1 * 9.80665, 1e-3));
    expect(Units.grainToKg(7000), closeTo(pound, 1e-12));
    expect(Units.moaToMrad(1), closeTo(3.141592653589793 / 10.8, 1e-12));
    expect(Units.mradToMoa(Units.moaToMrad(37.5)), closeTo(37.5, 1e-12));
    expect(AngularUnit.smoa.mradPerUnit, closeTo(inch / (100 * 3 * foot) * 1000, 1e-12));
    expect(UnitSystem.fahrenheitToCelsius(-40), closeTo(-40, 1e-12));
    expect(UnitSystem.celsiusToFahrenheit(100), closeTo(212, 1e-12));
  });

  _edgeCases();

  group('extreme inputs: a finite answer or a clean refusal, never NaN', () {
    const cases = <(String, EnvironmentData, double, double, double)>[
      // (name, environment, incline, cant, muzzle velocity m/s)
      ('cold dense', EnvironmentData(temperatureC: -60, pressureHpa: 1100), 0.0, 0.0, 800.0),
      ('hot humid high', EnvironmentData(temperatureC: 60, pressureHpa: 300, humidityPercent: 100), 0.0, 0.0, 800.0),
      ('gale crosswind', EnvironmentData(windMps: 59.9, windDirectionDeg: 270), 0.0, 0.0, 800.0),
      ('gale headwind', EnvironmentData(windMps: 59.9, windDirectionDeg: 0), 0.0, 0.0, 270.0),
      ('straight up', EnvironmentData(), 90.0, 0.0, 800.0),
      ('straight down', EnvironmentData(), -90.0, 0.0, 270.0),
      ('upside-down scope', EnvironmentData(), 0.0, 180.0, 800.0),
      ('backwards over the head', EnvironmentData(), 179.0, -179.0, 800.0),
      ('fastest allowed', EnvironmentData(), 0.0, 0.0, 1500.0),
    ];
    for (final (name, env, incline, cant, mv) in cases) {
      for (final model in [BallisticModel.g1, BallisticModel.g7]) {
        test('$name ${model.name}', () {
          final input = BallisticInput(
            muzzleVelocityMps: mv,
            grain: mv > 400 ? 175 : 18,
            zeroRangeM: mv > 400 ? 100 : 30,
            sightHeightMm: 45,
            rangesM: const [10, 50, 100, 300, 1000, 3000],
            environment: env,
            ballisticCoefficient: mv > 400 ? 0.243 : 0.035,
            ballisticModel: model,
            inclineDeg: incline,
            cantDeg: cant,
            latitudeDeg: 39,
            azimuthDeg: 90,
          );
          final solved = const BallisticEngine().solveReachable(input);
          for (final p in solved.points) {
            for (final v in [
              p.dropM,
              p.correctionMrad,
              p.correctionMoa,
              p.windMrad,
              p.velocityMps,
              p.energyJ,
              p.timeOfFlightS,
            ]) {
              expect(v.isFinite, isTrue, reason: '$name @ ${p.rangeM}');
            }
          }
          expect(
            solved.points.length + solved.unreachableM.length,
            6,
            reason: 'every range is either solved or reported unreachable',
          );
        });
      }
    }
  });
}

// Edge inputs outside the trajectory solver (review 2026-10-11): each helper
// returns a finite value, null, or refuses with ArgumentError — never a NaN
// that reaches the screen.
void _edgeCases() {
  group('edge inputs outside the solver', () {
    test('station pressure above the ISA domain is refused downstream', () {
      // ISA has no pressure above ~44 km: the helper yields NaN and the
      // density model refuses it, so the calculator shows a message.
      final p = FieldCalc.stationPressureHpa(1013.25, 50000);
      expect(p.isNaN, isTrue);
      expect(
        () => Atmosphere.densityKgM3(EnvironmentData(pressureHpa: p)),
        throwsArgumentError,
      );
      expect(FieldCalc.stationPressureHpa(1013.25, 9000).isFinite, isTrue);
      expect(
        FieldCalc.stationPressureHpa(1013.25, 9000, temperatureC: -40).isFinite,
        isTrue,
      );
    });

    test('dew point and density altitude stay finite', () {
      expect(FieldCalc.dewPointC(20, 0).isFinite, isTrue);
      expect(FieldCalc.dewPointC(-40, 100), closeTo(-40, 1e-9));
      expect(FieldCalc.densityAltitudeM(1e-4).isFinite, isTrue);
    });

    test('hit probabilities stay in 0..1', () {
      expect(Wez.atLeastOneHit(double.nan, 3), 0);
      expect(Wez.atLeastOneHit(1.5, 3), 1);
      expect(Wez.atLeastOneHit(0.5, 3), closeTo(0.875, 1e-12));
      final none = Wez.simulate(sources: const [], targetRadiusMrad: 0);
      expect(none.probability, 1);
      final p = HitProbabilityEngine.probabilityOfHit(
        groupDiameterMoa: 1e-9,
        targetDiameterCm: 10,
        rangeM: 3000,
      );
      expect(p, inInclusiveRange(0, 1));
    });

    test('powder temperature ignores unusable data', () {
      double f(double? k, double? t0, double t) => PowderTemperature.factor(
        coefPercentPer15C: k,
        referenceTempC: t0,
        todayTempC: t,
      );
      expect(f(double.nan, 20, 30), 1);
      expect(f(1.5, 20, double.infinity), 1);
      expect(f(10, -50, -1000), 1); // would be negative
      expect(f(1.5, 20, 35), closeTo(1.015, 1e-12));
    });

    test('phone incline and cant: signs and degenerate readings', () {
      double rad(double d) => d * 3.141592653589793 / 180;
      // Upright, back camera tipped 10° up: screen faces slightly down.
      final up10 = GravityVector(
        0,
        9.80665 * _cos(rad(10)),
        -9.80665 * _sin(rad(10)),
      );
      expect(ShotAngleMath.inclineDeg(up10), closeTo(10, 1e-9));
      // Top edge rolled 5° to the right: positive (clockwise) cant.
      final cw5 = GravityVector(
        -9.80665 * _sin(rad(5)),
        9.80665 * _cos(rad(5)),
        0,
      );
      expect(ShotAngleMath.cantDeg(cw5), closeTo(5, 1e-9));
      const zero = GravityVector(0, 0, 0);
      const bad = GravityVector(double.nan, 9.8, 0);
      expect(ShotAngleMath.inclineDeg(zero), isNull);
      expect(ShotAngleMath.cantDeg(zero), isNull);
      expect(ShotAngleMath.inclineDeg(bad), isNull);
      expect(ShotAngleMath.cantDeg(bad), isNull);
      expect(TiltMath.angles(zero, TiltMode.flat), isNull);
      expect(TiltMath.percentGrade(90), isNull);
      expect(TiltMath.percentGrade(45), closeTo(100, 1e-9));
    });

    test('sight height helpers refuse impossible marks', () {
      const pt = PixelPoint(100, 100);
      expect(
        SightHeightGeometry.measure(
          objectiveOuterDiameterMm: 50,
          objectiveTop: pt,
          objectiveBottom: pt,
          boreCentre: pt,
        ),
        isNull,
      );
      expect(
        SightHeightPhysical.compute(
          boreDiameterMm: double.nan,
          barrelWallMm: 5,
          gapMm: 5,
          objectiveOuterDiameterMm: 50,
        ),
        isNull,
      );
      // Bore radius + wall + gap + objective radius.
      expect(
        SightHeightPhysical.compute(
          boreDiameterMm: 7.82,
          barrelWallMm: 8,
          gapMm: 6,
          objectiveOuterDiameterMm: 56,
        )!.totalMm,
        closeTo(3.91 + 8 + 6 + 28, 1e-9),
      );
    });

    test('turret and wind-clock helpers refuse bad values', () {
      expect(() => ScopeDialMath.clicksFor(double.nan, 0.1), throwsArgumentError);
      expect(() => ScopeDialMath.clicksFor(1, 0), throwsArgumentError);
      expect(ScopeDialMath.mountCantClicks(90, 0.1, AngularUnit.mrad), 261);
      expect(() => WindClock.toDegrees(0), throwsArgumentError);
      expect(Gravity.at(latitudeDeg: 90, altitudeM: 9000).isFinite, isTrue);
    });
  });
}

double _sin(double x) => _series(x, true);
double _cos(double x) => _series(x, false);

/// Taylor series, so the sign checks above do not reuse dart:math's
/// functions that the code under test calls.
double _series(double x, bool sine) {
  var term = sine ? x : 1.0, sum = term;
  for (var n = 0; n < 40; n++) {
    term *= -x * x / ((2 * n + (sine ? 2 : 1)) * (2 * n + (sine ? 3 : 2)));
    sum += term;
  }
  return sum;
}

// BEGIN GENERATED (python3 tools/formula_reference.py --write-dart)
const referenceScenarios = <RefScenario>[
  RefScenario(
    id: 'pcp22_mild', model: BallisticModel.g1, bc: 0.035,
    grain: 18.13, mvMps: 270.0, zeroM: 30.0,
    sightMm: 50.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 20, pressureHpa: 1000, humidityPercent: 50, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(15.0, 0.503185803, -0.0, 252.586593671, 0.057477408, 37.476247743, 0.503113383, -0.0, 252.589634883, 0.057476962),
      RefPoint(20.0, 0.043368183, -0.0, 247.308757386, 0.077483828, 35.926466068, 0.043287564, -0.0, 247.313141838, 0.077483098),
      RefPoint(30.0, -0.00991561, -0.0, 237.347710878, 0.11876606, 33.090673304, -0.010014423, -0.0, 237.347045385, 0.11876498),
      RefPoint(50.0, 1.021437078, -0.0, 219.225307004, 0.206490471, 28.23039032, 1.021505841, -0.0, 219.117674736, 0.206507888),
      RefPoint(75.0, 3.090853497, -0.0, 199.094569437, 0.326222724, 23.283825588, 3.092615226, -0.0, 198.938932806, 0.326325766),
      RefPoint(100.0, 5.676438987, -0.0, 180.982940733, 0.457988222, 19.240253521, 5.681473488, -0.0, 180.832062939, 0.458198047),
    ],
  ),
  RefScenario(
    id: 'pcp22_cold', model: BallisticModel.g1, bc: 0.035,
    grain: 18.13, mvMps: 270.0, zeroM: 30.0,
    sightMm: 50.0, g: 9.80665,
    env: EnvironmentData(temperatureC: -10, pressureHpa: 1020, humidityPercent: 80, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(15.0, 0.515339852, -0.0, 248.772794394, 0.057950704, 36.353085507, 0.515265942, -0.0, 248.776391074, 0.057950253),
      RefPoint(20.0, 0.06480725, -0.0, 242.596521709, 0.078305509, 34.570419414, 0.064725188, -0.0, 242.601465844, 0.078304755),
      RefPoint(30.0, 0.037837728, -0.0, 231.164855999, 0.12054544, 31.389119029, 0.037730402, -0.0, 231.170311855, 0.120543692),
      RefPoint(50.0, 1.153615774, -0.0, 210.907330166, 0.211190831, 26.12876345, 1.153505255, -0.0, 210.83929981, 0.211196364),
      RefPoint(75.0, 3.394445163, -0.0, 188.908475582, 0.336534905, 20.96227412, 3.395641102, -0.0, 188.773633763, 0.336618434),
      RefPoint(100.0, 6.239020206, -0.0, 169.430937882, 0.476359992, 16.862460243, 6.24330524, -0.0, 169.306535145, 0.476545068),
    ],
  ),
  RefScenario(
    id: 'pcp22_hot_wind3', model: BallisticModel.g1, bc: 0.035,
    grain: 18.13, mvMps: 270.0, zeroM: 30.0,
    sightMm: 50.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 40, pressureHpa: 990, humidityPercent: 30, windMps: 4.0, windDirectionDeg: 270.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(15.0, 0.497526381, 0.452800623, 254.455202178, 0.057253978, 38.03278929, 0.497446637, 0.452615741, 254.459983801, 0.057253284),
      RefPoint(20.0, 0.033328575, 0.603569398, 249.65845828, 0.077092481, 36.612389803, 0.033237661, 0.603378822, 249.660969256, 0.077091528),
      RefPoint(30.0, -0.032475631, 0.90613024, 240.499829677, 0.117907929, 33.975437299, -0.032580816, 0.906078818, 240.482218877, 0.117907543),
      RefPoint(50.0, 0.958301536, 1.519654807, 223.639060403, 0.204182283, 29.378581781, 0.958543707, 1.521892847, 223.504616483, 0.204210259),
      RefPoint(75.0, 2.944724397, 2.310069218, 204.656691164, 0.321093751, 24.602962551, 2.946927824, 2.316243702, 204.49359806, 0.321209523),
      RefPoint(100.0, 5.405066163, 3.137054175, 187.414884801, 0.448799779, 20.632111189, 5.410596779, 3.145919587, 187.254063495, 0.449021417),
    ],
  ),
  RefScenario(
    id: 'pcp22_down30', model: BallisticModel.g1, bc: 0.035,
    grain: 18.13, mvMps: 270.0, zeroM: 30.0,
    sightMm: 50.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 20, pressureHpa: 1000, humidityPercent: 50, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: -30.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(30.0, -0.305911603, -0.0, 237.866434354, 0.118638023, 33.235470706, -0.306005669, -0.0, 237.866600596, 0.118636906),
      RefPoint(50.0, 0.492201391, -0.0, 220.090508692, 0.206095136, 28.453659978, 0.49223512, -0.0, 219.986993178, 0.206111129),
      RefPoint(75.0, 2.222629321, -0.0, 200.415296222, 0.325199679, 23.593764428, 2.22407269, -0.0, 200.256542867, 0.325300959),
    ],
  ),
  RefScenario(
    id: 'r308_icao', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 15.0, pressureHpa: 1013.25, humidityPercent: 0.0, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(100.0, -0.0, -0.0, 731.516771686, 0.13134275, 3034.061146991, -0.0, -0.0, 731.537318279, 0.131340907),
      RefPoint(200.0, 0.693778272, -0.0, 673.322134497, 0.273837703, 2570.52325141, 0.693724778, -0.0, 673.361607766, 0.273829665),
      RefPoint(300.0, 1.648124817, -0.0, 617.966396439, 0.428872384, 2165.237166573, 1.647968379, -0.0, 618.018711826, 0.428853161),
      RefPoint(400.0, 2.769326502, -0.0, 565.13191125, 0.598090699, 1810.82055693, 2.769008653, -0.0, 565.194399447, 0.598054995),
      RefPoint(500.0, 4.058368984, -0.0, 514.494473703, 0.783543621, 1500.849628683, 4.057816934, -0.0, 514.565687521, 0.783484814),
      RefPoint(600.0, 5.537715209, -0.0, 465.904584267, 0.98779755, 1230.74965013, 5.536837405, -0.0, 465.976385782, 0.987709123),
      RefPoint(700.0, 7.242789705, -0.0, 419.439678855, 1.214038789, 997.504303314, 7.241473332, -0.0, 419.523930872, 1.213910337),
      RefPoint(800.0, 9.221941652, -0.0, 375.540061056, 1.466094415, 799.628562617, 9.220010038, -0.0, 375.638732541, 1.465907566),
      RefPoint(900.0, 11.537953882, -0.0, 335.94175374, 1.748130631, 639.887643282, 11.535117848, -0.0, 336.156107653, 1.747845137),
      RefPoint(1000.0, 14.253681749, -0.0, 315.281317022, 2.056924381, 563.60161076, 14.249363945, -0.0, 315.260176957, 2.056537827),
    ],
  ),
  RefScenario(
    id: 'r308_hot_high', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 40, pressureHpa: 800, humidityPercent: 20, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(100.0, -0.011770938, -0.0, 747.37071256, 0.129941091, 3166.998834956, -0.011750458, -0.0, 747.363520928, 0.129941705),
      RefPoint(200.0, 0.642325471, -0.0, 703.790290256, 0.267828292, 2808.421539758, 0.642362547, -0.0, 703.777508052, 0.267830789),
      RefPoint(300.0, 1.521288672, -0.0, 661.77112132, 0.414362458, 2483.083797843, 1.521356207, -0.0, 661.749588289, 0.414368575),
      RefPoint(400.0, 2.521482461, -0.0, 621.188059503, 0.570334126, 2187.872209083, 2.521602162, -0.0, 621.155988033, 0.570346721),
      RefPoint(500.0, 3.630776332, -0.0, 581.876493043, 0.736668841, 1919.717743301, 3.630980853, -0.0, 581.833326466, 0.736691957),
      RefPoint(600.0, 4.853975042, -0.0, 543.742831192, 0.914457199, 1676.342832681, 4.854309382, -0.0, 543.687445233, 0.914496021),
      RefPoint(700.0, 6.202555731, -0.0, 506.722645703, 1.104980996, 1455.849161689, 6.203081407, -0.0, 506.648346064, 1.10504292),
      RefPoint(800.0, 7.692549742, -0.0, 470.815741136, 1.309741729, 1256.833368579, 7.693357337, -0.0, 470.732578753, 1.309837152),
      RefPoint(900.0, 9.344308735, -0.0, 436.121203201, 1.530480411, 1078.425520522, 9.345510446, -0.0, 436.034622111, 1.530617573),
      RefPoint(1000.0, 11.182834203, -0.0, 402.832973026, 1.76916247, 920.080394649, 11.184556297, -0.0, 402.748827673, 1.769348532),
    ],
  ),
  RefScenario(
    id: 'r308_cold', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: -10, pressureHpa: 1030, humidityPercent: 60, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(100.0, 0.004073123, -0.0, 726.153819731, 0.131826337, 2989.737136211, 0.004055978, -0.0, 726.195872454, 0.131822494),
      RefPoint(200.0, 0.711990229, -0.0, 663.025103017, 0.27595257, 2492.50304153, 0.711860578, -0.0, 663.105775953, 0.275935796),
      RefPoint(300.0, 1.694131909, -0.0, 603.260920956, 0.434083177, 2063.412889499, 1.693780427, -0.0, 603.37244506, 0.434042011),
      RefPoint(400.0, 2.861451298, -0.0, 546.594009808, 0.60823396, 1693.96912082, 2.860735729, -0.0, 546.730580018, 0.608154962),
      RefPoint(500.0, 4.221197894, -0.0, 492.567644888, 0.800956572, 1375.648616607, 4.219930906, -0.0, 492.726040492, 0.800822524),
      RefPoint(600.0, 5.804753311, -0.0, 440.970370137, 1.015526669, 1102.540551676, 5.80268289, -0.0, 441.141646486, 1.015316941),
      RefPoint(700.0, 7.66048596, -0.0, 391.930820805, 1.256107014, 870.95273571, 7.657268765, -0.0, 392.124682947, 1.255791301),
      RefPoint(800.0, 9.855405979, -0.0, 346.111720455, 1.527762518, 679.216716329, 9.850524593, -0.0, 346.325903648, 1.527295464),
      RefPoint(900.0, 12.476648408, -0.0, 310.448174592, 1.834786385, 546.45445978, 12.469256674, -0.0, 310.624943399, 1.834080192),
      RefPoint(1000.0, 15.583421294, -0.0, 294.214363991, 2.166566891, 490.79880566, 15.572924444, -0.0, 294.206992766, 2.165794281),
    ],
  ),
  RefScenario(
    id: 'r308_wind10_coriolis_east', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.800809171,
    env: EnvironmentData(temperatureC: 15, pressureHpa: 1013.25, humidityPercent: 50, windMps: 10.0, windDirectionDeg: 90.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: 39.0, azimuthDeg: 90.0,
    points: [
      RefPoint(300.0, 1.622402461, -1.691169242, 618.384712812, 0.428728041, 2168.169561366, 1.622301162, -1.690731791, 618.419671743, 0.428714929),
      RefPoint(600.0, 5.475963039, -3.873375196, 466.630822714, 0.987042226, 1234.589553724, 5.475406014, -3.872473959, 466.667803779, 0.986988249),
      RefPoint(1000.0, 14.112164936, -7.999838601, 315.958248181, 2.053936651, 566.024393495, 14.109389338, -7.996906446, 315.968850482, 2.05364401),
    ],
  ),
  RefScenario(
    id: 'r308_up30', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 15.0, pressureHpa: 1013.25, humidityPercent: 0.0, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 30.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(300.0, 1.282103431, -0.0, 615.998767453, 0.429517161, 2151.470719656, 1.281969183, -0.0, 616.050978699, 0.429497876),
      RefPoint(600.0, 4.676792989, -0.0, 461.560480772, 0.991835662, 1207.90558041, 4.676023048, -0.0, 461.633002983, 0.991746466),
    ],
  ),
  RefScenario(
    id: 'r308_down45', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 15.0, pressureHpa: 1013.25, humidityPercent: 0.0, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: -45.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(300.0, 0.830616324, -0.0, 620.731493294, 0.427967196, 2184.657268258, 0.830511176, -0.0, 620.784021282, 0.427948064),
      RefPoint(600.0, 3.518975585, -0.0, 471.939990618, 0.982202379, 1262.842858778, 3.518372451, -0.0, 472.011277601, 0.982114953),
    ],
  ),
  RefScenario(
    id: 'r308_up60', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 15.0, pressureHpa: 1013.25, humidityPercent: 0.0, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 60.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(200.0, -0.176661807, -0.0, 671.096920261, 0.274274115, 2553.561048955, -0.176680997, -0.0, 671.136314287, 0.27426604),
      RefPoint(400.0, 0.81440624, -0.0, 560.439656694, 0.600379951, 1780.875135286, 0.814252857, -0.0, 560.502362598, 0.600343935),
    ],
  ),
  RefScenario(
    id: 'r308_cant5', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 15.0, pressureHpa: 1013.25, humidityPercent: 0.0, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 0.0, cantDeg: 5.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(300.0, 1.637577045, -0.24158438, 617.966413285, 0.428872385, 2165.237284624, 1.637421261, -0.241569399, 618.018728673, 0.428853162),
      RefPoint(600.0, 5.512081541, -0.587125943, 465.904616746, 0.987797554, 1230.749821726, 5.511207154, -0.587048091, 465.976410708, 0.98770913),
      RefPoint(1000.0, 14.194775013, -1.349465631, 315.281342593, 2.056924434, 563.60170218, 14.190473893, -1.349087906, 315.26020226, 2.056537895),
    ],
  ),
  RefScenario(
    id: 'r308_coriolis_south_north', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 15.0, pressureHpa: 1013.25, humidityPercent: 0.0, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: -35.0, azimuthDeg: 0.0,
    points: [
      RefPoint(600.0, 5.537716636, 0.037500202, 465.904583998, 0.987797552, 1230.749648709, 5.536838834, 0.037497941, 465.976385558, 0.987709124),
      RefPoint(1000.0, 14.253687313, 0.071361928, 315.281316525, 2.056924393, 563.601608983, 14.24936952, 0.071353859, 315.260175877, 2.05653784),
    ],
  ),
  RefScenario(
    id: 'cm65_wind5_2oclock', model: BallisticModel.g7, bc: 0.315,
    grain: 140.0, mvMps: 826.008, zeroM: 100.0,
    sightMm: 40.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 15, pressureHpa: 1013.25, humidityPercent: 40, windMps: 5.0, windDirectionDeg: 300.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(100.0, 2.1974e-05, 0.160536254, 777.523527783, 0.12478293, 2742.16017864, 2.4775e-05, 0.160494298, 777.535475569, 0.124781958),
      RefPoint(200.0, 0.612397421, 0.330999668, 730.617459024, 0.257463057, 2421.284559724, 0.612374545, 0.330911039, 730.640830285, 0.257458951),
      RefPoint(300.0, 1.430047923, 0.512189015, 685.352093907, 0.398785747, 2130.557347854, 1.42997663, 0.512046421, 685.386677008, 0.398775838),
      RefPoint(400.0, 2.361957029, 0.704939947, 641.792469068, 0.549573795, 1868.335964939, 2.361808512, 0.704736798, 641.835384059, 0.549554972),
      RefPoint(500.0, 3.398472937, 0.910287962, 599.844733637, 0.710750572, 1632.087509702, 3.398214288, 0.910023258, 599.892346558, 0.710719914),
      RefPoint(600.0, 4.545076207, 1.129746698, 559.317671674, 0.883401849, 1419.001396189, 4.544671395, 1.129419728, 559.369472698, 0.883356405),
      RefPoint(700.0, 5.813451303, 1.365265825, 520.083416583, 1.068824352, 1226.907306147, 5.812858918, 1.364872933, 520.138002385, 1.068760646),
      RefPoint(800.0, 7.219760527, 1.619155196, 482.063734982, 1.268562209, 1054.082645628, 7.218932464, 1.618695683, 482.11355178, 1.268477056),
      RefPoint(900.0, 8.78464954, 1.894088844, 445.257970103, 1.4844495, 899.268010657, 8.783537084, 1.893565852, 445.311885987, 1.484340469),
      RefPoint(1000.0, 10.533890821, 2.193044574, 409.788832139, 1.718638452, 761.703546366, 10.532429007, 2.192438027, 409.85030673, 1.718497951),
    ],
  ),
  RefScenario(
    id: 'cm65_altitude3000', model: BallisticModel.g7, bc: 0.315,
    grain: 140.0, mvMps: 826.008, zeroM: 100.0,
    sightMm: 40.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 0, pressureHpa: 700, humidityPercent: 30, windMps: 0.0, windDirectionDeg: 90.0),
    inclineDeg: 0.0, cantDeg: 0.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(100.0, -0.008542488, -0.0, 791.083830918, 0.123707926, 2838.642864945, -0.008538405, -0.0, 791.094704119, 0.123707085),
      RefPoint(200.0, 0.575583876, -0.0, 756.957706245, 0.252935701, 2599.016100826, 0.575566288, -0.0, 756.978382827, 0.252932216),
      RefPoint(300.0, 1.341258553, -0.0, 723.649802957, 0.388051315, 2375.322797335, 1.341202293, -0.0, 723.68021349, 0.388043167),
      RefPoint(400.0, 2.19266261, -0.0, 691.186990067, 0.529450917, 2166.989717437, 2.192547564, -0.0, 691.226447206, 0.529435788),
      RefPoint(500.0, 3.114413134, -0.0, 659.592913296, 0.677560302, 1973.411716631, 3.114215585, -0.0, 659.641325033, 0.677535482),
      RefPoint(600.0, 4.104942722, -0.0, 628.888828358, 0.832835232, 1793.963077914, 4.104634981, -0.0, 628.943806248, 0.832797897),
      RefPoint(700.0, 5.167041466, -0.0, 599.026573623, 0.995773716, 1627.638364727, 5.166593033, -0.0, 599.086415125, 0.995721112),
      RefPoint(800.0, 6.305608893, -0.0, 569.936880003, 1.166936199, 1473.395237661, 6.304986448, -0.0, 570.000443409, 1.166865443),
      RefPoint(900.0, 7.527023199, -0.0, 541.545897831, 1.346960802, 1330.259231451, 7.526189938, -0.0, 541.614184874, 1.346868634),
      RefPoint(1000.0, 8.839002142, -0.0, 513.825143272, 1.536570977, 1197.557691925, 8.837915949, -0.0, 513.896394961, 1.536453763),
    ],
  ),
  RefScenario(
    id: 'r308_up30_cant10_wind_coriolis', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 20, pressureHpa: 950, humidityPercent: 40, windMps: 5.0, windDirectionDeg: 300.0),
    inclineDeg: 30.0, cantDeg: 10.0,
    latitudeDeg: 39.0, azimuthDeg: 45.0,
    points: [
      RefPoint(300.0, 1.123145928, 0.271894867, 627.976243239, 0.425372548, 2235.950487425, 1.123117747, 0.271796768, 627.995498255, 0.42536529),
      RefPoint(600.0, 4.207253347, 0.566412153, 482.515246716, 0.970131053, 1320.072656688, 4.207045586, 0.566271811, 482.524543903, 0.970106296),
      RefPoint(1000.0, 10.980989819, 0.977036464, 323.995098254, 1.993410481, 595.185898555, 10.980130661, 0.976443944, 324.096814119, 1.993239146),
    ],
  ),
  RefScenario(
    id: 'r308_down40_cantm15_wind_coriolis_south', model: BallisticModel.g7, bc: 0.243,
    grain: 175.0, mvMps: 792.48, zeroM: 100.0,
    sightMm: 45.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 5, pressureHpa: 1010, humidityPercent: 70, windMps: 8.0, windDirectionDeg: 45.0),
    inclineDeg: -40.0, cantDeg: -15.0,
    latitudeDeg: -30.0, azimuthDeg: 200.0,
    points: [
      RefPoint(300.0, 1.793243926, -0.200260284, 615.1446903, 0.429886229, 2145.508863139, 1.792749154, -0.199967843, 615.205777284, 0.42986412),
      RefPoint(600.0, 5.786850978, -0.384630816, 462.054801252, 0.992531179, 1210.494243121, 5.785233066, -0.38405957, 462.137284284, 0.992427303),
    ],
  ),
  RefScenario(
    id: 'pcp22_up10_cant170_wind', model: BallisticModel.g1, bc: 0.035,
    grain: 18.13, mvMps: 270.0, zeroM: 30.0,
    sightMm: 50.0, g: 9.80665,
    env: EnvironmentData(temperatureC: 25, pressureHpa: 1005, humidityPercent: 60, windMps: 3.0, windDirectionDeg: 120.0),
    inclineDeg: 10.0, cantDeg: 170.0,
    latitudeDeg: null, azimuthDeg: null,
    points: [
      RefPoint(30.0, -4.529607471, 0.240526503, 238.370421477, 0.118480574, 33.376457343, -4.529573017, 0.240400548, 238.365449259, 0.118478958),
      RefPoint(50.0, -6.94762935, 0.368003049, 220.596732431, 0.205745015, 28.584701368, -6.948147983, 0.36905178, 220.476699303, 0.205766317),
      RefPoint(75.0, -9.737594632, 0.496824159, 200.736743195, 0.324620694, 23.669509408, -9.740545659, 0.500063121, 200.5837535, 0.324726809),
    ],
  ),
];

/// (°C, hPa, %RH, CIPM-2007 kg/m³, speed of sound m/s, Buck dew point °C)
const referenceAir = <List<double>>[
  [-20, 1030, 50, 1.418387689, 318.94406159, -27.769081127],
  [-10, 1020, 80, 1.350177266, 325.267313117, -12.791464915],
  [0, 700, 30, 0.892253817, 331.409452951, -15.519709363],
  [15, 1013.25, 0, 1.225521345, 340.245781228, -999],
  [15, 1013.25, 100, 1.217751099, 341.161958832, 15.0],
  [20, 1000, 50, 1.183556609, 343.826025279, 9.270961152],
  [30, 900, 70, 1.021632214, 350.84362309, 23.927909145],
  [40, 990, 30, 1.092253944, 355.971728038, 19.125946262],
  [40, 800, 100, 0.859229546, 360.075267885, 40.0],
  [50, 1013.25, 90, 1.047424823, 366.856584994, 47.893198929],
];

/// (latitude °, height m, WGS-84 normal gravity m/s²)
const referenceGravity = <List<double>>[
  [0, 0, 9.780325336],
  [36, 0, 9.798190542],
  [39, 0, 9.800809171],
  [39.9, 900, 9.798831072],
  [42, 2000, 9.797319354],
  [45, 0, 9.806197769],
  [60, 3000, 9.809930056],
  [90, 0, 9.832184938],
  [-35, 500, 9.795793052],
];

/// (height m, ICAO station pressure hPa from 1013.25, ISA density kg/m³,
///  hypsometric station hPa from 1013.25 at 30 °C station temperature)
const referenceIsa = <List<double>>[
  [0, 1013.25, 1.224999156, 1013.25],
  [500, 954.608393423, 1.167268055, 958.022326074],
  [1000, 898.745705022, 1.111641812, 906.34351961],
  [2000, 794.952155105, 1.006489561, 812.616320254],
  [3000, 701.0854467, 0.909121457, 730.235694542],
  [5000, 540.199121038, 0.736115355, 593.543122406],
];
// END GENERATED
