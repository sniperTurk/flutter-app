# Ballistics / DOPE formula audit (v344)

Scope: the production DOPE path (`ballistic_engine.dart`, `atmosphere.dart`, `units.dart`,
`unit_system.dart`, `ballistics_screen.dart`) and the gated G1/G7 solver.
Method: offline Python re-implementation plus independent numerical integration. This is
**not** the py-ballisticcalc acceptance run; the production gate is now OPEN only through the CI reference comparison (tools/verify_production_gate.py).

## Verified correct
- Vacuum zero angle: closed form `A u^2 - x u + (s + A) = 0` (low root) matches a numerical
  gravity-only RK4 + bisection solution (zero angle to 1e-9 rad; drop, mrad, time of flight to 1e-5).
- MOA/MRAD (1 MOA = 0.290888 mrad), joules <-> ft-lb, grain -> kg, yd/ft/in/mph/inHg/degF conversions.
- Moist-air density (Magnus vapour pressure) and speed of sound (sqrt(gamma P / rho)).
- G1/G7 Cd tables (79/84 points) match the standard BRL/JBM values at the sampled points.
- BC -> retardation convention: `rho*pi*Cd*v^2/(8*BC_SI)` reproduces the published
  2.08551e-04 (fps) constant used by JBM / py-ballisticcalc.
- Drag solver integration + zero + range interpolation: agrees with SciPy DOP853 to ~5e-6 m on the four
  predeclared cases (`tools/offline_solver_crosscheck.py`).

## Model limitation (not a coding error)
The production UI runs the vacuum baseline. Compared with the drag solver on the same inputs:

| case | range | vacuum | with drag | vacuum too small by |
|------|-------|--------|-----------|---------------------|
| PCP, G1 BC 0.12, 270 m/s, zero 25 m | 100 m | 3.24 mrad | 3.86 mrad | 16 % |
| | 300 m | 16.30 mrad | 22.60 mrad | 28 % |
| Rifle, G7 BC 0.243, 800 m/s, zero 100 m | 500 m | 2.70 mrad | 3.97 mrad | 32 % |
| | 800 m | 4.97 mrad | 9.01 mrad | 45 % |

The drag figures come from the unvalidated solver, so they show the order of magnitude of the
vacuum error, not a reference DOPE. Enabling drag DOPE requires the external reference vectors
(`validation/README.md`).
