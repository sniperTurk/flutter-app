import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  group('ScopeDialMath', () {
    test('clicks convert to angle and back', () {
      expect(ScopeDialMath.clicksToAngle(15, 0.1), closeTo(1.5, 1e-12));
      expect(ScopeDialMath.clicksToAngle(-8, 0.25), closeTo(-2.0, 1e-12));
      expect(ScopeDialMath.clicksFor(1.54, 0.1), 15);
      expect(ScopeDialMath.clicksFor(-1.54, 0.1), -15);
      expect(() => ScopeDialMath.clicksToAngle(1, 0), throwsArgumentError);
      expect(
        () => ScopeDialMath.clicksFor(double.nan, 0.1),
        throwsArgumentError,
      );
    });

    test('impact sits below the crosshair until the turret is dialled up', () {
      final none = ScopeDialMath.impactOffset(
        dialedUp: 0,
        requiredUp: 1.5,
        dialedRight: 0,
      );
      expect(none.up, closeTo(-1.5, 1e-12));
      final dialled = ScopeDialMath.impactOffset(
        dialedUp: 1.5,
        requiredUp: 1.5,
        dialedRight: 0.3,
      );
      expect(dialled.up, closeTo(0, 1e-12));
      expect(dialled.right, closeTo(0.3, 1e-12));
    });

    test('required windage shifts the impact sideways', () {
      // Wind pushes the shot right: the solver asks for a LEFT correction.
      final undialled = ScopeDialMath.impactOffset(
        dialedUp: 0,
        requiredUp: 0,
        dialedRight: 0,
        requiredRight: -0.8,
      );
      expect(undialled.right, closeTo(0.8, 1e-12));
      final dialled = ScopeDialMath.impactOffset(
        dialedUp: 0,
        requiredUp: 0,
        dialedRight: -0.8,
        requiredRight: -0.8,
      );
      expect(dialled.right, closeTo(0, 1e-12));
    });

    test('linear size at range uses the angular unit', () {
      expect(
        ScopeDialMath.linearAtRange(1, 100, AngularUnit.mrad),
        closeTo(0.1, 1e-6),
      );
      // 1 MOA ≈ 2.909 cm at 100 m.
      expect(
        ScopeDialMath.linearAtRange(1, 100, AngularUnit.moa),
        closeTo(0.02909, 1e-5),
      );
    });

    test('holdovers use only the far (descending) branch', () {
      // Correction first falls (projectile rising to the line of sight),
      // then rises with range.
      const samples = [
        CorrectionSample(10, 2.0),
        CorrectionSample(20, 0.0),
        CorrectionSample(30, -0.5),
        CorrectionSample(40, 0.0),
        CorrectionSample(50, 1.0),
        CorrectionSample(60, 2.0),
      ];
      final holds = ScopeDialMath.holdovers(
        dialedUp: 0,
        markAngles: const [-0.25, 1, 2, 5],
        samples: samples,
      );
      final byMark = {for (final h in holds) h.markAngle: h.rangeM};
      expect(byMark[-0.25], closeTo(35, 1e-9));
      expect(byMark[1], closeTo(50, 1e-9));
      expect(byMark[2], closeTo(60, 1e-9));
      // Beyond the sampled interval: never extrapolated.
      expect(byMark.containsKey(5), isFalse);
    });

    test('dialling elevation shifts every hold label farther out', () {
      final points = const BallisticEngine().solve(
        BallisticInput(
          muzzleVelocityMps: 270,
          grain: 18,
          zeroRangeM: 25,
          sightHeightMm: 60,
          rangesM: [for (var r = 1.0; r <= 400; r += 1) r],
        ),
      );
      final samples = [
        for (final p in points) ScopeDialMath.sampleOf(p, AngularUnit.mrad),
      ];
      final atZero = ScopeDialMath.holdovers(
        dialedUp: 0,
        markAngles: const [1],
        samples: samples,
      ).single;
      final dialled = ScopeDialMath.holdovers(
        dialedUp: 1,
        markAngles: const [1],
        samples: samples,
      ).single;
      expect(dialled.rangeM, greaterThan(atZero.rangeM));

      // With the exact correction dialled, the centre (mark 0) hits at that
      // range: the impact offset is zero there.
      final at100 = samples.firstWhere((s) => s.rangeM == 100).correction;
      final centre = ScopeDialMath.holdovers(
        dialedUp: at100,
        markAngles: const [0],
        samples: samples,
      ).single;
      expect(centre.rangeM, closeTo(100, 1.0));
    });

    test('unsorted samples are rejected', () {
      expect(
        () => ScopeDialMath.holdovers(
          dialedUp: 0,
          markAngles: const [1],
          samples: const [CorrectionSample(20, 0), CorrectionSample(10, 1)],
        ),
        throwsArgumentError,
      );
    });
  });
}
