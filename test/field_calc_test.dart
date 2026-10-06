import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/features/tools/calculators_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/field_calc.dart';

import 'support/tool_fakes.dart';

double _conv(ConvCategory c, String from, String to, double v) {
  ConvUnit u(String label) =>
      c.units.firstWhere((x) => x.label.startsWith(label));
  return c.convert(v, u(from), u(to));
}

void main() {
  group('FieldCalc', () {
    test('stadia: 50 cm spanning 5 mil is 100 m', () {
      final d = FieldCalc.distanceFromAngle(0.5, 5 * FieldCalc.radPerMil)!;
      expect(d, closeTo(100, 0.01));
    });
    test('invalid angular inputs return null', () {
      expect(FieldCalc.distanceFromAngle(0, 0.001), isNull);
      expect(FieldCalc.distanceFromAngle(0.5, 0), isNull);
      expect(FieldCalc.sizeFromAngle(-1, 0.001), isNull);
    });
    test('1 MOA at 100 m is about 2.909 cm', () {
      final s = FieldCalc.sizeFromAngle(100, FieldCalc.radPerMoa)!;
      expect(s * 100, closeTo(2.909, 0.001));
    });
    test('real click: 40 clicks moved 40 cm at 100 m is 0.1 mil each', () {
      final r = FieldCalc.realClickRad(
        distanceM: 100,
        movedM: 0.4,
        clicks: 40,
      )!;
      expect(r / FieldCalc.radPerMil, closeTo(0.1, 1e-3));
      expect(
        FieldCalc.realClickRad(distanceM: 100, movedM: 0.4, clicks: 0),
        isNull,
      );
    });
    test('haversine and bearing', () {
      expect(FieldCalc.haversineM(0, 0, 0, 1), closeTo(111195, 5));
      expect(FieldCalc.bearingDeg(0, 0, 0, 1), closeTo(90, 1e-6));
      expect(FieldCalc.bearingDeg(0, 0, 1, 0), closeTo(0, 1e-6));
      expect(FieldCalc.bearingDeg(0, 0, 0, -1), closeTo(270, 1e-6));
      expect(FieldCalc.validLatLon(91, 0), isFalse);
    });
    test('air lab at ICAO standard', () {
      final lab = FieldCalc.airLab(
        const EnvironmentData(
          temperatureC: 15,
          pressureHpa: 1013.25,
          humidityPercent: 0,
        ),
      );
      expect(lab.densityKgM3, closeTo(1.225, 0.001));
      expect(lab.densityAltitudeM, closeTo(0, 6));
      expect(lab.speedOfSoundMps, closeTo(340.3, 0.6));
      expect(FieldCalc.dewPointC(20, 50), closeTo(9.3, 0.2));
      expect(FieldCalc.stationPressureHpa(1013.25, 0), closeTo(1013.25, 1e-9));
      expect(FieldCalc.stationPressureHpa(1013.25, 1000), closeTo(898.7, 1));
    });
    test('BC from two velocities round-trips through the drag model', () {
      const env = EnvironmentData(
        temperatureC: 15,
        pressureHpa: 1013.25,
        humidityPercent: 50,
      );
      for (final table in [StandardDragTables.g1, StandardDragTables.g7]) {
        final v2 = FieldCalc.velocityAfter(
          table: table,
          bc: 0.03,
          v1Mps: 280,
          distanceM: 30,
          env: env,
        )!;
        expect(v2, lessThan(280));
        final bc = FieldCalc.ballisticCoefficientFromTwoVelocities(
          table: table,
          v1Mps: 280,
          v2Mps: v2,
          distanceM: 30,
          env: env,
        )!;
        expect(bc, closeTo(0.03, 1e-3));
      }
    });
    test('BC solver refuses impossible inputs', () {
      const env = EnvironmentData();
      expect(
        FieldCalc.ballisticCoefficientFromTwoVelocities(
          table: StandardDragTables.g1,
          v1Mps: 280,
          v2Mps: 290,
          distanceM: 30,
          env: env,
        ),
        isNull,
      );
    });
  });

  group('Converters', () {
    test('known factors', () {
      expect(_conv(Converters.angle, 'MIL', 'MOA', 1), closeTo(3.43775, 1e-4));
      expect(_conv(Converters.angle, 'Derece', 'MOA', 1), closeTo(60, 1e-9));
      expect(
        _conv(Converters.angle, 'NATO', 'Derece', 6400),
        closeTo(360, 1e-9),
      );
      expect(_conv(Converters.speed, 'm/s', 'fps', 1), closeTo(3.28084, 1e-5));
      expect(_conv(Converters.speed, 'km/sa', 'm/s', 36), closeTo(10, 1e-9));
      expect(
        _conv(Converters.weight, 'grain', 'gram', 1),
        closeTo(0.0647989, 1e-7),
      );
      expect(
        _conv(Converters.weight, 'libre', 'grain', 1),
        closeTo(7000, 0.01),
      );
      expect(
        _conv(Converters.pressure, 'bar', 'psi', 1),
        closeTo(14.5038, 1e-3),
      );
      expect(
        _conv(Converters.pressure, 'atm', 'hPa', 1),
        closeTo(1013.25, 1e-9),
      );
      expect(
        _conv(Converters.length, 'inç', 'milimetre', 1),
        closeTo(25.4, 1e-9),
      );
      expect(
        _conv(Converters.length, 'yarda', 'metre', 100),
        closeTo(91.44, 1e-9),
      );
      expect(
        _conv(Converters.torque, 'lbf·ft', 'N·m', 1),
        closeTo(1.35582, 1e-5),
      );
    });
    test('round trip is the identity', () {
      for (final cat in [
        Converters.angle,
        Converters.speed,
        Converters.weight,
        Converters.pressure,
        Converters.length,
        Converters.torque,
      ]) {
        for (final a in cat.units) {
          for (final b in cat.units) {
            expect(
              cat.convert(cat.convert(12.5, a, b), b, a),
              closeTo(12.5, 1e-9),
            );
          }
        }
      }
    });
  });

  group('Hesaplayıcılar screens', () {
    testWidgets('hub lists all twelve tools', (tester) async {
      await tester.pumpWidget(host(const CalculatorsScreen()));
      for (final k in const [
        'calc-stadia',
        'calc-distance',
        'calc-custom-location',
        'calc-moa-at-distance',
        'calc-click-check',
        'calc-bc-two-velocities',
        'calc-air-lab',
        'conv-angle',
        'conv-speed',
        'conv-weight',
        'conv-pressure',
        'conv-length',
        'conv-torque',
      ]) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
    });

    testWidgets('stadia shows the distance', (tester) async {
      await tester.pumpWidget(host(const StadiaScreen()));
      expect(find.text('100,0'), findsWidgets);
    });

    testWidgets('air lab shows density at standard conditions', (tester) async {
      await tester.pumpWidget(host(const AirLabScreen()));
      expect(find.text('Hava yoğunluğu'), findsOneWidget);
    });

    testWidgets('converter lists every unit', (tester) async {
      await tester.pumpWidget(
        host(ConverterScreen(category: Converters.pressure)),
      );
      expect(find.byKey(const Key('conv-pressure-bar')), findsOneWidget);
      expect(find.byKey(const Key('conv-pressure-psi')), findsOneWidget);
    });
  });
}
