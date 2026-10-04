import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/atmosphere.dart';
import 'package:sniper_turk/core/drag_table.dart';
import 'package:sniper_turk/core/reference_drag_model.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  final model = ReferenceDragModel(DragTable(const [
    DragSample(0, 0.25),
    DragSample(5, 0.25),
  ]));

  test('zero speed has zero aerodynamic deceleration', () {
    expect(model.decelerationMps2(
      speedMps: 0,
      ballisticCoefficient: 0.12,
      environment: const EnvironmentData(),
    ), 0);
  });

  test('drag follows dynamic-pressure equation with explicit BC SI conversion', () {
    const env = EnvironmentData();
    const speed = 300.0;
    const bc = 0.12;
    const cd = 0.25;
    final rho = Atmosphere.densityKgM3(env);
    final bcSi = bc * ReferenceDragModel.poundsPerSquareInchToKgPerSquareMeter;
    final expected = 0.5 * rho * cd * (math.pi / 4) * speed * speed / bcSi;
    expect(model.decelerationMps2(
      speedMps: speed,
      ballisticCoefficient: bc,
      environment: env,
    ), closeTo(expected, expected * 1e-12));
  });

  test('BC conversion pins one lb per square inch in SI', () {
    expect(
      ReferenceDragModel.ballisticCoefficientKgPerM2(1),
      closeTo(703.0695796391593, 1e-10),
    );
  });

  test('doubling BC halves drag at identical atmosphere and speed', () {
    final a = model.decelerationMps2(
      speedMps: 300,
      ballisticCoefficient: 0.1,
      environment: const EnvironmentData(),
    );
    final b = model.decelerationMps2(
      speedMps: 300,
      ballisticCoefficient: 0.2,
      environment: const EnvironmentData(),
    );
    expect(a / b, closeTo(2, 1e-12));
  });

  test('invalid BC fails closed at conversion boundary', () {
    expect(() => ReferenceDragModel.ballisticCoefficientKgPerM2(0), throwsArgumentError);
    expect(() => ReferenceDragModel.ballisticCoefficientKgPerM2(double.nan), throwsArgumentError);
  });
}
