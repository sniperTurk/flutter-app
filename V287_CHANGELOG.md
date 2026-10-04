# V287

- iOS scaffold bootstrap now delegates Flutter/.fvmrc validation to the canonical fail-closed `tools/verify_flutter_toolchain.py` instead of maintaining a second fragile JSON parser.
- Malformed or non-object `flutter --version --machine` output therefore blocks scaffold generation cleanly rather than surfacing a Python traceback from inline JSON indexing.
- Added regression coverage proving the canonical verifier runs before `flutter create` and the duplicate inline parser is gone.
- This does not claim a real iOS build: the current environment still lacks a verified Flutter/Xcode execution path.
