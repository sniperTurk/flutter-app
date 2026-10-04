# V148

- Added `tools/claude_flutter_verify.sh` as the fail-closed Claude Code/local verification entry point.
- Enforces pinned Flutter version from `.fvmrc`.
- Runs lockfile-safe dependency resolution, formatting, `flutter analyze`, `flutter test`, all offline Python regression tests, and the G1/G7 production gate.
- On macOS + Xcode, additionally bootstraps the iOS scaffold and performs an iOS Simulator build.
- Added explicit first-time `pubspec.lock` bootstrap mode; missing/drifting lockfiles cannot be reported as verified.
- Added `CLAUDE.md` with exact verification/CI truthfulness instructions.
- Added regression coverage protecting the verification entry point and instructions.
