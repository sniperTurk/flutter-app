/// Small deterministic fourth-order Runge-Kutta integrator used as the
/// numerical foundation for the future validated G1/G7 trajectory solver.
///
/// This module deliberately contains no drag coefficients. Keeping numerical
/// integration separate from reference drag data lets SNIPER TÜRK validate
/// each layer independently before aerodynamic DOPE is enabled in production.
class Rk4State {
  final double x;
  final double y;
  final double z;
  final double vx;
  final double vy;
  final double vz;

  const Rk4State({
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
  });
}

class Rk4Derivative {
  final double dx;
  final double dy;
  final double dz;
  final double dvx;
  final double dvy;
  final double dvz;

  const Rk4Derivative({
    required this.dx,
    required this.dy,
    required this.dz,
    required this.dvx,
    required this.dvy,
    required this.dvz,
  });
}

typedef Rk4DerivativeFunction = Rk4Derivative Function(Rk4State state);

class Rk4Integrator {
  const Rk4Integrator._();

  static Rk4State step({
    required Rk4State state,
    required double dt,
    required Rk4DerivativeFunction derivative,
  }) {
    if (!dt.isFinite || dt <= 0) {
      throw ArgumentError.value(dt, 'dt', 'must be finite and > 0');
    }
    _validateState(state);

    final k1 = derivative(state);
    _validateDerivative(k1);
    final k2 = derivative(_advance(state, k1, dt / 2));
    _validateDerivative(k2);
    final k3 = derivative(_advance(state, k2, dt / 2));
    _validateDerivative(k3);
    final k4 = derivative(_advance(state, k3, dt));
    _validateDerivative(k4);

    final next = Rk4State(
      x: state.x + dt / 6 * (k1.dx + 2 * k2.dx + 2 * k3.dx + k4.dx),
      y: state.y + dt / 6 * (k1.dy + 2 * k2.dy + 2 * k3.dy + k4.dy),
      z: state.z + dt / 6 * (k1.dz + 2 * k2.dz + 2 * k3.dz + k4.dz),
      vx: state.vx + dt / 6 * (k1.dvx + 2 * k2.dvx + 2 * k3.dvx + k4.dvx),
      vy: state.vy + dt / 6 * (k1.dvy + 2 * k2.dvy + 2 * k3.dvy + k4.dvy),
      vz: state.vz + dt / 6 * (k1.dvz + 2 * k2.dvz + 2 * k3.dvz + k4.dvz),
    );
    _validateState(next);
    return next;
  }

  static Rk4State _advance(Rk4State s, Rk4Derivative k, double scale) =>
      Rk4State(
        x: s.x + k.dx * scale,
        y: s.y + k.dy * scale,
        z: s.z + k.dz * scale,
        vx: s.vx + k.dvx * scale,
        vy: s.vy + k.dvy * scale,
        vz: s.vz + k.dvz * scale,
      );

  static void _validateState(Rk4State s) {
    for (final value in [s.x, s.y, s.z, s.vx, s.vy, s.vz]) {
      if (!value.isFinite) throw StateError('RK4 state must remain finite');
    }
  }

  static void _validateDerivative(Rk4Derivative d) {
    for (final value in [d.dx, d.dy, d.dz, d.dvx, d.dvy, d.dvz]) {
      if (!value.isFinite) {
        throw StateError('RK4 derivative must remain finite');
      }
    }
  }
}
