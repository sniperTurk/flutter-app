import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/features/tools/calculators_screen.dart';
import 'package:sniper_turk/features/tools/reticle_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/field_calc.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

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
      // With the real temperature (weather-service sea-level pressure):
      // warm air column -> higher station pressure than ISA.
      expect(
        FieldCalc.stationPressureHpa(1013.25, 1000, temperatureC: 30),
        closeTo(906.3, 0.2),
      );
      // At the ISA temperature for 1000 m (8.5 °C) both agree.
      expect(
        FieldCalc.stationPressureHpa(1013.25, 1000, temperatureC: 8.5),
        closeTo(898.7, 0.2),
      );
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

  group('Energy', () {
    test('½·m·v², momentum, power factor, velocity for energy', () {
      // 25.39 gr at 270 m/s.
      expect(FieldCalc.energyJ(25.39, 270), closeTo(59.97, 0.01));
      expect(FieldCalc.momentumNs(25.39, 270), closeTo(0.4442, 1e-4));
      expect(FieldCalc.powerFactor(25.39, 270), closeTo(22.49, 0.01));
      // 12 ft·lbf (16.27 J) limit for that pellet.
      expect(FieldCalc.velocityForEnergyMps(25.39, 16.27), closeTo(140.6, 0.1));
    });
  });

  group('Converters', () {
    test('energy and temperature', () {
      expect(_conv(Converters.energy, 'ft', 'joule', 12), closeTo(16.27, 0.01));
      expect(_conv(Converters.temperature, 'Celsius', 'Fahrenheit', 100),
          closeTo(212, 1e-9));
      expect(_conv(Converters.temperature, 'Fahrenheit', 'Celsius', -40),
          closeTo(-40, 1e-9));
      expect(_conv(Converters.temperature, 'Celsius', 'Kelvin', 0),
          closeTo(273.15, 1e-9));
    });

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

  group('reticle geometry', () {
    test('1 mil spans 60 cm at 600 m', () {
      expect(FieldCalc.spanM(600, 1)!, closeTo(0.6, 1e-6));
    });
    test('FFP covers nominal, SFP scales with magnification', () {
      expect(
        FieldCalc.trueMilPerReticleMil(
          firstFocalPlane: true,
          mag: 5,
          calibrationMag: 10,
        ),
        1.0,
      );
      expect(
        FieldCalc.trueMilPerReticleMil(
          firstFocalPlane: false,
          mag: 5,
          calibrationMag: 10,
        )!,
        closeTo(2.0, 1e-12),
      );
      expect(
        FieldCalc.trueMilPerReticleMil(
          firstFocalPlane: false,
          mag: 0,
          calibrationMag: 10,
        ),
        isNull,
      );
    });
    test('USMC mil formula: 1.8 m target at 3 mil is 600 m', () {
      expect(FieldCalc.milOfSize(1.8, 600)!, closeTo(3.0, 1e-3));
      expect(FieldCalc.distanceFromAngle(1.8, 0.003)!, closeTo(600, 0.01));
    });
  });

  group('Hesaplayıcılar screens', () {
    testWidgets('hub lists all tools', (tester) async {
      await tester.pumpWidget(host(const CalculatorsScreen()));
      for (final k in const [
        'calc-stadia',
        'calc-reticle',
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
        'calc-energy',
        'conv-energy',
        'conv-temperature',
      ]) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
    });

    testWidgets('reticle shows dot spacing and honest scope note', (
      tester,
    ) async {
      await tester.pumpWidget(host(const ReticleScreen()));
      expect(find.byKey(const Key('reticle-canvas')), findsOneWidget);
      expect(find.text('1 mil (nokta aralığı)'), findsOneWidget);
      expect(find.textContaining('yalnızca geometridir'), findsOneWidget);
    });

    testWidgets('stadia shows the distance', (tester) async {
      await tester.pumpWidget(host(const StadiaScreen()));
      expect(find.byType(MenzilMetricGrid), findsOneWidget);
      expect(find.text('Mesafe'), findsWidgets);
    });

    testWidgets('air lab shows density at standard conditions', (tester) async {
      await tester.pumpWidget(host(const AirLabScreen()));
      expect(find.text('Hava yoğunluğu'), findsOneWidget);
    });

    testWidgets('energy page shows J and ft·lbf and the needed velocity', (
      tester,
    ) async {
      await tester.pumpWidget(host(const EnergyScreen()));
      expect(find.byKey(const Key('energy-result')), findsOneWidget);
      expect(find.textContaining('60,0', findRichText: true), findsWidgets);
      expect(find.byKey(const Key('energy-need')), findsNothing);
      await tester.enterText(find.byKey(const Key('energy-target')), '16,27');
      await tester.pump();
      expect(find.byKey(const Key('energy-need')), findsOneWidget);
      expect(find.byTooltip('Bilgi: Ağırlık'), findsOneWidget);
    });

    testWidgets('converter lists every unit', (tester) async {
      await tester.pumpWidget(
        host(const ConverterScreen(category: Converters.pressure)),
      );
      expect(find.byKey(const Key('conv-pressure-bar')), findsOneWidget);
      expect(find.byKey(const Key('conv-pressure-psi')), findsOneWidget);
    });
  });
}
