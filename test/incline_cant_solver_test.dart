// Shot incline (tüfek eğimi) and scope cant (dürbün eğimi) in the solvers.
//
// The production solver rotates gravity and wind into the scope frame. This
// test re-solves the same shot in plain WORLD coordinates (gravity straight
// down, wind horizontal, scope axes rotated) with its own RK4 loop and the
// same drag law, and requires the same answer. A sign or axis mistake in the
// rotation cannot pass this.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/reference_drag_model.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/models/domain.dart';

const _g = 9.80665;
const _dt = 0.0005;
const _env = EnvironmentData(
  temperatureC: 18,
  pressureHpa: 1005,
  humidityPercent: 55,
  windMps: 3,
  windDirectionDeg: 60,
);
const _zeroEnv = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 0,
  altitudeM: 0,
  windMps: 0,
  windDirectionDeg: 90,
);

BallisticInput _input({
  double incline = 0,
  double cant = 0,
  List<double> ranges = const [20, 45, 70],
  bool drag = true,
  EnvironmentData env = _env,
  double? latitude,
  double? azimuth,
}) => BallisticInput(
  muzzleVelocityMps: 275,
  grain: 33.95,
  zeroRangeM: 30,
  sightHeightMm: 62,
  rangesM: ranges,
  environment: env,
  ballisticCoefficient: drag ? 0.08 : null,
  ballisticModel: drag ? BallisticModel.g1 : null,
  inclineDeg: incline,
  cantDeg: cant,
  latitudeDeg: latitude,
  azimuthDeg: azimuth,
);

typedef _V = List<double>;
double _dot(_V a, _V b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

/// World axes: [forward (horizontal), up, right].
class _World {
  final ReferenceDragModel drag = ReferenceDragModel(StandardDragTables.g1);

  /// Earth's rotation in world axes; zero = no Coriolis.
  final _V omega;

  _World() : omega = const [0.0, 0.0, 0.0];

  /// East-north-up Ω = ω(0, cos φ, sin φ) seen along the shot azimuth A:
  /// forward = (sin A, cos A, 0), right = (cos A, −sin A, 0).
  _World.coriolis(double latDeg, double azDeg)
    : omega = _earthRotation(latDeg, azDeg);

  static _V _earthRotation(double latDeg, double azDeg) {
    const w = 7.2921159e-5;
    final lat = latDeg * math.pi / 180, az = azDeg * math.pi / 180;
    return [
      w * math.cos(lat) * math.cos(az),
      w * math.sin(lat),
      -w * math.cos(lat) * math.sin(az),
    ];
  }

  _V _accel(_V v, _V air, EnvironmentData env) {
    final rv = [v[0] - air[0], v[1] - air[1], v[2] - air[2]];
    final speed = math.sqrt(_dot(rv, rv));
    final decel = drag.decelerationMps2(
      speedMps: speed,
      ballisticCoefficient: 0.08,
      environment: env,
    );
    final s = speed == 0 ? 0.0 : -decel / speed;
    // Coriolis: a = −2 Ω × v.
    final o = omega;
    final cx = o[1] * v[2] - o[2] * v[1];
    final cy = o[2] * v[0] - o[0] * v[2];
    final cz = o[0] * v[1] - o[1] * v[0];
    return [s * rv[0] - 2 * cx, s * rv[1] - _g - 2 * cy, s * rv[2] - 2 * cz];
  }

  List<double> _step(List<double> st, _V air, EnvironmentData env) {
    List<double> d(List<double> s) => [
      s[3],
      s[4],
      s[5],
      ..._accel([s[3], s[4], s[5]], air, env),
    ];
    List<double> add(List<double> s, List<double> k, double h) => [
      for (var i = 0; i < 6; i++) s[i] + h * k[i],
    ];
    final k1 = d(st);
    final k2 = d(add(st, k1, _dt / 2));
    final k3 = d(add(st, k2, _dt / 2));
    final k4 = d(add(st, k3, _dt));
    return [
      for (var i = 0; i < 6; i++)
        st[i] + _dt / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]),
    ];
  }

  /// (up, right) offset from the line of sight, in the scope's own axes, at
  /// slant range [range].
  (double, double) offsetAt({
    required double boreAngle,
    required double range,
    required double inclineDeg,
    required double cantDeg,
    required EnvironmentData env,
  }) {
    final t = inclineDeg * math.pi / 180, p = cantDeg * math.pi / 180;
    final los = [math.cos(t), math.sin(t), 0.0];
    final up0 = [-math.sin(t), math.cos(t), 0.0];
    const right0 = [0.0, 0.0, 1.0];
    // Clockwise cant: the scope's "up" leans to the right.
    final up = [
      for (var i = 0; i < 3; i++)
        up0[i] * math.cos(p) + right0[i] * math.sin(p),
    ];
    final right = [
      for (var i = 0; i < 3; i++)
        right0[i] * math.cos(p) - up0[i] * math.sin(p),
    ];
    const h = 0.062;
    final dir = [
      for (var i = 0; i < 3; i++)
        math.cos(boreAngle) * los[i] + math.sin(boreAngle) * up[i],
    ];
    var st = <double>[
      for (var i = 0; i < 3; i++) -h * up[i],
      for (var i = 0; i < 3; i++) 275 * dir[i],
    ];
    final wd = env.windDirectionDeg * math.pi / 180;
    final air = [-env.windMps * math.cos(wd), 0.0, env.windMps * math.sin(wd)];
    for (var n = 0; n < 2000000; n++) {
      final prev = st;
      st = _step(st, air, env);
      final a = _dot(prev.sublist(0, 3), los), b = _dot(st.sublist(0, 3), los);
      if (b >= range) {
        final f = (range - a) / (b - a);
        final q = [for (var i = 0; i < 3; i++) prev[i] + (st[i] - prev[i]) * f];
        return (_dot(q, up), _dot(q, right));
      }
    }
    throw StateError('not reached');
  }

  /// Level, cant-free zero in the ICAO zero environment (bisection).
  double zeroAngle() {
    double height(double a) => offsetAt(
      boreAngle: a,
      range: 30,
      inclineDeg: 0,
      cantDeg: 0,
      env: _zeroEnv,
    ).$1;
    var lo = -0.05, hi = 0.25;
    var yLo = height(lo);
    for (var i = 0; i < 60; i++) {
      final mid = (lo + hi) / 2;
      final y = height(mid);
      if (y.sign == yLo.sign) {
        lo = mid;
        yLo = y;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }
}

void main() {
  test('incline 0 and cant 0 give exactly the level answer', () {
    final level = const BallisticEngine().solve(
      BallisticInput(
        muzzleVelocityMps: 275,
        grain: 33.95,
        zeroRangeM: 30,
        sightHeightMm: 62,
        rangesM: const [20, 45, 70],
        environment: _env,
        ballisticCoefficient: 0.08,
        ballisticModel: BallisticModel.g1,
      ),
    );
    final same = const BallisticEngine().solve(_input());
    for (var i = 0; i < level.length; i++) {
      expect(same[i].dropM, level[i].dropM);
      expect(same[i].windMrad, level[i].windMrad);
    }
  });

  final world = _World();
  final zero = world.zeroAngle();
  for (final (incline, cant) in const [
    (30.0, 0.0),
    (-40.0, 0.0),
    (0.0, 12.0),
    (25.0, -8.0),
    (-15.0, 20.0),
    // Beyond vertical and a large cant: no artificial limits.
    (-102.0, 0.0),
    (10.0, 120.0),
  ]) {
    test('drag solver = world-frame reference (∠$incline°, cant $cant°)', () {
      final points = const BallisticEngine().solve(
        _input(incline: incline, cant: cant),
      );
      for (final p in points) {
        final (up, right) = world.offsetAt(
          boreAngle: zero,
          range: p.rangeM,
          inclineDeg: incline,
          cantDeg: cant,
          env: _env,
        );
        // dropM = −up; windMrad = atan2(−right, range).
        expect(p.dropM, closeTo(-up, 2e-5), reason: '${p.rangeM} m drop');
        expect(
          p.windMrad,
          closeTo(math.atan2(-right, p.rangeM) * 1000, 2e-3),
          reason: '${p.rangeM} m lateral',
        );
      }
    });
  }

  test('uphill and downhill both need less elevation than level', () {
    double corr(double incline) => const BallisticEngine()
        .solve(_input(incline: incline, ranges: const [70]))
        .single
        .correctionMrad;
    final level = corr(0);
    expect(corr(30), lessThan(level));
    expect(corr(-30), lessThan(level));
  });

  test('cant to the right sends the shot right (dial left)', () {
    const calm = EnvironmentData(windMps: 0);
    final p = const BallisticEngine()
        .solve(_input(cant: 10, ranges: const [50], env: calm))
        .single;
    // windMrad > 0 means dial RIGHT; a right cant needs LEFT.
    expect(p.windMrad, lessThan(0));
    final q = const BallisticEngine()
        .solve(_input(cant: -10, ranges: const [50], env: calm))
        .single;
    expect(q.windMrad, closeTo(-p.windMrad, 1e-6));
  });

  test('vacuum incline matches the closed form in the inclined frame', () {
    final level = const BallisticEngine()
        .solve(_input(drag: false, ranges: const [60]))
        .single;
    final up = const BallisticEngine()
        .solve(_input(drag: false, incline: 35, ranges: const [60]))
        .single;
    expect(up.correctionMrad, lessThan(level.correctionMrad));
    // θ = 0 vacuum stays the classic formula.
    final classic = const BallisticEngine()
        .vacuumDope(
          muzzleVelocityMps: 275,
          grain: 33.95,
          zeroRangeM: 30,
          sightHeightMm: 62,
          rangesM: const [60],
        )
        .single;
    expect(level.dropM, closeTo(classic.dropM, 1e-12));
  });

  test('vacuum: a canted scope moves the shot sideways (geometry only)', () {
    const calm = EnvironmentData(windMps: 0);
    TrajectoryPoint at(double cant, {double incline = 0}) =>
        const BallisticEngine()
            .solve(
              _input(
                drag: false,
                cant: cant,
                incline: incline,
                env: calm,
                ranges: const [60],
              ),
            )
            .single;
    expect(at(0).windMrad, 0);
    final p = at(10);
    // Right cant → shot right → dial LEFT (windMrad < 0).
    expect(p.windMrad, lessThan(0));
    expect(at(-10).windMrad, closeTo(-p.windMrad, 1e-9));
    // z = ½·g·cosθ·sinφ·t²
    final z =
        0.5 *
        _g *
        math.sin(10 * math.pi / 180) *
        p.timeOfFlightS *
        p.timeOfFlightS;
    expect(p.windMrad, closeTo(math.atan2(-z, 60) * 1000, 1e-9));
    // Uphill/downhill shrink it by cosθ.
    expect(at(10, incline: 40).windMrad.abs(), lessThan(p.windMrad.abs()));
    // Wind still adds nothing without drag.
    final windy = const BallisticEngine()
        .solve(
          _input(
            drag: false,
            env: const EnvironmentData(windMps: 8, windDirectionDeg: 90),
            ranges: const [60],
          ),
        )
        .single;
    expect(windy.windMrad, 0);
  });

  test('incline and cant accept the full circle, nothing beyond', () {
    // Full circle accepted (field apps measure e.g. −102°); beyond it not.
    expect(() => _input(incline: 181), throwsArgumentError);
    expect(() => _input(cant: -181), throwsArgumentError);
    expect(() => _input(incline: double.nan), throwsArgumentError);
  });

  group('Coriolis', () {
    for (final (lat, az, incline, cant) in const [
      (45.0, 0.0, 0.0, 0.0),
      (39.9, 90.0, 0.0, 0.0),
      (41.0, 270.0, 0.0, 0.0),
      (-33.9, 135.0, 0.0, 0.0),
      (38.0, 200.0, 25.0, -8.0),
      (60.0, 45.0, -30.0, 15.0),
    ]) {
      test('drag solver = world-frame reference '
          '(φ $lat°, A $az°, ∠$incline°, cant $cant°)', () {
        final reference = _World.coriolis(lat, az);
        final points = const BallisticEngine().solve(
          _input(incline: incline, cant: cant, latitude: lat, azimuth: az),
        );
        for (final p in points) {
          // The zero is solved level, without cant and without Coriolis.
          final (up, right) = reference.offsetAt(
            boreAngle: zero,
            range: p.rangeM,
            inclineDeg: incline,
            cantDeg: cant,
            env: _env,
          );
          expect(p.dropM, closeTo(-up, 2e-5), reason: '${p.rangeM} m drop');
          expect(
            p.windMrad,
            closeTo(math.atan2(-right, p.rangeM) * 1000, 2e-3),
            reason: '${p.rangeM} m lateral',
          );
        }
      });
    }

    const calm = EnvironmentData(windMps: 0);
    TrajectoryPoint at(double? lat, double? az, {double range = 70}) =>
        const BallisticEngine()
            .solve(
              _input(env: calm, ranges: [range], latitude: lat, azimuth: az),
            )
            .single;

    test('northern hemisphere drifts right, southern left', () {
      final base = at(null, null);
      expect(base.windMrad, closeTo(0, 1e-9));
      // windMrad > 0 means dial RIGHT: a right drift needs LEFT.
      expect(at(40, 0).windMrad, lessThan(0));
      expect(at(-40, 0).windMrad, greaterThan(0));
    });

    test('east shoots high, west low (Eötvös)', () {
      final base = at(null, null).dropM;
      expect(at(40, 90).dropM, lessThan(base));
      expect(at(40, 270).dropM, greaterThan(base));
    });

    test('horizontal drift ≈ ω·sin φ·R·t', () {
      const range = 100.0;
      final p = at(45, 0, range: range);
      final drift = -range * math.tan(p.windMrad / 1000);
      final expected =
          7.2921159e-5 * math.sin(math.pi / 4) * range * p.timeOfFlightS;
      expect(drift, closeTo(expected, expected * 0.35));
      // Air rifle at 100 m: well under a centimetre.
      expect(drift.abs(), lessThan(0.01));
    });

    test('latitude and azimuth come together and stay in range', () {
      expect(() => _input(latitude: 40), throwsArgumentError);
      expect(() => _input(azimuth: 40), throwsArgumentError);
      expect(() => _input(latitude: 91, azimuth: 0), throwsArgumentError);
      expect(() => _input(latitude: 40, azimuth: 361), throwsArgumentError);
    });
  });
}
