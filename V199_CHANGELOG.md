# V199
- Hardened App Store source preflight so a non-empty `pubspec.lock` is no longer sufficient by itself.
- App Store preflight now requires `lockfile-provenance.txt` and fail-closes on missing/malformed provenance, wrong Flutter version, or a pubspec/lockfile SHA-256 mismatch.
- Added regression coverage for missing/tampered provenance and wrong-Flutter provenance.
- No Flutter/Xcode/iOS execution is claimed in this environment.
