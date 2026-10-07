// Lifecycle tests listed as missing in release/RELEASE_CHECKLIST.md (B3):
// Weather timer/resume, camera init-failure/cleanup, orientation lifecycle,
// Level reference/reset. All platform access goes through the fakes in
// test/support/tool_fakes.dart; the orientation lock is observed on the
// SystemChannels.platform channel, not on a real device.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/tools/compass_screen.dart';
import 'package:sniper_turk/features/tools/level_screen.dart';
import 'package:sniper_turk/features/tools/sight_height_screen.dart';
import 'package:sniper_turk/features/tools/weather_screen.dart';
import 'package:sniper_turk/tools/domain/tilt_math.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';
import 'package:sniper_turk/tools/state/level_controller.dart';

import 'support/tool_fakes.dart';

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// Records every SystemChrome.setPreferredOrientations call as the list of
/// orientation names the framework sent to the platform.
List<List<String>> _recordOrientations(WidgetTester tester) {
  final calls = <List<String>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        calls.add([
          for (final o in call.arguments as List<Object?>)
            o.toString().split('.').last,
        ]);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

const _allOrientations = [
  'portraitUp',
  'landscapeLeft',
  'portraitDown',
  'landscapeRight',
];

Future<void> _resumeApp(WidgetTester tester) async {
  // A legal background -> foreground sequence.
  for (final s in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(s.toString()),
      (_) {},
    );
  }
  await tester.pump();
}

void main() {
  group('Hava & Rüzgâr — age timer and resume', () {
    testWidgets('badge turns stale by itself after 30 min, without refetch', (
      tester,
    ) async {
      final clock = TestClock(DateTime.utc(2026, 10, 3, 12));
      final weather = TestWeather(observation(fetchedAt: clock.current));
      await tester.pumpWidget(
        host(
          const WeatherScreen(),
          services: testServices(weather: weather, clock: clock),
        ),
      );
      await tester.tap(find.text('Hava verisini getir'));
      await tester.pumpAndSettle();
      expect(find.text('Güncel'), findsOneWidget);

      clock.current = clock.current.add(const Duration(minutes: 31));
      await tester.pump(const Duration(minutes: 1)); // periodic age timer
      expect(find.text('Güncel'), findsNothing);
      expect(find.text('Bayat veri'), findsOneWidget);
      // The timer only re-evaluates the age; it never calls the service.
      expect(weather.calls, 1);
      await _unmount(tester);
    });

    testWidgets('returning to the foreground re-evaluates the age at once', (
      tester,
    ) async {
      final clock = TestClock(DateTime.utc(2026, 10, 3, 12));
      final weather = TestWeather(observation(fetchedAt: clock.current));
      await tester.pumpWidget(
        host(
          const WeatherScreen(),
          services: testServices(weather: weather, clock: clock),
        ),
      );
      await tester.tap(find.text('Hava verisini getir'));
      await tester.pumpAndSettle();
      expect(find.text('Güncel'), findsOneWidget);

      // Seven hours in the background: no timer tick is pumped here, only
      // the resume event, so the change must come from the lifecycle hook.
      clock.current = clock.current.add(const Duration(hours: 7));
      await _resumeApp(tester);
      expect(find.text('Güncel'), findsNothing);
      expect(find.text('Güncel değil'), findsOneWidget);
      expect(weather.calls, 1);
      await _unmount(tester);
    });

    testWidgets('timer and observer are released when the screen closes', (
      tester,
    ) async {
      final clock = TestClock(DateTime.utc(2026, 10, 3, 12));
      final weather = TestWeather(observation(fetchedAt: clock.current));
      await tester.pumpWidget(
        host(
          const WeatherScreen(),
          services: testServices(weather: weather, clock: clock),
        ),
      );
      await tester.tap(find.text('Hava verisini getir'));
      await tester.pumpAndSettle();
      await _unmount(tester);

      // No setState-after-dispose and no pending timer after closing.
      clock.current = clock.current.add(const Duration(hours: 1));
      await tester.pump(const Duration(minutes: 5));
      await _resumeApp(tester);
      expect(tester.takeException(), isNull);
      expect(weather.calls, 1);
    });
  });

  group('Kamera — init failure and cleanup', () {
    Future<void> openSideCapture(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('sight-capture-side')));
      await tester.tap(find.byKey(const Key('sight-capture-side')));
    }

    NavigatorState navigator(WidgetTester tester) =>
        tester.state<NavigatorState>(find.byType(Navigator).first);

    testWidgets('unexpected plugin error shows a message, not a crash', (
      tester,
    ) async {
      final camera = TestCamera(error: StateError('plugin init failed'));
      await tester.pumpWidget(
        host(const SightHeightScreen(), services: testServices(camera: camera)),
      );
      await openSideCapture(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(camera.opened, 1);
      expect(find.text('Kamera kullanılamıyor.'), findsOneWidget);
      expect(find.byKey(const Key('sight-shutter')), findsNothing);
      // Settings is offered only for a permanent permission denial.
      expect(find.text('Ayarları aç'), findsNothing);
    });

    testWidgets('leaving the capture page disposes the camera session', (
      tester,
    ) async {
      final camera = TestCamera();
      await tester.pumpWidget(
        host(const SightHeightScreen(), services: testServices(camera: camera)),
      );
      await openSideCapture(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sight-shutter')), findsOneWidget);
      expect(camera.disposed, 0);

      navigator(tester).pop();
      await tester.pumpAndSettle();
      expect(camera.opened, 1);
      expect(camera.disposed, 1);
    });

    testWidgets('closing before the camera opens still disposes the session', (
      tester,
    ) async {
      final camera = TestCamera()..hold = Completer<void>();
      await tester.pumpWidget(
        host(const SightHeightScreen(), services: testServices(camera: camera)),
      );
      await openSideCapture(tester);
      // The spinner animates forever, so settle by time, not pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      navigator(tester).pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      camera.hold!.complete(); // the open call finishes after the page is gone
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(camera.opened, 1);
      expect(camera.disposed, 1);
    });
  });

  group('Ekran yönü — lock and restore', () {
    testWidgets('Su Terazisi locks portrait and restores on close', (
      tester,
    ) async {
      final calls = _recordOrientations(tester);
      await tester.pumpWidget(host(const LevelScreen()));
      await tester.pump();
      expect(calls, [
        ['portraitUp'],
      ]);
      await _unmount(tester);
      expect(calls.last, unorderedEquals(_allOrientations));
    });

    testWidgets('Pusula locks portrait and restores on close', (tester) async {
      final calls = _recordOrientations(tester);
      await tester.pumpWidget(host(const CompassScreen()));
      await tester.pump();
      expect(calls.first, ['portraitUp']);
      await _unmount(tester);
      expect(calls.last, unorderedEquals(_allOrientations));
    });

    testWidgets('side photo forces landscape and restores when popped', (
      tester,
    ) async {
      final calls = _recordOrientations(tester);
      await tester.pumpWidget(host(const SightHeightScreen()));
      await tester.ensureVisible(find.byKey(const Key('sight-capture-side')));
      await tester.tap(find.byKey(const Key('sight-capture-side')));
      await tester.pumpAndSettle();
      expect(calls.last, unorderedEquals(['landscapeLeft', 'landscapeRight']));

      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(calls.last, unorderedEquals(_allOrientations));
    });
  });

  group('Su Terazisi — reference set and clear', () {
    testWidgets('reference zeroes a tilted surface; Temizle restores it', (
      tester,
    ) async {
      final tilt = TestTilt();
      await tester.pumpWidget(
        host(const LevelScreen(), services: testServices(tilt: tilt)),
      );
      await tester.pump();
      tilt.controller.add(const TiltAvailable(GravityVector(2, 0, 9.6)));
      await tester.pump();
      await tester.pump(); // stream events are delivered asynchronously
      String state() =>
          tester.widget<Text>(find.byKey(const Key('level-state'))).data!;
      String pose() =>
          tester.widget<Text>(find.byKey(const Key('level-pose'))).data!;
      expect(state(), 'Eğik');
      expect(pose(), isNot(contains('referans etkin')));

      // Reference controls live in the settings sheet of the bottom bar.
      await tester.tap(find.byKey(const Key('level-calibrate-open')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Referans ayarı etkin'), findsNothing);

      final clear = find.byKey(const Key('level-clear-reference'));
      // Nothing to clear yet.
      await tester.tap(clear, warnIfMissed: false);
      await tester.pump();
      expect(state(), 'Eğik');

      await tester.tap(find.byKey(const Key('level-set-reference')));
      await tester.pump();
      expect(state(), 'Seviyede');
      expect(pose(), contains('referans etkin'));
      expect(find.textContaining('Referans ayarı etkin'), findsOneWidget);

      await tester.tap(clear);
      await tester.pump();
      expect(state(), 'Eğik');
      expect(pose(), isNot(contains('referans etkin')));
      expect(find.textContaining('Referans ayarı etkin'), findsNothing);
      await _unmount(tester);
    });

    test(
      'reference is dropped on a pose change; calibration is kept',
      () async {
        final tilt = TestTilt();
        final c = LevelController(provider: tilt)..start();
        addTearDown(c.dispose);
        tilt.controller.add(const TiltAvailable(GravityVector(2, 0, 9.6)));
        await Future<void>.delayed(Duration.zero);
        expect(c.mode, TiltMode.flat);

        c.setReferenceHere();
        expect(c.hasOffset, isTrue);
        expect(TiltMath.isLevel(c.angles!), isTrue);
        expect(c.captureCalibration(flipped: false), isTrue);

        c.setMode(TiltMode.upright);
        expect(c.hasOffset, isFalse);
        expect(c.autoMode, isFalse);
        // Per-mode flip calibration survives the switch.
        expect(c.calibrationFor(TiltMode.flat).normal, isNotNull);
      },
    );

    test('reference needs a reading; without one nothing is stored', () {
      final c = LevelController(provider: TestTilt())..start();
      addTearDown(c.dispose);
      c.setReferenceHere();
      expect(c.hasOffset, isFalse);
      expect(c.captureCalibration(flipped: true), isFalse);
    });

    test('lock freezes the shown angles until released', () async {
      final tilt = TestTilt();
      final c = LevelController(provider: tilt, smoothing: 1)..start();
      addTearDown(c.dispose);
      tilt.controller.add(const TiltAvailable(GravityVector(0, 0, 9.81)));
      await Future<void>.delayed(Duration.zero);
      final frozen = c.angles!;
      c.toggleLock();
      expect(c.locked, isTrue);

      tilt.controller.add(const TiltAvailable(GravityVector(2, 0, 9.6)));
      await Future<void>.delayed(Duration.zero);
      expect(c.angles!.xDeg, frozen.xDeg);
      expect(c.angles!.yDeg, frozen.yDeg);
      expect(c.liveAngles!.xDeg, isNot(frozen.xDeg));

      c.toggleLock();
      expect(c.locked, isFalse);
      expect(c.angles!.xDeg, c.liveAngles!.xDeg);
    });
  });
}
