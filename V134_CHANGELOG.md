# V134 CHANGELOG

- Hardened App Store source preflight against protected-iOS-capability metadata drift.
- Preflight now scans Dart source for camera, microphone, location, or photo-library capability markers and fail-closes when the generated `Info.plist` lacks the corresponding non-empty iOS purpose string.
- Added regression coverage for camera capability detection and empty location-purpose strings.
- No claim is made that static scanning proves runtime privacy behavior; App Store Connect privacy answers, Xcode privacy report/archive/signing, Simulator/device validation, a resolver-generated lockfile, hosted privacy-policy URL, and generated iOS scaffold remain external/open gates.
