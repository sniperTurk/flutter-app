# V171 — pinned Flutter toolchain gate

- Continued from v170; no project restart.
- Added `tools/verify_flutter_toolchain.py`, a fail-closed machine-readable check that requires the runtime Flutter framework version to be exactly `3.47.2`.
- Wired the verifier immediately after Flutter setup and before dependency resolution in iOS CI. Merely printing `flutter --version` no longer counts as enforcing the release toolchain contract.
- Added unit tests for exact-version acceptance, version drift, missing version, malformed output, and CI ordering.
- This does **not** claim a real Flutter/iOS build: Flutter/Xcode are unavailable in the local validation environment. CI must execute the new gate on macOS.
