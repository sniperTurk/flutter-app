# V263 — isolated independent ballistic validator bootstrap

- Continued from v262; project was not restarted.
- Fixed the validator bootstrap so pinned py-ballisticcalc and dependencies are installed into `.validator_venv` instead of mutating the runner/global Python environment.
- Version verification now executes inside that isolated environment, preventing unrelated host package versions from causing false dependency-drift failures.
- Production G1/G7 gate remains fail-closed: no independent vectors were generated in this run and aerodynamic DOPE was not activated.
- Added two offline regression/contract tests for validator isolation.
