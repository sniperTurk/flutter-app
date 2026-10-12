import 'atmosphere.dart';
import 'drag_table.dart';
import '../models/domain.dart';

/// Converts a standard G-function Cd table plus a conventional G1/G7
/// ballistic coefficient into along-velocity drag deceleration.
///
/// Conventional small-arms BC is expressed in lb/in² relative to the selected
/// G reference projectile.  Converting that sectional-density unit explicitly
/// avoids the easy-to-miss error of treating BC as an SI dimensionless scalar.
/// For the reference projectile the form factor is 1, therefore:
///
///   a = 0.5 * rho * Cd * (pi/4) * v² / BC_SI
///   BC_SI = BC(lb/in²) * 703.06957964 kg/m²
///
/// The pi/4 term comes from reference area / diameter².  This is algebraically
/// equivalent to using a 1 lb, 1 inch unit-BC reference projectile, but the
/// conversion is kept explicit so it can be independently audited.
///
/// This primitive is intentionally NOT wired to production DOPE until the
/// complete trajectory solver is cross-validated against an independent
/// external-ballistics reference dataset.
class ReferenceDragModel {
  static const double poundsPerSquareInchToKgPerSquareMeter = 703.0695796391593;
  static const double _pi = 3.14159265358979323846;

  final DragTable table;
  const ReferenceDragModel(this.table);

  /// Converts a conventional G1/G7 BC to its SI sectional-density scale.
  static double ballisticCoefficientKgPerM2(double ballisticCoefficient) {
    if (!ballisticCoefficient.isFinite || ballisticCoefficient <= 0) {
      throw ArgumentError.value(
        ballisticCoefficient,
        'ballisticCoefficient',
        'must be finite and > 0',
      );
    }
    return ballisticCoefficient * poundsPerSquareInchToKgPerSquareMeter;
  }

  /// Positive deceleration magnitude in m/s².
  double decelerationMps2({
    required double speedMps,
    required double ballisticCoefficient,
    required EnvironmentData environment,
  }) {
    if (!speedMps.isFinite || speedMps < 0) {
      throw ArgumentError.value(
        speedMps,
        'speedMps',
        'must be finite and >= 0',
      );
    }
    final bcSi = ballisticCoefficientKgPerM2(ballisticCoefficient);
    if (speedMps == 0) return 0;

    final rho = Atmosphere.densityKgM3(environment);
    final mach = Atmosphere.machNumber(
      velocityMps: speedMps,
      environment: environment,
    );
    final cd = table.coefficientAtMach(mach);
    return 0.5 * rho * cd * (_pi / 4) * speedMps * speedMps / bcSi;
  }
}
