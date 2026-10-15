// Formüller core'a taşındı (owner, 2026-10-15). Every function moved out of
// the screens is checked twice:
//  1. against a value calculated by hand (tools/formuller_core_reference.py
//     prints them; no other ballistic app is used), and
//  2. against the exact expression the screen used before the move, on a
//     grid of inputs, with == (not closeTo): the move must not change a
//     single bit.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/estimated_bc.dart';
import 'package:sniper_turk/core/low_pass.dart';
import 'package:sniper_turk/core/moving_target.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/core/stability.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/core/units.dart';
import 'package:sniper_turk/core/wez.dart';
import 'package:sniper_turk/core/wind_clock.dart';

const _sizes = [-0.37, -0.01, 0.0, 0.0001, 0.01, 0.0254, 0.1, 0.3, 1.0, 12.5];
const _ranges = [1.0, 25.0, 91.44, 100.0, 300.0, 457.2, 1000.0, 2500.0];
const _mrads = [-30.0, -1.0, -0.1, 0.0, 0.05, 0.1, 1.0, 7.3, 30.0];
const _typed = [-100.0, -3.5, -0.5, 0.0, 0.3, 1.0, 2.0, 12.7, 99.9, 100.0];

void main() {
  group('Units: linear ↔ mrad', () {
    test('hand values', () {
      // atan(0,01 / 100) · 1000 = 0,0999999997 (1 cm at 100 m ≈ 0,1 mrad).
      expect(
        Units.linearToMrad(0.01, 100),
        closeTo(0.09999999966666667, 1e-15),
      );
      // tan(0,1 / 1000) · 100 = 0,0100000000333 m.
      expect(
        Units.mradToLinear(0.1, 100),
        closeTo(0.010000000033333335, 1e-15),
      );
      expect(Units.linearToMrad(0, 100), 0);
      expect(Units.mradToLinear(0, 100), 0);
      // Round trip.
      expect(
        Units.mradToLinear(Units.linearToMrad(0.37, 450), 450),
        closeTo(0.37, 1e-12),
      );
    });

    test('bit-identical to the old inline expressions', () {
      for (final m in _sizes) {
        for (final r in _ranges) {
          expect(Units.linearToMrad(m, r), math.atan(m / r) * 1000);
          // Lateral wind (Hedef impact): -range · tan(w / 1000).
          expect(-Units.mradToLinear(m, r), -r * math.tan(m / 1000));
        }
      }
      for (final w in _mrads) {
        for (final r in _ranges) {
          expect(Units.mradToLinear(w, r), math.tan(w / 1000) * r);
          expect(Units.mradToLinear(w.abs(), r), r * math.tan(w.abs() / 1000));
        }
      }
    });
  });

  group('Units: small lengths', () {
    test('hand values', () {
      expect(Units.cmOrInchToMeters(10, metric: true), 0.1);
      expect(Units.cmOrInchToMeters(1, metric: false), closeTo(0.0254, 1e-15));
      expect(Units.inchesToMeters(1), 0.0254);
      expect(Units.inchesToMeters(4), closeTo(0.1016, 1e-15));
      // 0,0254 · 39,3700787 = 0,99999999898 (the rounded display factor).
      expect(
        Units.metersToInchesDisplay(0.0254),
        closeTo(0.99999999898, 1e-12),
      );
    });

    test('bit-identical to the old inline expressions', () {
      for (final v in _typed) {
        expect(Units.cmOrInchToMeters(v, metric: true), v / 100);
        expect(
          Units.cmOrInchToMeters(v, metric: false),
          UnitSystem.inchesToMillimeters(v) / 1000,
        );
        expect(Units.inchesToMeters(v), v * 0.0254);
        expect(Units.metersToInchesDisplay(v), v * 39.3700787);
        // Profil / calculators: mm → in, ft and fps.
        expect(UnitSystem.millimetersToInches(v), v / 25.4);
        expect(UnitSystem.metersToFeet(v), v / 0.3048);
        expect(UnitSystem.mpsToFps(v), v / 0.3048);
        expect(UnitSystem.fpsToMps(v), v * 0.3048);
      }
    });
  });

  group('Stability: spin drift and aerodynamic jump', () {
    test('hand values', () {
      // 1,25 · (2 + 1,2) · 1^1,83 = 4 in.
      expect(Stability.spinDriftInches(sg: 2, timeOfFlightS: 1), 4.0);
      // 4 · 0,5^1,83 = 1,12505848 in.
      expect(
        Stability.spinDriftInches(sg: 2, timeOfFlightS: 0.5),
        closeTo(1.1250584846888094, 1e-12),
      );
      // 4 in = 0,1016 m at 100 m: atan(0,001016) · 1000 = 1,01599965 mrad.
      final right = Stability.spinDriftMrad(
        sg: 2,
        timeOfFlightS: 1,
        rangeM: 100,
        rightHandTwist: true,
      );
      expect(right, closeTo(1.0159996504095177, 1e-12));
      expect(
        Stability.spinDriftMrad(
          sg: 2,
          timeOfFlightS: 1,
          rangeM: 100,
          rightHandTwist: false,
        ),
        -right,
      );
      // 31 mm bullet, 7,62 mm calibre: 31 / 7,62 = 4,0682 calibres.
      expect(
        Stability.lengthCalibers(31, 7.62),
        closeTo(4.0682414698162725, 1e-12),
      );
      // 0,01 · 2 − 0,0024 · 4 + 0,032 = 0,0424 MOA per mph.
      expect(
        Stability.aeroJumpMoaPerMph(sg: 2, lCal: 4),
        closeTo(0.0424, 1e-15),
      );
      // 10 mph from the right (270°), right twist: +0,424 MOA up
      // = 0,424 · π / 10800 · 1000 = 0,12333660 mrad.
      final up = Stability.aeroJumpMrad(
        sg: 2,
        lCal: 4,
        windMps: UnitSystem.mphToMps(10),
        windDirectionDeg: 270,
        rightHandTwist: true,
      );
      expect(up, closeTo(0.12333660047426595, 1e-12));
      // Wind from the left drops it; left twist mirrors it.
      expect(
        Stability.aeroJumpMrad(
          sg: 2,
          lCal: 4,
          windMps: UnitSystem.mphToMps(10),
          windDirectionDeg: 90,
          rightHandTwist: true,
        ),
        closeTo(-0.12333660047426595, 1e-12),
      );
      expect(
        Stability.aeroJumpMrad(
          sg: 2,
          lCal: 4,
          windMps: UnitSystem.mphToMps(10),
          windDirectionDeg: 270,
          rightHandTwist: false,
        ),
        closeTo(-0.12333660047426595, 1e-12),
      );
      // Headwind: no crosswind, no jump.
      expect(
        Stability.aeroJumpMrad(
          sg: 2,
          lCal: 4,
          windMps: 5,
          windDirectionDeg: 0,
          rightHandTwist: true,
        ),
        closeTo(0, 1e-15),
      );
    });

    test('bit-identical to the old inline expressions', () {
      for (final sg in [0.9, 1.3, 1.5, 2.1, 3.7]) {
        for (final tof in [0.0, 0.11, 0.5, 1.0, 1.73, 3.2]) {
          for (final r in _ranges) {
            for (final right in [true, false]) {
              final driftIn = 1.25 * (sg + 1.2) * math.pow(tof, 1.83);
              final m = driftIn * 0.0254 * (right ? 1 : -1);
              expect(
                Stability.spinDriftMrad(
                  sg: sg,
                  timeOfFlightS: tof,
                  rangeM: r,
                  rightHandTwist: right,
                ),
                math.atan(m / r) * 1000,
              );
            }
          }
        }
        for (final lCal in [2.5, 3.9, 4.0682414698162725, 5.6]) {
          for (final w in [0.0, 1.0, 3.3, 7.5]) {
            for (final dir in [0.0, 45.0, 90.0, 200.0, 270.0, 300.0]) {
              for (final right in [true, false]) {
                final fromRightMph =
                    -UnitSystem.mpsToMph(w) * math.sin(dir * math.pi / 180);
                final moaPerMph = 0.01 * sg - 0.0024 * lCal + 0.032;
                final moa = moaPerMph * fromRightMph * (right ? 1 : -1);
                expect(
                  Stability.aeroJumpMrad(
                    sg: sg,
                    lCal: lCal,
                    windMps: w,
                    windDirectionDeg: dir,
                    rightHandTwist: right,
                  ),
                  moa * math.pi / 10800 * 1000,
                );
              }
            }
          }
        }
      }
      for (final len in [5.0, 25.5, 31.0, 35.0]) {
        for (final cal in [4.5, 5.7, 6.71, 7.62, 8.59]) {
          expect(Stability.lengthCalibers(len, cal), len / 25.4 / (cal / 25.4));
        }
      }
    });
  });

  group('WindClock.crosswindFromRight', () {
    test('hand values', () {
      expect(WindClock.crosswindFromRight(5, 90), closeTo(-5, 1e-15));
      expect(WindClock.crosswindFromRight(5, 270), closeTo(5, 1e-15));
      expect(WindClock.crosswindFromRight(5, 0), closeTo(0, 1e-15));
      expect(WindClock.crosswindFromRight(5, 180), closeTo(0, 1e-14));
      // 30° off the right (clock 2 = 300°): sin 300° = −√3/2 → +4,33.
      expect(
        WindClock.crosswindFromRight(5, 300),
        closeTo(5 * math.sqrt(3) / 2, 1e-12),
      );
    });
  });

  group('MovingTarget', () {
    test('hand values', () {
      expect(MovingTarget.leadM(2, 0.5), 1.0);
      // 1 m at 100 m: atan(0,01) · 1000 = 9,99966669 mrad.
      expect(
        MovingTarget.leadMrad(2, 0.5, 100),
        closeTo(9.999666686665238, 1e-12),
      );
      expect(MovingTarget.leadM(0, 1.2), 0);
    });

    test('bit-identical to the old inline expressions', () {
      for (final speed in [0.3, 1.5, 2.0, 3.0, 10.0]) {
        for (final tof in [0.05, 0.42, 1.27, 2.4]) {
          for (final r in _ranges) {
            final leadM = speed * tof;
            expect(MovingTarget.leadM(speed, tof), leadM);
            expect(
              MovingTarget.leadMrad(speed, tof, r),
              math.atan(leadM / r) * 1000,
            );
          }
        }
      }
    });
  });

  group('Wez.targetRadiusMrad', () {
    test('hand values', () {
      // 10 cm ring at 100 m: atan(0,0005) · 1000 = 0,49999996 mrad.
      expect(
        Wez.targetRadiusMrad(0.1, 100),
        closeTo(0.49999995833333954, 1e-14),
      );
    });

    test('bit-identical to the old inline expression', () {
      for (final d in _sizes) {
        for (final r in _ranges) {
          expect(Wez.targetRadiusMrad(d, r), math.atan(d / 2 / r) * 1000);
        }
      }
    });
  });

  group('ScopeDialMath', () {
    test('horizontalRange: hand values', () {
      expect(ScopeDialMath.horizontalRange(100, 0), 100);
      expect(ScopeDialMath.horizontalRange(100, 60), closeTo(50, 1e-12));
      expect(ScopeDialMath.horizontalRange(100, -60), closeTo(50, 1e-12));
    });

    test('horizontalRange: bit-identical', () {
      for (final r in _ranges) {
        for (final a in [-45.0, -15.0, -1.0, 0.0, 3.0, 10.0, 30.0, 60.0]) {
          expect(
            ScopeDialMath.horizontalRange(r, a),
            r * math.cos(a * math.pi / 180),
          );
        }
      }
    });

    test('zeroOffsetMrad: hand values and limits', () {
      // 1 cm at 100 m ≈ 0,1 mrad; 1 in at 100 m = atan(0,000254) · 1000.
      expect(
        ScopeDialMath.zeroOffsetMrad(1, 100, metric: true),
        closeTo(0.09999999966666667, 1e-15),
      );
      expect(
        ScopeDialMath.zeroOffsetMrad(1, 100, metric: false),
        closeTo(0.25399999453764555, 1e-14),
      );
      expect(ScopeDialMath.zeroOffsetMrad(null, 100, metric: true), 0);
      expect(ScopeDialMath.zeroOffsetMrad(1, null, metric: true), 0);
      expect(ScopeDialMath.zeroOffsetMrad(1, 0, metric: true), 0);
      expect(ScopeDialMath.zeroOffsetMrad(1, -5, metric: true), 0);
      expect(ScopeDialMath.zeroOffsetMrad(100.5, 100, metric: true), 0);
      expect(ScopeDialMath.zeroOffsetMrad(-101, 100, metric: true), 0);
      expect(
        ScopeDialMath.zeroOffsetMrad(100, 100, metric: true),
        greaterThan(0),
      );
    });

    test('zeroOffsetMrad: bit-identical to both old copies', () {
      // Hedef (ballistics_screen) and Kule Doğrulama (truing_screen) had
      // the same rule written twice.
      double old(double? v, double? z, bool metric) {
        if (z == null || z <= 0 || v == null || v.abs() > 100) return 0;
        final m = metric ? v / 100 : UnitSystem.inchesToMillimeters(v) / 1000;
        return math.atan(m / z) * 1000;
      }

      for (final v in [null, ..._typed, 100.01, -150.0]) {
        for (final z in [null, -1.0, 0.0, ..._ranges]) {
          for (final metric in [true, false]) {
            expect(
              ScopeDialMath.zeroOffsetMrad(v, z, metric: metric),
              old(v, z, metric),
            );
          }
        }
      }
    });
  });

  group('LowPass', () {
    test('hand values', () {
      expect(LowPass.factor(0, 0.12), 0);
      // dt = τ: 1 − 1/e = 0,63212056.
      expect(LowPass.factor(0.12, 0.12), closeTo(0.6321205588285577, 1e-15));
      expect(LowPass.step(0, 10, 0.5), 5);
      expect(LowPass.step(3, 3, 0.7), 3);
    });

    test('bit-identical to the old inline expressions', () {
      for (final dt in [0.001, 0.016, 0.0167, 0.033, 0.12, 0.5]) {
        final k = 1 - math.exp(-dt / 0.12);
        expect(LowPass.factor(dt, 0.12), k);
        for (final x in [-12.3, -0.4, 0.0, 0.002, 7.9]) {
          for (final target in [-3.0, 0.0, 0.5, 44.4]) {
            var old = x;
            old += (target - old) * k;
            expect(LowPass.step(x, target, k), old);
          }
        }
      }
    });
  });

  group('EstimatedBc: sectional density', () {
    test('hand values', () {
      // 7,62 mm = 0,3 in: 168 / (7000 · 0,09) = 0,26667 lb/in².
      expect(
        EstimatedBc.sectionalDensity(168, 7.62),
        closeTo(0.26666666666666655, 1e-12),
      );
      // 0,2 · 7000 · 0,09 = 126 gr.
      expect(
        EstimatedBc.grainForSectionalDensity(0.2, 7.62),
        closeTo(126, 1e-9),
      );
    });

    test('bit-identical to the old Profil expressions', () {
      for (final cal in [4.5, 5.5, 5.7, 6.71, 7.62, 8.59, 9.0]) {
        final dIn = cal / 25.4;
        final k = 7000 * dIn * dIn;
        expect(EstimatedBc.grainForSectionalDensity(0.08, cal), 0.08 * k);
        expect(EstimatedBc.grainForSectionalDensity(0.45, cal), 0.45 * k);
        for (final grain in [18.1, 25.4, 77.0, 140.0, 168.0, 250.0]) {
          for (final bc in [0.03, 0.2, 0.462, 0.7]) {
            expect(
              EstimatedBc.sectionalDensity(grain, cal) / bc,
              grain / (7000 * dIn * dIn) / bc,
            );
          }
        }
      }
    });
  });
}
