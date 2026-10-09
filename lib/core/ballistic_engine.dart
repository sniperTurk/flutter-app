import 'dart:math' as math;

import '../models/domain.dart';
import 'aerodynamic_trajectory_solver.dart';
import 'units.dart';
import 'ballistic_input.dart';

class BallisticEngine {
  const BallisticEngine();
  double energyJ({required double grain, required double velocityMps}) =>
      0.5 * Units.grainToKg(grain) * velocityMps * velocityMps;
  double correctionMrad({required double offsetM, required double rangeM}) {
    if (rangeM <= 0) throw ArgumentError('rangeM must be > 0');
    return math.atan2(offsetM, rangeM) * 1000;
  }

  /// Production entry point.
  ///
  /// With a ballistic coefficient and drag law (G1/G7) the aerodynamic solver
  /// is used. Its output has been compared with an independent reference
  /// (py-ballisticcalc) in CI under the frozen tolerances in
  /// `validation/acceptance.json`, for G1 and G7, with and without wind;
  /// `tools/verify_production_gate.py` fails the build if that comparison is
  /// removed from CI. Without a coefficient the labelled vacuum baseline runs.
  /// An aerodynamic request is never silently downgraded to the vacuum solver:
  /// that would produce plausible-looking but materially wrong DOPE.
  ///
  /// The aerodynamic solver throws [StateError] when the projectile cannot
  /// reach a requested range; callers must say so instead of inventing a value.
  List<TrajectoryPoint> solve(BallisticInput input) {
    if (input.ballisticModel != null || input.ballisticCoefficient != null) {
      return const AerodynamicTrajectorySolver().solve(input);
    }
    return solveVacuum(input);
  }

  /// Like [solve], but a range the projectile cannot reach is reported
  /// instead of failing the whole request. The farthest unreachable ranges are
  /// dropped one by one; [unreachableM] lists them (ascending). When nothing
  /// can be solved (for example the zero cannot be found) [points] is empty.
  ({List<TrajectoryPoint> points, List<double> unreachableM}) solveReachable(
    BallisticInput input,
  ) {
    var wanted = input.rangesM.toSet().toList()..sort();
    final dropped = <double>[];
    while (wanted.isNotEmpty) {
      try {
        final points = solve(input.withRanges(wanted));
        return (points: points, unreachableM: dropped.reversed.toList());
      } on StateError {
        dropped.add(wanted.last);
        wanted = wanted.sublist(0, wanted.length - 1);
      }
    }
    return (points: const [], unreachableM: dropped.reversed.toList());
  }

  List<TrajectoryPoint> solveVacuum(BallisticInput input) => vacuumDope(
    muzzleVelocityMps: input.muzzleVelocityMps,
    grain: input.grain,
    zeroRangeM: input.zeroRangeM,
    sightHeightMm: input.sightHeightMm,
    rangesM: input.rangesM,
    environment: input.environment,
    inclineDeg: input.inclineDeg,
    cantDeg: input.cantDeg,
    zeroVelocityMps: input.zeroMuzzleVelocityMps,
  );

  /// Deterministic baseline trajectory. This is intentionally documented as a
  /// vacuum/gravity solver, not a G1/G7 drag solver. It gives a testable V1
  /// baseline and must not be presented as drag-corrected external ballistics.
  List<TrajectoryPoint> vacuumDope({
    required double muzzleVelocityMps,
    required double grain,
    required double zeroRangeM,
    required double sightHeightMm,
    required Iterable<double> rangesM,
    EnvironmentData environment = const EnvironmentData(),
    double inclineDeg = 0,
    double cantDeg = 0,

    /// Velocity on the zeroing day, when it differs (barut sıcaklığı).
    double? zeroVelocityMps,
  }) {
    if (muzzleVelocityMps <= 0 || zeroRangeM <= 0) {
      throw ArgumentError('velocity and zero must be > 0');
    }
    const g = 9.80665;
    final sightM = sightHeightMm / 1000;
    // Solve the launch angle against the line of sight exactly for the
    // vacuum model. Using atan((gravityDrop + sightHeight) / zeroRange) is
    // only an approximation because time of flight itself depends on cos(angle).
    // With u = tan(angle), the zero condition becomes:
    //   A*u^2 - x*u + (s + A) = 0, A = g*x^2/(2*v^2).
    // Select the low-angle root used by a normal sighted rifle.
    final x = zeroRangeM;
    final vZero = zeroVelocityMps ?? muzzleVelocityMps;
    if (vZero <= 0) throw ArgumentError('zero velocity must be > 0');
    final a = g * x * x / (2 * vZero * vZero);
    final discriminant = x * x - 4 * a * (sightM + a);
    if (discriminant < 0) {
      throw ArgumentError(
        'zeroRangeM is unreachable at this muzzle velocity in the vacuum model',
      );
    }
    final tanBoreAngle = (x - math.sqrt(discriminant)) / (2 * a);
    final boreAngle = math.atan(tanBoreAngle);
    // The zero is level; the shot may be inclined (θ) and canted (φ). In the
    // scope frame gravity is (−g·sinθ, −g·cosθ·cosφ, g·cosθ·sinφ): constant,
    // so the vacuum trajectory stays closed-form. θ = φ = 0 reproduces the
    // level formula exactly.
    final theta = inclineDeg * math.pi / 180;
    final phi = cantDeg * math.pi / 180;
    final gAlong = -g * math.sin(theta);
    final gUp = -g * math.cos(theta) * math.cos(phi);
    final gRight = g * math.cos(theta) * math.sin(phi);
    final vAlong = muzzleVelocityMps * math.cos(boreAngle);
    final vUp = muzzleVelocityMps * math.sin(boreAngle);
    return rangesM
        .map((r) {
          // r = vAlong·t + ½·gAlong·t²  →  stable root form (also for g=0).
          final disc = vAlong * vAlong + 2 * gAlong * r;
          if (disc < 0) {
            throw StateError('projectile did not reach the requested range');
          }
          final t = 2 * r / (vAlong + math.sqrt(disc));
          final projectileY = -sightM + vUp * t + 0.5 * gUp * t * t;
          final drop = -projectileY;
          final mrad = correctionMrad(offsetM: drop, rangeM: r);
          // A vacuum trajectory has no aerodynamic coupling to the air, so a
          // physically meaningful WIND drift cannot be computed here: wind
          // adds nothing (the old `crossWind * time` guess overstated it).
          // A canted scope, however, tips part of gravity sideways — that is
          // plain geometry, valid without drag (owner, 2026-10-09): the
          // pellet goes ½·g·cosθ·sinφ·t² toward the canted side. With no
          // cant this is exactly zero.
          final projectileZ = 0.5 * gRight * t * t;
          final windMrad = math.atan2(-projectileZ, r) * 1000;
          return TrajectoryPoint(
            rangeM: r,
            dropM: drop,
            correctionMrad: mrad,
            correctionMoa: Units.mradToMoa(mrad),
            velocityMps: muzzleVelocityMps,
            energyJ: energyJ(grain: grain, velocityMps: muzzleVelocityMps),
            timeOfFlightS: t,
            windMrad: windMrad,
          );
        })
        .toList(growable: false);
  }
}
