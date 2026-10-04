# V304

- Added a fail-closed guard before destructive iOS scaffold refreshes.
- `bootstrap_ios_scaffold.sh` now detects manual signing, provisioning, entitlements, and Xcode target capabilities before moving/removing the existing `ios/` tree.
- If such configuration exists, bootstrap exits before touching `ios/` instead of silently deleting production signing/capability state.
- Added regression coverage for plain generated projects, development-team signing, target capabilities, entitlements files, and guard ordering.
- This does not claim to migrate arbitrary Xcode customizations; those must first be encoded as reproducible post-generation configuration.
