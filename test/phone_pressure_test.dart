// Ö4 — "Basıncı telefondan al": the phone barometer (Core Motion
// CMAltimeter through sensors_plus) is read ONLY when the button is pressed
// (owner rule); without a barometer it quietly says "okunamadı".
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/adapters/sensors_plus_pressure_sensor.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

BarometerEvent _event(double hpa) => BarometerEvent(hpa, DateTime(2026));

String _pressureText(WidgetTester tester) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(BallisticsFieldKeys.pressure),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Future<void> _pump(WidgetTester tester, TestPressure pressure) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      const Scaffold(
        body: BallisticsScreen(
          profile: _profile,
          view: BallisticsView.environment,
          autoWeather: true,
        ),
      ),
      services: testServices(
        location: TestLocation(const LocationFix(39.9, 32.8)),
        pressure: pressure,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester) async {
  final button = find.byKey(const Key('environment-phone-pressure'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('SensorsPlusPressureSensor', () {
    test('nothing is subscribed before read()', () async {
      var listened = false;
      final controller = StreamController<BarometerEvent>(
        onListen: () => listened = true,
      );
      final sensor = SensorsPlusPressureSensor(source: () => controller.stream);
      await Future<void>.delayed(Duration.zero);
      expect(listened, isFalse);
      unawaited(sensor.read());
      await Future<void>.delayed(Duration.zero);
      expect(listened, isTrue);
      await controller.close();
    });

    test('first valid sample in hPa, then the stream is cancelled', () async {
      var cancelled = false;
      final controller = StreamController<BarometerEvent>(
        onCancel: () => cancelled = true,
      );
      final sensor = SensorsPlusPressureSensor(source: () => controller.stream);
      final pending = sensor.read();
      // Out-of-range samples (sealed-phone handling spikes) are skipped.
      controller.add(_event(5000));
      controller.add(_event(912.4));
      controller.add(_event(913.0));
      final reading = await pending;
      expect(reading, isA<PressureRead>());
      expect((reading as PressureRead).hpa, 912.4);
      expect(cancelled, isTrue);
      await controller.close();
    });

    test(
      'no barometer: a stream error is "unavailable", not a crash',
      () async {
        final sensor = SensorsPlusPressureSensor(
          source: () => Stream<BarometerEvent>.error(
            PlatformException(code: 'UNAVAILABLE'),
          ),
        );
        expect(await sensor.read(), isA<PressureUnavailable>());
      },
    );

    test('a kPa sample (Core Motion unit) is read as hPa', () async {
      final sensor = SensorsPlusPressureSensor(
        source: () => Stream.fromIterable([_event(91.24)]),
      );
      final r = await sensor.read();
      expect(r, isA<PressureRead>());
      expect((r as PressureRead).hpa, closeTo(912.4, 1e-9));
    });

    test('failures say why: no sample vs. implausible value', () async {
      final quiet = StreamController<BarometerEvent>();
      final silent = await SensorsPlusPressureSensor(
        source: () => quiet.stream,
        timeout: const Duration(milliseconds: 20),
      ).read();
      expect((silent as PressureUnavailable).reason, PressureFailure.noSample);
      await quiet.close();

      final bad = await SensorsPlusPressureSensor(
        source: () => Stream.fromIterable([_event(5000)]),
      ).read();
      expect((bad as PressureUnavailable).reason, PressureFailure.outOfRange);
      expect(bad.lastValue, 5000);

      final err = await SensorsPlusPressureSensor(
        source: () => Stream<BarometerEvent>.error(
          PlatformException(code: 'UNAVAILABLE'),
        ),
      ).read();
      expect((err as PressureUnavailable).reason, PressureFailure.noSensor);
    });

    test('plugin missing (simulator, tests) is "unavailable"', () async {
      final sensor = SensorsPlusPressureSensor(
        source: () => throw MissingPluginException('no barometer'),
      );
      expect(await sensor.read(), isA<PressureUnavailable>());
    });

    test('silence until the timeout is "unavailable"', () async {
      final controller = StreamController<BarometerEvent>();
      final sensor = SensorsPlusPressureSensor(
        source: () => controller.stream,
        timeout: const Duration(milliseconds: 20),
      );
      expect(await sensor.read(), isA<PressureUnavailable>());
      await controller.close();
    });

    test(
      'a stream that ends without a valid sample is "unavailable"',
      () async {
        final sensor = SensorsPlusPressureSensor(
          source: () => Stream.fromIterable([_event(0), _event(1500)]),
        );
        expect(await sensor.read(), isA<PressureUnavailable>());
      },
    );
  });

  group('Hava Durumu: Basınç al', () {
    testWidgets('opening Hava Durumu (with auto weather) reads nothing', (
      tester,
    ) async {
      final pressure = TestPressure();
      await _pump(tester, pressure);
      expect(find.text('Basınç al'), findsOneWidget);
      expect(pressure.reads, 0);
    });

    testWidgets('the button writes the phone pressure into Basınç', (
      tester,
    ) async {
      final pressure = TestPressure(const PressureRead(912.4));
      await _pump(tester, pressure);
      await _tapButton(tester);
      expect(pressure.reads, 1);
      expect(_pressureText(tester), '912.4');
      // No extra line: the orange button and the date row say it (owner,
      // 2026-10-14).
      expect(find.text('Basınç alındı'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-phone-pressure-status')),
        findsNothing,
      );
    });

    testWidgets('without a barometer it says "okunamadı" and keeps Basınç', (
      tester,
    ) async {
      final pressure = TestPressure(const PressureUnavailable());
      await _pump(tester, pressure);
      final before = _pressureText(tester);
      await _tapButton(tester);
      expect(pressure.reads, 1);
      expect(_pressureText(tester), before);
      expect(find.textContaining('Basınç okunamadı'), findsOneWidget);
    });

    test('the Basınç ⓘ names the button and gives an example', () {
      expect(EnvironmentFieldInfo.pressure, contains('Basıncı telefondan al'));
      expect(EnvironmentFieldInfo.pressure, contains('Örnek'));
    });
  });
}
