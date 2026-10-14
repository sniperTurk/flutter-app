// Formül denetimi 2026-10-14 (docs/reports/formul_denetimi_2026_10_14.md).
//
// The production solver (scope frame) against an independent WORLD-frame
// point-mass reference (tools/formul_denetimi_2026_10_14.py: ENU frame,
// RK4 dt = 0.05 ms, Hermite range crossing, secant zero, -2 Ω × v). The two
// frames agreeing checks the app's incline, cant, wind and Coriolis
// rotations, not only the level case the 2026-10-13 audit covered.
//
// Tolerance: 0.005 mrad (a 0.1 mrad click is 20 times larger) and 0.5 ms.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/models/domain.dart';

const _fps = 0.3048;
const _mph = 0.44704;

/// ICAO Doc 7488/3 sea level, dry air (zero and shot).
EnvironmentData _icao({double windMps = 0, double windDeg = 90}) =>
    EnvironmentData(
      temperatureC: 15,
      pressureHpa: 1013.25,
      humidityPercent: 0,
      windMps: windMps,
      windDirectionDeg: windDeg,
    );

class _Case {
  final String name;
  final double mvMps, bc, zeroM, sightMm;
  final BallisticModel model;
  final double windMps, windDeg, inclineDeg, cantDeg;
  final double? lat, az;

  /// (range m, elevation mrad, windage mrad, TOF s) from
  /// `python3 tools/formul_denetimi_2026_10_14.py --dart`.
  final List<(double, double, double, double)> expected;
  const _Case(
    this.name, {
    required this.mvMps,
    required this.bc,
    required this.model,
    required this.zeroM,
    required this.sightMm,
    required this.expected,
    this.windMps = 0,
    this.windDeg = 90,
    this.inclineDeg = 0,
    this.cantDeg = 0,
    this.lat,
    this.az,
  });
}

const _mv308 = 2650 * _fps;

// dart format off
const _cases = <_Case>[
  _Case('.308 168 gr G1 level', mvMps: _mv308, bc: 0.462,
      model: BallisticModel.g1, zeroM: 100, sightMm: 38.1,
      expected: [
    (100.0, 0.0000, 0.0000, 0.12905),
    (300.0, 1.6372, 0.0000, 0.42282),
    (500.0, 4.0089, 0.0000, 0.77546),
    (800.0, 9.1019, 0.0000, 1.45031),
  ]),
  _Case('.308 10 mph from saat 3 (270°)', mvMps: _mv308, bc: 0.462,
      model: BallisticModel.g1, zeroM: 100, sightMm: 38.1,
      windMps: 10 * _mph, windDeg: 270, expected: [
    (300.0, 1.6372, 0.7660, 0.42282),
    (500.0, 4.0089, 1.3986, 0.77546),
  ]),
  _Case('.308 incline +30°', mvMps: _mv308, bc: 0.462,
      model: BallisticModel.g1, zeroM: 100, sightMm: 38.1,
      inclineDeg: 30, expected: [
    (300.0, 1.2825, 0.0000, 0.42344),
    (500.0, 3.3471, 0.0000, 0.77775),
  ]),
  _Case('.308 cant +5° (clockwise)', mvMps: _mv308, bc: 0.462,
      model: BallisticModel.g1, zeroM: 100, sightMm: 38.1,
      cantDeg: 5, expected: [
    (300.0, 1.6270, -0.2341, 0.42282),
    (500.0, 3.9895, -0.4452, 0.77546),
  ]),
  _Case('.308 Coriolis 40° N, shot east', mvMps: _mv308, bc: 0.462,
      model: BallisticModel.g1, zeroM: 100, sightMm: 38.1,
      lat: 40, az: 90, expected: [
    (800.0, 9.0309, -0.0596, 1.45031),
  ]),
  _Case('.308 Coriolis 40° N, shot north', mvMps: _mv308, bc: 0.462,
      model: BallisticModel.g1, zeroM: 100, sightMm: 38.1,
      lat: 40, az: 0, expected: [
    (800.0, 9.1019, -0.0600, 1.45031),
  ]),
  _Case('6.5 mm G7 0.315 2700 fps', mvMps: 2700 * _fps, bc: 0.315,
      model: BallisticModel.g7, zeroM: 100, sightMm: 40, expected: [
    (300.0, 1.4420, 0.0000, 0.40020),
    (600.0, 4.5763, 0.0000, 0.88629),
  ]),
  _Case('.22 pellet G1 0.031 280 m/s', mvMps: 280, bc: 0.031,
      model: BallisticModel.g1, zeroM: 30, sightMm: 50, expected: [
    (10.0, 1.8820, 0.0000, 0.03676),
    (30.0, 0.0000, 0.0000, 0.11634),
    (50.0, 0.9965, 0.0000, 0.20400),
    (100.0, 5.7368, 0.0000, 0.46146),
  ]),
  _Case('.22 pellet 3 m/s from saat 9 (90°)', mvMps: 280, bc: 0.031,
      model: BallisticModel.g1, zeroM: 30, sightMm: 50, windMps: 3,
      windDeg: 90, expected: [
    (50.0, 0.9966, -1.5256, 0.20400),
    (100.0, 5.7372, -3.1297, 0.46147),
  ]),
  _Case('.25 slug G1 0.110 290 m/s', mvMps: 290, bc: 0.110,
      model: BallisticModel.g1, zeroM: 50, sightMm: 50, expected: [
    (100.0, 2.9418, 0.0000, 0.37438),
    (150.0, 6.5780, 0.0000, 0.58289),
  ]),
];
// dart format on

void main() {
  group('solver vs independent world-frame reference', () {
    for (final c in _cases) {
      test(c.name, () {
        final pts = const BallisticEngine().solve(
          BallisticInput(
            muzzleVelocityMps: c.mvMps,
            grain: 100,
            zeroRangeM: c.zeroM,
            sightHeightMm: c.sightMm,
            rangesM: [for (final e in c.expected) e.$1],
            environment: _icao(windMps: c.windMps, windDeg: c.windDeg),
            zeroEnvironment: _icao(),
            ballisticCoefficient: c.bc,
            ballisticModel: c.model,
            inclineDeg: c.inclineDeg,
            cantDeg: c.cantDeg,
            latitudeDeg: c.lat,
            azimuthDeg: c.az,
          ),
        );
        for (var i = 0; i < pts.length; i++) {
          final e = c.expected[i];
          final p = pts[i];
          expect(
            p.correctionMrad,
            closeTo(e.$2, 0.005),
            reason: '${e.$1} m up',
          );
          expect(p.windMrad, closeTo(e.$3, 0.005), reason: '${e.$1} m wind');
          expect(p.timeOfFlightS, closeTo(e.$4, 0.0005), reason: '${e.$1} m');
        }
      });
    }
  });

  group('sign conventions (physics, not numbers)', () {
    BallisticInput input({
      double windMps = 0,
      double windDeg = 90,
      double cant = 0,
      double? lat,
      double? az,
    }) => BallisticInput(
      muzzleVelocityMps: _mv308,
      grain: 168,
      zeroRangeM: 100,
      sightHeightMm: 38.1,
      rangesM: const [600],
      environment: _icao(windMps: windMps, windDeg: windDeg),
      zeroEnvironment: _icao(),
      ballisticCoefficient: 0.462,
      ballisticModel: BallisticModel.g1,
      cantDeg: cant,
      latitudeDeg: lat,
      azimuthDeg: az,
    );
    double wind(BallisticInput i) =>
        const BallisticEngine().solve(i).single.windMrad;
    double up(BallisticInput i) =>
        const BallisticEngine().solve(i).single.correctionMrad;

    test('wind from saat 3 pushes left: dial RIGHT (+); saat 9 mirrors', () {
      final right = wind(input(windMps: 4, windDeg: 270));
      final left = wind(input(windMps: 4, windDeg: 90));
      expect(right, greaterThan(0));
      expect(left, closeTo(-right, 1e-9));
    });

    test('a headwind/tailwind moves nothing sideways', () {
      expect(wind(input(windMps: 4, windDeg: 0)).abs(), lessThan(1e-9));
      expect(wind(input(windMps: 4, windDeg: 180)).abs(), lessThan(1e-9));
    });

    test('clockwise cant drifts right (dial left) and mirrors', () {
      final cw = wind(input(cant: 5)), ccw = wind(input(cant: -5));
      expect(cw, lessThan(0));
      expect(ccw, closeTo(-cw, 1e-9));
    });

    test('Coriolis: northern hemisphere drifts right; east shoots high, '
        'west low (Eötvös)', () {
      expect(wind(input(lat: 40, az: 0)), lessThan(0));
      expect(wind(input(lat: -40, az: 0)), greaterThan(0));
      final level = up(input());
      expect(up(input(lat: 40, az: 90)), lessThan(level));
      expect(up(input(lat: 40, az: 270)), greaterThan(level));
    });
  });
}
