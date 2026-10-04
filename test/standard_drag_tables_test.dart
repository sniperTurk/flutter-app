import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';

void main() {
  test('G1 reference table preserves authoritative anchor values', () {
    expect(StandardDragTables.g1.samples.length, 79);
    expect(StandardDragTables.g1.coefficientAtMach(0.0), 0.2629);
    expect(StandardDragTables.g1.coefficientAtMach(1.0), 0.4805);
    expect(StandardDragTables.g1.coefficientAtMach(2.0), 0.5934);
    expect(StandardDragTables.g1.coefficientAtMach(5.0), 0.4988);
  });

  test('G7 reference table preserves authoritative anchor values', () {
    expect(StandardDragTables.g7.samples.length, 84);
    expect(StandardDragTables.g7.coefficientAtMach(0.0), 0.1198);
    expect(StandardDragTables.g7.coefficientAtMach(1.0), 0.3803);
    expect(StandardDragTables.g7.coefficientAtMach(2.0), 0.2980);
    expect(StandardDragTables.g7.coefficientAtMach(5.0), 0.1618);
  });

  test('transonic interpolation is deterministic', () {
    expect(
      StandardDragTables.g1.coefficientAtMach(0.9875),
      closeTo(0.46265, 1e-12),
    );
    expect(
      StandardDragTables.g7.coefficientAtMach(0.9875),
      closeTo(0.3398, 1e-12),
    );
  });
}
