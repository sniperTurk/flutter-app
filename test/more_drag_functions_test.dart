import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  test('every drag law has a reference table with BRL anchors', () {
    for (final m in BallisticModel.values) {
      expect(
        StandardDragTables.forModel(m).coefficientAtMach(1.0),
        greaterThan(0),
        reason: '$m',
      );
    }
    // Spot values at Mach 0 (BRL tables).
    expect(
      StandardDragTables.forModel(BallisticModel.g2).coefficientAtMach(0),
      closeTo(0.2303, 1e-4),
    );
    expect(
      StandardDragTables.forModel(BallisticModel.gs).coefficientAtMach(0),
      closeTo(0.4662, 1e-4),
    );
    expect(
      StandardDragTables.forModel(BallisticModel.ra4).coefficientAtMach(0),
      closeTo(0.2283, 1e-4),
    );
  });

  test('a .22 LR with RA4 solves to 100 m', () {
    final p = const BallisticEngine()
        .solve(
          BallisticInput(
            muzzleVelocityMps: 330,
            grain: 40,
            zeroRangeM: 50,
            sightHeightMm: 40,
            rangesM: const [100],
            ballisticCoefficient: 0.13,
            ballisticModel: BallisticModel.ra4,
          ),
        )
        .single;
    expect(p.correctionMrad, greaterThan(0));
    expect(p.velocityMps, lessThan(330));
  });

  test('labels', () {
    expect(BallisticModel.ra4.label, 'RA4');
    expect(BallisticModel.g7.label, 'G7');
    expect(BallisticModel.gi.label, 'GI');
  });
}
