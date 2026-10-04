import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/rk4.dart';

void main() {
  test('RK4 reproduces constant-gravity analytic motion', () {
    const g = 9.80665;
    var state = const Rk4State(x: 0, y: 0, z: 0, vx: 100, vy: 10, vz: 0);
    const dt = 0.01;
    for (var i = 0; i < 100; i++) {
      state = Rk4Integrator.step(
        state: state,
        dt: dt,
        derivative: (s) => Rk4Derivative(
          dx: s.vx,
          dy: s.vy,
          dz: s.vz,
          dvx: 0,
          dvy: -g,
          dvz: 0,
        ),
      );
    }
    expect(state.x, closeTo(100, 1e-9));
    expect(state.y, closeTo(10 - 0.5 * g, 1e-9));
    expect(state.vy, closeTo(10 - g, 1e-9));
  });

  test('RK4 rejects invalid time step', () {
    expect(
      () => Rk4Integrator.step(
        state: const Rk4State(x: 0, y: 0, z: 0, vx: 1, vy: 0, vz: 0),
        dt: 0,
        derivative: (s) =>
            const Rk4Derivative(dx: 1, dy: 0, dz: 0, dvx: 0, dvy: 0, dvz: 0),
      ),
      throwsArgumentError,
    );
  });
}
