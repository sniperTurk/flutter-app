# V282

- Hardened official Flutter ZIP extraction to fail closed on absolute paths, parent traversal, Windows-style absolute paths, and Unix symlink entries.
- Added four ZIP extraction regression tests (normal member + three hostile archive cases).
- Full Python suite: 336/336 passing.
- Python compileall: passing.
- Real Flutter/iOS build, Simulator, and physical iPhone tests remain unverified in this environment.
