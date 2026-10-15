// Pre-TestFlight audit 2026-10-15b — PR #324 (commit 4c51b77): formulas
// moved from the screens into lib/core/ "with identical numbers".
//
// Every vector below is checked twice:
//  1. against a hand calculation built from definitions only
//     (tools/denetim_2026_10_15b_core.py: 1 in = 25,4 mm, 1 ft = 0,3048 m,
//     1 mph = 0,44704 m/s, 1 gr = 64,79891 mg, 1 MOA = π/(180·60) rad,
//     1 mrad = 0,001 rad, 1 inHg = 3386,389 Pa, ICAO γ = 1,4 and
//     R = 287,05; Miller 2005 twist rule; Litz spin drift / jump fits) —
//     no other ballistic app is used;
//  2. against the exact inline expression the screen had at d3fdf29 (the
//     commit before #324), with == so a moved formula cannot change a bit.
//
// Result of the audit: no number changed by #324 was found; these tests
// pin that on concrete user-like vectors (inch paths, fps paths, Profil
// BC window, Su Terazisi easing, click math) as regression guards.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/estimated_bc.dart';
import 'package:sniper_turk/core/low_pass.dart';
import 'package:sniper_turk/core/moving_target.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/core/stability.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/core/units.dart';
import 'package:sniper_turk/data/cartridges.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/field_calc.dart';

String _tr(double v, int digits) =>
    v.toStringAsFixed(digits).replaceAll('.', ',');

void main() {
  group('Miller Sg (unchanged by #324) against the published formula', () {
    test('168 gr .300 in, 1,2 in long, 2800 fps, 15 °C, 1013,25 hPa', () {
      // d = 0,3 in, l = 4 cal; t = 40 cal (12 in) / 33,33 cal (10 in).
      // 30·168 / (40²·0,027·4·17) · 1 · 1 · 29,92/29,9212 = 1,71561428.
      expect(
        Stability.millerSg(
          grain: 168,
          caliberMm: 7.62,
          twistIn: 12,
          lengthMm: 30.48,
          velocityMps: UnitSystem.fpsToMps(2800),
          temperatureC: 15,
          pressureHpa: 1013.25,
        ),
        closeTo(1.7156142795049392, 1e-6),
      );
      expect(
        Stability.millerSg(
          grain: 168,
          caliberMm: 7.62,
          twistIn: 10,
          lengthMm: 30.48,
          velocityMps: UnitSystem.fpsToMps(2800),
          temperatureC: 15,
          pressureHpa: 1013.25,
        ),
        closeTo(2.470484562487113, 1e-6),
      );
    });

    test('subsonic 300 m/s uses the factor at the speed of sound', () {
      // Speed of sound at 15 °C: √(1,4·287,05·288,15) = 340,29 m/s.
      expect(
        Stability.millerSg(
          grain: 168,
          caliberMm: 7.62,
          twistIn: 12,
          lengthMm: 30.48,
          velocityMps: 300,
          temperatureC: 15,
          pressureHpa: 1013.25,
        ),
        closeTo(1.262736370091015, 1e-6),
      );
    });

    test('lengthCalibers is the same l Miller uses', () {
      expect(Stability.lengthCalibers(30.48, 7.62), closeTo(4.0, 1e-12));
      // Old Hedef expression, d3fdf29 ballistics_screen.dart.
      for (final (_, cal) in Cartridges.firearm) {
        for (final len in [20.0, 30.48, 33.7, 41.0]) {
          expect(
            Stability.lengthCalibers(len, cal),
            len / 25.4 / (cal / 25.4),
          );
        }
      }
    });
  });

  group('Hedef spin drift and aerodynamic jump (moved to Stability)', () {
    test('spin drift: Sg 1,8, 1,2 s, 800 m, right twist', () {
      // 1,25·3,0·1,2^1,83 = 5,2351960 in = 13,2974 cm at 800 m.
      const sg = 1.8, tof = 1.2, range = 800.0;
      final mrad = Stability.spinDriftMrad(
        sg: sg,
        timeOfFlightS: tof,
        rangeM: range,
        rightHandTwist: true,
      );
      expect(mrad, closeTo(0.1662174722983255, 1e-12));
      // Old inline (d3fdf29).
      final driftIn = 1.25 * (sg + 1.2) * math.pow(tof, 1.83);
      final oldM0 = driftIn * 0.0254 * 1;
      final oldMrad = math.atan(oldM0 / range) * 1000;
      expect(mrad, oldMrad);
      // Displayed cm and in (old: tan(|spin| / 1000) · range).
      final oldM = math.tan(oldMrad.abs() / 1000) * range;
      final newM = Units.mradToLinear(mrad.abs(), range);
      expect(newM, oldM);
      expect(newM * 100, closeTo(13.29739790632731, 1e-9));
      expect(_tr(newM * 100, 1), '13,3');
      expect(
        _tr(UnitSystem.millimetersToInches(newM * 1000), 1),
        _tr(UnitSystem.millimetersToInches(oldM * 1000), 1),
      );
      expect(_tr(UnitSystem.millimetersToInches(newM * 1000), 1), '5,2');
    });

    test('aerodynamic jump: Sg 1,8, l 4, 4 m/s from the right (270°)', () {
      // (0,018 − 0,0096 + 0,032)·(4 / 0,44704) MOA → mrad = 0,10515286.
      final up = Stability.aeroJumpMrad(
        sg: 1.8,
        lCal: 4,
        windMps: 4,
        windDirectionDeg: 270,
        rightHandTwist: true,
      );
      expect(up, closeTo(0.10515285996863953, 1e-12));
      final fromRightMph =
          -UnitSystem.mpsToMph(4) * math.sin(270 * math.pi / 180);
      final moa = (0.01 * 1.8 - 0.0024 * 4 + 0.032) * fromRightMph * 1;
      expect(up, moa * math.pi / 10800 * 1000);
    });
  });

  group('Sıfır ofseti inch path (Hedef and Kule Doğrulama)', () {
    test('2 in and 2 cm at a 100 m zero', () {
      // 2 in = 0,0508 m: atan(0,000508)·1000 = 0,50799996 mrad.
      expect(
        ScopeDialMath.zeroOffsetMrad(2, 100, metric: false),
        closeTo(0.5079999563011695, 1e-12),
      );
      expect(
        ScopeDialMath.zeroOffsetMrad(2, 100, metric: true),
        closeTo(0.1999999973333334, 1e-12),
      );
      // 5 clicks of 0,1 mrad for the inch value.
      expect(
        ScopeDialMath.clicksFor(
          ScopeDialMath.zeroOffsetMrad(2, 100, metric: false),
          0.1,
        ),
        5,
      );
    });

    test('same as the old Kule Doğrulama copy (non-null zero)', () {
      double oldTruing(double? v, double zeroM, bool metric) {
        if (zeroM <= 0 || v == null || v.abs() > 100) return 0;
        final m = metric ? v / 100 : UnitSystem.inchesToMillimeters(v) / 1000;
        return math.atan(m / zeroM) * 1000;
      }

      const typed = [null, -100.0, -2.5, 0.0, 0.4, 2.0, 50.0, 100.0, 101.0];
      for (final v in typed) {
        for (final z in [-10.0, 0.0, 25.0, 91.44, 100.0, 300.0]) {
          for (final metric in [true, false]) {
            expect(
              ScopeDialMath.zeroOffsetMrad(v, z, metric: metric),
              oldTruing(v, z, metric),
            );
          }
        }
      }
    });
  });

  group('Hareketli hedef lead', () {
    test('1,5 m/s, 0,9 s, 600 m: 1,35 m = 53,1 in = 2,25 mrad', () {
      expect(MovingTarget.leadM(1.5, 0.9), 1.5 * 0.9);
      expect(
        MovingTarget.leadMrad(1.5, 0.9, 600),
        closeTo(2.2499962031365333, 1e-12),
      );
      expect(
        MovingTarget.leadMrad(1.5, 0.9, 600),
        math.atan(1.5 * 0.9 / 600) * 1000,
      );
      final leadM = MovingTarget.leadM(1.5, 0.9);
      expect(_tr(leadM * 100, 0), '135');
      expect(_tr(UnitSystem.millimetersToInches(leadM * 1000), 1), '53,1');
    });
  });

  group('Profil BC plausibility and labels (moved to EstimatedBc)', () {
    test('grain window without catalog weights, 7,62 mm', () {
      // 0,08·7000·0,09 = 50,4 gr; 0,45·7000·0,09 = 283,5 gr.
      expect(
        EstimatedBc.grainForSectionalDensity(0.08, 7.62),
        closeTo(50.4, 1e-9),
      );
      expect(
        EstimatedBc.grainForSectionalDensity(0.45, 7.62),
        closeTo(283.5, 1e-9),
      );
    });

    test('sectional density 77 gr at 5,69 mm', () {
      expect(
        EstimatedBc.sectionalDensity(77, 5.69),
        closeTo(0.219197494448065, 1e-12),
      );
    });

    test('old and new agree for every firearm calibre in the list', () {
      for (final (_, cal) in Cartridges.firearm) {
        final dIn = cal / 25.4;
        final k = 7000 * dIn * dIn;
        expect(EstimatedBc.grainForSectionalDensity(0.08, cal), 0.08 * k);
        expect(EstimatedBc.grainForSectionalDensity(0.45, cal), 0.45 * k);
        for (final grain in [40.0, 77.0, 147.0, 168.0, 230.0]) {
          for (final bc in [0.1, 0.25, 0.462, 0.69]) {
            expect(
              EstimatedBc.sectionalDensity(grain, cal) / bc,
              grain / (7000 * dIn * dIn) / bc,
            );
          }
        }
        // Çap list dedupe key and label (profile_editor.dart).
        expect(
          UnitSystem.millimetersToInches(cal).toStringAsFixed(3),
          (cal / 25.4).toStringAsFixed(3),
        );
      }
    });

    test('diameter and barrel labels by hand', () {
      String inch(double mm) =>
          UnitSystem.millimetersToInches(mm).toStringAsFixed(3);
      expect(inch(7.82), '0.308');
      expect(inch(5.69), '0.224');
      expect(inch(6.71), '0.264');
      expect(inch(8.59), '0.338');
      expect(inch(6.35), '0.250');
      // 610 mm barrel = 24,016 in → "24 in namlu".
      final b = UnitSystem.millimetersToInches(610);
      expect(b, 610 / 25.4);
      expect(b.toStringAsFixed((b - b.round()).abs() < 0.05 ? 0 : 1), '24');
    });
  });

  group('Hesaplayıcılar (calculators_screen) fps / inch paths', () {
    test('Stadia: 18 in at 2 mil and 45 cm at 5 MOA', () {
      final sizeIn = Units.inchesToMeters(18);
      expect(sizeIn, 18 * 0.0254);
      expect(
        FieldCalc.distanceFromAngle(sizeIn, 2 * FieldCalc.radPerMil),
        closeTo(228.5996951999187, 1e-9),
      );
      expect(
        FieldCalc.distanceFromAngle(45 / 100, 5 * FieldCalc.radPerMoa),
        closeTo(309.3969912044573, 1e-9),
      );
    });

    test('Enerji: 168 gr at 2650 fps, and 3000 J needs 2436 fps', () {
      final v = UnitSystem.fpsToMps(2650);
      expect(v, 2650 * 0.3048);
      expect(FieldCalc.energyJ(168, v), closeTo(3551.14707760493, 1e-6));
      final need = FieldCalc.velocityForEnergyMps(168, 3000);
      expect(UnitSystem.mpsToFps(need), need / 0.3048);
      expect(UnitSystem.mpsToFps(need), closeTo(2435.6908878299773, 1e-6));
      expect(_tr(UnitSystem.mpsToFps(need), 0), '2436');
    });

    test('İki hız BC: velocity loss 2800 → 2400 fps = 121,9 m/s', () {
      double mps(double v, bool fps) => fps ? UnitSystem.fpsToMps(v) : v;
      const v1 = 2800.0, v2 = 2400.0;
      expect(mps(v1 - v2, true), (v1 - v2) * 0.3048);
      expect(mps(v1 - v2, true), closeTo(121.92, 1e-9));
      expect(_tr(mps(v1 - v2, true), 1), '121,9');
      // m/s mode: the old code multiplied by 1.0.
      for (final v in [0.1, 12.3, 853.44, 1000.0]) {
        expect(mps(v, false), v * 1.0);
        expect(mps(v, true), v * 0.3048);
      }
    });

    test('Hava lab: density altitude 1000 m = 3281 ft', () {
      expect(UnitSystem.metersToFeet(1000), 1000 / 0.3048);
      expect(UnitSystem.metersToFeet(1000), closeTo(3280.839895013123, 1e-9));
      expect(UnitSystem.metersToFeet(-250), -250 / 0.3048);
    });
  });

  group('Su Terazisi easing (moved to LowPass)', () {
    test('one 60 Hz frame and one second of frames', () {
      const tau = 0.12, dt = 1 / 60;
      final k = LowPass.factor(dt, tau);
      expect(k, 1 - math.exp(-dt / tau));
      expect(LowPass.step(0, 10, k), closeTo(1.296752741666095, 1e-12));
      // 60 frames of 1/60 s compose to one exponential over 1 s:
      // 10·(1 − e^(−1/0,12)) = 9,99759631.
      var x = 0.0, old = 0.0;
      for (var i = 0; i < 60; i++) {
        x = LowPass.step(x, 10, k);
        old += (10 - old) * k;
      }
      expect(x, old);
      expect(x, closeTo(9.997596305235806, 1e-9));
      // Negative tilt target, mixed frame times (old += form).
      var y = 3.0, oldY = 3.0;
      for (final f in [0.008, 0.016, 0.033, 0.016, 0.1]) {
        final kf = LowPass.factor(f, tau);
        y = LowPass.step(y, -4.5, kf);
        oldY += (-4.5 - oldY) * kf;
        expect(y, oldY);
      }
    });
  });

  group('Turret click math (scope_dial, unchanged by #324)', () {
    test('mount cant clicks by hand', () {
      // 20 MOA = 5,8178 mrad = 58 clicks of 0,1; = 80 clicks of ¼ MOA.
      expect(ScopeDialMath.mountCantClicks(20, 0.1, AngularUnit.mrad), 58);
      expect(ScopeDialMath.mountCantClicks(20, 0.25, AngularUnit.moa), 80);
      expect(ScopeDialMath.mountCantClicks(60, 0.25, AngularUnit.moa), 240);
      expect(ScopeDialMath.mountCantClicks(30, 0.1, AngularUnit.mrad), 87);
    });

    test('MOA ↔ mrad by definition', () {
      // 1 MOA = π/10800 rad = 0,29088821 mrad; 1 mrad = 3,43774677 MOA.
      expect(Units.moaToMrad(1), closeTo(0.29088820866572157, 1e-15));
      expect(
        ScopeDialMath.convert(1, AngularUnit.mrad, AngularUnit.moa),
        closeTo(3.4377467707849396, 1e-12),
      );
      // The two MOA factors in the code agree to rounding.
      for (final a in [0.25, 1.0, 7.5, 20.0, 60.0]) {
        expect(
          Units.moaToMrad(a),
          closeTo(AngularUnit.moa.toMrad(a), 1e-12),
        );
      }
      // Sıfır ofseti and Stadia convert inches two ways; same to rounding.
      for (final v in [0.5, 1.0, 2.0, 18.0, 99.9]) {
        expect(
          Units.cmOrInchToMeters(v, metric: false),
          closeTo(Units.inchesToMeters(v), 1e-15),
        );
      }
    });
  });
}
