# V166 — fail-closed Dart source hygiene

- Fixed the legacy literal-newline regression regex so it no longer looks for two backslashes when guarding a single literal `\\n` token.
- Added `tools/offline_dart_lint.py`, a dependency-free Dart source lexer that rejects a backslash token outside strings/comments and correctly descends into `${...}` interpolation. This closes the structural blind spot where replacing a physical newline with literal `\\n` also removes the regex's `^` anchor.
- Added direct unit coverage for normal strings, raw strings, comments, interpolation-safe real source, unanchored stray backslashes, and a controlled mutation of `catalog_screen.dart` that replaces a real newline with literal `\\n`.
- Wired the offline Dart lint into iOS CI before Flutter setup.
- Reordered `tools/claude_flutter_verify.sh` so Python compile, offline Dart lint, full unittest discovery, and the closed G1/G7 production gate run before Flutter/Dart availability checks. Offline source regressions therefore remain observable even when Flutter is unavailable.
- Added wiring regressions locking both CI and local verifier ordering.

## Verification performed in this environment

- `python3 -m compileall -q tools`: PASS
- `python3 tools/offline_dart_lint.py`: PASS (53 Dart files, 0 issues)
- `python3 -m unittest discover -s tools -p 'test_*.py' -v`: PASS (88 tests)
- `python3 tools/verify_production_gate.py`: PASS / CLOSED
- `bash -n tools/claude_flutter_verify.sh`: PASS
- `bash -n tools/claude_bootstrap_and_verify.sh`: PASS

Flutter/Xcode/iOS Simulator/device execution was not performed in this environment and is not claimed as passed.
