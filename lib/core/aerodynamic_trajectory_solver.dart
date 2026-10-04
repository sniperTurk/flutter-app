import 'dart:math' as math;

import '../models/domain.dart';
import 'ballistic_input.dart';
import 'reference_drag_model.dart';
import 'rk4.dart';
import 'standard_drag_tables.dart';
import 'units.dart';

/// Experimental, deterministic 3-D G1/G7 trajectory integrator.
///
/// This is deliberately not called by BallisticEngine.solve() yet. Production
/// activation requires cross-validation against an independent reference
/// trajectory dataset. Keeping this class separate prevents an unvalidated
/// solver from leaking into user-visible DOPE.
class AerodynamicTrajectorySolver {
  static const double _g = 9.80665;
  static const int _maxSteps = 4000000;

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

  /// Experimental G1/G7 trajectory including vector wind coupling.
  ///
  /// Wind convention follows the UI: 0° = headwind, 90° = full-value
  /// crosswind, 180° = tailwind, 270° = opposite crosswind. The wind vector
  /// represents moving air, so drag is computed from projectile velocity
  /// relative to that air mass. This remains experimental until external
  /// trajectory-vector cross-validation is complete.
  List<TrajectoryPoint> solve(BallisticInput input) {
    _validateStep();
    final bc = input.ballisticCoefficient;
    final model = input.ballisticModel;
    if (bc == null || model == null) {
      throw ArgumentError('G1/G7 ballisticCoefficient and ballisticModel are required');
    }
    final drag = ReferenceDragModel(
      model == BallisticModel.g1 ? StandardDragTables.g1 : StandardDragTables.g7,
    );
    // The sight setting is a mechanical launch angle established at zeroing;
    // it must not be silently re-zeroed for the current shot's wind/weather.
    // Zeroing conditions are distinct from the current shot environment.
    // This preserves the mechanical sight setting across weather changes.
    final angle = _zeroAngle(input, drag, bc);
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
        derivative: (s) => _derivative(s, drag, bc, input.environment),
      );
      time += integrationStepSeconds;
      if (state.vx <= 0) throw StateError('projectile stopped before requested range');

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
      throw StateError('trajectory integration did not reach every requested range');
    }
    return input.rangesM.map((r) => results[r]!).toList(growable: false);
  }

  /// Backward-compatible no-wind validation entry point.
  List<TrajectoryPoint> solveNoWind(BallisticInput input) {
    if (input.environment.windMps != 0) {
      throw ArgumentError('solveNoWind requires windMps == 0; use solve() for vector wind experiments');
    }
    return solve(input);
  }

  double _zeroAngle(BallisticInput input, ReferenceDragModel drag, double bc) {
    // Normal rifle/PCP zeroing should live inside this deliberately conservative
    // bracket. Failure is safer than silently selecting a high-angle solution.
    var low = -0.05;
    var high = 0.25;
    var yLow = _heightAtRange(input, drag, bc, low, input.zeroRangeM);
    var yHigh = _heightAtRange(input, drag, bc, high, input.zeroRangeM);
    if (yLow == 0) return low;
    if (yHigh == 0) return high;
    if (yLow.sign == yHigh.sign) {
      throw StateError('could not bracket a low-angle aerodynamic zero solution');
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

  double _heightAtRange(BallisticInput input, ReferenceDragModel drag, double bc, double angle, double range) {
    var state = _initialState(input, angle);
    for (var step = 0; step < _maxSteps; step++) {
      final previous = state;
      state = Rk4Integrator.step(
        state: state,
        dt: integrationStepSeconds,
        derivative: (s) => _derivative(s, drag, bc, input.zeroEnvironment),
      );
      if (state.x >= range) {
        final f = (range - previous.x) / (state.x - previous.x);
        return _lerp(previous.y, state.y, f);
      }
      if (state.vx <= 0) break;
    }
    throw StateError('projectile did not reach zero range');
  }

  Rk4State _initialState(BallisticInput input, double angle) => Rk4State(
    x: 0,
    y: -input.sightHeightMm / 1000,
    z: 0,
    vx: input.muzzleVelocityMps * math.cos(angle),
    vy: input.muzzleVelocityMps * math.sin(angle),
    vz: 0,
  );

  Rk4Derivative _derivative(Rk4State s, ReferenceDragModel drag, double bc, EnvironmentData env) {
    final directionRad = env.windDirectionDeg * math.pi / 180;
    // 0° is a headwind: air moves toward the shooter (-x). 90° moves in +z.
    final airVx = -env.windMps * math.cos(directionRad);
    final airVz = env.windMps * math.sin(directionRad);
    final relativeVx = s.vx - airVx;
    final relativeVy = s.vy;
    final relativeVz = s.vz - airVz;
    final relativeSpeed = math.sqrt(
      relativeVx * relativeVx + relativeVy * relativeVy + relativeVz * relativeVz,
    );
    final decel = drag.decelerationMps2(
      speedMps: relativeSpeed,
      ballisticCoefficient: bc,
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
      dvx: scale * relativeVx,
      dvy: scale * relativeVy - _g,
      dvz: scale * relativeVz,
    );
  }

  double _lerp(double a, double b, double f) => a + (b - a) * f;
}
