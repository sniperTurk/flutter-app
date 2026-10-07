import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/tools/level_screen.dart';
import 'package:sniper_turk/tools/domain/tilt_math.dart';
import 'package:sniper_turk/tools/ports/level_calibration_store.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';
import 'package:sniper_turk/tools/state/level_controller.dart';

import 'support/tool_fakes.dart';

const _g = 9.80665;

/// Gravity for a phone lying screen-up whose readings are tilted by
/// [xDeg]/[yDeg] (device-frame angles, as the level reports them).
GravityVector _tilted(double xDeg, double yDeg) {
  double s(double d) => math.sin(d * math.pi / 180);
  final x = _g * s(xDeg);
  final y = _g * s(yDeg);
  return GravityVector(x, y, math.sqrt(_g * _g - x * x - y * y));
}

/// The phone has a constant device bias (camera bump + accelerometer
/// offset) of (-1.10°, +1.90°), like the TestFlight recording. The table is
/// truly level, so turning the phone 180° in place does not change it.
const _biasX = -1.10, _biasY = 1.90;

class _ThrowingStore implements LevelCalibrationStore {
  @override
  Future<Map<String, LevelBias>> load() async => {};
  @override
  Future<void> save(String pose, LevelBias? bias) async =>
      throw StateError('disk full');
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'flip calibration removes a constant device bias on a level table',
    () async {
      final tilt = TestTilt();
      final store = InMemoryLevelCalibrationStore();
      final c = LevelController(
        provider: tilt,
        calibrationStore: store,
        smoothing: 1,
      )..start();
      addTearDown(c.dispose);

      tilt.controller.add(TiltAvailable(_tilted(_biasX, _biasY)));
      await _settle();
      expect(TiltMath.isLevel(c.angles!), isFalse, reason: 'uncalibrated');

      expect(c.captureCalibration(flipped: false), isTrue);
      // Same level table, phone turned 180°: the device bias is unchanged.
      tilt.controller.add(TiltAvailable(_tilted(_biasX, _biasY)));
      await _settle();
      expect(c.captureCalibration(flipped: true), isTrue);
      await _settle();

      expect(c.angles!.xDeg, closeTo(0, 0.01));
      expect(c.angles!.yDeg, closeTo(0, 0.01));
      expect(TiltMath.isLevel(c.angles!), isTrue);

      // A real 1° slope is still measured after calibration.
      tilt.controller.add(TiltAvailable(_tilted(_biasX + 1, _biasY)));
      await _settle();
      expect(c.angles!.xDeg, closeTo(1, 0.02));

      final saved = await store.load();
      expect(saved['flat']!.xDeg, closeTo(_biasX, 0.01));
      expect(saved['flat']!.yDeg, closeTo(_biasY, 0.01));
    },
  );

  test('a stored calibration is restored when the level opens again', () async {
    final store = InMemoryLevelCalibrationStore();
    await store.save('flat', (xDeg: _biasX, yDeg: _biasY));

    final tilt = TestTilt();
    final c = LevelController(
      provider: tilt,
      calibrationStore: store,
      smoothing: 1,
    )..start();
    addTearDown(c.dispose);
    await _settle();
    tilt.controller.add(TiltAvailable(_tilted(_biasX, _biasY)));
    await _settle();

    expect(c.calibration.restored, isNotNull);
    expect(TiltMath.isLevel(c.angles!), isTrue);
  });

  test(
    'half a recalibration keeps the stored bias; clearing removes it',
    () async {
      final store = InMemoryLevelCalibrationStore();
      await store.save('flat', (xDeg: _biasX, yDeg: _biasY));
      final tilt = TestTilt();
      final c = LevelController(
        provider: tilt,
        calibrationStore: store,
        smoothing: 1,
      )..start();
      addTearDown(c.dispose);
      await _settle();
      tilt.controller.add(TiltAvailable(_tilted(0.3, 0.2)));
      await _settle();

      c.captureCalibration(flipped: false);
      await _settle();
      expect((await store.load())['flat'], isNotNull);

      c.clearCalibration(TiltMode.flat);
      await _settle();
      expect((await store.load())['flat'], isNull);
    },
  );

  test(
    'a failed save is reported, the session calibration still applies',
    () async {
      final tilt = TestTilt();
      final c = LevelController(
        provider: tilt,
        calibrationStore: _ThrowingStore(),
        smoothing: 1,
      )..start();
      addTearDown(c.dispose);
      tilt.controller.add(TiltAvailable(_tilted(_biasX, _biasY)));
      await _settle();
      c.captureCalibration(flipped: false);
      c.captureCalibration(flipped: true);
      await _settle();
      expect(c.calibrationSaveFailed, isTrue);
      expect(TiltMath.isLevel(c.angles!), isTrue);
    },
  );

  testWidgets('calibration steps from the bottom-left sheet work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tilt = TestTilt();
    final store = InMemoryLevelCalibrationStore();
    await tester.pumpWidget(
      host(
        const LevelScreen(),
        services: testServices(tilt: tilt, levelCalibration: store),
      ),
    );
    await tester.pump();
    tilt.controller.add(TiltAvailable(_tilted(_biasX, _biasY)));
    await tester.pump();
    await tester.pump();

    // No warning banner; the note only states the calibration status.
    expect(find.byKey(const Key('level-calibration-hint')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('level-pose'))).data,
      contains('kalibre değil'),
    );
    await tester.tap(find.byKey(const Key('level-calibrate-open')));
    await tester.pumpAndSettle();

    // Each reading averages ~2 s of still samples (100 after 15 skipped).
    Future<void> holdStill() async {
      for (var i = 0; i < 130; i++) {
        tilt.controller.add(TiltAvailable(_tilted(_biasX, _biasY)));
        await tester.pump();
      }
    }

    await tester.tap(find.byKey(const Key('level-calibrate-normal')));
    await tester.pump();
    expect(find.byKey(const Key('level-calibration-progress')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('level-calibration-status')))
          .data,
      contains('dokunmayın'),
    );
    await holdStill();
    expect(find.byKey(const Key('level-calibration-progress')), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('level-calibration-status')))
          .data,
      contains('180°'),
    );
    await tester.tap(find.byKey(const Key('level-calibrate-flipped')));
    await tester.pump();
    await holdStill();
    expect(
      tester
          .widget<Text>(find.byKey(const Key('level-calibration-status')))
          .data,
      contains('kaydedildi'),
    );
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('level-pose'))).data,
      contains('kalibre'),
    );
    expect(find.text('Seviyede'), findsOneWidget);
    expect((await store.load())['flat'], isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
