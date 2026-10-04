# V149

- Replaced the hand-maintained CI `py_compile` file list with recursive `python3 -m compileall -q tools`.
- This closes a release-CI coverage gap where a newly added non-test Python helper could contain a syntax error yet be omitted from the explicit compile list.
- Added `test_ios_ci_python_compile_wiring.py` to prevent regression back to a partial compile list.
- No Flutter/iOS build success is claimed; those still require the pinned Flutter SDK and macOS/Xcode runner.
