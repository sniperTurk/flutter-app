import 'dart:math' as math;

import '../models/domain.dart';
import 'ballistic_input.dart';
import 'reference_drag_model.dart';
import 'rk4.dart';
import 'standard_drag_tables.dart';
import 'units.dart';

/// Deterministic 3-D G1/G7 trajectory integrator.
///
/// Called by `BallisticEngine.solve()` for requests that carry a ballistic
/// coefficient and drag law. Its no-wind and wind output is compared with an
/// independent reference trajectory (py-ballisticcalc) in CI under the frozen
/// tolerances of `validation/acceptance.json`; `tools/verify_production_gate.py`
/// fails the build if that comparison is no longer wired into CI.
class AerodynamicTrajectorySolver {
  static const double _g = 9.80665;
  static const int _maxSteps = 4000000;

  /// No real shot flies this long. A projectile that has not reached the
  /// requested range by then (a slow, high-drag pellet asked for a far range)
  /// is reported as unreachable instead of integrating for minutes.
  static const double maxFlightTimeS = 60.0;

  /// Fixed RK4 integration step. Exposed only to support deterministic
  /// convergence checks before the solver is allowed into production DOPE.
  /// Production callers should keep the default.
  final double integrationStepSeconds;

  const AerodynamicTrajectorySolver({this.integrationStepSeconds = 0.0005});

  void _validateStep() {
    if (!integrationStepSeconds.isFinite ||
        integrationStepSeconds <= 0 ||
        integrationStepSeconds > 0.01) {
      throw ArgumentError.value(
        integrationStepSeconds,
        'integrationStepSeconds',
        'must be finite, > 0 and <= 0.01 s',
      );
    }
  }

  /// The solver works in the frame of the (possibly inclined and canted)
  /// scope: x along the line of sight, y the scope's "up" and z its "right".
  /// Gravity and the horizontal wind are rotated into that frame, so the
  /// sampled y/z are directly what the scope's turrets must correct.
  ///   incline θ (LOS above horizontal) and cant φ (clockwise roll):
  ///   g = (−g·sinθ, −g·cosθ·cosφ, +g·cosθ·sinφ)
  ///   air(ax, 0, az) → (ax·cosθ, −ax·sinθ·cosφ + az·sinφ,
  ///                     az·cosφ + ax·sinθ·sinφ)
  /// With θ = φ = 0 this is exactly the level solver used before.
  static _Frame _frameFor({
    required double inclineDeg,
    required double cantDeg,
    double? latitudeDeg,
    double? azimuthDeg,
  }) {
    final t = inclineDeg * math.pi / 180;
    final p = cantDeg * math.pi / 180;
    final sinT = math.sin(t), cosT = math.cos(t);
    final sinP = math.sin(p), cosP = math.cos(p);
    var ox = 0.0, oy = 0.0, oz = 0.0;
    if (latitudeDeg != null && azimuthDeg != null) {
      // Earth's rotation in the local horizontal frame (forward along the
      // shot azimuth, up, right): Ω = ω·(cosφ·cosA, sinφ, −cosφ·sinA),
      // then into the scope frame exactly like gravity and wind.
      const omega = 7.2921159e-5; // rad/s
      final lat = latitudeDeg * math.pi / 180;
      final az = azimuthDeg * math.pi / 180;
      final f = omega * math.cos(lat) * math.cos(az);
      final u = omega * math.sin(lat);
      final r = -omega * math.cos(lat) * math.sin(az);
      ox = f * cosT + u * sinT;
      final y1 = -f * sinT + u * cosT;
      oy = y1 * cosP + r * sinP;
      oz = r * cosP - y1 * sinP;
    }
    return _Frame(sinT, cosT, sinP, cosP, ox, oy, oz);
  }

  /// G1/G7/GA trajectory including vector wind coupling.
  ///
  /// Wind degrees (internal): 0° = headwind, 90° = from the LEFT (saat 9),
  /// 180° = tailwind, 270° = from the right (saat 3); see WindClock. The UI
  /// shows clock hours only, so users never see these degrees. The wind vector
  /// represents moving air, so drag is computed from projectile velocity
  /// relative to that air mass.
  List<TrajectoryPoint> solve(BallisticInput input) {
    _validateStep();
    final model = input.ballisticModel;
    if (input.ballisticCoefficient == null || model == null) {
      throw ArgumentError(
        'ballisticCoefficient and ballisticModel (G1/G7/GA) are required',
      );
    }
    final drag = ReferenceDragModel(switch (model) {
      BallisticModel.g1 => StandardDragTables.g1,
      BallisticModel.g7 => StandardDragTables.g7,
      BallisticModel.ga => StandardDragTables.ga,
    });
    // BC as a function of air-relative speed (çoklu BC; constant without
    // bands).
    final bc = input.bcAtSpeed;
    // The sight setting is a mechanical launch angle established at zeroing;
    // it must not be silently re-zeroed for the current shot's wind/weather.
    // Zeroing conditions are distinct from the current shot environment.
    // This preserves the mechanical sight setting across weather changes.
    final angle = _zeroAngle(input, drag, bc);
    final frame = _frameFor(
      inclineDeg: input.inclineDeg,
      cantDeg: input.cantDeg,
      latitudeDeg: input.latitudeDeg,
      azimuthDeg: input.azimuthDeg,
    );
    final wanted = input.rangesM.toList()..sort();
    final results = <double, TrajectoryPoint>{};
    var state = _initialState(input, angle);
    var time = 0.0;
    var nextIndex = 0;

    for (var step = 0; step < _maxSteps && nextIndex < wanted.length; step++) {
      final previous = state;
      final previousTime = time;
      state = Rk4Integrator.step(
        state: state,
        dt: integrationStepSeconds,
        derivative: (s) => _derivative(
          s,
          drag,
          bc,
          input.environment,
          frame,
          windMps: input.windAt(s.x),
        ),
      );
      time += integrationStepSeconds;
      if (state.vx <= 0) {
        throw StateError('projectile stopped before requested range');
      }
      if (time > maxFlightTimeS) {
        throw StateError('projectile did not reach the requested range');
      }

      while (nextIndex < wanted.length && state.x >= wanted[nextIndex]) {
        final range = wanted[nextIndex];
        final span = state.x - previous.x;
        final f = span == 0 ? 0.0 : (range - previous.x) / span;
        final y = _lerp(previous.y, state.y, f);
        final vx = _lerp(previous.vx, state.vx, f);
        final vy = _lerp(previous.vy, state.vy, f);
        final vz = _lerp(previous.vz, state.vz, f);
        final tof = _lerp(previousTime, time, f);
        // Report true 3-D ground speed. Once crosswind coupling changes vz,
        // omitting the lateral component understates velocity and kinetic energy.
        final speed = math.sqrt(vx * vx + vy * vy + vz * vz);
        final drop = -y;
        final mrad = math.atan2(drop, range) * 1000;
        results[range] = TrajectoryPoint(
          rangeM: range,
          dropM: drop,
          correctionMrad: mrad,
          correctionMoa: Units.mradToMoa(mrad),
          velocityMps: speed,
          energyJ: 0.5 * Units.grainToKg(input.grain) * speed * speed,
          timeOfFlightS: tof,
          windMrad: math.atan2(-_lerp(previous.z, state.z, f), range) * 1000,
        );
        nextIndex++;
      }
    }
    // `results` is keyed by range, so duplicate requested ranges intentionally
    // collapse to one sampled point. Completion must therefore be checked by
    // how many requests were consumed, not by the map's unique-key count.
    // Otherwise a valid input such as [50, 50, 100] integrates successfully
    // and then fails after the trajectory has already reached every request.
    if (nextIndex != wanted.length) {
      throw StateError(
        'trajectory integration did not reach every requested range',
      );
    }
    return input.rangesM.map((r) => results[r]!).toList(growable: false);
  }

  /// Backward-compatible no-wind validation entry point.
  List<TrajectoryPoint> solveNoWind(BallisticInput input) {
    if (input.environment.windMps != 0) {
      throw ArgumentError(
        'solveNoWind requires windMps == 0; use solve() for vector wind experiments',
      );
    }
    return solve(input);
  }

  double _zeroAngle(
    BallisticInput input,
    ReferenceDragModel drag,
    double Function(double) bc,
  ) {
    // Normal rifle/PCP zeroing should live inside this deliberately conservative
    // bracket. Failure is safer than silently selecting a high-angle solution.
    var low = -0.05;
    var high = 0.25;
    var yLow = _heightAtRange(input, drag, bc, low, input.zeroRangeM);
    var yHigh = _heightAtRange(input, drag, bc, high, input.zeroRangeM);
    if (yLow == 0) return low;
    if (yHigh == 0) return high;
    if (yLow.sign == yHigh.sign) {
      throw StateError(
        'could not bracket a low-angle aerodynamic zero solution',
      );
    }
    for (var i = 0; i < 60; i++) {
      final mid = (low + high) / 2;
      final yMid = _heightAtRange(input, drag, bc, mid, input.zeroRangeM);
      if (yMid.abs() < 1e-8) return mid;
      if (yMid.sign == yLow.sign) {
        low = mid;
        yLow = yMid;
      } else {
        high = mid;
        yHigh = yMid;
      }
    }
    return (low + high) / 2;
  }

  double _heightAtRange(
    BallisticInput input,
    ReferenceDragModel drag,
    double Function(double) bc,
    double angle,
    double range,
  ) {
    // The zero was established with the zero-day velocity.
    var state = _initialState(input, angle, input.zeroVelocityMps);
    for (var step = 0; step < _maxSteps; step++) {
      final previous = state;
      state = Rk4Integrator.step(
        state: state,
        dt: integrationStepSeconds,
        // The zero is established level and without cant.
        derivative: (s) =>
            _derivative(s, drag, bc, input.zeroEnvironment, _Frame.level),
      );
      if (state.x >= range) {
        final f = (range - previous.x) / (state.x - previous.x);
        return _lerp(previous.y, state.y, f);
      }
      if (state.vx <= 0) break;
    }
    throw StateError('projectile did not reach zero range');
  }

  Rk4State _initialState(
    BallisticInput input,
    double angle, [
    double? velocityMps,
  ]) {
    final v = velocityMps ?? input.muzzleVelocityMps;
    return Rk4State(
      x: 0,
      y: -input.sightHeightMm / 1000,
      z: 0,
      vx: v * math.cos(angle),
      vy: v * math.sin(angle),
      vz: 0,
    );
  }

  Rk4Derivative _derivative(
    Rk4State s,
    ReferenceDragModel drag,
    double Function(double) bc,
    EnvironmentData env,
    _Frame f, {
    double? windMps,
  }) {
    final directionRad = env.windDirectionDeg * math.pi / 180;
    // Rüzgâr bölgeleri: the caller may pass the wind at this distance.
    final w = windMps ?? env.windMps;
    // 0° is a headwind: air moves toward the shooter (-x). 90° moves in +z.
    // Horizontal (world) components, then rotated into the scope frame.
    final ax = -w * math.cos(directionRad);
    final az = w * math.sin(directionRad);
    final airVx = ax * f.cosT;
    final airVy = -ax * f.sinT * f.cosP + az * f.sinP;
    final airVz = az * f.cosP + ax * f.sinT * f.sinP;
    final relativeVx = s.vx - airVx;
    final relativeVy = s.vy - airVy;
    final relativeVz = s.vz - airVz;
    final relativeSpeed = math.sqrt(
      relativeVx * relativeVx +
          relativeVy * relativeVy +
          relativeVz * relativeVz,
    );
    final decel = drag.decelerationMps2(
      speedMps: relativeSpeed,
      ballisticCoefficient: bc(relativeSpeed),
      environment: env,
    );
    final scale = relativeSpeed == 0 ? 0.0 : -decel / relativeSpeed;
    return Rk4Derivative(
      dx: s.vx,
      dy: s.vy,
      // Position must integrate the projectile's lateral velocity. Keeping
      // dz at zero makes crosswind acceleration invisible in sampled drift
      // even though vz changes, producing a false zero-wind correction.
      dz: s.vz,
      // Coriolis: a = −2·Ω × v (zero when Ω = 0).
      dvx: scale * relativeVx - _g * f.sinT - 2 * (f.oy * s.vz - f.oz * s.vy),
      dvy:
          scale * relativeVy -
          _g * f.cosT * f.cosP -
          2 * (f.oz * s.vx - f.ox * s.vz),
      dvz:
          scale * relativeVz +
          _g * f.cosT * f.sinP -
          2 * (f.ox * s.vy - f.oy * s.vx),
    );
  }

  double _lerp(double a, double b, double f) => a + (b - a) * f;
}

/// Sines and cosines of the shot incline (T) and scope cant (P).
class _Frame {
  final double sinT, cosT, sinP, cosP;

  /// Earth's rotation vector in the scope frame (rad/s); zero = no Coriolis.
  final double ox, oy, oz;
  const _Frame(
    this.sinT,
    this.cosT,
    this.sinP,
    this.cosP, [
    this.ox = 0,
    this.oy = 0,
    this.oz = 0,
  ]);
  static const level = _Frame(0, 1, 0, 1);
}
