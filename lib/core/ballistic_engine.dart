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

  int clicks({required double correction, required double clickValue}) {
    if (clickValue <= 0) throw ArgumentError('clickValue must be > 0');
    return (correction / clickValue).round();
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
    final a = g * x * x / (2 * muzzleVelocityMps * muzzleVelocityMps);
    final discriminant = x * x - 4 * a * (sightM + a);
    if (discriminant < 0) {
      throw ArgumentError(
        'zeroRangeM is unreachable at this muzzle velocity in the vacuum model',
      );
    }
    final tanBoreAngle = (x - math.sqrt(discriminant)) / (2 * a);
    final boreAngle = math.atan(tanBoreAngle);
    return rangesM
        .map((r) {
          final t = r / (muzzleVelocityMps * math.cos(boreAngle));
          final projectileY =
              -sightM + r * math.tan(boreAngle) - 0.5 * g * t * t;
          final drop = -projectileY;
          final mrad = correctionMrad(offsetM: drop, rangeM: r);
          // A vacuum trajectory has no aerodynamic coupling to the air, so a
          // physically meaningful wind drift cannot be computed here. Returning
          // zero is deliberate: the previous `crossWind * time` approximation
          // implicitly assumed the projectile instantly acquires the full wind
          // velocity and materially overstated drift. Wind correction stays
          // disabled until the validated drag solver is available.
          const windMrad = 0.0;
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
