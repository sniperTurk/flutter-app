// Ö6 — Çok mesafeli doğrulama: observations at several far ranges give
// Cd scale factors per Mach band; the result is the bullet's own Cd curve
// (DragCurve). McCoy 1999 ch. 4–7; Courtney & Courtney arXiv:0705.0389.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/drag_band_truing.dart';
import 'package:sniper_turk/core/drag_curve.dart';
import 'package:sniper_turk/core/drag_table.dart';
import 'package:sniper_turk/models/domain.dart';

const _engine = BallisticEngine();

const _icao = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 0,
);

// T1 of the report: .308 175 gr, G7 0.243, 790 m/s, 45 mm, zero 100 m.
final _sd = DragCurve.sectionalDensity(grain: 175, diameterMm: 7.82);

BallisticInput _t1({
  List<double> ranges = const [100],
  List<BcBand> bands = const [],
}) => BallisticInput(
  muzzleVelocityMps: 790,
  grain: 175,
  zeroRangeM: 100,
  sightHeightMm: 45,
  rangesM: ranges,
  environment: _icao,
  ballisticCoefficient: 0.243,
  ballisticModel: BallisticModel.g7,
  bcBands: bands,
);

/// The same rifle flying with [curve] as its own Cd (BC = SD).
BallisticInput _withCurve(List<DragSample> curve, List<double> ranges) =>
    BallisticInput(
      muzzleVelocityMps: 790,
      grain: 175,
      zeroRangeM: 100,
      sightHeightMm: 45,
      rangesM: ranges,
      environment: _icao,
      ballisticCoefficient: _sd,
      ballisticModel: BallisticModel.g1,
      dragTable: DragTable(curve),
    );

List<double> _corrections(BallisticInput input) => [
  for (final p in _engine.solve(input)) p.correctionMrad,
];

List<DragObservation> _observe(List<double> ranges, List<double> mrad) => [
  for (var i = 0; i < ranges.length; i++) DragObservation(ranges[i], mrad[i]),
];

void _expectRejected(DragTruingRejection reason, void Function() run) {
  expect(
    run,
    throwsA(
      isA<DragTruingFailure>()
          .having((f) => f.reason, 'reason', reason)
          .having((f) => f.message, 'message', isNotEmpty),
    ),
  );
}

void main() {
  const far = [500.0, 700.0, 900.0];

  test('the own Cd curve (G7 × SD / BC) reproduces the G7 solution', () {
    final own = DragBandTruing.ownCurve(base: _t1(), sectionalDensity: _sd);
    final ranges = [300.0, 600.0, 800.0, 1000.0];
    final g7 = _corrections(_t1(ranges: ranges));
    final curve = _corrections(_withCurve(own, ranges));
    for (var i = 0; i < ranges.length; i++) {
      expect(curve[i], closeTo(g7[i], 1e-6));
    }
    // Storable as an Özel sürüklenme eğrisi.
    expect(DragCurve.fromJson(DragCurve.toJson(own)), isNotNull);
  });

  test('scale 1 everywhere leaves the curve unchanged', () {
    final own = DragBandTruing.ownCurve(base: _t1(), sectionalDensity: _sd);
    final same = DragBandTruing.scaledCurve(own, const [1, 1, 1, 1]);
    expect(same.length, own.length);
    for (var i = 0; i < own.length; i++) {
      expect(same[i].mach, own[i].mach);
      expect(same[i].coefficient, closeTo(own[i].coefficient, 1e-12));
    }
  });

  test('observations equal to the prediction change nothing', () {
    final r = DragBandTruing.solve(
      base: _t1(),
      observations: _observe(far, _corrections(_t1(ranges: far))),
      sectionalDensity: _sd,
    );
    for (final b in r.bands) {
      expect(b.scale, closeTo(1, 0.002), reason: b.label);
    }
    expect(r.maxResidualAfterMrad, lessThan(0.005));
    expect(r.inconsistent, isFalse);
  });

  test('finds a 3 % drag increase between Mach 1.2 and 2 (500/700/900 m)', () {
    final own = DragBandTruing.ownCurve(base: _t1(), sectionalDensity: _sd);
    final truth = DragBandTruing.scaledCurve(own, const [1, 1.03, 1.03, 1]);
    final observed = _corrections(_withCurve(truth, far));
    final r = DragBandTruing.solve(
      base: _t1(),
      observations: _observe(far, observed),
      sectionalDensity: _sd,
    );
    // Before: the published G7 BC misses the far hit by more than a click.
    expect(
      r.fits
          .map((f) => (f.observedMrad - f.beforeMrad).abs())
          .reduce((a, b) => a > b ? a : b),
      greaterThan(0.1),
    );
    expect(r.maxResidualAfterMrad, lessThan(0.03));
    expect(r.bands[1].scale, greaterThan(1.0));
    expect(r.bands[2].scale, greaterThan(1.0));
    // The new curve, flown by the solver, hits where the rifle hit.
    final check = _corrections(_withCurve(r.curve, far));
    for (var i = 0; i < far.length; i++) {
      expect(check[i], closeTo(observed[i], 0.03));
    }
  });

  test('above Mach 2 is never fitted (velocity truing owns it)', () {
    final r = DragBandTruing.solve(
      base: _t1(),
      observations: _observe(far, [
        for (final c in _corrections(_t1(ranges: far))) c + 0.1,
      ]),
      sectionalDensity: _sd,
    );
    expect(r.bands, hasLength(4));
    expect(r.bands.last.fitted, isFalse);
    expect(r.bands.last.scale, 1.0);
  });

  test('overfitting guard: 3 ranges fit at most 2 bands', () {
    final r = DragBandTruing.solve(
      base: _t1(),
      observations: _observe(
        const [400, 700, 1000],
        [
          for (final c in _corrections(_t1(ranges: const [400, 700, 1000])))
            c + 0.05,
        ],
      ),
      sectionalDensity: _sd,
    );
    expect(r.bands.where((b) => b.fitted).length, lessThanOrEqualTo(2));
  });

  test('overfitting guard: half-click noise does not bend the curve', () {
    final base = _corrections(_t1(ranges: far));
    final r = DragBandTruing.solve(
      base: _t1(),
      observations: _observe(far, [base[0] + 0.05, base[1] - 0.05, base[2]]),
      sectionalDensity: _sd,
    );
    for (final b in r.bands) {
      expect((b.scale - 1).abs(), lessThan(0.10), reason: b.label);
    }
  });

  group('refusals', () {
    test('fewer than 3 ranges', () {
      _expectRejected(
        DragTruingRejection.tooFewRanges,
        () => DragBandTruing.solve(
          base: _t1(),
          observations: _observe(const [500, 900], const [3, 8]),
          sectionalDensity: _sd,
        ),
      );
    });
    test('the same range twice', () {
      _expectRejected(
        DragTruingRejection.duplicateRange,
        () => DragBandTruing.solve(
          base: _t1(),
          observations: _observe(const [500, 700, 700], const [3, 5, 5.1]),
          sectionalDensity: _sd,
        ),
      );
    });
    test('a range not beyond the zero', () {
      _expectRejected(
        DragTruingRejection.rangeTooShort,
        () => DragBandTruing.solve(
          base: _t1(),
          observations: _observe(const [100, 700, 900], const [0, 5, 8]),
          sectionalDensity: _sd,
        ),
      );
    });
    test('velocity-dependent BC (çoklu BC)', () {
      _expectRejected(
        DragTruingRejection.multiBc,
        () => DragBandTruing.solve(
          base: _t1(bands: const [BcBand(600, 0.25), BcBand(0, 0.23)]),
          observations: _observe(far, const [3, 5, 8]),
          sectionalDensity: _sd,
        ),
      );
    });
    test('ranges too close to tell the bands apart', () {
      _expectRejected(
        DragTruingRejection.notSensitive,
        () => DragBandTruing.solve(
          base: _t1(),
          observations: _observe(
            const [150, 200, 250],
            [
              for (final c in _corrections(_t1(ranges: const [150, 200, 250])))
                c,
            ],
          ),
          sectionalDensity: _sd,
        ),
      );
    });
    test('more than 20 % drag change needed', () {
      _expectRejected(
        DragTruingRejection.outOfBounds,
        () => DragBandTruing.solve(
          base: _t1(),
          observations: _observe(far, [
            for (final c in _corrections(_t1(ranges: far))) c * 1.5,
          ]),
          sectionalDensity: _sd,
        ),
      );
    });
    test('every reason has a Turkish message', () {
      for (final r in DragTruingRejection.values) {
        expect(DragTruingFailure(r).message, isNotEmpty);
      }
    });
  });
}
