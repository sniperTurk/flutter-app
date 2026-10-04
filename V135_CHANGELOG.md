# V135 changelog

- Hardened iOS/App Store source preflight with a fail-closed deployment-target contract.
- `project.pbxproj` must now declare an iOS deployment target and every discovered target must be at least iOS 13.0.
- Added regression coverage for a missing deployment target and a stale iOS 12.0 target.
- No real Flutter/Xcode build claim is made by this source-only change.
