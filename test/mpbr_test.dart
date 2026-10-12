// Ö7 Avcı sıfırı / MPBR. Expected values come from an independent scan with
// tools/formula_reference.py (not the app solver); see
// docs/superpowers/specs/2026-10-12-paralaks-mpbr-design.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/mpbr.dart';
import 'package:sniper_turk/models/domain.dart';

BallisticInput Function(double, List<double>) _builder({
  required double mv,
  required double grain,
  required double sightMm,
  double? bc,
  BallisticModel? model,
}) =>
    (zeroM, ranges) => BallisticInput(
      muzzleVelocityMps: mv,
      grain: grain,
      zeroRangeM: zeroM,
      sightHeightMm: sightMm,
      rangesM: ranges,
      ballisticCoefficient: bc,
      ballisticModel: model,
    );

final _t1 = _builder(
  mv: 790,
  grain: 175,
  sightMm: 45,
  bc: 0.243,
  model: BallisticModel.g7,
);
final _p1 = _builder(
  mv: 275,
  grain: 18,
  sightMm: 50,
  bc: 0.031,
  model: BallisticModel.g1,
);
final _p2 = _builder(
  mv: 290,
  grain: 25,
  sightMm: 50,
  bc: 0.090,
  model: BallisticModel.g1,
);

/// The trajectory of [r] stays inside ±half between near and far.
void _staysInside(
  BallisticInput Function(double, List<double>) build,
  MpbrResult r,
  double half,
) {
  final ranges = [
    for (var x = r.nearM.ceilToDouble() + 1; x < r.farM - 1; x += 1) x,
  ];
  if (ranges.isEmpty) return;
  final pts = const BallisticEngine().solve(build(r.zeroM, ranges));
  for (final p in pts) {
    expect(
      p.dropM.abs(),
      lessThanOrEqualTo(half + 0.001),
      reason: '${p.rangeM}',
    );
  }
}

void main() {
  test('zone list is the owner list', () {
    expect(Mpbr.zoneDiametersCm, [2.5, 4, 10, 15, 20]);
  });

  test('T1 .308, 15 cm: zero ≈ 203 m, no hold 0–237 m', () {
    final r = Mpbr.solve(
      build: _t1,
      zoneDiameterM: 0.15,
      grid: MpbrGrid.firearm,
    )!;
    expect(r.zeroM, closeTo(203, 4));
    expect(r.nearM, closeTo(0, 0.5));
    expect(r.farM, closeTo(237.7, 5));
    expect(r.nearZeroM, closeTo(24.9, 4));
    expect(r.apexM, lessThanOrEqualTo(0.075 + 0.001));
    expect(r.apexM, greaterThan(0.07));
    _staysInside(_t1, r, 0.075);
  });

  test('P1 PCP pellet, 2,5 cm: near crossing 16 m, zero 40 m, 11–44 m', () {
    final r = Mpbr.solve(build: _p1, zoneDiameterM: 0.025, grid: MpbrGrid.pcp)!;
    expect(r.nearZeroM, closeTo(15.9, 1));
    expect(r.zeroM, closeTo(39.9, 1.5));
    expect(r.nearM, closeTo(10.6, 1));
    expect(r.farM, closeTo(44.6, 1));
    expect(r.apexM, lessThanOrEqualTo(0.0125 + 0.001));
    _staysInside(_p1, r, 0.0125);
  });

  test('P2 PCP slug, 4 cm: zero 50 m, far 57 m', () {
    final r = Mpbr.solve(build: _p2, zoneDiameterM: 0.04, grid: MpbrGrid.pcp)!;
    expect(r.zeroM, closeTo(50.2, 1.5));
    expect(r.farM, closeTo(57.2, 1.5));
    expect(r.nearM, closeTo(8.2, 1));
  });

  test('a larger zone reaches farther', () {
    final small = Mpbr.solve(
      build: _t1,
      zoneDiameterM: 0.10,
      grid: MpbrGrid.firearm,
    )!;
    final big = Mpbr.solve(
      build: _t1,
      zoneDiameterM: 0.20,
      grid: MpbrGrid.firearm,
    )!;
    expect(big.farM, greaterThan(small.farM));
    expect(big.zeroM, greaterThan(small.zeroM));
  });

  test('without a ballistic coefficient the vacuum baseline still answers', () {
    final vac = _builder(mv: 275, grain: 18, sightMm: 50);
    final r = Mpbr.solve(build: vac, zoneDiameterM: 0.025, grid: MpbrGrid.pcp);
    expect(r, isNotNull);
    expect(r!.farM, greaterThan(r.zeroM));
  });
}
