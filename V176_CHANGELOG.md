# V176

- Added a fail-closed built-archive iOS privacy-manifest gate.
- CI now inspects `Runner.xcarchive` after the unsigned IPA/archive build and before artifact upload.
- The gate requires at least one parseable `PrivacyInfo.xcprivacy` carrying a non-empty required-reason API declaration; it does not claim App Review compliance.
- Added unit coverage for missing, empty, malformed, and valid manifests plus CI ordering regression coverage.
- No Flutter/Xcode/Simulator/device execution was claimed in this environment.
