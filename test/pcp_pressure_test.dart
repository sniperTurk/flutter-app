// PCP tüp ve regülatör basıncı (owner, 2026-10-12): the velocity at the
// tube pressure left in the field. Regulated: constant while the tube is at
// or above the regulator set pressure; below it the regulator is out of
// play and the velocity drops (only the user's own chronograph table tells
// by how much). Unregulated: the user's table, linearly interpolated.
// No invented curve: without a usable table the profile velocity is used.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/pcp_pressure.dart';

const _table = [
  PressureVelocityPoint(bar: 100, mps: 250),
  PressureVelocityPoint(bar: 200, mps: 280),
  PressureVelocityPoint(bar: 150, mps: 270),
];

void main() {
  group('PcpPressure.interpolate', () {
    test('fewer than 2 points is no table', () {
      expect(PcpPressure.interpolate(const [], 150), isNull);
      expect(
        PcpPressure.interpolate(const [
          PressureVelocityPoint(bar: 150, mps: 270),
        ], 150),
        isNull,
      );
    });

    test('linear between the neighbours (unsorted input)', () {
      expect(PcpPressure.interpolate(_table, 125), closeTo(260, 1e-9));
      expect(PcpPressure.interpolate(_table, 175), closeTo(275, 1e-9));
      expect(PcpPressure.interpolate(_table, 150), closeTo(270, 1e-9));
    });

    test('outside the table: held at the end values', () {
      expect(PcpPressure.interpolate(_table, 50), 250);
      expect(PcpPressure.interpolate(_table, 260), 280);
    });
  });

  group('PcpPressure.velocity', () {
    test('nothing entered: the profile velocity, no warning', () {
      final r = PcpPressure.velocity(profileMps: 270);
      expect(r.mps, 270);
      expect(r.regulatorBypassed, isFalse);
      expect(r.fromTable, isFalse);
    });

    test('table but no field pressure: the profile velocity', () {
      final r = PcpPressure.velocity(profileMps: 270, table: _table);
      expect(r.mps, 270);
      expect(r.fromTable, isFalse);
    });

    test('unregulated: velocity from the table at the tube pressure', () {
      final r = PcpPressure.velocity(
        profileMps: 290,
        tubeBar: 125,
        table: _table,
      );
      expect(r.mps, closeTo(260, 1e-9));
      expect(r.fromTable, isTrue);
      expect(r.regulatorBypassed, isFalse);
    });

    test('unregulated without a table: the profile velocity', () {
      final r = PcpPressure.velocity(profileMps: 290, tubeBar: 125);
      expect(r.mps, 290);
      expect(r.fromTable, isFalse);
    });

    test('regulated, tube at or above the regulator: profile velocity', () {
      for (final tube in [140.0, 200.0]) {
        final r = PcpPressure.velocity(
          profileMps: 275,
          regulatorBar: 140,
          tubeBar: tube,
          table: _table,
        );
        expect(r.mps, 275);
        expect(r.regulatorBypassed, isFalse);
        expect(r.fromTable, isFalse);
      }
    });

    test('regulated, tube below the regulator: warning + table speed', () {
      final r = PcpPressure.velocity(
        profileMps: 275,
        regulatorBar: 140,
        tubeBar: 125,
        table: _table,
      );
      expect(r.regulatorBypassed, isTrue);
      expect(r.fromTable, isTrue);
      expect(r.mps, closeTo(260, 1e-9));
    });

    test('regulated, below the regulator, no table point there: profile '
        'velocity with the warning (nothing invented)', () {
      final r = PcpPressure.velocity(
        profileMps: 275,
        regulatorBar: 140,
        tubeBar: 120,
        table: const [
          PressureVelocityPoint(bar: 150, mps: 275),
          PressureVelocityPoint(bar: 200, mps: 276),
        ],
      );
      expect(r.regulatorBypassed, isTrue);
      expect(r.fromTable, isFalse);
      expect(r.mps, 275);
    });

    test('invalid field pressure is ignored', () {
      for (final bad in [0.0, -5.0, double.nan, double.infinity]) {
        final r = PcpPressure.velocity(
          profileMps: 270,
          regulatorBar: 140,
          tubeBar: bad,
          table: _table,
        );
        expect(r.mps, 270);
        expect(r.regulatorBypassed, isFalse);
      }
    });
  });
}
