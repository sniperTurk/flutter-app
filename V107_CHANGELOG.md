# V107 changelog

- Added `tools/verify_production_gate.py`, an executable fail-closed policy check for the unvalidated G1/G7 production path.
- CI now verifies that `BallisticEngine.solve()` still rejects aerodynamic requests and has no direct dependency on `AerodynamicTrajectorySolver` while `validation/acceptance.json` requires the gate to remain closed.
- Added the gate verifier to Python syntax validation in iOS CI.
- No claim is made that independent G1/G7 vector comparison, Flutter tests, or iOS builds passed in this environment.
