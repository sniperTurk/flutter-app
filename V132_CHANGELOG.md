# V132 CHANGELOG

- Promoted the V1 application release identity from development `0.1.0+1` to production `1.0.0+1` in `pubspec.yaml`.
- Hardened App Store source preflight so V1 must remain on marketing version `1.0.0` with a strictly positive build number; accidental regression to development/pre-release numbering now fails closed.
- Added regression coverage for wrong V1 marketing version and zero build number.
- No Flutter/Dart/Xcode execution is claimed in this environment. Existing external blockers (real resolver-generated `pubspec.lock`, public privacy-policy URL, generated iOS scaffold, real Simulator/device/build validation) remain open.
