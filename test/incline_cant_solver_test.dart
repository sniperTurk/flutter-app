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
);

typedef _V = List<double>;
double _dot(_V a, _V b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

/// World axes: [forward (horizontal), up, right].
class _World {
  final ReferenceDragModel drag = ReferenceDragModel(StandardDragTables.g1);

  _V _accel(_V v, _V air, EnvironmentData env) {
    final rv = [v[0] - air[0], v[1] - air[1], v[2] - air[2]];
    final speed = math.sqrt(_dot(rv, rv));
    final decel = drag.decelerationMps2(
      speedMps: speed,
      ballisticCoefficient: 0.08,
      environment: env,
    );
    final s = speed == 0 ? 0.0 : -decel / speed;
    return [s * rv[0], s * rv[1] - _g, s * rv[2]];
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

  test('incline and cant outside the limits are rejected', () {
    expect(() => _input(incline: 85), throwsArgumentError);
    expect(() => _input(cant: -50), throwsArgumentError);
    expect(() => _input(incline: double.nan), throwsArgumentError);
  });
}
