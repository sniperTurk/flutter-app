import 'dart:math' as math;
import '../models/domain.dart';
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

  /// Production-safe entry point. Aerodynamic requests are never silently
  /// downgraded to the vacuum solver: doing so would produce plausible-looking
  /// but materially wrong long-range DOPE.
  List<TrajectoryPoint> solve(BallisticInput input) {
    if (input.ballisticModel != null || input.ballisticCoefficient != null) {
      throw UnsupportedError(
        'G1/G7 drag solver is not validated yet; aerodynamic DOPE is unavailable.',
      );
    }
    return solveVacuum(input);
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
