// Formül denetimi 2026-10-14 (docs/reports/formul_denetimi_2026_10_14.md).
//
// Characterization of every closed-form formula on the way from a typed
// value to a shown number, each against a published reference (the values
// are printed by tools/formul_denetimi_2026_10_14.py or follow from the
// cited definition). All of these PASS on the current code: they are the
// "✓" rows of the report.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/atmosphere.dart';
import 'package:sniper_turk/core/beaufort.dart';
import 'package:sniper_turk/core/dope_ranges.dart';
import 'package:sniper_turk/core/estimated_bc.dart';
import 'package:sniper_turk/core/gravity.dart';
import 'package:sniper_turk/core/parallax_range.dart';
import 'package:sniper_turk/core/pcp_pressure.dart';
import 'package:sniper_turk/core/powder_temperature.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/core/stability.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/core/units.dart';
import 'package:sniper_turk/core/wez.dart';
import 'package:sniper_turk/core/wind_clock.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/field_calc.dart';

Ammunition _pcpAmmo({
  required AmmunitionType type,
  required double caliberMm,
  required double grain,
  double? bc,
  bool userEntered = true,
  WeaponPlatform platform = WeaponPlatform.pcp,
}) => Ammunition(
  id: 'a',
  brand: 'Test',
  model: '',
  platform: platform,
  caliberMm: caliberMm,
  grain: grain,
  type: type,
  ballisticCoefficient: bc,
  ballisticModel: bc == null ? null : BallisticModel.g1,
  userEntered: userEntered,
);

void main() {
  group('atmosphere (CIPM-2007, ICAO Doc 7488/3)', () {
    // CIPM-2007 moist-air density (Picard et al. 2008), x_CO2 = 0.0004.
    // The app's Magnus/ideal-gas model stays within 0.1 % of it.
    const cipm = [
      (15.0, 1013.25, 0.0, 1.22552),
      (15.0, 1013.25, 50.0, 1.22163),
      (30.0, 950.0, 80.0, 1.07729),
      (-10.0, 1020.0, 30.0, 1.35089),
      (25.0, 900.0, 60.0, 1.04352),
    ];
    for (final c in cipm) {
      test('density ${c.$1} °C ${c.$2} hPa %${c.$3}', () {
        final rho = Atmosphere.densityKgM3(
          EnvironmentData(
            temperatureC: c.$1,
            pressureHpa: c.$2,
            humidityPercent: c.$3,
          ),
        );
        expect((rho - c.$4).abs() / c.$4, lessThan(0.001));
      });
    }

    test('speed of sound: ICAO 340.294 m/s at 15 °C (dry)', () {
      const env = EnvironmentData(humidityPercent: 0);
      expect(Atmosphere.speedOfSoundMps(env), closeTo(340.294, 0.01));
      expect(Stability.speedOfSoundMps(15), closeTo(340.294, 0.01));
    });

    test('altitude never enters the density (station pressure only)', () {
      const sea = EnvironmentData(humidityPercent: 0);
      const high = EnvironmentData(humidityPercent: 0, altitudeM: 1500);
      expect(Atmosphere.densityKgM3(high), Atmosphere.densityKgM3(sea));
    });

    test('ISA station pressure from QNH: 1000 m → 898.75 hPa', () {
      expect(FieldCalc.stationPressureHpa(1013.25, 1000), closeTo(898.75, 0.1));
      expect(FieldCalc.stationPressureHpa(1013.25, 2000), closeTo(794.95, 0.1));
    });

    test(
      'density altitude: 1.225 kg/m³ is 0 m; ISA 1000 m density ≈ 1000 m',
      () {
        expect(FieldCalc.densityAltitudeM(1.225), closeTo(0, 1e-6));
        // ICAO density at 1000 m: 1.11164 kg/m³.
        expect(FieldCalc.densityAltitudeM(1.11164), closeTo(1000, 2));
      },
    );

    test('dew point (Magnus): 20 °C %50 → 9.3 °C', () {
      expect(FieldCalc.dewPointC(20, 50), closeTo(9.26, 0.05));
    });

    test('normal gravity (WGS-84 Somigliana): 45° → 9.80620 m/s²', () {
      expect(Gravity.at(latitudeDeg: 45), closeTo(9.806198, 1e-6));
      expect(Gravity.at(latitudeDeg: 0), closeTo(9.7803253, 1e-6));
      // Free-air: −3.086 mm/s² per km.
      expect(
        Gravity.at(latitudeDeg: 45) -
            Gravity.at(latitudeDeg: 45, altitudeM: 1000),
        closeTo(0.003086, 0.00002),
      );
    });
  });

  group('units (NIST SP 811, exact definitions)', () {
    test('length, speed, pressure, temperature, energy', () {
      expect(UnitSystem.fpsToMps(1000), closeTo(304.8, 1e-12));
      expect(UnitSystem.mphToMps(10), closeTo(4.4704, 1e-12));
      expect(UnitSystem.yardsToMeters(100), closeTo(91.44, 1e-12));
      expect(UnitSystem.inHgToHpa(29.92), closeTo(1013.21, 0.01));
      expect(UnitSystem.fahrenheitToCelsius(59), closeTo(15, 1e-12));
      expect(UnitSystem.joulesToFootPounds(16.27), closeTo(12.0, 0.001));
      expect(Units.grainToKg(7000), closeTo(0.45359237, 1e-9));
    });

    test('angles: 1 MOA = π/10.8 mrad, 1 SMOA = 1 in / 100 yd', () {
      expect(Units.moaToMrad(1), closeTo(0.2908882, 1e-7));
      expect(Units.mradToMoa(1), closeTo(3.4377468, 1e-7));
      expect(
        AngularUnit.smoa.mradPerUnit,
        closeTo(0.0254 / 91.44 * 1000, 1e-12),
      );
      expect(
        ScopeDialMath.convert(1, AngularUnit.mrad, AngularUnit.smoa),
        closeTo(3.6, 1e-12),
      );
    });

    test('clicks: nearest whole click; mount MOA rounded down', () {
      expect(ScopeDialMath.clicksFor(1.04, 0.1), 10);
      expect(ScopeDialMath.clicksFor(-0.26, 0.1), -3);
      expect(ScopeDialMath.mountCantClicks(20, 0.1, AngularUnit.mrad), 58);
      expect(ScopeDialMath.mountCantClicks(30, 0.1, AngularUnit.mrad), 87);
      expect(ScopeDialMath.mountCantClicks(20, 0.25, AngularUnit.moa), 80);
      expect(ScopeDialMath.mountCantClicks(0, 0.1, AngularUnit.mrad), 0);
    });

    test('FFP covers its value; SFP scales calibration / magnification', () {
      expect(
        ScopeDialMath.reticleSubtension(
          firstFocalPlane: true,
          magnification: 8,
          calibrationMagnification: 16,
        ),
        1,
      );
      expect(
        ScopeDialMath.reticleSubtension(
          firstFocalPlane: false,
          magnification: 8,
          calibrationMagnification: 16,
        ),
        2,
      );
      // 1 mrad at 100 m is 10.0003 cm (tan).
      expect(
        ScopeDialMath.linearAtRange(1, 100, AngularUnit.mrad),
        closeTo(0.1000003, 1e-7),
      );
    });
  });

  group('stability (Miller 2005, Courtney & Miller 2012, Litz)', () {
    test('.308 168 gr 1.23 in 1:10 at 2650 fps, ICAO: Sg 2.381', () {
      final sg = Stability.millerSg(
        grain: 168,
        caliberMm: 7.82,
        twistIn: 10,
        lengthMm: 31.2,
        velocityMps: 2650 * 0.3048,
        temperatureC: 15,
        pressureHpa: 1013.25,
      );
      expect(sg, closeTo(2.38103, 0.0005));
    });

    test('subsonic slug uses the speed-of-sound factor (15 °C and −10 °C)', () {
      double sg(double t) => Stability.millerSg(
        grain: 50,
        caliberMm: 6.35,
        twistIn: 16,
        lengthMm: 10,
        velocityMps: 300,
        temperatureC: t,
        pressureHpa: 1013.25,
      );
      expect(sg(15), closeTo(3.14760, 0.0005));
      expect(sg(-10), closeTo(2.83153, 0.0005));
    });

    test('Sg classes and transonic rule', () {
      expect(Stability.classify(0.9), StabilityLevel.unstable);
      expect(Stability.classify(1.2), StabilityLevel.marginal);
      expect(Stability.classify(1.5), StabilityLevel.stable);
      expect(Stability.bcLossPercent(1.4), closeTo(3, 1e-9));
      expect(
        Stability.transonicAtTarget(muzzleMach: 2.3, targetMach: 1.1),
        isTrue,
      );
      expect(
        Stability.transonicAtTarget(muzzleMach: 0.85, targetMach: 0.7),
        isFalse,
      );
    });
  });

  group('PCP: estimated G1 BC and tube pressure', () {
    test('BC = SD / i: .25 34 gr slug 0.094, .22 18.13 gr pellet 0.027', () {
      expect(
        EstimatedBc.g1For(
          _pcpAmmo(type: AmmunitionType.slug, caliberMm: 6.35, grain: 34),
        ),
        0.094,
      );
      expect(
        EstimatedBc.g1For(
          _pcpAmmo(type: AmmunitionType.pellet, caliberMm: 5.5, grain: 18.13),
        ),
        0.027,
      );
    });

    test('never for a firearm, a catalog row or a given BC', () {
      expect(
        EstimatedBc.g1For(
          _pcpAmmo(
            type: AmmunitionType.bullet,
            caliberMm: 7.82,
            grain: 168,
            platform: WeaponPlatform.firearm,
          ),
        ),
        isNull,
      );
      expect(
        EstimatedBc.g1For(
          _pcpAmmo(
            type: AmmunitionType.slug,
            caliberMm: 6.35,
            grain: 34,
            userEntered: false,
          ),
        ),
        isNull,
      );
      expect(
        EstimatedBc.g1For(
          _pcpAmmo(
            type: AmmunitionType.slug,
            caliberMm: 6.35,
            grain: 34,
            bc: 0.08,
          ),
        ),
        isNull,
      );
    });

    test('#195: an old GA record loses its BC and gets the estimated G1', () {
      final catalog = UserCatalog.fromManualEntries([
        {
          'id': 'manual_ammo_ga',
          'kind': 'ammo',
          'platform': 'pcp',
          'brand': 'Test 18',
          'model': '',
          'caliberMm': 5.5,
          'grain': 18,
          'ammoType': 'pellet',
          'bc': 0.03,
          'bcModel': 'ga',
        },
      ]);
      final a = catalog.ammunition.single;
      expect(a.ballisticCoefficient, isNull);
      expect(a.ballisticModel, isNull);
      final filled = EstimatedBc.fill(a);
      expect(filled.ballisticModel, BallisticModel.g1);
      expect(filled.ballisticCoefficient, closeTo(0.027, 0.0005));
      expect([
        for (final m in BallisticModel.values) m.name,
      ], isNot(contains('ga')));
    });

    const table = [
      PressureVelocityPoint(bar: 120, mps: 255),
      PressureVelocityPoint(bar: 200, mps: 270),
    ];

    test('regulated: at or above the set pressure the profile velocity', () {
      final v = PcpPressure.velocity(
        profileMps: 270,
        regulatorBar: 150,
        tubeBar: 250,
        table: table,
      );
      expect(v.mps, 270);
      expect(v.regulatorBypassed, isFalse);
    });

    test('unregulated: linear between points, held at the ends', () {
      double at(double bar) =>
          PcpPressure.velocity(profileMps: 270, tubeBar: bar, table: table).mps;
      expect(at(160), closeTo(262.5, 1e-9));
      expect(at(100), 255);
      expect(at(300), 270);
      expect(PcpPressure.velocity(profileMps: 270, table: table).mps, 270);
    });
  });

  group('wind input path (#272)', () {
    test('clock hour → solver degrees (3 = from the right = 270°)', () {
      expect(WindClock.toDegrees(12), 0);
      expect(WindClock.toDegrees(3), 270);
      expect(WindClock.toDegrees(6), 180);
      expect(WindClock.toDegrees(9), 90);
      for (var h = 1; h <= 12; h++) {
        expect(WindClock.fromDegrees(WindClock.toDegrees(h)), h);
      }
    });

    test('Beaufort 0–7 limits are the WMO table, without gaps', () {
      const wmo = [
        (0.0, 0.2),
        (0.3, 1.5),
        (1.6, 3.3),
        (3.4, 5.4),
        (5.5, 7.9),
        (8.0, 10.7),
        (10.8, 13.8),
        (13.9, 17.1),
      ];
      for (var f = 0; f < wmo.length; f++) {
        final b = Beaufort.classes[f];
        expect(b.force, f);
        expect(b.minMps, wmo[f].$1);
        expect(b.maxMps, wmo[f].$2);
      }
      expect(Beaufort.classes[3].midMps, 4.4);
    });
  });

  group('other closed forms', () {
    test('powder: v = v0 (1 + k/100 · ΔT/15)', () {
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 1,
          referenceTempC: 21,
          todayTempC: 36,
        ),
        closeTo(1.01, 1e-12),
      );
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: null,
          referenceTempC: 21,
          todayTempC: 36,
        ),
        1,
      );
      expect(PowderTemperature.effectiveTempC(airC: 30, ammoC: 10), 10);
    });

    test('WEZ: 5-shot ES = 3.067 σ; ± is 2 σ', () {
      expect(
        Wez.groupSigmaMrad(0.03, 100),
        closeTo(math.atan(0.0003) * 1000 / 3.067, 1e-12),
      );
      expect(Wez.sigmaOfPlusMinus(2), 1);
      expect(Wez.atLeastOneHit(0.5, 3), closeTo(0.875, 1e-12));
    });

    test('DOPE ranges: sorted, unique; parallax: linear between marks', () {
      expect(DopeRanges.parse('300, 100;200 100'), [100, 200, 300]);
      final pts = const [
        ParallaxPoint(mark: 1, distanceM: 20),
        ParallaxPoint(mark: 3, distanceM: 60),
      ];
      expect(ParallaxRange.distanceAt(pts, 2), closeTo(40, 1e-12));
      expect(ParallaxRange.distanceAt(pts, 5), 60);
    });
  });
}
