# V201

- Fixed the verified lockfile adoption path so it installs both `pubspec.lock` and its matching `lockfile-provenance.txt`.
- Both files are staged before replacement; an interruption can only leave a pair that the existing fail-closed verifier rejects.
- The installed pair is re-verified after replacement.
- Added regression coverage for paired adoption and installed-pair verification.
- No real Flutter/Xcode/iOS build, Simulator, physical-device, archive, or IPA result is claimed by this change.
