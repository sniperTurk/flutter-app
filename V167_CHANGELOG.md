# SNIPER TÜRK V1 — v167

v167 continues directly from the accessible v166 source tree; it does not restart the project.

## Production hardening
- Fixed `tools/offline_dart_lint.py::scan(root=...)` so an explicit root is actually honored instead of always scanning the repository-global directories.
- Hardened the dependency-free Dart lexer to explicitly consume Dart simple `$identifier` interpolation in non-raw strings, complementing the existing `${...}` interpolation handling.
- Added direct regression tests for both behaviors.

## Verification scope
Offline Python compile/tests, the G1/G7 production gate, dependency-free Dart lint, shell syntax, and archive hygiene are verified during packaging. Flutter/Xcode/Simulator/device results are not claimed unless actually executed in the required toolchain.
