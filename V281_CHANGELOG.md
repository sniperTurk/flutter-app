# V281

- Hardened `tools/install_pinned_flutter.py` tar extraction against absolute paths, parent traversal, and escaping symlink/hardlink targets.
- Added three regression tests covering traversal rejection, escaping symlink rejection, and normal extraction.
- Full Python tool test suite and compileall pass in this environment.
- No claim of Flutter/iOS build, Simulator, or physical-device validation.
