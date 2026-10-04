import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/drag_table.dart';

void main() {
  test('drag table interpolates linearly and clamps endpoints', () {
    final table = DragTable(const [
      DragSample(0.5, 0.2),
      DragSample(1.0, 0.4),
      DragSample(2.0, 0.3),
    ]);
    expect(table.coefficientAtMach(0.25), 0.2);
    expect(table.coefficientAtMach(0.75), closeTo(0.3, 1e-12));
    expect(table.coefficientAtMach(3.0), 0.3);
  });

  test('drag table rejects unordered or non-positive coefficient data', () {
    expect(() => DragTable(const [DragSample(1, 0.2), DragSample(1, 0.3)]), throwsArgumentError);
    expect(() => DragTable(const [DragSample(0, 0.2), DragSample(1, 0)]), throwsArgumentError);
  });
}
