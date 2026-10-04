# V284 CHANGELOG

- Hardened `tools/verify_flutter_toolchain.py` to fail closed when `flutter --version --machine` returns valid JSON whose root is not an object (for example `[]`).
- Added one regression test for non-object JSON toolchain output.
- Full Python suite: 340/340 passing in this environment.
- Python compileall: passing.
- No claim of Flutter analyze/test, iOS build, Simulator, or physical iPhone validation; those were not run successfully in this environment.
