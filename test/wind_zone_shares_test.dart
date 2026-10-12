import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/wind_zone_shares.dart';
import 'package:sniper_turk/models/domain.dart';

/// T1 of docs/yeni-hesaplar-2026-10-11.md: .308 Win 175 gr, G7 0.243.
BallisticInput t1() => BallisticInput(
  muzzleVelocityMps: 790,
  grain: 175,
  zeroRangeM: 100,
  sightHeightMm: 45,
  rangesM: const [800],
  ballisticCoefficient: 0.243,
  ballisticModel: BallisticModel.g7,
);

/// P1: PCP .22 pellet 18 gr, G1 0.031, 275 m/s, zero 30 m.
BallisticInput p1() => BallisticInput(
  muzzleVelocityMps: 275,
  grain: 18,
  zeroRangeM: 30,
  sightHeightMm: 50,
  rangesM: const [50],
  ballisticCoefficient: 0.031,
  ballisticModel: BallisticModel.g1,
);

void main() {
  test('T1 at 800 m: near 45 %, middle 37 %, far 18 % (±2)', () {
    final s = WindZoneShares.compute(t1(), 800)!;
    expect(s.nearPct, inInclusiveRange(43, 47));
    expect(s.midPct, inInclusiveRange(35, 39));
    expect(s.farPct, inInclusiveRange(16, 20));
  });

  test('P1 at 50 m: near 56 %, middle 33 %, far 11 % (±2)', () {
    final s = WindZoneShares.compute(p1(), 50)!;
    expect(s.nearPct, inInclusiveRange(54, 58));
    expect(s.midPct, inInclusiveRange(31, 35));
    expect(s.farPct, inInclusiveRange(9, 13));
  });

  test('shares are whole percents adding up to 100, near > middle > far', () {
    for (final r in [100.0, 300.0, 600.0, 1000.0]) {
      final s = WindZoneShares.compute(t1(), r)!;
      expect(s.nearPct + s.midPct + s.farPct, 100, reason: '$r');
      expect(s.nearPct, greaterThan(s.midPct), reason: '$r');
      expect(s.midPct, greaterThan(s.farPct), reason: '$r');
    }
  });

  test('ignores the wind, cant and Coriolis of the base input', () {
    final b = t1();
    final windy = BallisticInput(
      muzzleVelocityMps: 790,
      grain: 175,
      zeroRangeM: 100,
      sightHeightMm: 45,
      rangesM: const [800],
      ballisticCoefficient: 0.243,
      ballisticModel: BallisticModel.g7,
      environment: const EnvironmentData(windMps: 7, windDirectionDeg: 45),
      windZones: const WindZones(rangeM: 800, midMps: 3, farMps: 9),
      cantDeg: 5,
      latitudeDeg: 40,
      azimuthDeg: 90,
    );
    final a = WindZoneShares.compute(b, 800)!;
    final w = WindZoneShares.compute(windy, 800)!;
    expect([w.nearPct, w.midPct, w.farPct], [a.nearPct, a.midPct, a.farPct]);
  });

  test('a range the solver cannot use gives null', () {
    expect(WindZoneShares.compute(t1(), 0), isNull);
    expect(WindZoneShares.compute(t1(), double.nan), isNull);
  });
}
