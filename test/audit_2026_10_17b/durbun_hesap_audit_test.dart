// Pre-TestFlight audit 2026-10-17b — Dürbün girişi (#367) and Profil
// summary labels (#377), main 8cc3aab against TestFlight 112 (9db11e3).
//
// Pure calculation guards (no finding): every value below is a hand
// calculation from the definitions, never another ballistic app.
//   1 MOA (true) = 1/60° = π/10800 rad = 0.290888… mrad
//   1 SMOA      = 1 in at 100 yd = 1/3600 rad = 0.277777… mrad
//   1 mrad      = 3.437747 MOA = 3.6 SMOA
//   SFP: one reticle mark covers calibration / current magnification.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/production_limits.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';

Map<String, dynamic> _profileJson({Object? mount}) => {
  'id': 'p1',
  'name': 'Denetim',
  'rifleId': 'r1',
  'ammunitionId': 'a1',
  'scopeId': 's1',
  'muzzleVelocityMps': 800.0,
  'zeroRangeM': 100.0,
  'sightHeightMm': 45.0,
  'angularUnit': 'mrad',
  'distanceUnit': 'meter',
  if (mount != null) 'mountCantMoa': mount,
};

void main() {
  group('Dürbün ayağı list (#367)', () {
    // The TestFlight 112 list (9db11e3 production_limits.dart).
    const tf112 = <double>[0, 10, 15, 20, 30, 40, 45, 60, 90];

    test('every TestFlight 112 value is still offered', () {
      for (final v in tf112) {
        expect(
          ProductionLimits.mountCantOptionsMoa,
          contains(v),
          reason: '$v',
        );
      }
    });

    test('0–60 MOA in 5 MOA steps plus 90, nothing else', () {
      expect(ProductionLimits.mountCantOptionsMoa, [
        for (var m = 0; m <= 60; m += 5) m.toDouble(),
        90.0,
      ]);
    });

    test('old and new values decode unchanged; others refused', () {
      const codec = ProfileCodec();
      for (final v in [...tf112, 5.0, 25.0, 35.0, 50.0, 55.0]) {
        final p = codec.decode(_profileJson(mount: v));
        expect(p.mountCantMoa, v);
        // Round trip keeps it.
        expect(codec.decode(codec.encode(p)).mountCantMoa, v);
      }
      // A profile saved before the field existed is a normal mount.
      expect(codec.decode(_profileJson()).mountCantMoa, 0);
      for (final bad in [7.0, 12.5, -5.0, 120.0]) {
        expect(
          () => codec.decode(_profileJson(mount: bad)),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });

  group('mount click gain = floor(mount angle / click), hand values', () {
    // Hand table: mount MOA → clicks, from 1 MOA = π/10.8 mrad.
    //   0,1 MRAD : MOA × 2.908882 → floor
    //   0,05 MRAD: MOA × 5.817764 → floor
    //   1/4 MOA  : MOA × 4; 1/8 MOA: MOA × 8
    //   1/4 SMOA : MOA × 1.047198 / 0.25 = MOA × 4.188790 → floor
    const table = <int, List<int>>{
      // mount: [0,1 MRAD, 0,05 MRAD, 1/4 MOA, 1/8 MOA, 1/4 SMOA]
      5: [14, 29, 20, 40, 20],
      10: [29, 58, 40, 80, 41],
      15: [43, 87, 60, 120, 62],
      20: [58, 116, 80, 160, 83],
      25: [72, 145, 100, 200, 104],
      30: [87, 174, 120, 240, 125],
      35: [101, 203, 140, 280, 146],
      40: [116, 232, 160, 320, 167],
      45: [130, 261, 180, 360, 188],
      50: [145, 290, 200, 400, 209],
      55: [159, 319, 220, 440, 230],
      60: [174, 349, 240, 480, 251],
      90: [261, 523, 360, 720, 376],
    };
    for (final MapEntry(key: moa, value: want) in table.entries) {
      final m = moa.toDouble();
      test('$moa MOA', () {
        expect(
          ScopeDialMath.mountCantClicks(m, 0.1, AngularUnit.mrad),
          want[0],
        );
        expect(
          ScopeDialMath.mountCantClicks(m, 0.05, AngularUnit.mrad),
          want[1],
        );
        expect(
          ScopeDialMath.mountCantClicks(m, 0.25, AngularUnit.moa),
          want[2],
        );
        expect(
          ScopeDialMath.mountCantClicks(m, 0.125, AngularUnit.moa),
          want[3],
        );
        expect(
          ScopeDialMath.mountCantClicks(m, 0.25, AngularUnit.smoa),
          want[4],
        );
      });
    }

    test('0 MOA gives no gain (mount 0 = TestFlight 112 numbers)', () {
      for (final (click, unit) in [
        (0.1, AngularUnit.mrad),
        (0.05, AngularUnit.mrad),
        (0.25, AngularUnit.moa),
        (0.125, AngularUnit.moa),
        (0.5, AngularUnit.moa),
        (0.25, AngularUnit.smoa),
      ]) {
        expect(ScopeDialMath.mountCantClicks(0, click, unit), 0);
      }
    });

    test('the table agrees with the angle definitions', () {
      const mradPerMoa = math.pi / 10.8;
      for (final moa in ProductionLimits.mountCantOptionsMoa) {
        final mrad = moa * mradPerMoa;
        expect(
          ScopeDialMath.mountCantClicks(m, 0.1, AngularUnit.mrad),
          (mrad / 0.1 + 1e-9).floor(),
        );
        expect(
          ScopeDialMath.mountCantClicks(m, 0.25, AngularUnit.smoa),
          (mrad / (1000 / 3600) / 0.25 + 1e-9).floor(),
        );
      }
    });
  });

  group('click value + unit → turret clicks (Hedef, DOPE)', () {
    test('unit definitions', () {
      expect(AngularUnit.moa.mradPerUnit, closeTo(0.2908882087, 1e-10));
      expect(AngularUnit.smoa.mradPerUnit, closeTo(0.2777777778, 1e-10));
      expect(
        ScopeDialMath.convert(1, AngularUnit.mrad, AngularUnit.moa),
        closeTo(3.437747, 1e-6),
      );
      expect(
        ScopeDialMath.convert(1, AngularUnit.mrad, AngularUnit.smoa),
        closeTo(3.6, 1e-12),
      );
    });

    test('every Klik değeri of the typed list counts clicks by hand', () {
      // correction → clicks = round(correction / click)
      expect(ScopeDialMath.clicksFor(3.27, 0.1), 33); // 32.7
      expect(ScopeDialMath.clicksFor(3.27, 0.05), 65); // 65.4
      expect(ScopeDialMath.clicksFor(11.3, 0.25), 45); // 45.2
      expect(ScopeDialMath.clicksFor(11.3, 0.125), 90); // 90.4
      expect(ScopeDialMath.clicksFor(11.3, 0.5), 23); // 22.6
      expect(ScopeDialMath.clicksFor(-1.04, 0.1), -10); // -10.4
    });
  });

  group('FFP / SFP and magnification → reticle holds', () {
    test('FFP marks are true at every magnification', () {
      for (final mag in [5.0, 12.0, 25.0]) {
        expect(
          ScopeDialMath.reticleSubtension(
            firstFocalPlane: true,
            magnification: mag,
            calibrationMagnification: 25,
          ),
          1.0,
        );
      }
    });

    test('SFP marks scale with calibration / magnification', () {
      expect(
        ScopeDialMath.reticleSubtension(
          firstFocalPlane: false,
          magnification: 12,
          calibrationMagnification: 24,
        ),
        2.0,
      );
      expect(
        ScopeDialMath.reticleSubtension(
          firstFocalPlane: false,
          magnification: 25,
          calibrationMagnification: 25,
        ),
        1.0,
      );
      // A catalog-only minimum (0,75x, offered since #367) on a 0,75-6x
      // SFP scope calibrated at 6x: one mark = 8 units.
      expect(
        ScopeDialMath.reticleSubtension(
          firstFocalPlane: false,
          magnification: 0.75,
          calibrationMagnification: 6,
        ),
        8.0,
      );
    });
  });
}
