# V283

- Hardened `tools/verify_flutter_toolchain.py` so the release verifier reads the project Flutter pin from `.fvmrc` fail-closed before invoking Flutter.
- Rejects missing, malformed, non-UTF-8, non-object, empty-version, and symlinked `.fvmrc` inputs instead of silently relying only on a duplicated hard-coded value.
- Cross-checks the project pin against the release policy pin to expose version drift explicitly.
- Added 3 regression tests for valid pin loading, malformed JSON, and symlink rejection.
- Full Python tool test suite: 339/339 PASS.
- `python -m compileall -q tools`: PASS.
- No claim of Flutter/iOS build, Simulator, or physical-device validation in this environment.
