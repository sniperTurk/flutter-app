# V208

Continues directly from V207.

## Production change

- App Store source preflight now validates the app-owned `release/ios/PrivacyInfo.xcprivacy` before Flutter/Xcode work begins.
- Missing, unreadable, malformed, or structurally invalid source privacy manifests fail closed.
- The source manifest must contain a recognized required-reason API declaration from the same allowlist used by the built-archive privacy gate (`NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1` for the current dependency contract).
- The existing archive verifier remains authoritative for proving that privacy metadata survives into the built `Runner.app`; this new check only catches a broken release template earlier.

## Regression coverage

- Missing and malformed source privacy manifest.
- Structurally valid manifest with no recognized required-reason declaration.

## Verification in this environment

- Python unittest discovery: 237/237 PASS.
- Python compileall: PASS.
- Offline Dart lint: PASS (55 Dart files, 0 issues).
- Production G1/G7 gate contract: CLOSED / fail-closed contract verified.
- Shell syntax (`tools/*.sh`): PASS.
- GitHub Actions YAML parse: PASS.
- Real Dart/Flutter/Xcode/Simulator/device/archive execution: NOT RUN in this environment.
