# V276

- Hardened App Store source preflight against symlink substitution beyond the lockfile trio.
- `.fvmrc`, `tools/bootstrap_ios_scaffold.sh`, `release/ios/PrivacyInfo.xcprivacy`, and every required iOS scaffold file must now be regular files; symlinks fail closed.
- Added regression coverage for five representative release-input symlink substitutions.
- No Flutter/Xcode/Simulator/device result is claimed by this change.
