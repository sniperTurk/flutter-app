# V179 — iOS 15 deployment contract aligned with Flutter 3.47

- Continued directly from v178; no project restart.
- Raised the source/preflight iOS deployment floor from 13.0 to 15.0 to match the supported iOS range documented for Flutter 3.47.
- Updated the generated-scaffold contract so a pinned Flutter 3.47.2 scaffold targeting below iOS 15 fails closed.
- Extended unsigned archive metadata validation to read the built Runner.app `MinimumOSVersion` and reject values below iOS 15.0.
- Added offline regression coverage locking the iOS 15 floor into both source preflight and scaffold verification.
- No Flutter, Xcode, Simulator, physical-device, signing, TestFlight, or App Store Connect success is claimed by this Linux/offline verification.
