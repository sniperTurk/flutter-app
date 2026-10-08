import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/tools/domain/tilt_math.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';
import 'package:sniper_turk/tools/state/level_controller.dart';

import 'support/tool_fakes.dart';

const _g = 9.80665;

GravityVector _tilted(double xDeg, double yDeg) {
  double s(double d) => math.sin(d * math.pi / 180);
  final x = _g * s(xDeg);
  final y = _g * s(yDeg);
  return GravityVector(x, y, math.sqrt(_g * _g - x * x - y * y));
}

/// Deterministic accelerometer noise of about ±0.03 m/s² (~±0.2°).
List<GravityVector> _noisy(GravityVector base, int n, {int seed = 7}) {
  final r = math.Random(seed);
  double j() => (r.nextDouble() - 0.5) * 0.06;
  return [
    for (var i = 0; i < n; i++)
      GravityVector(base.x + j(), base.y + j(), base.z + j()),
  ];
}

double _spreadDeg(List<GravityVector> out) {
  final xs = [for (final g in out) TiltMath.angles(g, TiltMode.flat)!.xDeg];
  return xs.reduce(math.max) - xs.reduce(math.min);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('GravityFilter.adaptive', () {
    test('holds a still reading steadier than the old fixed filter', () {
      final samples = _noisy(_tilted(0.3, 0), 400);
      final fixed = GravityFilter(alpha: 0.15);
      final adaptive = GravityFilter.adaptive();
      final f = [for (final s in samples) fixed.add(s)].skip(150).toList();
      final a = [for (final s in samples) adaptive.add(s)].skip(150).toList();
      expect(_spreadDeg(a), lessThan(_spreadDeg(f) * 0.6));
      expect(TiltMath.angles(a.last, TiltMode.flat)!.xDeg, closeTo(0.3, 0.05));
    });

    test('follows a real move quickly', () {
      final adaptive = GravityFilter.adaptive();
      for (var i = 0; i < 50; i++) {
        adaptive.add(_tilted(0, 0));
      }
      GravityVector? out;
      for (var i = 0; i < 10; i++) {
        out = adaptive.add(_tilted(10, 0)); // 10 samples = ~0.2 s
      }
      expect(TiltMath.angles(out!, TiltMode.flat)!.xDeg, greaterThan(9));
    });
  });

  group('StillAverager', () {
    test('skips the settle samples and averages the rest', () {
      final a = StillAverager(settleSamples: 3, samples: 4);
      for (final v in [
        const GravityVector(5, 5, 5), // tap jolt, skipped
        const GravityVector(5, 5, 5),
        const GravityVector(5, 5, 5),
        const GravityVector(0.10, 0, 9.8),
        const GravityVector(0.12, 0, 9.8),
        const GravityVector(0.08, 0, 9.8),
      ]) {
        expect(a.add(v), isFalse);
      }
      expect(a.add(const GravityVector(0.10, 0, 9.8)), isTrue);
      expect(a.mean!.x, closeTo(0.10, 1e-9));
      expect(a.restarts, 0);
    });

    test('moving restarts the collection', () {
      final a = StillAverager(settleSamples: 0, samples: 3);
      a.add(const GravityVector(0, 0, 9.8));
      a.add(const GravityVector(0, 0, 9.8));
      a.add(const GravityVector(1, 0, 9.75)); // moved
      expect(a.restarts, 1);
      expect(a.isComplete, isFalse);
      a.add(const GravityVector(1, 0, 9.75));
      a.add(const GravityVector(1, 0, 9.75));
      expect(a.add(const GravityVector(1, 0, 9.75)), isTrue);
      expect(a.mean!.x, closeTo(1, 1e-9));
    });
  });

  group('averaged calibration capture', () {
    test('a noisy still phone gives an accurate bias', () async {
      final tilt = TestTilt();
      final c = LevelController(
        provider: tilt,
        calibrationSamples: 60,
        calibrationSettleSamples: 5,
      )..start();
      addTearDown(c.dispose);
      tilt.controller.add(TiltAvailable(_tilted(-1.1, 1.9)));
      await _settle();

      for (final flipped in [false, true]) {
        final done = c.startCalibrationCapture(flipped: flipped);
        expect(c.capturingCalibration, isTrue);
        for (final s in _noisy(_tilted(-1.1, 1.9), 70, seed: flipped ? 2 : 1)) {
          tilt.controller.add(TiltAvailable(s));
        }
        await _settle();
        expect(await done, isTrue);
      }
      final bias = c.calibration.bias!;
      expect(bias.xDeg, closeTo(-1.1, 0.03));
      expect(bias.yDeg, closeTo(1.9, 0.03));
      expect(c.capturingCalibration, isFalse);
    });

    test('a phone that never stays still stores nothing', () async {
      final tilt = TestTilt();
      final c = LevelController(
        provider: tilt,
        calibrationSamples: 10,
        calibrationSettleSamples: 0,
      )..start();
      addTearDown(c.dispose);
      tilt.controller.add(TiltAvailable(_tilted(0, 0)));
      await _settle();
      final done = c.startCalibrationCapture(flipped: false);
      for (var i = 0; i < 80; i++) {
        tilt.controller.add(TiltAvailable(_tilted(i.isEven ? 0 : 3, 0)));
      }
      await _settle();
      expect(await done, isFalse);
      expect(c.calibration.normal, isNull);
    });

    test('a pose change cancels the reading', () async {
      final tilt = TestTilt();
      final c = LevelController(provider: tilt)..start();
      addTearDown(c.dispose);
      tilt.controller.add(TiltAvailable(_tilted(0, 0)));
      await _settle();
      final done = c.startCalibrationCapture(flipped: false);
      tilt.controller.add(const TiltAvailable(GravityVector(0, 9.81, 0)));
      await _settle();
      expect(await done, isFalse);
      expect(c.mode, TiltMode.upright);
    });
  });

  group('display dead band', () {
    test('a still, noisy phone shows a still number', () async {
      final tilt = TestTilt();
      final c = LevelController(provider: tilt)..start();
      addTearDown(c.dispose);
      final shown = <double>{};
      for (final s in _noisy(_tilted(0.3, 0), 300, seed: 11)) {
        tilt.controller.add(TiltAvailable(s));
        await _settle();
        shown.add(
          double.parse(TiltMath.format(c.angles!.xDeg).replaceAll(',', '.')),
        );
      }
      // The first samples converge; after that the read-out holds still.
      final tail = <double>{};
      for (final s in _noisy(_tilted(0.3, 0), 300, seed: 12)) {
        tilt.controller.add(TiltAvailable(s));
        await _settle();
        tail.add(
          double.parse(TiltMath.format(c.angles!.xDeg).replaceAll(',', '.')),
        );
      }
      // What the user reads (0.1° text) does not change at all.
      expect(tail.length, 1);
      expect(tail.first, closeTo(0.3, 0.1));
    });

    test('a real change past the band shows at once', () async {
      final tilt = TestTilt();
      final c = LevelController(provider: tilt, smoothing: 1)..start();
      addTearDown(c.dispose);
      tilt.controller.add(TiltAvailable(_tilted(0, 0)));
      await _settle();
      tilt.controller.add(TiltAvailable(_tilted(0.06, 0)));
      await _settle();
      expect(c.angles!.xDeg, closeTo(0, 1e-9), reason: 'inside the band');
      tilt.controller.add(TiltAvailable(_tilted(0.5, 0)));
      await _settle();
      expect(c.angles!.xDeg, closeTo(0.5, 1e-6));
      expect(c.liveAngles!.xDeg, closeTo(0.5, 1e-6));
    });

    test('setting a reference shows exactly zero, not a held value', () async {
      final tilt = TestTilt();
      final c = LevelController(provider: tilt, smoothing: 1)..start();
      addTearDown(c.dispose);
      tilt.controller.add(TiltAvailable(_tilted(0.03, 0)));
      await _settle();
      expect(c.angles!.xDeg, closeTo(0.03, 1e-6));
      c.setReferenceHere();
      expect(c.angles!.xDeg, closeTo(0, 1e-9));
    });

    test(
      'set back on the calibration spot it settles to 0,0, not a held -0,1',
      () async {
        // TestFlight 2026-10-08: lifted and set back on the same spot the
        // read-out stayed at the value passed while setting it down.
        final tilt = TestTilt();
        final c = LevelController(provider: tilt, smoothing: 1)..start();
        addTearDown(c.dispose);
        String shownX() => TiltMath.format(c.angles!.xDeg);

        tilt.controller.add(TiltAvailable(_tilted(-0.12, 0)));
        await _settle();
        expect(shownX(), '-0,1');
        // It comes to rest at -0.03 (within the dead band of -0.12).
        // The first rest sample starts the stillness count.
        for (var i = 0; i < 40; i++) {
          tilt.controller.add(TiltAvailable(_tilted(-0.03, 0)));
          await _settle();
        }
        expect(shownX(), '-0,1', reason: 'not yet still long enough');
        tilt.controller.add(TiltAvailable(_tilted(-0.03, 0)));
        await _settle();
        expect(c.angles!.xDeg, closeTo(-0.03, 1e-6));
        expect(shownX(), '0,0');

        // Still with tiny noise: the number does not move again.
        final shown = <String>{};
        for (var i = 0; i < 200; i++) {
          tilt.controller.add(TiltAvailable(_tilted(i.isEven ? -0.01 : -0.05, 0)));
          await _settle();
          shown.add(shownX());
        }
        expect(shown, {'0,0'});

        // A real move shows at once and later settles again.
        tilt.controller.add(TiltAvailable(_tilted(0.5, 0)));
        await _settle();
        expect(c.angles!.xDeg, closeTo(0.5, 1e-6));
        for (var i = 0; i < 41; i++) {
          tilt.controller.add(TiltAvailable(_tilted(0.43, 0)));
          await _settle();
        }
        expect(c.angles!.xDeg, closeTo(0.43, 1e-6));
      },
    );
  });
}
